//
//  CFileWrapper.swift
//
//  Copyright © 2015 David Walter (www.davidwalter.at)
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

#if os(OSX) || os(iOS) || os(watchOS) || os(tvOS)
    import Darwin
    private typealias CFileWrapperDIR = UnsafeMutablePointer<DIR>
#else
    import Glibc
    private typealias CFileWrapperDIR = COpaquePointer
#endif

protocol CFileWrapperFileDelegate {
    func CFileWrapper(readLine line: String)
}

protocol CFileWrapperDirectoryDelegate {
    func CFileWrapper(getFiles file: String)
}

class CFileWrapper {
    
    // MARK: Read File
    
    /**
     * Reads a file line by line and returns every line to CFileWrapperDelegate
     */
    class func readFrom(file: String, delegate: CFileWrapperFileDelegate) {
        readFrom(file, bufferSize: 1024, delegate: delegate)
    }
    
    /**
     * Reads a file line by line with a custom buffer size and returns every line to CFileWrapperDelegate
     */
    class func readFrom(file: String, bufferSize: Int32, delegate: CFileWrapperFileDelegate) {
        if (bufferSize < 1) {
            perror("Invalid buffer size")
            return
        }

        var fd = fopen(file, "r")

        if (fd == nil) {
            perror("Could not open file \(file)")
            return
        }
        
        while let line = readFileHelper(&fd, bufferSize: bufferSize) {
            delegate.CFileWrapper(readLine: line)
        }

        fclose(fd)
    }

    /**
     * Reads a file line by line and returns the filecontent as a String
     */
    class func readFrom(file: String) -> String? {
        return readFrom(file, bufferSize: 1024)
    }

    /**
     * Reads a file line by line with a custom buffer size and returns the filecontent as a String
     */
    class func readFrom(file: String, bufferSize: Int32) -> String? {
        if (bufferSize < 1) {
            perror("Invalid buffer size")
            return nil
        }

        var fd = fopen(file, "r")

        if (fd == nil) {
            perror("Could not open file \(file)")
            return nil
        }
        
        var message = String()
        while let line = readFileHelper(&fd, bufferSize: bufferSize) {
            message += line
        }

        fclose(fd)
        return message
    }
    
    private class func readFileHelper(inout fd: UnsafeMutablePointer<FILE>, bufferSize: Int32) -> String? {
        let line = UnsafeMutablePointer<Int8>.alloc(Int(bufferSize))
        
        if (fgets(line, bufferSize, fd) != nil) {
            if let text = String.fromCString(line) {
                return text
            }
        }
        
        return nil
    }
    
    // MARK : Write File

    /**
     * Overwrites an exsiting file or creates a new file with a String as content
     */
    class func writeTo(file: String, content: String) {
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
    class func appendTo(file: String, content: String) {
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
    class func getFiles(directory: String, delegate: CFileWrapperDirectoryDelegate) {
        var dir = opendir(directory)
        
        if (dir == nil) {
            perror("Unable to open directory \(directory)")
            return
        }
        
        while let file = getFilesHelper(&dir) {
            delegate.CFileWrapper(getFiles: file)
        }
        
        closedir(dir)
    }
    
    /**
     * Returns every file from the given directory in an array
     */
    class func getFiles(directory: String) -> Array<String>? {
        var dir = opendir(directory)
        var array = Array<String>()
        
        if (dir == nil) {
            perror("Unable to open directory \(directory)")
            return nil
        }
        
        while let file = getFilesHelper(&dir) {
            array.append(file)
        }
        
        closedir(dir)
        return array
    }
    
    private class func getFilesHelper(inout dir: CFileWrapperDIR) -> String? {
        let entry = readdir(dir)
        
        if (entry != nil) {
            var nameBuf = Array<CChar>()
            
            let mirror = Mirror(reflecting: entry.memory.d_name)
            for (_, elem) in mirror.children {
                if let new = elem as? Int8 {
                    nameBuf.append(new)
                }
            }
            
            nameBuf.append(0)
            if let name = String.fromCString(nameBuf) {
                return name
            }
        }
        
        return nil
    }

}
