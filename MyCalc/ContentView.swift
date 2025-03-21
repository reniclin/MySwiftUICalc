//
//  ContentView.swift
//  MyCalc
//
//  Created by Renic Lin on 2025/3/21.
//

import Combine
import SwiftData
import SwiftUI

struct ContentView: View {
    @State private var displayValue = "0"
    @State private var currentOperation: Operation? = nil
    @State private var previousValue: Double? = nil
    @State private var shouldResetDisplay = false
    @State private var isError = false
    @StateObject private var keyboardHandler = KeyboardHandler()

    @State private var cancellables = Set<AnyCancellable>()

    enum Operation {
        case add, subtract, multiply, divide
    }

    // Define calculator colors
    let operatorBackground = Color(
        red: 254 / 255, green: 159 / 255, blue: 10 / 255)
    let numbersBackground = Color(
        red: 51 / 255, green: 51 / 255, blue: 51 / 255)
    let specialBackground = Color(
        red: 165 / 255, green: 165 / 255, blue: 165 / 255)
    let errorColor = Color(red: 255 / 255, green: 69 / 255, blue: 58 / 255)

    // Get button spacing
    var buttonSpacing: CGFloat {
        #if os(iOS)
            let device = UIDevice.current.userInterfaceIdiom
            return device == .pad ? 20 : 14
        #elseif os(macOS)
            return 10
        #else
            return 14
        #endif
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.black.edgesIgnoringSafeArea(.all)

                VStack {
                    // Display screen - Use Spacer to automatically fill extra space while maintaining reasonable proportions
                    Spacer(minLength: 20)

                    HStack {
                        Spacer()
                        Text(displayValue)
                            .font(.system(size: displayFontSize(for: geometry)))
                            .fontWeight(.light)
                            .foregroundColor(isError ? errorColor : .white)
                            .padding(.trailing, 20)
                            .lineLimit(1)
                            .minimumScaleFactor(0.4)
                    }
                    .padding(.bottom, 10)
                    .frame(maxWidth: .infinity)

                    // Calculator buttons - Use Spacer to push the button area to the bottom of the screen
                    Spacer(minLength: 20)

                    buttonsLayout(geometry: geometry)
                }
                .padding(.horizontal, geometry.size.width * 0.05)
                .padding(.bottom, geometry.size.height * 0.05)
                .padding(.top, geometry.size.height * 0.05)  // Ensure consistent spacing at top and bottom
            }
        }
        #if os(macOS)
            .frame(width: 360, height: 530)
        #elseif os(iOS)
            .observeKeyboard(using: keyboardHandler)  // Add this line for iOS
        #endif
        .onAppear {
            setupKeyboardHandling()
        }
    }

    private func setupKeyboardHandling() {
        // React to keyboard presses
        keyboardHandler.objectWillChange
            .sink { [self] _ in
                if let pressedKey = keyboardHandler.pressedKey {
                    handleKeyPress(pressedKey)
                }
            }
            .store(in: &cancellables)
    }

    private func handleKeyPress(_ key: String) {
        switch key {
        case "0", "1", "2", "3", "4", "5", "6", "7", "8", "9":
            if !isError { appendDigit(key) }
        case ".":
            if !isError && !displayValue.contains(".") {
                displayValue += "."
            }
        case "+":
            if !isError { performOperation(.add) }
        case "−":
            if !isError { performOperation(.subtract) }
        case "×":
            if !isError { performOperation(.multiply) }
        case "÷":
            if !isError { performOperation(.divide) }
        case "=":
            if !isError { calculateResult() }
        case "AC":
            resetCalculator()
        case "%":
            if !isError {
                if let value = Double(displayValue) {
                    displayValue = String(format: "%g", value / 100)
                }
            }
        case "+/-":
            if !isError {
                if let value = Double(displayValue) {
                    displayValue = String(format: "%g", -value)
                }
            }
        default:
            break
        }
    }

    // Determine if display is in landscape mode
    private func isLandscapeDisplay(geometry: GeometryProxy) -> Bool {
        return geometry.size.width > geometry.size.height
    }

    // Calculate appropriate display font size for current screen
    private func displayFontSize(for geometry: GeometryProxy) -> CGFloat {
        #if os(iOS)
            let device = UIDevice.current.userInterfaceIdiom
            if device == .pad {
                return isLandscapeDisplay(geometry: geometry)
                    ? min(geometry.size.height * 0.15, 100)
                    : min(geometry.size.width * 0.2, 100)
            } else {
                return min(geometry.size.width * 0.2, 80)
            }
        #elseif os(macOS)
            return 50
        #else
            return 80
        #endif
    }

    // Calculate button size
    private func buttonSize(for geometry: GeometryProxy) -> CGFloat {
        #if os(iOS)
            let device = UIDevice.current.userInterfaceIdiom
            if device == .pad {
                if isLandscapeDisplay(geometry: geometry) {
                    // Landscape
                    return min(geometry.size.height * 0.13, 90)
                } else {
                    // Portrait
                    return min(geometry.size.width * 0.16, 100)
                }
            } else {
                // iPhone
                return min(geometry.size.width * 0.18, 80)
            }
        #elseif os(macOS)
            return 70
        #else
            return 80
        #endif
    }

    // Button layout, adapting to landscape and portrait orientations
    private func buttonsLayout(geometry: GeometryProxy) -> some View {
        let spacing = buttonSpacing

        #if os(iOS)
            // Calculate number of buttons per row
            let buttonsPerRow = 4
            // Calculate available width and height
            let availableWidth = geometry.size.width * 0.9  // Consider padding
            let availableHeight = geometry.size.height * 0.6  // Reserve space for display area and spacing
            // Calculate button width based on landscape or portrait orientation
            let buttonWidth =
                (availableWidth - (spacing * CGFloat(buttonsPerRow - 1)))
                / CGFloat(buttonsPerRow)
            // Calculate button height, ensuring appropriate height
            let device = UIDevice.current.userInterfaceIdiom
            let buttonHeight: CGFloat = {
                if isLandscapeDisplay(geometry: geometry) {
                    // Landscape, calculate height
                    return (availableHeight - (spacing * 4)) / 5  // 5 rows of buttons
                } else {
                    // Portrait, determine height based on device type
                    if device == .pad {
                        return (availableHeight - (spacing * 4)) / 5  // 5 rows of buttons
                    } else {
                        return buttonWidth
                    }
                }
            }()
        #else
            let buttonWidth = buttonSize(for: geometry)
            let buttonHeight = buttonSize(for: geometry)
        #endif

        return VStack(spacing: spacing) {
            HStack(spacing: spacing) {
                CalculatorButton(
                    title: "AC", color: specialBackground, width: buttonWidth,
                    height: buttonHeight,
                    isPressed: keyboardHandler.isKeyPressed("AC")
                ) {
                    resetCalculator()
                }
                CalculatorButton(
                    title: "+/-", color: specialBackground, width: buttonWidth,
                    height: buttonHeight,
                    isPressed: keyboardHandler.isKeyPressed("+/-")
                ) {
                    if !isError {
                        if let value = Double(displayValue) {
                            displayValue = String(format: "%g", -value)
                        }
                    }
                }
                CalculatorButton(
                    title: "%", color: specialBackground, width: buttonWidth,
                    height: buttonHeight,
                    isPressed: keyboardHandler.isKeyPressed("%")
                ) {
                    if !isError {
                        if let value = Double(displayValue) {
                            displayValue = String(format: "%g", value / 100)
                        }
                    }
                }
                CalculatorButton(
                    title: "÷", color: operatorBackground, width: buttonWidth,
                    height: buttonHeight,
                    isPressed: keyboardHandler.isKeyPressed("÷")
                ) {
                    if !isError {
                        performOperation(.divide)
                    }
                }
            }

            HStack(spacing: spacing) {
                CalculatorButton(
                    title: "7", color: numbersBackground, width: buttonWidth,
                    height: buttonHeight,
                    isPressed: keyboardHandler.isKeyPressed("7")
                ) {
                    if !isError { appendDigit("7") }
                }
                CalculatorButton(
                    title: "8", color: numbersBackground, width: buttonWidth,
                    height: buttonHeight,
                    isPressed: keyboardHandler.isKeyPressed("8")
                ) {
                    if !isError { appendDigit("8") }
                }
                CalculatorButton(
                    title: "9", color: numbersBackground, width: buttonWidth,
                    height: buttonHeight,
                    isPressed: keyboardHandler.isKeyPressed("9")
                ) {
                    if !isError { appendDigit("9") }
                }
                CalculatorButton(
                    title: "×", color: operatorBackground, width: buttonWidth,
                    height: buttonHeight,
                    isPressed: keyboardHandler.isKeyPressed("×")
                ) {
                    if !isError {
                        performOperation(.multiply)
                    }
                }
            }

            HStack(spacing: spacing) {
                CalculatorButton(
                    title: "4", color: numbersBackground, width: buttonWidth,
                    height: buttonHeight,
                    isPressed: keyboardHandler.isKeyPressed("4")
                ) {
                    if !isError { appendDigit("4") }
                }
                CalculatorButton(
                    title: "5", color: numbersBackground, width: buttonWidth,
                    height: buttonHeight,
                    isPressed: keyboardHandler.isKeyPressed("5")
                ) {
                    if !isError { appendDigit("5") }
                }
                CalculatorButton(
                    title: "6", color: numbersBackground, width: buttonWidth,
                    height: buttonHeight,
                    isPressed: keyboardHandler.isKeyPressed("6")
                ) {
                    if !isError { appendDigit("6") }
                }
                CalculatorButton(
                    title: "−", color: operatorBackground, width: buttonWidth,
                    height: buttonHeight,
                    isPressed: keyboardHandler.isKeyPressed("−")
                ) {
                    if !isError {
                        performOperation(.subtract)
                    }
                }
            }

            HStack(spacing: spacing) {
                CalculatorButton(
                    title: "1", color: numbersBackground, width: buttonWidth,
                    height: buttonHeight,
                    isPressed: keyboardHandler.isKeyPressed("1")
                ) {
                    if !isError { appendDigit("1") }
                }
                CalculatorButton(
                    title: "2", color: numbersBackground, width: buttonWidth,
                    height: buttonHeight,
                    isPressed: keyboardHandler.isKeyPressed("2")
                ) {
                    if !isError { appendDigit("2") }
                }
                CalculatorButton(
                    title: "3", color: numbersBackground, width: buttonWidth,
                    height: buttonHeight,
                    isPressed: keyboardHandler.isKeyPressed("3")
                ) {
                    if !isError { appendDigit("3") }
                }
                CalculatorButton(
                    title: "+", color: operatorBackground, width: buttonWidth,
                    height: buttonHeight,
                    isPressed: keyboardHandler.isKeyPressed("+")
                ) {
                    if !isError {
                        performOperation(.add)
                    }
                }
            }

            HStack(spacing: spacing) {
                // 0 button takes up two button widths plus one spacing
                ZeroButton(
                    width: (buttonWidth * 2) + spacing, height: buttonHeight,
                    isPressed: keyboardHandler.isKeyPressed("0")
                ) {
                    if !isError { appendDigit("0") }
                }
                CalculatorButton(
                    title: ".", color: numbersBackground, width: buttonWidth,
                    height: buttonHeight,
                    isPressed: keyboardHandler.isKeyPressed(".")
                ) {
                    if !isError {
                        if !displayValue.contains(".") {
                            displayValue += "."
                        }
                    }
                }
                CalculatorButton(
                    title: "=", color: operatorBackground, width: buttonWidth,
                    height: buttonHeight,
                    isPressed: keyboardHandler.isKeyPressed("=")
                ) {
                    if !isError {
                        calculateResult()
                    }
                }
            }
        }
    }

    private func resetCalculator() {
        displayValue = "0"
        currentOperation = nil
        previousValue = nil
        shouldResetDisplay = false
        isError = false
    }

    private func appendDigit(_ digit: String) {
        if shouldResetDisplay {
            displayValue = digit
            shouldResetDisplay = false
        } else {
            displayValue = displayValue == "0" ? digit : displayValue + digit
        }
    }

    private func performOperation(_ operation: Operation) {
        if let value = Double(displayValue) {
            if let prev = previousValue, let op = currentOperation {
                let result = calculate(prev, value, op)
                if isError {
                    return
                }
                displayValue = formatResult(result)
                previousValue = result
            } else {
                previousValue = value
            }
        }

        shouldResetDisplay = true
        currentOperation = operation
    }

    private func calculateResult() {
        if let value = Double(displayValue), let prev = previousValue,
            let op = currentOperation
        {
            let result = calculate(prev, value, op)
            if isError {
                return
            }
            displayValue = formatResult(result)
            previousValue = nil
            currentOperation = nil
        }
    }

    private func calculate(_ a: Double, _ b: Double, _ operation: Operation)
        -> Double
    {
        switch operation {
        case .add:
            return a + b
        case .subtract:
            return a - b
        case .multiply:
            return a * b
        case .divide:
            if b == 0 {
                displayValue = "Error: Division by Zero"
                isError = true
                return 0
            }
            return a / b
        }
    }

    private func formatResult(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 8

        return String(format: "%g", value)
    }
}

