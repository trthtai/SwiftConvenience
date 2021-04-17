import Foundation


/// Performs convenient enumeration of filesystem items at given locations.
public final class FileEnumerator {
    private var locations: [URL]
    private var enumerator: NSEnumerator?
    
    public var filter: Filter?
    
    
    public init(locations: [URL], filter: Filter? = nil) {
        self.locations = locations.reversed()
        self.filter = filter
    }
    
    public convenience init(_ location: URL, filter: Filter? = nil) {
        self.init(locations: [location], filter: filter)
    }
}

public extension FileEnumerator {
    enum Filter {
        case function(_ isIncluded: (URL) -> Bool)
        case types(Set<URL.FileType>)
    }
}

extension FileEnumerator: Sequence, IteratorProtocol {
    public func next() -> URL? {
        while let next = nextUnfiltered() {
            guard let filter = filter else { return next }
            if filter(isIncluded: next) {
                return next
            }
        }
        
        return nil
    }
    
    private func nextUnfiltered() -> URL? {
        //  If next file exists, just return it.
        if let next = enumerator?.nextObject() as? URL {
            return next
        }
        
        //  All files/locations enumerated. 'nil' means the end of the sequence.
        guard let nextLocation = locations.popLast() else {
            return nil
        }
        
        //  If location doesn't exists, just skip it.
        var isDirectory = false
        guard FileManager.default.fileExists(at: nextLocation, isDirectory: &isDirectory) else {
            return nextUnfiltered()
        }
        
        //  If location is directory, update enumerator.
        if isDirectory {
            enumerator = FileManager.default.enumerator(at: nextLocation, includingPropertiesForKeys: nil)
        }
        
        return nextLocation
    }
}

private extension FileEnumerator.Filter {
    func callAsFunction(isIncluded url: URL) -> Bool {
        switch self {
        case .function(let isIncluded):
            return isIncluded(url)
            
        case .types(let types):
            guard let fileType = url.fileType else { return false }
            return types.contains(fileType)
        }
    }
}