# CFileWrapper

A simple wrapper for File handling in Swift without Foundation

You can read files, save files, append to files and list directories

## Usage

```swift
if let hello = CFileWrapper.readFrom("/Users/david/Desktop/HelloWorld.txt") {
  print(hello)
}
```

You can also read by line with a delegate

```swift
class MyClass: CFileWrapperFileDelegate {
  func CFileWrapper(readLine line: String) {
    print(line)
  }
}

let myClass = MyClass()
CFileWrapper.readFrom("/Users/david/Desktop/HelloWorld.txt", delegate: myClass)
```
