//
//  main.swift
//  Demo
//
//  Created by David Walter on 29.04.18.
//  Copyright © 2018 David Walter. All rights reserved.
//

CFileWrapper.write("HelloWorld.txt", content: "Hello\nWorld!")

if let hello = CFileWrapper.read("HelloWorld.txt") {
	print(hello)
}

CFileWrapper.read("HelloWorld.txt") { text in
	guard let text = text else {
		print("Unable to read file")
		return
	}
	print(text)
}

class MyClass: CFileWrapperDelegate {
	func CFileWrapper(read line: String) {
		print(line)
	}
}

let myClass = MyClass()
CFileWrapper.read("HelloWorld.txt", delegate: myClass)
