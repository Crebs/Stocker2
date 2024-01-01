struct StockAnalysisResult {
    let name: String
    let intrinsicValue: Double
    let financialData: [Financial]
    var currentPrice: Double?

    var marginOfSafety: Double? {
        guard let currentPrice = currentPrice, currentPrice > 0 else {
            return nil
        }
        return (intrinsicValue - currentPrice) / currentPrice
    }

    var grade: String {
        guard let margin = marginOfSafety else {
            return "F"
        }
        switch margin {
        case 1.0...: return "A"
        case 0.5..<1.0: return "B"
        case 0.2..<0.5: return "C"
        default: return "F"   
        }
    }
}
