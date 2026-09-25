import SpriteKit
import SwiftUI
import UIKit

/// Role: YearPlate. The one SpriteKit host. Bloom on a successful set. Owns no MoodEntry.
struct PlateBloomHost: UIViewRepresentable {
    var generation: Int
    var hue: UIColor
    var point: CGPoint
    var reduceMotion: Bool

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIView(context: Context) -> SKView {
        let view = SKView()
        view.allowsTransparency = true
        view.backgroundColor = .clear
        view.isUserInteractionEnabled = false
        view.ignoresSiblingOrder = true
        let scene = PlateBloomScene(size: CGSize(width: 1, height: 1))
        scene.scaleMode = .resizeFill
        scene.backgroundColor = .clear
        view.presentScene(scene)
        return view
    }

    func updateUIView(_ view: SKView, context: Context) {
        guard let scene = view.scene as? PlateBloomScene else { return }
        let size = view.bounds.size
        if size.width > 1, size.height > 1 {
            scene.size = size
        }
        guard generation > 0, context.coordinator.lastGeneration != generation else { return }
        guard size.width > 1, size.height > 1 else { return }
        context.coordinator.lastGeneration = generation
        let scenePoint = CGPoint(x: point.x, y: size.height - point.y)
        if reduceMotion {
            scene.fadeMark(color: hue, at: scenePoint)
        } else {
            scene.bloom(color: hue, at: scenePoint)
        }
    }

    final class Coordinator {
        var lastGeneration = 0
    }
}

/// Role: YearPlate. SpriteKit bloom scene. Reads the plate after commit. Owns no entries.
final class PlateBloomScene: SKScene {
    func bloom(color: UIColor, at point: CGPoint) {
        let node = SKShapeNode(circleOfRadius: 10)
        node.fillColor = color
        node.strokeColor = .clear
        node.position = point
        node.alpha = 0.88
        node.blendMode = .add
        addChild(node)
        let grow = SKAction.scale(to: 7, duration: 0.32)
        grow.timingMode = .easeOut
        let fade = SKAction.fadeOut(withDuration: 0.32)
        fade.timingMode = .easeOut
        node.run(SKAction.sequence([
            SKAction.group([grow, fade]),
            SKAction.removeFromParent()
        ]))
    }

    func fadeMark(color: UIColor, at point: CGPoint) {
        let node = SKShapeNode(circleOfRadius: 14)
        node.fillColor = color.withAlphaComponent(0.4)
        node.strokeColor = .clear
        node.position = point
        addChild(node)
        node.run(SKAction.sequence([
            SKAction.fadeOut(withDuration: 0.25),
            SKAction.removeFromParent()
        ]))
    }
}
