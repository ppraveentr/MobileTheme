//
//  GradientModifier.swift
//  Theme
//
//  Created by Praveen Prabhakar on 28/03/23.
//

import SwiftUI
import ThemeCore

typealias StyleGradient = ThemeJSONModel.GradientModel

struct GradientModifier: ViewModifier {
	var style: StyleGradient?

	func body(content: Content) -> some View {
		if let style {
			let gradient = Self.generateGradient(style)
			content
				.background(gradient)
		} else {
			content
		}
	}
}

private extension GradientModifier {
	static func getColors(_ colors: [String]) -> [Color] {
		colors.map { $0.getColor() }
	}

	static func generateGradient(_ style: StyleGradient) -> LinearGradient {
		let colors = Self.getColors(style.colors)
		if let locations = style.locations {
			let stops = zip(colors, locations).map { Gradient.Stop(color: $0, location: $1) }
			return LinearGradient(stops: stops, startPoint: .top, endPoint: .bottom)
		}
		return LinearGradient(colors: colors, startPoint: .top, endPoint: .bottom)
	}
}

extension View {
	/// Call this function to set the clip style
	/// - Parameters:
	///   - style: ``ThemeStructure.StyleGradient`` value from themes
	/// - Returns: Modified ``View`` that incorporates the view modifier.
	func gradientStyle(_ gradientStyle: StyleGradient?) -> some View {
		modifier(GradientModifier(style: gradientStyle))
	}
}
