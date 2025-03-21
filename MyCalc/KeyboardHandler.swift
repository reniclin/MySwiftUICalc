//
//  KeyboardHandler.swift
//  MyCalc
//
//  Created by Renic Lin on 2025/3/21.
//

import Combine
import SwiftUI

class KeyboardHandler: ObservableObject {
    @Published var pressedKey: String? = nil

    // Map keyboard keys to calculator buttons
    private let keyMapping: [String: String] = [
        "0": "0", "1": "1", "2": "2", "3": "3", "4": "4",
        "5": "5", "6": "6", "7": "7", "8": "8", "9": "9",
        ".": ".", "+": "+", "-": "−", "*": "×", "/": "÷",
        "=": "=", "return": "=", "enter": "=",
        "delete": "AC", "backspace": "AC",
        "%": "%", "_": "+/-",  // underscore for +/- since there's no direct key
    ]

    init() {
        #if os(macOS)
            setupMacOSKeyboardMonitoring()
        #endif
    }

    // Clear the pressed key after a short delay to allow for visual feedback
    func clearPressedKey() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            self.pressedKey = nil
        }
    }

    #if os(macOS)
        private var cancellables = Set<AnyCancellable>()

        private var localEventMonitor: Any?

        private func setupMacOSKeyboardMonitoring() {
            // Only set up once when window becomes key
            NotificationCenter.default.publisher(
                for: NSWindow.didBecomeKeyNotification
            )
            .sink { [weak self] _ in
                // Remove any existing monitor first
                self?.removeLocalMonitor()
                // Then add a new one
                self?.addLocalMonitorForEvents()
            }
            .store(in: &cancellables)

            // Also handle when window resigns key to remove monitor
            NotificationCenter.default.publisher(
                for: NSWindow.didResignKeyNotification
            )
            .sink { [weak self] _ in
                self?.removeLocalMonitor()
            }
            .store(in: &cancellables)
        }

        private func addLocalMonitorForEvents() {
            // Store reference to the monitor so we can remove it later
            localEventMonitor = NSEvent.addLocalMonitorForEvents(
                matching: .keyDown
            ) { [weak self] event -> NSEvent? in
                self?.handleKeyEvent(event)
                return nil  // Tell the system this event has been handled and should not be propagated further"

            }
        }

        private func removeLocalMonitor() {
            if let monitor = localEventMonitor {
                NSEvent.removeMonitor(monitor)
                localEventMonitor = nil
            }
        }

        private func handleKeyEvent(_ event: NSEvent) {
            if event.keyCode == 51 {  // Backspace key
                processKey("backspace")
            } else if event.keyCode == 36 {  // Return key
                processKey("return")
            } else if let key = event.charactersIgnoringModifiers?.lowercased()
            {
                processKey(key)
            }
        }
    #endif

    #if os(iOS)
        func handleKeyPress(key: String) {
            processKey(key.lowercased())
        }
    #endif

    private func processKey(_ key: String) {
        if let mappedKey = keyMapping[key] {
            self.pressedKey = mappedKey
            clearPressedKey()
        }
    }

    // Function to check if a specific button should show pressed state
    func isKeyPressed(_ buttonTitle: String) -> Bool {
        return pressedKey == buttonTitle
    }
}

#if os(iOS)
    struct KeyboardCommandsModifier: ViewModifier {
        @ObservedObject var keyboardHandler: KeyboardHandler

        func body(content: Content) -> some View {
            content.background(
                KeyCommandsView(keyboardHandler: keyboardHandler))
        }

        // Hidden view that will handle key commands
        struct KeyCommandsView: UIViewRepresentable {
            var keyboardHandler: KeyboardHandler

            func makeUIView(context: Context) -> UIView {
                let view = KeyCommandsUIView(keyboardHandler: keyboardHandler)
                return view
            }

            func updateUIView(_ uiView: UIView, context: Context) {}

            class KeyCommandsUIView: UIView {
                var keyboardHandler: KeyboardHandler

                init(keyboardHandler: KeyboardHandler) {
                    self.keyboardHandler = keyboardHandler
                    super.init(frame: .zero)
                }

                required init?(coder: NSCoder) {
                    fatalError("init(coder:) has not been implemented")
                }

                override var canBecomeFirstResponder: Bool {
                    return true
                }

                override func didMoveToWindow() {
                    super.didMoveToWindow()
                    becomeFirstResponder()
                }

                override var keyCommands: [UIKeyCommand]? {
                    let commands = [
                        UIKeyCommand(
                            input: "0", modifierFlags: [],
                            action: #selector(keyPressed(_:))),
                        UIKeyCommand(
                            input: "1", modifierFlags: [],
                            action: #selector(keyPressed(_:))),
                        UIKeyCommand(
                            input: "2", modifierFlags: [],
                            action: #selector(keyPressed(_:))),
                        UIKeyCommand(
                            input: "3", modifierFlags: [],
                            action: #selector(keyPressed(_:))),
                        UIKeyCommand(
                            input: "4", modifierFlags: [],
                            action: #selector(keyPressed(_:))),
                        UIKeyCommand(
                            input: "5", modifierFlags: [],
                            action: #selector(keyPressed(_:))),
                        UIKeyCommand(
                            input: "6", modifierFlags: [],
                            action: #selector(keyPressed(_:))),
                        UIKeyCommand(
                            input: "7", modifierFlags: [],
                            action: #selector(keyPressed(_:))),
                        UIKeyCommand(
                            input: "8", modifierFlags: [],
                            action: #selector(keyPressed(_:))),
                        UIKeyCommand(
                            input: "9", modifierFlags: [],
                            action: #selector(keyPressed(_:))),
                        UIKeyCommand(
                            input: ".", modifierFlags: [],
                            action: #selector(keyPressed(_:))),
                        UIKeyCommand(
                            input: "+", modifierFlags: [],
                            action: #selector(keyPressed(_:))),
                        UIKeyCommand(
                            input: "-", modifierFlags: [],
                            action: #selector(keyPressed(_:))),
                        UIKeyCommand(
                            input: "*", modifierFlags: [],
                            action: #selector(keyPressed(_:))),
                        UIKeyCommand(
                            input: "/", modifierFlags: [],
                            action: #selector(keyPressed(_:))),
                        UIKeyCommand(
                            input: "=", modifierFlags: [],
                            action: #selector(keyPressed(_:))),
                        UIKeyCommand(
                            input: "%", modifierFlags: [],
                            action: #selector(keyPressed(_:))),
                        UIKeyCommand(
                            input: "_", modifierFlags: [],
                            action: #selector(keyPressed(_:))),
                        UIKeyCommand(
                            input: "\r", modifierFlags: [],
                            action: #selector(enterPressed)),
                        UIKeyCommand(
                            input: "\u{8}", modifierFlags: [],
                            action: #selector(backspacePressed)),
                    ]
                    return commands
                }

                @objc func keyPressed(_ sender: UIKeyCommand) {
                    if let key = sender.input {
                        keyboardHandler.handleKeyPress(key: key)
                    }
                }

                @objc func enterPressed() {
                    keyboardHandler.handleKeyPress(key: "return")
                }

                @objc func backspacePressed() {
                    keyboardHandler.handleKeyPress(key: "backspace")
                }
            }
        }
    }

    extension View {
        func observeKeyboard(using keyboardHandler: KeyboardHandler)
            -> some View
        {
            self.modifier(
                KeyboardCommandsModifier(keyboardHandler: keyboardHandler))
        }
    }
#endif
