import SwiftUI
import Combine
import libIdbcl

extension String {
    var asRange: ClosedRange<Int> {
        assert(range(of: "^[0-9]+[DWMY]$", options: .regularExpression, range: nil, locale: nil) != nil, "Not a range: \(self)")
        
        var dc = DateComponents()
        if let n = Int(String(dropLast())), let l = last {
            switch l {
            case "D": dc.day = -n
            case "W": dc.day = -7 * n
            case "M": dc.month = -n
            case "Y": dc.year = -n
            default: break
            }
        }
        return Int(Calendar.current.date(byAdding: dc, to: Date())!.timeIntervalSince1970) ... Int(Date().timeIntervalSince1970)
    }
}

class PlotData: ObservableObject {
    @Published var domain: String = "1M" {
        willSet { objectWillChange.send() }
        didSet { updateSamples() }
    }
    @Published var function: String = "PlayCount" {
        didSet { updateSamples() }
    }
    @Published var selection: [PlayList] = [] {
        willSet { objectWillChange.send() }
        didSet { updateSamples() }
    }
    @Published var cursor: PlayList? {
        willSet { objectWillChange.send() }
        didSet { updateSamples() }
    }
    
    @Published var yRange: Range<Double> = 0 ..< 0
    @Published var data: [AnimatableData] = []
    
    let objectWillChange = ObservableObjectPublisher()
    let samplingQueue = DispatchQueue(label: "sampling", qos: .userInteractive)
    
    func updateSamples() {
        self.samplingQueue.async {
            let lists = self.cursor != nil && !self.selection.contains(self.cursor!) ? self.selection + [self.cursor!] : self.selection
            let samples = lists.map{ $0.getSamples(self.function, range: self.domain.asRange) }
            
            let max = samples.map { $0.max() ?? 0 }.max() ?? 0
            let min = samples.map { $0.min() ?? 0 }.min() ?? 0
            
            let normalized = samples.map { $0.map { ($0 - min)/(max != min ? max - min : 1) }}
            
            DispatchQueue.main.async {
                self.objectWillChange.send()
                self.yRange = min ..< max
                self.data = normalized.map { AnimatableData(with: $0) }
            }
        }
    }
}


struct AnimatableData: VectorArithmetic, AdditiveArithmetic {
    var values: [Double]
    
    init(with values: [Double] = []) {
        self.values = values
        self.magnitudeSquared = 0
        self.updateMagnitude()
    }
    
    // MARK: VectorArithmetic
    
    var magnitudeSquared: Double
    
    func computeMagnitude() -> Double {
        return self.values.reduce(0, { $0 + $1 * $1 })
    }
    
    mutating func updateMagnitude() {
        self.magnitudeSquared = self.computeMagnitude()
    }
    
    mutating func scale(by rhs: Double) {
        values = values.map { $0 * rhs }
        self.magnitudeSquared = self.computeMagnitude()
    }
    
    // MARK: AdditiveArithmetic
    
    static var zero: AnimatableData = AnimatableData()
    
    static func + (lhs: AnimatableData, rhs: AnimatableData) -> AnimatableData {
        let (longer, shorter) = lhs.values.count > rhs.values.count ? (lhs.values, rhs.values) : (rhs.values, lhs.values)
        return AnimatableData(with: zip(longer, shorter).map(+) + longer[shorter.count ..< longer.count])
    }
    
    static func += (lhs: inout AnimatableData, rhs: AnimatableData) {
        let (longer, shorter) = lhs.values.count > rhs.values.count ? (lhs.values, rhs.values) : (rhs.values, lhs.values)
        lhs.values = zip(longer, shorter).map(+) + longer[shorter.count ..< longer.count]
        lhs.updateMagnitude()
    }

    static func - (lhs: AnimatableData, rhs: AnimatableData) -> AnimatableData {
        let lhsValues = lhs.values + [Double](repeating: 0.0, count: max(rhs.values.count - lhs.values.count, 0))
        let rhsValues = rhs.values + [Double](repeating: 0.0, count: max(lhs.values.count - rhs.values.count, 0))
        return AnimatableData(with: zip(lhsValues, rhsValues).map(-))
    }
    
    static func -= (lhs: inout AnimatableData, rhs: AnimatableData) {
        if rhs.values.count > lhs.values.count { lhs.values += [Double](repeating: 0.0, count: rhs.values.count - lhs.values.count) }
        lhs.values = zip(lhs.values, rhs.values).map(-)
        lhs.updateMagnitude()
    }
}
