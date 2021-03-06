//
// Copyright (c) Vatsal Manot
//

#if os(iOS) || os(tvOS) || targetEnvironment(macCatalyst)

import Combine
import Swift
import SwiftUI
import UIKit

/// An object representing the keyboard.
public final class Keyboard: ObservableObject {
    public static let main = Keyboard()
    
    @Published public var state: State = .default
    
    public var isShowing: Bool {
        state.height.map({ $0 != 0 }) ?? false
    }
    
    private var subscription: AnyCancellable?
    
    public init(notificationCenter: NotificationCenter = .default) {
        self.subscription = notificationCenter
            .publisher(for: UIResponder.keyboardWillChangeFrameNotification)
            .compactMap({ Keyboard.State(notification: $0, screen: .main) })
            .assign(to: \.state, on: self)
    }
    
    public func dismiss() {
        if isShowing {
            UIApplication.shared.firstKeyWindow?.endEditing(true)
        }
    }
    
    public class func dismiss() {
        if Keyboard.main.isShowing {
            UIApplication.shared.firstKeyWindow?.endEditing(true)
        }
    }
}

extension Keyboard {
    public struct State {
        public static let `default` = State()
        
        public let animationDuration: TimeInterval
        public let animationCurve: UInt?
        public let keyboardFrame: CGRect?
        public let height: CGFloat?
        
        private init() {
            self.animationDuration = 0.25
            self.animationCurve = 0
            self.keyboardFrame = nil
            self.height = nil
        }
        
        init?(notification: Notification, screen: Screen) {
            guard
                let userInfo = notification.userInfo,
                let animationDuration = userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval,
                let animationCurve = userInfo[UIResponder.keyboardAnimationCurveUserInfoKey] as? UInt
                else {
                    return nil
            }
            
            self.animationDuration = animationDuration
            self.animationCurve = animationCurve
            
            if let keyboardFrame = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
                self.keyboardFrame = keyboardFrame
                
                if keyboardFrame.origin.y == screen.bounds.height {
                    self.height = 0
                } else {
                    self.height = keyboardFrame.height
                }
            } else {
                self.keyboardFrame = nil
                self.height = nil
            }
        }
    }
}

// MARK: - Helpers -

struct HiddenIfKeyboardActive: ViewModifier {
    @ObservedObject var keyboard: Keyboard
    
    init() {
        keyboard = .main
    }
    
    func body(content: Content) -> some View {
        content.hidden(keyboard.isShowing)
    }
}

struct VisibleIfKeyboardActive: ViewModifier {
    @ObservedObject var keyboard: Keyboard
    
    init() {
        keyboard = .main
    }
    
    func body(content: Content) -> some View {
        content.hidden(!keyboard.isShowing)
    }
}

struct RemoveIfKeyboardActive: ViewModifier {
    @ObservedObject var keyboard: Keyboard
    
    init() {
        keyboard = .main
    }
    
    func body(content: Content) -> some View {
        Group {
            if keyboard.isShowing {
                EmptyView()
            } else {
                content
            }
        }
    }
}

struct AddIfKeyboardActive: ViewModifier {
    @ObservedObject var keyboard: Keyboard
    
    init() {
        keyboard = .main
    }
    
    func body(content: Content) -> some View {
        Group {
            if keyboard.isShowing {
                content
            } else {
                EmptyView()
            }
        }
    }
}

extension View {
    public func hiddenIfKeyboardActive() -> some View {
        modifier(HiddenIfKeyboardActive())
    }
    
    public func visibleIfKeyboardActive() -> some View {
        modifier(VisibleIfKeyboardActive())
    }

    public func removeIfKeyboardActive() -> some View {
        modifier(RemoveIfKeyboardActive())
    }
    
    public func addIfKeyboardActive() -> some View {
        modifier(AddIfKeyboardActive())
    }
}

#endif
