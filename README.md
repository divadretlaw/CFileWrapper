# CFileWrapper

A simple wrapper for File handling in Swift without Foundation

You can read files, save files, append to files and list directories

## Usage

```swift
if let hello = CFileWrapper.read("HelloWorld.txt") {
  print(hello)
}
```

Another way to read the file is using a completion handler

```swift
CFileWrapper.read("HelloWorld.txt") { text in
	guard let text = text else {
		print("Unable to read file")
		return
	}
	print(text)
}
```

You can also read by line with a delegate

```swift
class MyClass: CFileWrapperDelegate {
  func CFileWrapper(read line: String) {
    print(line)
  }
}

let myClass = MyClass()
CFileWrapper.readw("HelloWorld.txt", delegate: myClass)
```
