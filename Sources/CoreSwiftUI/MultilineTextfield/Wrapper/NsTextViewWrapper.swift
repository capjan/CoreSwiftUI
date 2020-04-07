
//
//  NsTextViewWrapper.swift
//
//
//  Created by Jan Ruhlaender on 07.04.20.
//
//  All credits for this wrapper are going to Thiago Holanda (https://twitter.com/tholanda)

import SwiftUI

struct NsTextViewWrapper: NSViewRepresentable {
    @Binding var text: String
    @Binding var wordWrap: Bool

    var onEditingChanged    : () -> Void           = {}
    var onCommit            : () -> Void          = {}
    var onTextChange        : (String) -> Void   = { _ in }

    var fontSize: CGFloat = 12

    init(text: Binding<String>,
         onEditingChanged: (() -> Void)? = nil,
         onCommit: (() -> Void)? = nil,
         onTextChange: ((String) -> Void)? = nil,
         fontSize: Float = 12,
         wordWrap: Binding<Bool> = .constant(true)) {
        self._text = text
        self.onEditingChanged = onEditingChanged ?? {}
        self.onCommit = onCommit ?? {}
        self.onTextChange = onTextChange ?? {_ in }
        self.fontSize = CGFloat(fontSize)
        self._wordWrap = wordWrap
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeNSView(context: Context) -> CustomTextView {

        let textView = CustomTextView(text: self.text, font: .monospacedSystemFont(ofSize: self.fontSize, weight: .regular), wordWrap: self.wordWrap)
        textView.delegate = context.coordinator

        return textView
    }

    func updateNSView(_ view: CustomTextView, context: Context) {
        view.text = text
        view.selectedRanges = context.coordinator.selectedRanges
        if (view.font.pointSize != fontSize) {
            view.font = .monospacedSystemFont(ofSize: fontSize, weight: .regular)
        }
        view.updateWordWrap(isWordWrap: wordWrap)
    }
}

#if DEBUG
struct NsTextViewWrapper_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            NsTextViewWrapper(text: .constant("{ \n    planets { \n        name \n    }\n}"), wordWrap: .constant(false))
                .environment(\.colorScheme, .dark)
                .previewDisplayName("Dark Mode")

            NsTextViewWrapper(text: .constant("{ \n    planets { \n        name \n    }\n}"), wordWrap: .constant(false))
                .environment(\.colorScheme, .light)
                .previewDisplayName("Light Mode")
        }
    }
}
#endif


extension NsTextViewWrapper {

    class Coordinator: NSObject, NSTextViewDelegate {
        var parent: NsTextViewWrapper
        var selectedRanges: [NSValue] = []

        init(_ parent: NsTextViewWrapper) {
            self.parent = parent
        }

        func textDidBeginEditing(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else {
                return
            }

            self.parent.text = textView.string
            self.parent.onEditingChanged()
        }

        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else {
                return
            }

            self.parent.text = textView.string
            self.selectedRanges = textView.selectedRanges
        }

        func textDidEndEditing(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else {
                return
            }

            self.parent.text = textView.string
            self.parent.onCommit()
        }
    }
}

final class CustomTextView: NSView {
    private var isEditable: Bool
    public var font: NSFont {
        didSet {
            textView.font = font
        }
    }

    private var wordWrap: Bool

    weak var delegate: NSTextViewDelegate?

    var text: String {
        didSet {
            textView.string = text
        }
    }

    var selectedRanges: [NSValue] = [] {
        didSet {
            guard selectedRanges.count > 0 else {
                return
            }

            textView.selectedRanges = selectedRanges
        }
    }

    func updateWordWrap(isWordWrap: Bool) {
        guard isWordWrap != self.wordWrap else { return }
        if isWordWrap {
            scrollView.hasHorizontalRuler = false
            scrollView.hasHorizontalScroller = false
            textContainer.widthTracksTextView = true
            textContainer.containerSize = NSSize(
                width: scrollView.contentSize.width,
                height: CGFloat.greatestFiniteMagnitude
            )
            textView.isHorizontallyResizable = true
        } else {
            scrollView.hasHorizontalRuler = true
            scrollView.hasHorizontalScroller = true
            textContainer.widthTracksTextView = false
            textContainer.containerSize = NSSize(
                width: CGFloat.greatestFiniteMagnitude,
                height: CGFloat.greatestFiniteMagnitude
            )
            textView.isHorizontallyResizable = false
        }
        self.wordWrap = isWordWrap
    }

    func updateFontSize(newValue: Float) {
        textView.font = .monospacedSystemFont(ofSize: CGFloat(newValue), weight: .regular)
    }

    private lazy var scrollView: NSScrollView = {
        let scrollView = NSScrollView()
        scrollView.drawsBackground = true
        scrollView.borderType = .noBorder
        scrollView.hasVerticalScroller = true
        if self.wordWrap {
            scrollView.hasHorizontalRuler = false
            scrollView.hasHorizontalScroller = false
        } else {
            scrollView.hasHorizontalRuler = true
            scrollView.hasHorizontalScroller = true

        }


        scrollView.autoresizingMask = [.width, .height]
        scrollView.translatesAutoresizingMaskIntoConstraints = false

        return scrollView
    }()

    private lazy var textContainer: NSTextContainer = {

        let contentSize = scrollView.contentSize
        let result = NSTextContainer(containerSize: scrollView.frame.size)


        if self.wordWrap {
            result.widthTracksTextView = true
            result.containerSize = NSSize(
                width: contentSize.width,
                height: CGFloat.greatestFiniteMagnitude
            )
        }
        else {
            result.widthTracksTextView = false
            result.containerSize = NSSize(
                width: CGFloat.greatestFiniteMagnitude,
                height: CGFloat.greatestFiniteMagnitude
            )
        }
        return result
    }()

    private lazy var textView: NSTextView = {
        let contentSize = scrollView.contentSize
        let textStorage = NSTextStorage()


        let layoutManager = NSLayoutManager()
        textStorage.addLayoutManager(layoutManager)





        layoutManager.addTextContainer(textContainer)


        let textView                     = NSTextView(frame: .zero, textContainer: textContainer)
        textView.autoresizingMask        = .width
        textView.backgroundColor         = NSColor.textBackgroundColor
        textView.delegate                = self.delegate
        textView.drawsBackground         = true
        textView.font                    = self.font
        textView.isEditable              = self.isEditable

        if self.wordWrap {
            textView.isHorizontallyResizable = false
        } else {
            textView.isHorizontallyResizable = true
        }

        textView.isVerticallyResizable   = true
        textView.maxSize                 = NSSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
        textView.minSize                 = NSSize(width: 0, height: contentSize.height)
        textView.textColor               = NSColor.labelColor


        return textView
    }()

    // MARK: - Init
    init(text: String, isEditable: Bool = true, font: NSFont = NSFont.systemFont(ofSize: 32, weight: .ultraLight), wordWrap: Bool = true) {
        self.font       = font
        self.isEditable = isEditable
        self.text       = text
        self.wordWrap   = wordWrap

        super.init(frame: .zero)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Life cycle

    override func viewWillDraw() {
        super.viewWillDraw()

        setupScrollViewConstraints()
        setupTextView()
    }

    func setupScrollViewConstraints() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false

        addSubview(scrollView)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: topAnchor),
            scrollView.trailingAnchor.constraint(equalTo: trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: leadingAnchor)
        ])
    }

    func setupTextView() {
        scrollView.documentView = textView
    }
}
