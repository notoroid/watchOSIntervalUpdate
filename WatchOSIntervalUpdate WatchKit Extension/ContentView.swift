//
//  ContentView.swift
//  WatchOSIntervalUpdate WatchKit Extension
//
//  Created by 能登 要 on 2021/12/15.
//

import SwiftUI

// SwiftUI - content view / app
struct ContentView: View {
    @StateObject var extensionDelegate: ExtensionDelegate
    var body: some View {
        if let randomFox = extensionDelegate.randomFox {
            AsyncImage(url: URL(string: randomFox.image)) { image in
                image.resizable().aspectRatio(nil, contentMode: .fill).ignoresSafeArea()
            } placeholder: { ProgressView() }
        } else { Text("🦊").font(.largeTitle).padding() }
    }
}

struct ContentView_Previews: PreviewProvider {
    @WKExtensionDelegateAdaptor(ExtensionDelegate.self) static var extensionDelegate
    static var previews: some View {
        ContentView(extensionDelegate: Self.extensionDelegate)
            
    }
}
