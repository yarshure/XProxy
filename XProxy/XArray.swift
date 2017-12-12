//
//  XArray.swift
//  XProxy
//
//  Created by yarshure on 2017/12/7.
//  Copyright © 2017年 yarshure. All rights reserved.
//

import Foundation
#if os(macOS) || os(iOS) || os(watchOS) || os(tvOS)
    import Darwin // for arc4random_uniform()
#elseif os(Linux)
    import Glibc // for random()
#endif

extension Sequence {
    func shuffled() -> [Iterator.Element] {
        var contents = Array(self)
        for i in 0 ..< contents.count - 1 {
            #if os(macOS) || os(iOS) || os(watchOS) || os(tvOS)
                // FIXME: This breaks if the array has 2^32 elements or more.
                let j = i + Int(arc4random_uniform(UInt32(contents.count - i)))
            #elseif os(Linux)
                // FIXME: This has modulo bias. Also, `random` should be seeded by calling `srandom`.
                let j = i + random() % (contents.count - i)
            #endif
            contents.swapAt(i, j)
        }
        return contents
    }
}
public protocol SortedSet: BidirectionalCollection, CustomStringConvertible, CustomPlaygroundQuickLookable where Element: Comparable {
    init()
    func contains(_ element: Element) -> Bool
    mutating func insert(_ newElement: Element) -> (inserted: Bool, memberAfterInsert: Element)
}
extension SortedSet {
    public var description: String {
        let contents = self.lazy.map { "\($0)" }.joined(separator: ", ")
        return "[\(contents)]"
    }
}
#if os(iOS)
    import UIKit
    
    extension PlaygroundQuickLook {
        public static func monospacedText(_ string: String) -> PlaygroundQuickLook {
            let text = NSMutableAttributedString(string: string)
            let range = NSRange(location: 0, length: text.length)
            let style = NSParagraphStyle.default.mutableCopy() as! NSMutableParagraphStyle
            style.lineSpacing = 0
            style.alignment = .left
            style.maximumLineHeight = 17
            text.addAttribute(.font, value: UIFont(name: "Menlo", size: 13)!, range: range)
            text.addAttribute(.paragraphStyle, value: style, range: range)
            return PlaygroundQuickLook.attributedString(text)
        }
    }
#endif
public struct SortedArray<Element: Comparable>: SortedSet {
    public var customPlaygroundQuickLook: PlaygroundQuickLook {
        #if os(iOS)
            return .monospacedText(String(describing: self))
        #else
            return .text(String(describing: self))
        #endif
    }
    
    public func index(before i: SortedArray<Element>.Index) -> SortedArray<Element>.Index {
        return storage.startIndex
    }
    
    @discardableResult
    public mutating func insert(_ newElement: Element) -> (inserted: Bool, memberAfterInsert: Element)
    {
        let index = self.index(for: newElement)
        if index < count && storage[index] == newElement {
            return (false, storage[index])
        }
        storage.insert(newElement, at: index)
        return (true, newElement)
    }
    
    fileprivate var storage: [Element] = []
    
    public init() {
        
    }
}
extension SortedArray {
    func index(for element: Element) -> Int {
        var start = 0
        var end = storage.count
        while start < end {
            let middle = start + (end - start) / 2
            if element > storage[middle] {
                start = middle + 1
            }
            else {
                end = middle
            }
        }
        return start
    }
}
extension SortedArray {
    public func index(of element: Element) -> Int? {
        let index = self.index(for: element)
        guard index < count, storage[index] == element else { return nil }
        return index
    }
}
extension SortedArray {
    public func contains(_ element: Element) -> Bool {
        let index = self.index(for: element)
        return index < count && storage[index] == element
    }
}
extension SortedArray {
    public func forEach(_ body: (Element) throws -> Void) rethrows {
        try storage.forEach(body)
    }
}
extension SortedArray {
    public func sorted() -> [Element] {
        return storage
    }
}
extension SortedArray: RandomAccessCollection {
    public typealias Indices = CountableRange<Int>
    
    public var startIndex: Int { return storage.startIndex }
    public var endIndex: Int { return storage.endIndex }
    
    public subscript(index: Int) -> Element { return storage[index] }
}
