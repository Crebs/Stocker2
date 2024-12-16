import Vapor
import Logging

@main
enum Entrypoint {
    static var vm: StockDataViewModel? 
    static func main() async throws {
        var env = try Environment.detect()
        try LoggingSystem.bootstrap(from: &env)
        let app = Application(env)
        defer { app.shutdown() }
        
        do {
            // let arguments = CommandLine.arguments
            // if arguments.contains("--run-as-client") {
                runAsClient(app)
                try await app.execute()
                
            // } else {
            //     try await configure(app)
            // }
            
        } catch {
            app.logger.report(error: error)
            throw error
        }
    }

    static func runAsClient(_ app: Application) {
        vm = StockDataViewModel(app: app)
        let stockList = ["AAPL", "GM", "AMD", "TGT", "INTC", "AMZN", "PARA", "TTWO", "DIS", "MMM", "SOLV", "CRM", "PEP", "SPY", "SLDP", "SNDL"]
        vm?.fetchBatchStockData(tickers: stockList) { results in
            for result in results {
                print("\(result.name) intrinsic value: \(result.intrinsicValue), margin of safty grade: \(result.grade)")
                if let currentPrice = result.currentPrice {
                    print("current price: \(currentPrice)")
                } 
            }
            exit(0)
        }
    }
}
