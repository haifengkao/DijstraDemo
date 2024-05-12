//
//  DijstraApp.swift
//  Dijstra
//
//  Created by Lono on 2022/11/3.
//

import Foundation
import SwiftUI
@main
struct DijstraApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

protocol Nameable: Hashable {
    var name: String { get }
}

struct Node: Hashable, Nameable {
    let name: String

    init(name: String) {
        self.name = name
    }
}

class NodeGraphInfo<NodeType> where NodeType: Nameable {
    public init() {}

    public func addNode(n: NodeType) {
        pathsFrom[n] = .init()
        nodes.insert(n)
    }

    public func addPath(from: NodeType, to: NodeType, distance: Int) {
        pathsFrom[from]![to] = distance
    }

    public func distance(from: NodeType, to: NodeType) -> Int {
        return pathsFrom[from]![to]!
    }

    func pathsFrom(n: NodeType) -> Set<NodeType> {
        let distanceMap = pathsFrom[n]!
        return Set(distanceMap.keys)
    }

    func setDistanceFor(from: NodeType, to: NodeType, d: Int) {
        var distanceMap = pathsFrom[from] ?? .init()
        distanceMap[to] = d

        pathsFrom[from] = distanceMap
    }

    func setStartAndEnd(start: NodeType, endNode: NodeType) {
        self.start = start
        self.endNode = endNode
    }

    private var pathsFrom: [NodeType: [NodeType: Int]] = .init()
    var nodes: Set<NodeType> = .init()

    var start: NodeType?
    var endNode: NodeType?
}

// Context
class Dijkstra<NodeType> where NodeType: Nameable {
    init(graph: NodeGraphInfo<NodeType>) {
        self.graph = graph
    }

    func unvisitedNeighboursOf(node: NodeType) -> [NodeType] {
        let allNeighbours = Array(graph.pathsFrom(n: node))
        let retval = allNeighbours.filter { unvisited.contains($0) }
        return retval
    }

    private func unvisitedNodeWithMinimumDistance() -> NodeType! {
        var min = Int.max
        var retval: NodeType?
        for n in unvisited where tentativeDistances[n]! < min {
            min = tentativeDistances[n]!
            retval = n
        }

        return retval!
    }

    private func recur(current: NodeType) {
        let currentUnivisitedNeighbours: Set<NodeType> = Set(unvisitedNeighboursOf(node: current))
        var smallestDistance: NodeType? // ??
        let myTenativeDistance = tentativeDistances[current]!
        for n in currentUnivisitedNeighbours {
            let distanceIncrement = graph.distance(from: current, to: n)
            if distanceIncrement == Int.max { continue }
            let itsDistance = tentativeDistances[n]!
            let net_distance = myTenativeDistance + distanceIncrement
            if net_distance < itsDistance {
                tentativeDistances[n] = net_distance
                smallestDistance = n
                pathTo[n] = current
            }
        }

        unvisited.remove(current)

        if unvisited.contains(graph.endNode!) {
            recur(current: unvisitedNodeWithMinimumDistance())
        }
    }

    func doit() {
        for n in graph.nodes {
            tentativeDistances[n] = Int.max
        }

        tentativeDistances[graph.start!] = 0
        unvisited = graph.nodes
        recur(current: graph.start!)
    }

    func pathTo(i: NodeType) -> NodeType? {
        return pathTo[i]
    }

    var tentativeDistances: [NodeType: Int] = .init()
    var graph: NodeGraphInfo<NodeType> = .init()
    var unvisited: Set<NodeType> = .init()
    var pathTo: [NodeType: NodeType] = .init()
}

class NameableRoleHashableByValue: Nameable {
    internal init(node: Node, context: Any) {
        self.node = node
        self.context = context
    }

    static func == (lhs: NameableRoleHashableByValue, rhs: NameableRoleHashableByValue) -> Bool {
        lhs.node == rhs.node
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(node)
    }
    
    var name: String { node.name }
    
    let node: Node
    let context : Any
}

