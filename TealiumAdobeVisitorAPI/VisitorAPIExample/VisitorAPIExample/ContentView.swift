// 
// ContentView.swift
// VisitorAPIExample
//
//  
//

import SwiftUI
import TealiumSwift

struct ContentView: View {
    
    @ObservedObject var updater = Updater()
    @State var orgID = ""
    @State var knownId = ""
    @State var initDisabled = true
    @State var linkDisabled = true
    
    var body: some View {
        ScrollView{
            VStack(spacing: 15) {
                Text("Tealium Adobe Visitor API Example")
                 .frame(maxWidth: .infinity, alignment: .center)
                    .font(.custom("HelveticaNeue", size: 22.0)).multilineTextAlignment(.center).padding()
                
                TextField("Enter Adobe Org ID", text: $orgID, onCommit:  {
                    initDisabled = false
                }).font(.custom("HelveticaNeue", size: 10.0)).multilineTextAlignment(.center).textFieldStyle(RoundedBorderTextFieldStyle())
                
                Button("Initialize Tealium", action: {
                    TealiumHelper.start(orgId: orgID)
                }).disabled(initDisabled)
                
                Button("Track Event", action: {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        TealiumHelper.trackEvent(title: "Sample Event", data: nil)
                    }
                }).frame(maxWidth: .infinity, alignment: .center).disabled(initDisabled)
                
                
                Button("Reset ECID", action: {
                    TealiumHelper.resetECID()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        TealiumHelper.trackEvent(title: "ECID Reset", data: nil)
                    }
                }).frame(maxWidth: .infinity, alignment: .center).disabled(initDisabled)
                
                Text("Enter a known visitor ID, e.g. email address, below to link with the ECID.").font(.custom("HelveticaNeue", size: 10.0)).multilineTextAlignment(.center)
                
                TextField("Enter Known Visitor ID", text: $knownId, onCommit:  {
                    linkDisabled = false
                }).font(.custom("HelveticaNeue", size: 10.0)).multilineTextAlignment(.center).textFieldStyle(RoundedBorderTextFieldStyle())
                
                Button("Link Visitor ID", action: {
                    if (knownId != "") {
                        TealiumHelper.linkToKnownId(id: knownId)
                    }
                }).disabled(linkDisabled)
                
                
                Text("Adobe ECID:\n\(updater.ecid ?? "Not Available")")
                    .multilineTextAlignment(.center).padding()
            }
        }

    }
}

class Updater: ObservableObject {
    @Published var ecid: String?
    
    init() {
        NotificationCenter.default.addObserver(forName: Notification.Name("ecid"), object: nil, queue: nil) { notification in
            guard let ecid = notification.userInfo?["ecid"] as? String else {
                return
            }
            DispatchQueue.main.async {
                self.ecid = ecid
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
