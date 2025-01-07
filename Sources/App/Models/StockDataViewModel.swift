import Vapor

enum ANSIColor: String {
    case reset = "\u{001B}[0m"
    case red = "\u{001B}[31m"
    case green = "\u{001B}[32m"
    case yellow = "\u{001B}[33m"
    case blue = "\u{001B}[34m"
    case magenta = "\u{001B}[35m"
    case cyan = "\u{001B}[36m"
    case white = "\u{001B}[37m"
}

class StockDataViewModel {
    let app: Application
    let stockService: StockService

    init(app: Application) {
        self.app = app
        self.stockService = StockService(for: app.client)
    }

    func fetchBatchStockDataOutput(tickers: [String]) async -> [String] {
        do {
            let results = try await fetchBatchStockData(tickers: tickers)
        
            // Define column widths
            let symbolWidth = 7
            let intrinsicWidth = 16
            let priceWidth = 6
            let gradeWidth = 5
        
            // Header
            let header = String(
                format: "%-\(symbolWidth)@ %-\(intrinsicWidth)@ %-\(priceWidth)@ %-\(gradeWidth)@",
                "Sym", "Value", "Price", "Grade"
            )
            var output: [String] = [header]
        
            for result in results {
                let currentPriceText = result.currentPrice != nil ? String(format: "%.2f", result.currentPrice!) : "0.00"
                let grade = colorizeGrade(result.grade)
                let symbol = colorize(result.name, color: .blue)
                let value = colorize(String(format: "%.2f", result.intrinsicValue), color: .blue)
                let price = colorize(currentPriceText, color: .blue)
            
                let formattedLine: String = String(
                    format: "%-\(symbolWidth)@ %-\(intrinsicWidth)@ %-\(priceWidth)@ %-\(gradeWidth)@",
                    symbol, value, price, grade
                )
                output.append("\(formattedLine)")
            }
        
            return output
        } catch {
            print("Error fetching batch stock data: \(error)")
            return []
        }
    }

    private func fetchBatchStockData(tickers: [String]) async throws -> [StockAnalysisResult] {
        // Fetch financial data for each ticker asynchronously
        let financialDataResults = try await withThrowingTaskGroup(of: StockAnalysisResult.self) { group -> [StockAnalysisResult] in
            for ticker in tickers {
                group.addTask {
                    try await self.fetchData(ticker: ticker)
                }
            }
        
            var results: [StockAnalysisResult] = []
            for try await result in group {
                results.append(result)
            }
            return results
        }
    
        // Fetch stock prices asynchronously
        let prices = try await stockService.fetchCurrentPrices(for: tickers).get()
    
        // Map prices to analysis results and sort them
        var updatedResults = mapPricesToAnalysisResults(prices: prices, analysisResults: financialDataResults)
        updatedResults.sort { lhs, rhs in
            guard let ls = lhs.marginOfSafety, let rs = rhs.marginOfSafety else {
                return false
            }
            return ls > rs
        }
    
        return updatedResults
    }


    private func fetchData(ticker: String) async throws -> StockAnalysisResult {
        let financialData = try await stockService.fetchFinancialData(for: ticker).get()
        let analyzer = StockAnalyzer(financialData: financialData)
        let intrinsicValue = analyzer.intrinsicValue()
        return StockAnalysisResult(name: ticker, intrinsicValue: intrinsicValue, financialData: financialData)
    }

    private func mapPricesToAnalysisResults(prices: [StockPrice], analysisResults: [StockAnalysisResult]) -> [StockAnalysisResult] {
        var updatedResults = analysisResults
        for (index, result) in updatedResults.enumerated() {
            if let priceInfo = prices.first(where: { $0.symbol == result.name }) {
                updatedResults[index].currentPrice = priceInfo.price
            }
        }
        return updatedResults
    }

    private func colorizeGrade(_ grade: String) -> String {
        switch grade {
        case "A":
            return colorize(grade, color: .green)
        case "B":
            return colorize(grade, color: .yellow)
        case "C":
            return colorize(grade, color: .magenta)
        case "D":
            return colorize(grade, color: .white)
        case "F":
            return colorize(grade, color: .red)
        default:
            return grade // Return the uncolored grade if it doesn't match
        }
    }

    private func colorize(_ text: String, color: ANSIColor) -> String {
        return "\(color.rawValue)\(text)\(ANSIColor.reset.rawValue)"
    }
}