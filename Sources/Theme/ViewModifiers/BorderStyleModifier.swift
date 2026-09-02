//
//  BorderStyleModifier.swift
//  Theme
//
//  Created by Praveen Prabhakar on 28/03/23.
//

import SwiftUI

public struct BorderStyleModifier: ViewModifier {
    var themeValue: ThemeModel.StyleBorder?
    @Environment(\.colorScheme) var colorScheme

    public func body(content: Content) -> some View {
		if themeValue != nil {
			let shape = generateShape()
            if let color {
				content
                    .clipShape(shape)
                    .background(shape.stroke(color, lineWidth: thickness))
			} else {
				content
					.clipShape(shape)
			}
		} else {
			content
		}
	}
}

public extension View {
	/// Call this function to set the clip style
	/// - Parameters:
	///   - style: ``ThemeModel.StyleBorder`` value from themes
	/// - Returns: Modified ``View`` that incorporates the view modifier.
	func theme(_ borderStyle: ThemeModel.StyleBorder?) -> some View {
		modifier(BorderStyleModifier(themeValue: borderStyle))
	}
}

private extension BorderStyleModifier {
    var radius: CGFloat {
        let value = themeValue?.radius?.first { $0 > 0.0 }
        return CGFloat(value ?? 0.0)
    }

    var thickness: CGFloat {
        themeValue?.thickness ?? 1.0
    }

    var color: Color? {
        themeValue?.color?.value(colorScheme)
    }

    var corners: RectCorner {
        RectCorner.corners(themeValue?.radius)
    }

    func generateShape() -> BezierPathShape {
        BezierPathShape(radius: radius, corners: corners)
    }
}

// MARK: Preview

struct BorderStyleModifier_Previews: PreviewProvider {
	static let cancelStyle: ThemeModel.StyleBorder = {
		var syle = ThemeModel.StyleBorder()
		syle.radius = [8]
        syle.color = .init("#EE2C4A".getColor())
		syle.thickness = 2
		return syle
	}()

	static let doneStyle: ThemeModel.StyleBorder = {
		var syle = ThemeModel.StyleBorder()
		syle.radius = [10]
        syle.color = .init("#F9DAE0".getColor())
		syle.thickness = 2
		return syle
	}()

	static var previews: some View {
		HStack {
			Button("Cancel") {
                debugPrint("")
			}.padding()
				.theme(.background(color: .init(.yellow, dark: .blue)))
				.theme(cancelStyle)

			Button("Done") {
                debugPrint("")
			}.padding()
				.theme(doneStyle)
		}
	}
}
