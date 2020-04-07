//
//  MultilineTextField.swift
//  
//
//  Created by Jan Ruhlaender on 07.04.20.
//

import Foundation
import SwiftUI

public struct MultilineTextField: View {

    let textBinding: Binding<String>
    let fontSize: Float
    let wordWrap: Bool

    public init(text: Binding<String>, fontSize: Float = 12, wordWrap: Bool = true) {
        self.textBinding = text
        self.fontSize = fontSize
        self.wordWrap = wordWrap
    }

    public var body: some View {
        NsTextViewWrapper(text: textBinding, fontSize: fontSize, wordWrap: .constant(wordWrap))
    }
}
