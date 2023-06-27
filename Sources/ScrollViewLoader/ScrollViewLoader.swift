
import SwiftUI
import UIKit
import Introspect

public enum OffsetTrigger {
    case relative(CGFloat)
    case absolute(CGFloat)
}

extension View {
    public func shouldLoadMore(bottomDistance offsetTrigger: OffsetTrigger = .relative(0.5),
                        shouldLoadMore: @escaping () async -> ()) -> some View  {
        return DelegateHolder(offsetNotifier: ScrollOffsetNotifier(offsetTrigger: offsetTrigger,
                                                                   onNotify: shouldLoadMore),
                              content: self)
    }
}

struct DelegateHolder<Content: View>: View {
    
    @StateObject var offsetNotifier: ScrollOffsetNotifier
    var content: Content
    
    var body: some View {
        content
            .introspectScrollView { scrollView in
                scrollView.delegate = offsetNotifier
                scrollView.addObserver(offsetNotifier, forKeyPath: "contentSize", context: nil)
                offsetNotifier.scrollViewDidScroll(scrollView)
            }
    }
}

class ScrollOffsetNotifier: NSObject, UIScrollViewDelegate, ObservableObject {
    
    let onNotify: () async -> ()
    private var canNotify = true
    private var trigger: OffsetTrigger
    private var oldContentHeight: Double = 0
    
    init(offsetTrigger: OffsetTrigger, onNotify: @escaping () async -> ()) {
        self.trigger = offsetTrigger
        self.onNotify = onNotify
    }
    
    deinit {
        removeObserver(self, forKeyPath: "contentSize")
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
        
        Task { @MainActor in
            if bottomOffset < triggerHeight, canNotify {
                oldContentHeight = scrollView.contentSize.height
                canNotify = false
                await onNotify()
            }
            canNotify = bottomOffset >= triggerHeight || oldContentHeight != scrollView.contentSize.height
        }
    }
}
