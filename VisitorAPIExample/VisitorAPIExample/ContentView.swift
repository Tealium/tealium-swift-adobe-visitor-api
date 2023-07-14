// 
// ContentView.swift
// VisitorAPIExample
//
//  
//

import SwiftUI
import Combine
import TealiumSwift

struct ContentView: View {
    
    @ObservedObject var updater = Updater()
    @ObservedObject var helper = TealiumHelper.shared
    @State var orgID = ""
    @State var knownId = ""
    @State var initDisabled = true
    @State var linkDisabled = true
    @State var urlToDecorate = "https://www.example.com"
    @State var params = ""
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
                    helper.start(orgId: orgID, knownId: knownId.nonEmpty(), existingECID: updater.ecid)
                }).disabled(initDisabled)
                
                Button("Track Event", action: {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        helper.trackEvent(title: "Sample Event", data: nil)
                    }
                }).frame(maxWidth: .infinity, alignment: .center).disabled(initDisabled)
                
                
                Button("Reset ECID", action: {
                    helper.resetECID()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        helper.trackEvent(title: "ECID Reset", data: nil)
                    }
                }).frame(maxWidth: .infinity, alignment: .center).disabled(initDisabled)
                
                Text("Enter a known visitor ID, e.g. email address, below to link with the ECID.").font(.custom("HelveticaNeue", size: 10.0)).multilineTextAlignment(.center)
                
                TextField("Enter Known Visitor ID", text: $knownId, onCommit:  {
                    linkDisabled = false
                }).font(.custom("HelveticaNeue", size: 10.0)).multilineTextAlignment(.center).textFieldStyle(RoundedBorderTextFieldStyle())
                
                Button("Link Visitor ID", action: {
                    if (knownId != "") {
                        helper.linkToKnownId(id: knownId)
                    }
                }).disabled(linkDisabled)
                VStack(alignment: .center, spacing: 4) {
                    Text("Adobe ECID:")
                    if helper.tealium != nil {
                        if let ecid = updater.ecid {
                            Text(ecid)
                                .font(.custom("HelveticaNeue", size: 10.0))
                        } else {
                            ProgressView()
                        }
                    } else {
                        TextField("Enter Existing ECID", text: Binding<String>(get: {
                            updater.ecid ?? ""
                        }, set: { newValue in
                            updater.ecid = newValue
                        }), onCommit:  {
                            
                        }).font(.custom("HelveticaNeue", size: 10.0))
                            .multilineTextAlignment(.center)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                    Button {
                        guard let url = URL(string: urlToDecorate) else { return }
                        helper.tealium?.adobeVisitorApi?.decorateUrl(url, completion: { newUrl in
                            DispatchQueue.main.async {
                                self.urlToDecorate = newUrl.absoluteString
                            }
                        })
                    } label: {
                        Text("Decorate URL")
                    }.padding(.top)
                    TextField("url", text: $urlToDecorate)
                        .lineLimit(2)
                        .multilineTextAlignment(.center)
                        .font(.custom("HelveticaNeue", size: 10.0)).multilineTextAlignment(.center).textFieldStyle(RoundedBorderTextFieldStyle())
                    Button {
                        helper.tealium?.adobeVisitorApi?.getURLParameters(completion: { params in
                            DispatchQueue.main.async {
                                self.params = params?.description ?? ""
                            }
                        })
                    } label: {
                        Text("Retrieve Query Params")
                    }.padding(.top)
                    TextField("url", text: $params)
                        .lineLimit(2)
                        .multilineTextAlignment(.center)
                        .font(.custom("HelveticaNeue", size: 10.0)).multilineTextAlignment(.center).textFieldStyle(RoundedBorderTextFieldStyle())
                }.padding(.vertical)
            }
        }

    }
}

class Updater: ObservableObject {
    @Published var ecid: String?
    private var cancellable: Set<AnyCancellable> = []
    init() {
        TealiumHelper.shared.$currentECID
            .assign(to: \.ecid, on: self)
            .store(in: &cancellable)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

extension String {
    
    func nonEmpty() -> String? {
        guard !isEmpty else {
            return nil
        }
        return self
    }
    
}