func runWithRole() {
    typealias NodeType = NameableRoleHashableByValue
    let graph = NodeGraphInfo<NodeType>()
    let dijkstra = Dijkstra<NodeType>(graph: graph)
    
    /* Aliases to help set up the grid. Grid is of Manhattan form:
     *
     *        a - 2 - b - 3 -    c
     *          |            |            |
     *       1            2            1
     *       |            |            |
     *        d - 1 -    e - 1 -    f
     *       |                        |
     *        2                        4
     *    |                        |
     *        g - 1 -    h - 2 -    i
     */
    let names = ["a", "b", "c", "d", "e", "f", "g", "h", "i"]
    let originalNodes: [Node] = names.map { .init(name: $0) }
    let nodes: [NodeType] = originalNodes.map { .init(node: $0, context: dijkstra) }

    for n in nodes {
        graph.addNode(n: n)
    }
    for node1 in graph.nodes {
        for node2 in graph.nodes {
            if node1 == node2 {
                graph.setDistanceFor(from: node1, to: node1, d: 0)
            } else {
                graph.setDistanceFor(from: node1, to: node2, d: Int.max)
            }
        }
    }

    let namedNode: [String: NodeType] = nodes.grouped(by: \.name).mapValues(\.first!)

    graph.setDistanceFor(from: namedNode["a"]!, to: namedNode["b"]!, d: 2)
    graph.setDistanceFor(from: namedNode["b"]!, to: namedNode["c"]!, d: 3)
    graph.setDistanceFor(from: namedNode["c"]!, to: namedNode["f"]!, d: 1)
    graph.setDistanceFor(from: namedNode["f"]!, to: namedNode["i"]!, d: 4)
    graph.setDistanceFor(from: namedNode["b"]!, to: namedNode["e"]!, d: 2)
    graph.setDistanceFor(from: namedNode["e"]!, to: namedNode["f"]!, d: 1)
    graph.setDistanceFor(from: namedNode["a"]!, to: namedNode["d"]!, d: 1)
    graph.setDistanceFor(from: namedNode["d"]!, to: namedNode["g"]!, d: 2)
    graph.setDistanceFor(from: namedNode["g"]!, to: namedNode["h"]!, d: 1)
    graph.setDistanceFor(from: namedNode["h"]!, to: namedNode["i"]!, d: 2)
    graph.setDistanceFor(from: namedNode["d"]!, to: namedNode["e"]!, d: 1)

    graph.setStartAndEnd(start: namedNode["a"]!, endNode: namedNode["i"]!)

   
    dijkstra.doit()

    var pathComponents: [String] = []
    var walker: NodeType? = graph.endNode
    while true {
        pathComponents.append(walker!.name)
        walker = dijkstra.pathTo(i: walker!)
        if walker == nil {
            break
        }
    }

    print("Path: \(pathComponents.reversed().joined(separator: " -> "))")
}

func run() {
    let graph = NodeGraphInfo<Node>()
    /* Aliases to help set up the grid. Grid is of Manhattan form:
     *
     *		a - 2 - b - 3 -	c
     *	  	|			|			|
     *	   1			2			1
     *	   |			|			|
     *		d - 1 -	e - 1 -	f
     *	   |						|
     *		2						4
     *    |						|
     *		g - 1 -	h - 2 -	i
     */
    let names = ["a", "b", "c", "d", "e", "f", "g", "h", "i"]
    let nodes: [Node] = names.map { .init(name: $0) }

    for n in nodes {
        graph.addNode(n: n)
    }
    for node1 in graph.nodes {
        for node2 in graph.nodes {
            if node1 == node2 {
                graph.setDistanceFor(from: node1, to: node1, d: 0)
            } else {
                graph.setDistanceFor(from: node1, to: node2, d: Int.max)
            }
        }
    }

    let namedNode: [String: Node] = nodes.grouped(by: \.name).mapValues(\.first!)

    graph.setDistanceFor(from: namedNode["a"]!, to: namedNode["b"]!, d: 2)
    graph.setDistanceFor(from: namedNode["b"]!, to: namedNode["c"]!, d: 3)
    graph.setDistanceFor(from: namedNode["c"]!, to: namedNode["f"]!, d: 1)
    graph.setDistanceFor(from: namedNode["f"]!, to: namedNode["i"]!, d: 4)
    graph.setDistanceFor(from: namedNode["b"]!, to: namedNode["e"]!, d: 2)
    graph.setDistanceFor(from: namedNode["e"]!, to: namedNode["f"]!, d: 1)
    graph.setDistanceFor(from: namedNode["a"]!, to: namedNode["d"]!, d: 1)
    graph.setDistanceFor(from: namedNode["d"]!, to: namedNode["g"]!, d: 2)
    graph.setDistanceFor(from: namedNode["g"]!, to: namedNode["h"]!, d: 1)
    graph.setDistanceFor(from: namedNode["h"]!, to: namedNode["i"]!, d: 2)
    graph.setDistanceFor(from: namedNode["d"]!, to: namedNode["e"]!, d: 1)

    graph.setStartAndEnd(start: namedNode["a"]!, endNode: namedNode["i"]!)

    let dijkstra = Dijkstra<Node>(graph: graph)
    dijkstra.doit()

    var pathComponents: [String] = []
    var walker: Node? = graph.endNode
    while true {
        pathComponents.append(walker!.name)
        walker = dijkstra.pathTo(i: walker!)
        if walker == nil {
            break
        }
    }

    print("Path: \(pathComponents.reversed().joined(separator: " -> "))")
}

public extension Sequence {
    func grouped<U: Hashable>(by key: (Iterator.Element) -> U) -> [U: [Iterator.Element]] {
        return Dictionary(grouping: self, by: key)
    }
}
