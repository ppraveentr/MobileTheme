//
//  NavigationContentView.swift
//  ExampleApp
//
//  Created by Praveen Prabhakar on 17/09/22.
//

import SwiftUI

/// - Parameters:
///   - title: Title of the list.
///   - content: A closure that creates the content for each instance in the group.
struct NavigationContentView<Content>: View where Content: View {
    let title: String
    @ViewBuilder var content: () -> Content

    var body: some View {
        HStack {
            Text(title)
            Spacer()
            Image(systemName: "chevron.right")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 7)
        }
        .foregroundColor(.blue)
        .background(
            NavigationLink("") { content() }
                .opacity(0)
        )
    }
}
