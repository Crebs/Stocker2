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
        let vm = StockDataViewModel(app: app)
        let stockList = ["AAPL", "GM", "AMD", "TGT", "INTC", "AMZN", "PARA", "TTWO", "DIS", "MMM", "SOLV", "CRM", "PEP", "SPY", "SLDP", "SNDL"]
    
        Task {
            let results = await vm.fetchBatchStockDataOutput(tickers: stockList)
            for result in results {
                print("\(result)")
            }
            exit(0)
        }
    }

}
