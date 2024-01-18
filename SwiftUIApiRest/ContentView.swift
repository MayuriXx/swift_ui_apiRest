//
//  ContentView.swift
//  SwiftUIApiRest
//
//  Created by Evan Martho on 17/01/2024.
//

import SwiftUI

enum NetworkError: Error {
    case badUrl
    case invalidRequest
    case badResponse
    case badStatus
    case failedToDecodeResponse
}

class WebService {
    func downloadData<T: Codable>(fromURL: String) async -> T? {
        do {
            guard let url = URL(string: fromURL) else { throw NetworkError.badUrl }
            let (data, response) = try await URLSession.shared.data(from: url)
            guard let response = response as? HTTPURLResponse else { throw NetworkError.badResponse }
            guard response.statusCode >= 200 && response.statusCode < 300 else { throw NetworkError.badStatus }
            guard let decodedResponse = try? JSONDecoder().decode(T.self, from: data) else { throw NetworkError.failedToDecodeResponse }
            
            return decodedResponse
        } catch NetworkError.badUrl {
            print("There was an error creating the URL")
        } catch NetworkError.badResponse {
            print("Did not get a valid response")
        } catch NetworkError.badStatus {
            print("Did not get a 2xx status code from the response")
        } catch NetworkError.failedToDecodeResponse {
            print("Failed to decode response into the given type")
        } catch {
            print("An error occured downloading the data")
        }
        
        return nil
    }
}

struct Post: Identifiable, Codable {
    let userId: Int
    let id: Int
    let title: String
    let body: String
}

@MainActor class PostViewModel: ObservableObject {
    @Published var postData = [Post]()
    
    func fetchData() async {
        guard let downloadedPosts: [Post] = await WebService().downloadData(fromURL: "https://jsonplaceholder.typicode.com/posts") else {return}
        
        postData = downloadedPosts
    }
}

struct ContentView: View {
    @StateObject var vm = PostViewModel()
    @State private var textToSearch = ""
    
    //inclusive search
    var filteredData: [Post] {
            if textToSearch.isEmpty {
                return vm.postData
            }
            
            return vm.postData.filter { post in
                textToSearch.split(separator: " ").allSatisfy { string in
                    post.title.lowercased().contains(string.lowercased())
                }
            }
        }
    
    var body: some View {
        NavigationStack {
            List(filteredData) { post in
                HStack {
                    Text("\(post.userId)")
                        .padding()
                        .overlay(Circle().stroke(.blue))
                    
                    VStack(alignment: .leading) {
                        Text(post.title)
                            .bold()
                            .lineLimit(1)
                        
                        Text(post.body)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }
                }
            }
            .onAppear {
                if vm.postData.isEmpty {
                    Task {
                        await vm.fetchData()
                    }
                }
            }
            .searchable(text: $textToSearch, prompt: "Search")
        }
    }
}

#Preview {
    ContentView()
}
