## Nordic Portfolio Optimisation and Out-of-Sample Performance

This project constructs and tests Nordic equity portfolios using mean-variance optimisation in R. Three portfolios, Minimum Variance, Maximum Sharpe, and Equal Weight, are built from a diversified 12-stock Nordic universe and compared against a market benchmark, with results validated using an out-of-sample backtest.

Built as part of my self-directed learning in quantitative finance and portfolio theory. Tools used: R, tidyquant, PortfolioAnalytics, PerformanceAnalytics, ggplot2, corrplot.


# Key Findings

**Full Period (2015-2024): all three portfolios beat the benchmark**
The Maximum Sharpe portfolio delivered the strongest full-period performance, 23.0% annualised return with a Sharpe ratio of 1.33. Minimum Variance delivered 16.9% return at the lowest volatility of the three (12.1%), and Equal Weight delivered 19.3%. All three comfortably outperformed the benchmark, which returned 8.5% annually with a Sharpe ratio of just 0.33.

**The central finding: Maximum Sharpe collapses out-of-sample**
Weights were calculated using only 2015-2019 data, then applied unchanged to 2020-2024 returns. In-sample, the Maximum Sharpe portfolio looked exceptional, with a Sharpe ratio of 2.07. Out-of-sample, using the identical weights, its Sharpe ratio fell to 0.42, the weakest of the three constructed portfolios, and barely ahead of the benchmark for much of the period. This is a textbook case of estimation risk: historical average returns are unstable predictors of future performance, so an optimiser that leans on them risks fitting noise rather than a repeatable pattern.

**Minimum Variance and Equal Weight proved more robust**
Both held up close to their in-sample risk-adjusted performance out-of-sample (Sharpe ratios of 1.04 and 1.00, respectively, versus 1.54 and 1.81 in-sample). Minimum Variance, which optimises only on volatility and correlation rather than expected return, was the most consistent performer across both periods.

**Diversification check: sector clustering is real**
The correlation matrix confirms that stocks within the same sector move together, construction (Veidekke, AF Gruppen: 0.60), energy (Equinor, Aker BP: 0.60), financials (DNB, Storebrand: 0.63), and especially seafood (Mowi, SalMar: 0.77). Novo Nordisk stood out as the most valuable diversifier in the universe, showing near-zero correlation with every other holding.

**Drawdown protection favoured Minimum Variance**
During the COVID-19 crash, Minimum Variance fell only 13.8% peak to trough, versus 24.2% for Maximum Sharpe and 29.5% for Equal Weight. The benchmark's worst drawdown wasn't COVID at all, a 2021-2024 episode that took it down 41.3% over 33 months, far deeper and longer than anything the constructed portfolios experienced.


# Methodology


Universe: 12 Nordic large caps across six sectors (industrials, energy, financials, healthcare, consumer staples, technology, seafood), deliberately diversified beyond the single-sector universe used in a prior M&A screening project.
Data: Monthly returns, 2015-2024, pulled live from Yahoo Finance via tidyquant. Benchmark is the iShares MSCI Norway ETF (EWN), used as a proxy since OSEBX/OBX were not available through Yahoo Finance.
Constraints: Long only, fully invested, maximum 20% per stock — chosen to reflect a realistic fund mandate.
Out-of-sample test: Weights estimated on 2015-2019 data only, then applied without modification to 2020-2024 returns, isolating the effect of estimation error.



# Limitations


Survivorship bias — all 12 companies are currently listed; delisted or failed companies from the period are not represented.
Small sample size — a 12-stock universe is sensitive to single-name outliers, particularly Novo Nordisk's outsized performance over this period.
Estimation risk — directly demonstrated by the Maximum Sharpe portfolio's in-sample vs out-of-sample collapse.
Benchmark proxy — EWN is USD-denominated and tracks a broader MSCI Norway universe rather than OSEBX directly.
No transaction costs or rebalancing costs are modelled.



# How to Run


1. Clone or download this repository
2. Open RStudio and navigate to the project folder
3. Run requirements.R once to install all required packages
4. Open Report.Rmd and click Knit


The report pulls all data live from Yahoo Finance and runs the entire analysis automatically, no separate script or saved files are required. Knitting takes a few minutes due to the data download and optimisation steps.


# Author

Ari Shareef Omar
Finance student, BI Norwegian Business School
