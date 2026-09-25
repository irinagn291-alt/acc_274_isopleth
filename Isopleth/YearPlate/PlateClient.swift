import Foundation

/// Role: YearPlate. Typed transport failures. This product has no remote catalog.
enum PlateClientError: Error, Equatable, Sendable {
    case notFound
    case decoding
    case transport
    case cancelled
    case invalidResponse
}

/// Role: YearPlate. Sends one HTTP request. Injected so tests never hit the network.
protocol PlateTransport: Sendable {
    func data(for request: URLRequest) async throws -> (Data, URLResponse)
}

/// Role: YearPlate. URLSession transport. 15 s timeout. User-Agent on every request.
struct PlateSessionTransport: PlateTransport {
    let session: URLSession

    init(session: URLSession) {
        self.session = session
    }

    init() {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.timeoutIntervalForRequest = 15
        configuration.timeoutIntervalForResource = 15
        configuration.httpAdditionalHeaders = ["User-Agent": PlateIdentity.userAgent]
        self.session = URLSession(configuration: configuration)
    }

    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        try await session.data(for: request)
    }
}

/// Role: YearPlate. Accepts a JSON number or a numeric string. Missing stays nil.
struct LooseDouble: Sendable, Equatable {
    var value: Double?
}

extension LooseDouble: Decodable {
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if container.decodeNil() {
            value = nil
            return
        }
        if let number = try? container.decode(Double.self) {
            value = number
            return
        }
        if let number = try? container.decode(Int.self) {
            value = Double(number)
            return
        }
        if let text = try? container.decode(String.self) {
            value = Double(text)
            return
        }
        value = nil
    }
}

/// Role: YearPlate. Owns URLSession. Offline plate. Transport seam only. No catalog.
actor PlateClient {
    static let userAgent = PlateIdentity.userAgent

    private let transport: any PlateTransport
    private let decoder: JSONDecoder

    init(transport: any PlateTransport) {
        self.transport = transport
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .useDefaultKeys
        self.decoder = decoder
    }

    init() {
        self.init(transport: PlateSessionTransport())
    }

    func getJSON<DTO: Decodable>(_ type: DTO.Type, from url: URL) async throws -> DTO {
        try Task.checkCancellation()
        let data = try await fetch(makeRequest(url: url))
        do {
            return try decoder.decode(DTO.self, from: data)
        } catch is CancellationError {
            throw PlateClientError.cancelled
        } catch {
            throw PlateClientError.decoding
        }
    }

    private func makeRequest(url: URL) -> URLRequest {
        var request = URLRequest(url: url, timeoutInterval: 15)
        request.setValue(Self.userAgent, forHTTPHeaderField: "User-Agent")
        return request
    }

    private func fetch(_ request: URLRequest) async throws -> Data {
        do {
            return try await send(request)
        } catch let error as PlateClientError {
            throw error
        } catch is CancellationError {
            throw PlateClientError.cancelled
        } catch {
            if isCancelled(error) {
                throw PlateClientError.cancelled
            }
            guard isTransient(error) else { throw PlateClientError.transport }
            do {
                return try await send(request)
            } catch let error as PlateClientError {
                throw error
            } catch is CancellationError {
                throw PlateClientError.cancelled
            } catch {
                if isCancelled(error) { throw PlateClientError.cancelled }
                throw PlateClientError.transport
            }
        }
    }

    private func send(_ request: URLRequest) async throws -> Data {
        try Task.checkCancellation()
        let (data, response) = try await transport.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw PlateClientError.invalidResponse
        }
        if http.statusCode == 404 {
            throw PlateClientError.notFound
        }
        guard (200 ..< 300).contains(http.statusCode) else {
            throw PlateClientError.transport
        }
        return data
    }
}

private func isTransient(_ error: Error) -> Bool {
    guard let urlError = error as? URLError else { return false }
    switch urlError.code {
    case .timedOut, .networkConnectionLost, .notConnectedToInternet,
         .cannotConnectToHost, .cannotFindHost, .dnsLookupFailed:
        return true
    default:
        return false
    }
}

private func isCancelled(_ error: Error) -> Bool {
    if error is CancellationError { return true }
    return (error as? URLError)?.code == .cancelled
}
