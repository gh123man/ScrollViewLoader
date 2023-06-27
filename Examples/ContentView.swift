
import SwiftUI
import ScrollViewLoader

@main
struct ScrollViewLoaderTestApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

struct ContentView: View {
    
    
    var body: some View {
        NavigationView {
            NavigationLink(destination: DetailsSearch()) {
                Text("Go to details")
                    .padding()
            }
        }
        
        
    }
}

struct DetailsSearch: View {
    @State var data: [Int] = Array(0..<1)
    
    var body: some View {
        ScrollView {
            LazyVStack {
                ForEach(data, id: \.self) { i in
                    Text("\(i)")
                        .font(.title)
                        .frame(maxWidth: .infinity)
                }
                ProgressView()
                    .scaleEffect(2)
            }
        }
        .shouldLoadMore {
            await Task.sleep(seconds: 0.1)
//            data.append(contentsOf: (data.last! + 1)...data.last! + 100)
            data.append(data.last! + 1)
        }
    }
}


extension Task where Success == Never, Failure == Never {
    static func sleep(seconds: Double) async {
        let duration = UInt64(seconds * 1_000_000_000)
        try! await Task.sleep(nanoseconds: duration)
    }
}
