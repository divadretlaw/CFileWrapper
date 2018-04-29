//
//  CFileWrapper.swift
//
//  Copyright © 2018 David Walter (www.davidwalter.at)
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.  IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.
//

#if os(macOS) || os(iOS) || os(watchOS) || os(tvOS)
    import Darwin
    private typealias CFileWrapperDIR = UnsafeMutablePointer<DIR>
#else
    import Glibc
    private typealias CFileWrapperDIR = COpaquePointer
#endif

protocol CFileWrapperDelegate {
	func CFileWrapper(read line: String)
	func CFileWrapper(files file: String)
}

extension CFileWrapperDelegate {
	func CFileWrapper(read line: String) {}
	func CFileWrapper(files file: String) {}
}

class CFileWrapper {

    // MARK: Read File

	/**
	 * Reads a file line by line and calls the completion handler with the file content
	 */
	class func read(_ file: String, completion: (String?) -> Void) {
		completion(read(file))
	}
	
    /**
     * Reads a file line by line and returns every line to CFileWrapperDelegate
     */
    class func read(_ file: String, delegate: CFileWrapperDelegate) {
        read(file, bufferSize: 4096, delegate: delegate)
    }

    /**
     * Reads a file line by line with a custom buffer size and returns every line to CFileWrapperDelegate
     */
    class func read(_ file: String, bufferSize: Int32, delegate: CFileWrapperDelegate) {
        if (bufferSize < 1) {
            perror("Invalid buffer size")
            return
        }

        if var fd = fopen(file, "r") {
            while let line = readFileHelper(&fd, bufferSize: bufferSize) {
                delegate.CFileWrapper(read: line)
            }

            fclose(fd)
        } else  {
            perror("Could not open file \(file)")
            return
        }
    }

    /**
     * Reads a file line by line and returns the filecontent as a String
     */
    class func read(_ file: String) -> String? {
        return read(file, bufferSize: 4096)
    }

    /**
     * Reads a file line by line with a custom buffer size and returns the filecontent as a String
     */
    class func read(_ file: String, bufferSize: Int32) -> String? {
        if (bufferSize < 1) {
            perror("Invalid buffer size")
            return nil
        }

        if var fd = fopen(file, "r") {
            var message = String()
            while let line = readFileHelper(&fd, bufferSize: bufferSize) {
                message += line
            }

            fclose(fd)
            return message
        } else {
            perror("Could not open file \(file)")
            return nil
        }
    }

    private class func readFileHelper(_ fd: inout UnsafeMutablePointer<FILE>, bufferSize: Int32) -> String? {
        let line = UnsafeMutablePointer<Int8>.allocate(capacity: Int(bufferSize))

        if (fgets(line, bufferSize, fd) != nil) {
            if let text = String(validatingUTF8: line) {
                return text
            }
        }

        return nil
    }

    // MARK : Write File

    /**
     * Overwrites an exsiting file or creates a new file with a String as content
     */
    class func write(_ file: String, content: String) {
        let fd = fopen(file, "w")

        if (fd == nil) {
            perror("Could not open file \(file)")
            return
        }

        fputs(content, fd)

        fclose(fd)
    }

    /**
     * Appends a String to an existing file or creates a new file
     */
    class func appendTo(_ file: String, content: String) {
        let fd = fopen(file, "a+")

        if (fd == nil) {
            perror("Could not open file \(file)")
            return
        }

        fputs(content, fd)

        fclose(fd)
    }

    // MARK : Directory

    /**
     * Returns every file from the given directory to CFileWrapperDelegate
     */
    class func files(_ directory: String, delegate: CFileWrapperDelegate) {
        if var dir = opendir(directory) {
            while let file = getFilesHelper(&dir) {
                delegate.CFileWrapper(files: file)
            }
            closedir(dir)
        } else {
            perror("Unable to open directory \(directory)")
        }
    }

    /**
     * Returns every file from the given directory in an array
     */
    class func files(_ directory: String) -> Array<String>? {
        if var dir = opendir(directory) {
            var array = Array<String>()
            
            while let file = getFilesHelper(&dir) {
                if ( access( file, F_OK ) == -1 ) {
                    array.append(file)
                }
            }
            
            closedir(dir)
            return array
        } else {
            perror("Unable to open directory \(directory)")
            return nil
        }
    }
    
    private class func getFilesHelper(_ dir: inout CFileWrapperDIR) -> String? {
        if let entry = readdir(dir) {
            var nameBuf: [CChar] = Array()
            
            for (_, elem) in Mirror(reflecting: entry.pointee.d_name as Any).children {
                nameBuf.append(elem as! Int8)
            }
            
            nameBuf.append(0)
            if let name = String(validatingUTF8: nameBuf) {
                return name
            }
        }
        
        return nil
    }

}
