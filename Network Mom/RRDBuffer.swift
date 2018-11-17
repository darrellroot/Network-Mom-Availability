/*
 From Ray Wenderlich data structures book
 Fixed-length ring buffer
 In this implementation, the read and write pointers always increment and
 never wrap around. On a 64-bit platform that should not get you into trouble
 any time soon.
 Not thread-safe, so don't read and write from different threads at the same
 time! To make this thread-safe for one reader and one writer, it should be
 enough to change read/writeIndex += 1 to OSAtomicIncrement64(), but I haven't
 tested this...
 */
public struct RRDBuffer<T> {
    private var array: [T?]
    //private var readIndex = 0
    private var writeIndex = 0 {
        didSet {
            if writeIndex >= array.count {
                writeIndex = 0
            }
        }
    }
    private var recentWriteIndex = 0
    
    public init(count: Int) {
        array = [T?](repeating: nil, count: count)
    }
    
    public mutating func insert(_ element: T) {
        array[writeIndex] = element
        recentWriteIndex = writeIndex
        writeIndex += 1
    }
    public func readRecent() -> T? {
        guard writeIndex == 0 && recentWriteIndex == 0 else { return nil }
        return array[recentWriteIndex]
    }
    
    public func getData() -> [T] {
        let data1 = Array(array[writeIndex..<array.count]).compactMap({ $0 })
        let data2 = Array(array[0...recentWriteIndex]).compactMap({ $0 })
        return data1 + data2
    }
}

/*extension RRDBuffer: Sequence {
    public func makeIterator() -> AnyIterator<T> {
        var index = readIndex
        return AnyIterator {
            guard index < self.writeIndex else { return nil }
            defer {
                index += 1
            }
            return self.array[wrapped: index]
        }
    }
}*/

