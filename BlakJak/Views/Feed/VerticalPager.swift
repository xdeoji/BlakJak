import SwiftUI
import UIKit

struct VerticalPager<Content: View>: UIViewControllerRepresentable {
    @Binding var currentPage: Int
    let pageCount: Int
    let content: (Int) -> Content
    var isScrollEnabled: Bool = true

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIViewController(context: Context) -> UIPageViewController {
        let pvc = UIPageViewController(
            transitionStyle: .scroll,
            navigationOrientation: .vertical,
            options: [.interPageSpacing: 0]
        )
        pvc.dataSource = context.coordinator
        pvc.delegate = context.coordinator
        pvc.view.backgroundColor = .clear

        let initial = makeHostingController(for: currentPage)
        pvc.setViewControllers([initial], direction: .forward, animated: false)

        return pvc
    }

    func updateUIViewController(_ pvc: UIPageViewController, context: Context) {
        let coord = context.coordinator
        coord.parent = self

        // Update scroll enabled state
        pvc.dataSource = isScrollEnabled ? coord : nil

        // Only programmatically scroll if the binding changed from outside (not from the delegate)
        if currentPage != coord.lastReportedPage {
            let direction: UIPageViewController.NavigationDirection =
                currentPage > coord.lastReportedPage ? .forward : .reverse
            let vc = makeHostingController(for: currentPage)
            coord.lastReportedPage = currentPage
            pvc.setViewControllers([vc], direction: direction, animated: true)
        }
    }

    private func makeHostingController(for page: Int) -> UIHostingController<AnyView> {
        let clamped = min(max(page, 0), max(pageCount - 1, 0))
        let view = AnyView(
            content(clamped)
                .ignoresSafeArea()
        )
        let hc = UIHostingController(rootView: view)
        hc.view.backgroundColor = .clear
        hc.view.tag = clamped
        return hc
    }

    class Coordinator: NSObject, UIPageViewControllerDataSource, UIPageViewControllerDelegate {
        var parent: VerticalPager
        var lastReportedPage: Int

        init(_ parent: VerticalPager) {
            self.parent = parent
            self.lastReportedPage = parent.currentPage
        }

        func pageViewController(_ pvc: UIPageViewController,
                                 viewControllerBefore vc: UIViewController) -> UIViewController? {
            let page = vc.view.tag
            guard page > 0 else { return nil }
            return parent.makeHostingController(for: page - 1)
        }

        func pageViewController(_ pvc: UIPageViewController,
                                 viewControllerAfter vc: UIViewController) -> UIViewController? {
            let page = vc.view.tag
            guard page < parent.pageCount - 1 else { return nil }
            return parent.makeHostingController(for: page + 1)
        }

        func pageViewController(_ pvc: UIPageViewController,
                                 didFinishAnimating finished: Bool,
                                 previousViewControllers: [UIViewController],
                                 transitionCompleted completed: Bool) {
            guard completed,
                  let visible = pvc.viewControllers?.first else { return }
            let page = visible.view.tag
            lastReportedPage = page
            DispatchQueue.main.async {
                self.parent.currentPage = page
            }
        }
    }
}
