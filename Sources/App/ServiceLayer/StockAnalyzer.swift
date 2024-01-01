import Foundation

struct StockAnalyzer {
    var financialData: [Financial]
    let discountRate = 0.1
    let growthRate = 0.03

    func intrinsicValue() -> Double {
        let financialDataInRange = getFinancialDataWithPositiveCashFlow()
        return (discountedCashFlow(financialDataInRange) + terminalValue(financialDataInRange)) / pow(1 + discountRate, Double(financialDataInRange.count))
    }

    private func discountedCashFlow(_ data: [Financial]) -> Double {
        return data.enumerated().reduce(0) { (result, enumeration) in
            let (year, financial) = enumeration
            return result + financial.freeCashFlowPerShare / pow(1 + discountRate, Double(year + 1))
        }
    }

    private func terminalValue(_ data: [Financial]) -> Double {
        guard let lastCF = data.first?.freeCashFlowPerShare else {
            return 0
        }
        return (lastCF * (1 + growthRate)) / (discountRate - growthRate)
    }

    private func getFinancialDataWithPositiveCashFlow() -> [Financial] {
        // Find indices of first and last positive cash flow per share values
        let recentIndex = financialData.firstIndex(where: { $0.freeCashFlowPerShare > 0 }) ?? 0
        let pastIndex = financialData.lastIndex(where: { $0.freeCashFlowPerShare > 0 }) ?? (financialData.count - 1)

        // Check if indices are valid and within the range
        guard recentIndex < financialData.count, pastIndex < financialData.count, recentIndex <= pastIndex else {
            return []
        }

        // Return the slice of financialData array within the range
        return Array(financialData[recentIndex...pastIndex])
    }
}
