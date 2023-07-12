# ScrollViewLoader

A simple utility to assist with loading more content in a `ScrollView` in SwiftUI.

### Usage 

Add `.shouldLoadMore` to any `ScrollView`. By default it will be triggered when the content at the bottom of the `ScrollView` is close to being in view. 


## See it in action
If you want to see it in a real app, check out [dateit](https://apps.apple.com/us/app/dateit/id1610780514)

Also works well with [SwiftUI-Refresher](https://github.com/gh123man/SwiftUI-Refresher)

![Navigation](/images/2.gif)


## Usage 
First add the package to your project. 

```swift
import ScrollViewLoader

struct ContentView: View {
    
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
            await Task.sleep(seconds: 0.05)
            data.append(data.last! + 1)
        }
    }
}
```

## Customization

By default, the callback will be triggered when distance to the bottom of the scrollable content is less than `50%` of the visible hight of the scroll view. You can customize this

Set the relative offset to `20%` instead of the default `50%`:
```swift 
.shouldLoadMore(bottomDistance: .relative(0.2)) { 
    // Load more
}
```

Set the absolute offset to a fixed value:
```swift 
.shouldLoadMore(bottomDistance: .absolute(200)) { 
    // Load more
}
```

### `waitForHeightChange`

It may be desirable for `shouldLoadMore` to be called whenever the user scrolls - even if the scroll view content didn't change. You can change this behavior with `waitForHeightChange`: 
```swift 
.shouldLoadMore(waitForHeightChange: .never) { 
    // Will be called regardless of if the height changed from a previous update
}
```

```swift 
.shouldLoadMore(waitForHeightChange: .always) { 
    // Will only be called if the content height changed since last time
}
```

```swift 
.shouldLoadMore(waitForHeightChange: .after(2)) { 
    // Will only be called if the content height changed since last time or after 2 seconds of no change
}
```
and now `shouldLoadMore` will be called whenever it's in the offset threshold. By default `waitForHeightChange` is `true` so the function doesn't get called in quick succession when no content updates are made. 

## More details

- The callback will only be called once when the bottom approaches. 
- If you scroll back up out of the trigger zone, it will be called again when you scroll back down. 
- It is up to you to synchronize and de-duplicate multiple scroll triggers by the user (depending on the kind of data you are loading)
- Loading conditions will be re-evaluated if the scroll view content changes in any way. 

# More Examples

## Using a completion handler instead of `async`

```swift
.shouldLoadMore { done in
    loadYourContent {
        data.append(data.last! + 1)
        done() // Call done so shouldLoadMore can be called again later
    }
}
```

Larger batching 

![Navigation](/images/1.gif)
