import Vapor

struct StockPrice: Content {
    var symbol: String
    var price: Double
}