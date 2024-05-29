//
//  ContentView.swift
//  Textual
//
//  Created by Henry Blanchette on 5/27/24.
//

import SwiftUI
import UIKit
import UniformTypeIdentifiers

struct Alert: View {
    public var title: String
    public var message: String
    
    var body: some View {
        VStack {
            Text(title)
                .font(.title)
            Text(message)
        }
    }
}

struct ContentView: View {
    @State private var selectedFileURL: URL?
    
    @State private var showFileImporter = false
    
    @State private var showFileExporter = false
    
    @State private var alert: Alert?
    private var alertIsPresented: Binding<Bool> {
        Binding(get: {
            self.alert != nil
        }, set: { isPresented in
            if !isPresented {
                self.alert = nil
            }
        })
    }
    
    @State private var document: TextDocument = TextDocument()
    
    var body: some View {
        VStack {
            VStack {
                TextEditor(text: $document.body)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            
            Divider()
            
            VStack {
                TextField(text: $document.title, label: { Text("Title") })
                    .font(.title3)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                
                HStack {
                    Button(action: {
                        document = TextDocument()
                    }, label: {
                        Image(systemName: "plus.app")
                    })
                    .font(.title)
                    .frame(maxWidth: .infinity)
                    
                    Button(action: {
                        showFileImporter = true
                    }, label: {
                        Image(systemName: "doc.text")
                    })
                    .font(.title)
                    .frame(maxWidth: .infinity)
                    
                    Button(action: {
                        showFileExporter = true
                    }, label: {
                        Image(systemName: "square.and.arrow.down")
                    })
                    .font(.title)
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .padding()
        .alert("Alert", isPresented: alertIsPresented, actions: {
            VStack {
                self.alert
                
                Button("Ok") {
                    self.alert = nil
                }
            }
        })
        .fileImporter(isPresented: $showFileImporter, allowedContentTypes: [.text]) { result in
            switch result {
            case .success(let url):
//                alert = Alert(title: "File imported", message: "\(url)")
                do {
                    let body = try String(contentsOf: url)
                    self.document = TextDocument(title: url.lastPathComponent.components(separatedBy: ".").first!, body: body)
                } catch {
                    alert = Alert(title: "Error reading file", message: error.localizedDescription)
                }
            case .failure(let error):
                alert = Alert(title: "Error importing file", message: error.localizedDescription)
            }
        }
        .fileExporter(isPresented: $showFileExporter, document: document, contentType: .text, defaultFilename: "\(document.title).txt") { result in
            switch result {
            case .success(let _url):
//                alert = Alert(title: "File exported", message: "\(url)")
                return
            case .failure(let error):
                alert = Alert(title: "Error saving file", message: error.localizedDescription)
            }
        }
    }
}

#Preview {
    ContentView()
}

struct TextDocument: FileDocument {
    var title: String
    var body: String
    
    init() {
        self.title = ""
        self.body = ""
    }
    
    init(title: String, body: String) {
        self.title = title
        self.body = body
    }
    
    static var readableContentTypes: [UTType] { [.text] }
    
    init(configuration: ReadConfiguration) throws {
        if let filename = configuration.file.preferredFilename {
            self.title = filename
        } else {
            self.title = ""
        }
        
        guard let data = configuration.file.regularFileContents,
              let body = String(data: data, encoding: .utf8)
        else {
            throw CocoaError(.fileReadCorruptFile)
        }
        
        self.body = body
    }
    
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        let data = body.data(using: .utf8)!
        return FileWrapper(regularFileWithContents: data)
    }
}
