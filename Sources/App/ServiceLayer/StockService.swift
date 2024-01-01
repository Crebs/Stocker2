import Vapor

class StockService {
    let client: Client

    init(for client: Client) {
        self.client = client
    }

    func fetchFinancialData(for ticker: String) -> EventLoopFuture<[Financial]> {
        let apiKey = Environment.get("FINANCIAL_MODELING_PREP_API_KEY") ?? "defaultKey"
        let url = "https://financialmodelingprep.com/api/v3/key-metrics/\(ticker)?apikey=\(apiKey)"
        return client.get(URI(string: url)).flatMapThrowing { response in
            guard response.status == .ok else {
                throw Abort(.badRequest, reason: "Bad response status: \(response.status)")
            }
            guard let body = response.body else {
                throw Abort(.badRequest, reason: "No data in response")
            }
            return try JSONDecoder().decode([Financial].self, from: body)
        }.flatMapErrorThrowing { error in
            // Handle specific errors or log them
            if let clientError = error as? HTTPClientError, clientError == .cancelled {
                // Handle the cancellation case specifically
                // req.logger.error("HTTP Client Request was cancelled: \(error)")
                print("HTTP Client Request was cancelled: \(error)")
            } else {
                // Handle other errors
                print("HTTP Client Request error: \(error)")
            }
            throw error
        }
    }

    func fetchCurrentPrices(for stocks: [String]) -> EventLoopFuture<[StockPrice]> {
        let stocksJoined = stocks.joined(separator: ",")
        let apiKey = Environment.get("FINANCIAL_MODELING_PREP_API_KEY") ?? "defaultKey"
        let url = "https://financialmodelingprep.com/api/v3/quote/\(stocksJoined)?apikey=\(apiKey)"
        return client.get(URI(string: url)).flatMapThrowing { response in
            guard let body = response.body else {
                throw Abort(.badRequest, reason: "No data in response")
            }
            return try JSONDecoder().decode([StockPrice].self, from: body)
        }
    }
}
