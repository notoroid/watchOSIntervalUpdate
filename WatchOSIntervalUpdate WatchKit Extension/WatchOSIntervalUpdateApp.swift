//
//  WatchOSIntervalUpdateApp.swift
//  WatchOSIntervalUpdate WatchKit Extension
//
//  Created by 能登 要 on 2021/12/15.
//

import SwiftUI

struct RandomFox: Equatable, Codable {
    let image: String; let link: String
}

class ExtensionDelegate: NSObject, ObservableObject, WKExtensionDelegate {
    var foregroundDataTask: URLSessionDataTask?; var backgroundDataTask: URLSessionDataTask?
    var timer: Timer?
    let url = URL(string: "https://randomfox.ca/floof/")!
    @Published var randomFox: RandomFox? = nil
    // utilities
    func taskRandomFox(completionHandler: @escaping (Error?) -> Void) -> URLSessionDataTask { // DataTask create function
        let request = URLRequest( url: url, cachePolicy: .reloadIgnoringLocalCacheData)
        let dataTask = URLSession.shared.dataTask(with: request, completionHandler: { [unowned self] jsonData, response, error in
            guard error == nil, let jsonData = jsonData else { completionHandler(error); return }
            DispatchQueue.main.async {
                self.randomFox = try? JSONDecoder().decode(RandomFox.self, from: jsonData)
                completionHandler(nil)
            }
        })
        return dataTask
    }
    func systemDateFormatter(_ dateFormat: String ) -> DateFormatter { // system date formatter for UTC + 00:00:00
        let dateFormatter = DateFormatter();dateFormatter.locale = NSLocale.system; dateFormatter.dateFormat = dateFormat; return dateFormatter
    }
    lazy var dateFormatterMinute: DateFormatter = { return systemDateFormatter("m") }()
    lazy var dateFormatterSecond: DateFormatter = { return systemDateFormatter("ss") }()
    func ceil13MinitesTimeInterval(_ date: Date) -> TimeInterval {
        let ref = Int(dateFormatterMinute.string(from: date)) ?? 0
        let second = Double(dateFormatterSecond.string(from: date)) ?? 0.0
        let diff = 5 - (ref % 5)
        let newDate = date.addingTimeInterval(60 * Double(diff) - second)
        
        let timeinterval = newDate.timeIntervalSince(date)
        print("timeinterval=\(timeinterval)")
        
        return timeinterval
    }
    func scheduleBackgroundRefreshTasks(_ timeInterval: TimeInterval) {
        let targetDate = Date().addingTimeInterval(timeInterval)
        WKExtension.shared().scheduleBackgroundRefresh(withPreferredDate: targetDate, userInfo: nil) { (error) in
            if let error = error {
                print("*** An background refresh error occurred: \(error.localizedDescription) ***")
                return
            }
        }
    }
    // Extension Delegate methods
    func applicationDidFinishLaunching() {
        foregroundDataTask = taskRandomFox(completionHandler: { _ in })
        foregroundDataTask?.resume()
    }
    func applicationDidBecomeActive() {
        backgroundDataTask = nil
        timer?.invalidate()
        timer = Timer.scheduledTimer(timeInterval: ceil13MinitesTimeInterval(Date()), target: self, selector: #selector(Self.onTimer), userInfo: nil, repeats: false)
    }
    @objc func onTimer() {
        self.timer = Timer.scheduledTimer(timeInterval: ceil13MinitesTimeInterval(Date()), target: self, selector: #selector(Self.onTimer), userInfo: nil, repeats: false)
        foregroundDataTask = taskRandomFox(completionHandler: { _ in })
        foregroundDataTask?.resume()
    }
    func applicationWillResignActive() {
        timer?.invalidate()
        foregroundDataTask = nil
    }
    func applicationDidEnterBackground() {
        backgroundDataTask = nil
        let timeInterval = ceil13MinitesTimeInterval(Date())
        scheduleBackgroundRefreshTasks(timeInterval)
    }
    func handle(_ backgroundTasks: Set<WKRefreshBackgroundTask>) {
        for task in backgroundTasks {
            switch task {
            case let backgroundTask as WKApplicationRefreshBackgroundTask:
                backgroundDataTask = taskRandomFox(completionHandler: { [unowned self] _ in
                    self.scheduleBackgroundRefreshTasks(ceil13MinitesTimeInterval(Date()))
                    backgroundTask.setTaskCompletedWithSnapshot(true)
                    self.backgroundDataTask = nil
                })
                backgroundDataTask?.resume()
            default:
                task.setTaskCompletedWithSnapshot(false)
            }
        }
    }
}

@main
struct WatchOSIntervalUpdateApp: App {
    @WKExtensionDelegateAdaptor(ExtensionDelegate.self) var extensionDelegate
    var body: some Scene { WindowGroup { ContentView(extensionDelegate: extensionDelegate)} }
}