struct CalculatorButton: View {
    var title: String
    var color: Color
    var width: CGFloat
    var height: CGFloat
    var isPressed: Bool
    var action: () -> Void

    init(
        title: String, color: Color, width: CGFloat, height: CGFloat,
        isPressed: Bool = false, action: @escaping () -> Void
    ) {
        self.title = title
        self.color = color
        self.width = width
        self.height = height
        self.isPressed = isPressed
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: min(width, height) * 0.45))
                .fontWeight(.medium)
                .foregroundColor(.white)
                .frame(width: width, height: height)
                .background(isPressed ? color.opacity(0.6) : color)
                .clipShape(Capsule())
                .scaleEffect(isPressed ? 0.95 : 1.0)
                .animation(.easeInOut(duration: 0.1), value: isPressed)
        }
        #if os(macOS)
            .buttonStyle(PlainButtonStyle())
        #endif
    }
}

// Modified "0" button that can adapt to different widths
struct ZeroButton: View {
    var width: CGFloat
    var height: CGFloat
    var isPressed: Bool
    var action: () -> Void

    init(
        width: CGFloat, height: CGFloat, isPressed: Bool = false,
        action: @escaping () -> Void
    ) {
        self.width = width
        self.height = height
        self.isPressed = isPressed
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            Text("0")
                .font(.system(size: height * 0.45))
                .fontWeight(.medium)
                .foregroundColor(.white)
                .frame(width: width, height: height, alignment: .center)
                .background(
                    isPressed
                        ? Color(red: 51 / 255, green: 51 / 255, blue: 51 / 255)
                            .opacity(0.6)
                        : Color(red: 51 / 255, green: 51 / 255, blue: 51 / 255)
                )
                .clipShape(Capsule())
                .scaleEffect(isPressed ? 0.95 : 1.0)
                .animation(.easeInOut(duration: 0.1), value: isPressed)
        }
        #if os(macOS)
            .buttonStyle(PlainButtonStyle())
        #endif
    }
}

