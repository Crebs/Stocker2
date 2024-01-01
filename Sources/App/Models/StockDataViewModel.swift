import Vapor

class StockDataViewModel {
    let app: Application
    let stockService: StockService

    init(app: Application) {
        self.app = app
        self.stockService = StockService(for: app.client)
    }

    func fetchBatchStockData(tickers: [String], completion: @escaping ([StockAnalysisResult]) -> Void) {
        let fetchDataFutures = tickers.map { fetchData(ticker: $0) }
        let fetchPricesFuture = stockService.fetchCurrentPrices(for: tickers)
        let combinedFuture = EventLoopFuture.whenAllSucceed(fetchDataFutures, on: app.eventLoopGroup.next())
            .and(fetchPricesFuture)
        
        combinedFuture.whenSuccess { (analysisResults, prices) in
            let updatedAnalysisResults = self.mapPricesToAnalysisResults(prices: prices, analysisResults: analysisResults) 
            completion(updatedAnalysisResults)
        }
    }

    private func fetchData(ticker: String) -> EventLoopFuture<StockAnalysisResult> {
        return stockService.fetchFinancialData(for: ticker).flatMapThrowing { financialData in
            let analyzer = StockAnalyzer(financialData: financialData)
            let intrinsicValue = analyzer.intrinsicValue()
            return StockAnalysisResult(name: ticker, intrinsicValue: intrinsicValue, financialData: financialData)
        }
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
}
