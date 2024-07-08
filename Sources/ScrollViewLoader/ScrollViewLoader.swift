
import SwiftUI
import UIKit
import SwiftUIIntrospect

public enum HeightChangeConfig {
    case always
    case until(TimeInterval)
    case never
}

public enum OffsetTrigger {
    case relative(CGFloat)
    case absolute(CGFloat)
}

extension View {
    public func shouldLoadMore(bottomDistance offsetTrigger: OffsetTrigger = .relative(0.5),
                               waitForHeightChange: HeightChangeConfig = .until(2),
                               shouldLoadMore: @escaping () async -> ()) -> some View  {
        return DelegateHolder(offsetNotifier: ScrollOffsetNotifier(offsetTrigger: offsetTrigger,
                                                                   waitForHeightChange: waitForHeightChange,
                                                                   onNotify: shouldLoadMore),
                              content: self)
    }
    
    public func shouldLoadMore(bottomDistance offsetTrigger: OffsetTrigger = .relative(0.5),
                               waitForHeightChange: HeightChangeConfig = .until(2),
                               shouldLoadMore: @escaping (_ done: @escaping () -> ()) -> ()) -> some View  {
        return DelegateHolder(offsetNotifier: ScrollOffsetNotifier(offsetTrigger: offsetTrigger,
                                                                   waitForHeightChange: waitForHeightChange,
                                                                   onNotify: {
            await withCheckedContinuation { continuation in
                shouldLoadMore {
                    continuation.resume()
                }
            }
        }),
                              content: self)
    }
}

struct DelegateHolder<Content: View>: View {
    
    @StateObject var offsetNotifier: ScrollOffsetNotifier
    var content: Content
    
    var body: some View {
        content
            .introspect(.scrollView, on: .iOS(.v15, .v16, .v17, .v18)) { scrollView in
                scrollView.delegate = offsetNotifier
                offsetNotifier.scrollView = scrollView
                offsetNotifier.scrollViewDidScroll(scrollView)
            }
    }
}

class ScrollOffsetNotifier: NSObject, UIScrollViewDelegate, ObservableObject {
    
    let onNotify: () async -> ()
    private var canNotify = true
    private var trigger: OffsetTrigger
    private var oldContentHeight: Double = 0
    private var waitForHeightChange: HeightChangeConfig
    private var isTimerRunning = false
    weak var scrollView: UIScrollView? {
        didSet {
            scrollView?.addObserver(self, forKeyPath: "contentSize", context: nil)
        }
    }
    
    init(offsetTrigger: OffsetTrigger, waitForHeightChange: HeightChangeConfig, onNotify: @escaping () async -> ()) {
        self.trigger = offsetTrigger
        self.onNotify = onNotify
        self.waitForHeightChange = waitForHeightChange
    }
    
    deinit {
        scrollView?.removeObserver(self, forKeyPath: "contentSize")
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey: Any]?, context: UnsafeMutableRawPointer?) {
        guard let scrollView = object as? UIScrollView else {
            return
        }
        
        scrollViewDidScroll(scrollView)
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        
        let triggerHeight: CGFloat
        
        switch trigger {
        case let .absolute(offset):
            triggerHeight = offset
        case let .relative(percent):
            triggerHeight = scrollView.visibleSize.height * percent
        }
        
        let bottomOffset = (scrollView.contentSize.height + scrollView.contentInset.bottom) - (scrollView.contentOffset.y + scrollView.visibleSize.height)
        var heightChanged = false
        
        switch waitForHeightChange {
        case .always:
            heightChanged = oldContentHeight != scrollView.contentSize.height
        case .until(let timeInterval):
            heightChanged = oldContentHeight != scrollView.contentSize.height
            if !isTimerRunning {
                isTimerRunning = true
                DispatchQueue.main.asyncAfter(deadline: .now() + timeInterval) {
                    self.oldContentHeight = 0
                    self.isTimerRunning = false
                }
            }
        case .never:
            heightChanged = true
        }
        
        Task { @MainActor in
            guard canNotify else { return }
            if bottomOffset < triggerHeight, heightChanged {
                oldContentHeight = scrollView.contentSize.height
                canNotify = false
                await onNotify()
                canNotify = true
            }
        }
    }
}