#if os(macOS)
    // Extension to fix macOS window size
    extension NSWindow {
        open override func awakeFromNib() {
            super.awakeFromNib()
            self.styleMask.remove(.resizable)
            self.setContentSize(NSSize(width: 360, height: 530))
            self.center()
        }
    }
#endif

#Preview() {
    ContentView()
        .modelContainer(for: Item.self, inMemory: true)
}

/*

import SwiftUI
import SwiftData

struct ContentView: View {
    @State private var displayValue = "0"
    @State private var currentOperation: Operation? = nil
    @State private var previousValue: Double? = nil
    @State private var shouldResetDisplay = false
    @State private var isError = false

    enum Operation {
        case add, subtract, multiply, divide
    }

    // Define calculator colors
    let operatorBackground = Color(red: 254/255, green: 159/255, blue: 10/255)
    let numbersBackground = Color(red: 51/255, green: 51/255, blue: 51/255)
    let specialBackground = Color(red: 165/255, green: 165/255, blue: 165/255)
    let errorColor = Color(red: 255/255, green: 69/255, blue: 58/255)

    // Get button spacing
    var buttonSpacing: CGFloat {
#if os(iOS)
        let device = UIDevice.current.userInterfaceIdiom
        return device == .pad ? 20 : 14
#elseif os(macOS)
        return 10
#else
        return 14
#endif
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.black.edgesIgnoringSafeArea(.all)

                VStack {
                    // Display screen - Use Spacer to automatically fill extra space while maintaining reasonable proportions
                    Spacer(minLength: 20)

                    HStack {
                        Spacer()
                        Text(displayValue)
                            .font(.system(size: displayFontSize(for: geometry)))
                            .fontWeight(.light)
                            .foregroundColor(isError ? errorColor : .white)
                            .padding(.trailing, 20)
                            .lineLimit(1)
                            .minimumScaleFactor(0.4)
                    }
                    .padding(.bottom, 10)
                    .frame(maxWidth: .infinity)

                    // Calculator buttons - Use Spacer to push the button area to the bottom of the screen
                    Spacer(minLength: 20)

                    buttonsLayout(geometry: geometry)
                }
                .padding(.horizontal, geometry.size.width * 0.05)
                .padding(.bottom, geometry.size.height * 0.05)
                .padding(.top, geometry.size.height * 0.05) // Ensure consistent spacing at top and bottom
            }
        }
#if os(macOS)
        .frame(width: 360, height: 530)
#endif
    }

    // Determine if display is in landscape mode
    private func isLandscapeDisplay(geometry: GeometryProxy) -> Bool {
        return geometry.size.width > geometry.size.height
    }

    // Calculate appropriate display font size for current screen
    private func displayFontSize(for geometry: GeometryProxy) -> CGFloat {
#if os(iOS)
        let device = UIDevice.current.userInterfaceIdiom
        if device == .pad {
            return isLandscapeDisplay(geometry: geometry)
            ? min(geometry.size.height * 0.15, 100)
            : min(geometry.size.width * 0.2, 100)
        } else {
            return min(geometry.size.width * 0.2, 80)
        }
#elseif os(macOS)
        return 50
#else
        return 80
#endif
    }

    // Calculate button size
    private func buttonSize(for geometry: GeometryProxy) -> CGFloat {
#if os(iOS)
        let device = UIDevice.current.userInterfaceIdiom
        if device == .pad {
            if isLandscapeDisplay(geometry: geometry) {
                // Landscape
                return min(geometry.size.height * 0.13, 90)
            } else {
                // Portrait
                return min(geometry.size.width * 0.16, 100)
            }
        } else {
            // iPhone
            return min(geometry.size.width * 0.18, 80)
        }
#elseif os(macOS)
        return 70
#else
        return 80
#endif
    }

    // Button layout, adapting to landscape and portrait orientations
    private func buttonsLayout(geometry: GeometryProxy) -> some View {
        let spacing = buttonSpacing

#if os(iOS)
        // Calculate number of buttons per row
        let buttonsPerRow = 4
        // Calculate available width and height
        let availableWidth = geometry.size.width * 0.9  // Consider padding
        let availableHeight = geometry.size.height * 0.6  // Reserve space for display area and spacing
        // Calculate button width based on landscape or portrait orientation
        let buttonWidth = (availableWidth - (spacing * CGFloat(buttonsPerRow - 1))) / CGFloat(buttonsPerRow)
        // Calculate button height, ensuring appropriate height
        let device = UIDevice.current.userInterfaceIdiom
        let buttonHeight: CGFloat = {
            if isLandscapeDisplay(geometry: geometry) {
                // Landscape, calculate height
                return (availableHeight - (spacing * 4)) / 5  // 5 rows of buttons
            } else {
                // Portrait, determine height based on device type
                if device == .pad {
                    return (availableHeight - (spacing * 4)) / 5  // 5 rows of buttons
                } else {
                    return buttonWidth
                }
            }
        }()
#else
        let buttonWidth = buttonSize(for: geometry)
        let buttonHeight = buttonSize(for: geometry)
#endif

        return VStack(spacing: spacing) {
            HStack(spacing: spacing) {
                CalculatorButton(title: "AC", color: specialBackground, width: buttonWidth, height: buttonHeight) {
                    resetCalculator()
                }
                CalculatorButton(title: "+/-", color: specialBackground, width: buttonWidth, height: buttonHeight) {
                    if !isError {
                        if let value = Double(displayValue) {
                            displayValue = String(format: "%g", -value)
                        }
                    }
                }
                CalculatorButton(title: "%", color: specialBackground, width: buttonWidth, height: buttonHeight) {
                    if !isError {
                        if let value = Double(displayValue) {
                            displayValue = String(format: "%g", value / 100)
                        }
                    }
                }
                CalculatorButton(title: "÷", color: operatorBackground, width: buttonWidth, height: buttonHeight) {
                    if !isError {
                        performOperation(.divide)
                    }
                }
            }

            HStack(spacing: spacing) {
                CalculatorButton(title: "7", color: numbersBackground, width: buttonWidth, height: buttonHeight) {
                    if !isError { appendDigit("7") }
                }
                CalculatorButton(title: "8", color: numbersBackground, width: buttonWidth, height: buttonHeight) {
                    if !isError { appendDigit("8") }
                }
                CalculatorButton(title: "9", color: numbersBackground, width: buttonWidth, height: buttonHeight) {
                    if !isError { appendDigit("9") }
                }
                CalculatorButton(title: "×", color: operatorBackground, width: buttonWidth, height: buttonHeight) {
                    if !isError {
                        performOperation(.multiply)
                    }
                }
            }

            HStack(spacing: spacing) {
                CalculatorButton(title: "4", color: numbersBackground, width: buttonWidth, height: buttonHeight) {
                    if !isError { appendDigit("4") }
                }
                CalculatorButton(title: "5", color: numbersBackground, width: buttonWidth, height: buttonHeight) {
                    if !isError { appendDigit("5") }
                }
                CalculatorButton(title: "6", color: numbersBackground, width: buttonWidth, height: buttonHeight) {
                    if !isError { appendDigit("6") }
                }
                CalculatorButton(title: "−", color: operatorBackground, width: buttonWidth, height: buttonHeight) {
                    if !isError {
                        performOperation(.subtract)
                    }
                }
            }

            HStack(spacing: spacing) {
                CalculatorButton(title: "1", color: numbersBackground, width: buttonWidth, height: buttonHeight) {
                    if !isError { appendDigit("1") }
                }
                CalculatorButton(title: "2", color: numbersBackground, width: buttonWidth, height: buttonHeight) {
                    if !isError { appendDigit("2") }
                }
                CalculatorButton(title: "3", color: numbersBackground, width: buttonWidth, height: buttonHeight) {
                    if !isError { appendDigit("3") }
                }
                CalculatorButton(title: "+", color: operatorBackground, width: buttonWidth, height: buttonHeight) {
                    if !isError {
                        performOperation(.add)
                    }
                }
            }

            HStack(spacing: spacing) {
                // 0 button takes up two button widths plus one spacing
                ZeroButton(width: (buttonWidth * 2) + spacing, height: buttonHeight) {
                    if !isError { appendDigit("0") }
                }
                CalculatorButton(title: ".", color: numbersBackground, width: buttonWidth, height: buttonHeight) {
                    if !isError {
                        if !displayValue.contains(".") {
                            displayValue += "."
                        }
                    }
                }
                CalculatorButton(title: "=", color: operatorBackground, width: buttonWidth, height: buttonHeight) {
                    if !isError {
                        calculateResult()
                    }
                }
            }
        }
    }

    private func resetCalculator() {
        displayValue = "0"
        currentOperation = nil
        previousValue = nil
        shouldResetDisplay = false
        isError = false
    }

    private func appendDigit(_ digit: String) {
        if shouldResetDisplay {
            displayValue = digit
            shouldResetDisplay = false
        } else {
            displayValue = displayValue == "0" ? digit : displayValue + digit
        }
    }

    private func performOperation(_ operation: Operation) {
        if let value = Double(displayValue) {
            if let prev = previousValue, let op = currentOperation {
                let result = calculate(prev, value, op)
                if isError {
                    return
                }
                displayValue = formatResult(result)
                previousValue = result
            } else {
                previousValue = value
            }
        }

        shouldResetDisplay = true
        currentOperation = operation
    }

    private func calculateResult() {
        if let value = Double(displayValue), let prev = previousValue, let op = currentOperation {
            let result = calculate(prev, value, op)
            if isError {
                return
            }
            displayValue = formatResult(result)
            previousValue = nil
            currentOperation = nil
        }
    }

    private func calculate(_ a: Double, _ b: Double, _ operation: Operation) -> Double {
        switch operation {
        case .add:
            return a + b
        case .subtract:
            return a - b
        case .multiply:
            return a * b
        case .divide:
            if b == 0 {
                displayValue = "Error: Division by Zero"
                isError = true
                return 0
            }
            return a / b
        }
    }

    private func formatResult(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 8

        return String(format: "%g", value)
    }
}

struct CalculatorButton: View {
    var title: String
    var color: Color
    var width: CGFloat
    var height: CGFloat
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: min(width, height) * 0.45))
                .fontWeight(.medium)
                .foregroundColor(.white)
                .frame(width: width, height: height)
                .background(color)
                .clipShape(Capsule()) // Use Capsule instead of Circle to allow shape stretching
        }
#if os(macOS)
        .buttonStyle(PlainButtonStyle())
#endif
    }
}

// Modified "0" button that can adapt to different widths
struct ZeroButton: View {
    var width: CGFloat
    var height: CGFloat
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Text("0")
                .font(.system(size: height * 0.45))
                .fontWeight(.medium)
                .foregroundColor(.white)
                .frame(width: width, height: height, alignment: .center) // Changed to center alignment
                .background(Color(red: 51/255, green: 51/255, blue: 51/255))
                .clipShape(Capsule())
        }
#if os(macOS)
        .buttonStyle(PlainButtonStyle())
#endif

    }
}

#if os(macOS)
// Extension to fix macOS window size
extension NSWindow {
    open override func awakeFromNib() {
        super.awakeFromNib()
        self.styleMask.remove(.resizable)
        self.setContentSize(NSSize(width: 360, height: 530))
        self.center()
    }
}
#endif

#Preview() {
    ContentView()
        .modelContainer(for: Item.self, inMemory: true)
}
*/
