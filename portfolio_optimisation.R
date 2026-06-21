#Installing missing packages
install.packages("dplyr")
install.packages("ggplot2")
install.packages("tidyquant")
install.packages("lubridate")
install.packages("PortfolioAnalytics")
install.packages("ROI")
install.packages("ROI.plugin.quadprog")
install.packages("tidyr")
install.packages("ROI.plugin.glpk")
install.packages("PerformanceAnalytics")
install.packages("corrplot")


#(1) Load packages
library(dplyr)
library(ggplot2)
library(tidyquant)
library(lubridate)
library(PortfolioAnalytics)
library(ROI)
library(ROI.plugin.quadprog)
library(tidyr)
library(xts)
library(ROI.plugin.glpk)
library(PerformanceAnalytics)
library(corrplot)


#(2) Stock universe
tickers <- c("VEI.OL", "AFG.OL", "KOG.OL",
             "EQNR.OL", "AKRBP.OL", "DNB.OL",
             "STB.OL", "NOVO-B.CO", "ORK.OL",
             "NOD.OL", "MOWI.OL", "SALM.OL")


#(3) Pull daily prices
prices <- tq_get(tickers,
                 from = "2015-01-01",
                 to = "2024-12-31")


#(4) Create monthly returns
returns <- prices %>%
  group_by(symbol) %>%
  tq_transmute(select = adjusted,
               mutate_fun = periodReturn,
               period = "monthly",
               col_rename = "return")


#(5) Reshape to wide format (one column per stock)
returns_wide <- returns %>%
  pivot_wider(names_from = symbol,
              values_from = return)
head(returns_wide)


#(6) Check for and remove missing values
colSums(is.na(returns_wide))
returns_wide[is.na(returns_wide$VEI.OL), ]

returns_wide <- na.omit(returns_wide)

colSums(is.na(returns_wide))  # confirm all zero


#(7) Convert to xts so PortfolioAnalytics can read it
returns_xts <- xts(returns_wide[, -1],
                   order.by = returns_wide$date)


#(8) Build the portfolio object
portfolio <- portfolio.spec(assets = colnames(returns_xts))


#(9) Add constraints

# No short selling
portfolio <- add.constraint(portfolio,
                            type = "long_only")

# Weights must sum to 100%
portfolio <- add.constraint(portfolio,
                            type = "full_investment")

# Maximum 20% per stock
portfolio <- add.constraint(portfolio,
                            type = "box",
                            min = 0,
                            max = 0.20)


#(10) Add objectives

# Minimum variance portfolio
portfolio_minvar <- add.objective(portfolio,
                                  type = "risk",
                                  name = "var")

# Maximum Sharpe portfolio
portfolio_maxsharpe <- add.objective(portfolio,
                                     type = "return",
                                     name = "mean")
portfolio_maxsharpe <- add.objective(portfolio_maxsharpe,
                                     type = "risk",
                                     name = "StdDev")


#(11) Run optimisation (full period)
opt_minvar <- optimize.portfolio(returns_xts,
                                 portfolio_minvar,
                                 optimize_method = "ROI")

opt_maxsharpe <- optimize.portfolio(returns_xts,
                                    portfolio_maxsharpe,
                                    optimize_method = "ROI",
                                    maxSR = TRUE)

print(opt_minvar)
print(opt_maxsharpe)


#(12) Equal weighted portfolio for comparison
weights_equal <- rep(1/12, 12)


#(13) Calculate actual performance of each portfolio (full period)
returns_minvar <- Return.portfolio(returns_xts,
                                   weights = extractWeights(opt_minvar))

returns_maxsharpe <- Return.portfolio(returns_xts,
                                      weights = extractWeights(opt_maxsharpe))

returns_equal <- Return.portfolio(returns_xts,
                                  weights = weights_equal)

head(returns_minvar)
head(returns_maxsharpe)
head(returns_equal)


#(14) Pull benchmark price data
# EWN (iShares MSCI Norway ETF) used as a proxy for the Norwegian
# equity market - the OSEBX/OBX indices were not available via Yahoo Finance
ob_prices <- tq_get("EWN",
                    from = "2015-01-01",
                    to = "2024-12-31")


#(15) Calculate monthly returns for the benchmark
returns_benchmark <- ob_prices %>%
  group_by(symbol) %>%
  tq_transmute(select = adjusted,
               mutate_fun = periodReturn,
               period = "monthly",
               col_rename = "return")


#(16) Convert benchmark returns to xts
ob_returns_xts <- xts(returns_benchmark[, "return"],
                      order.by = returns_benchmark$date)


#(17) Compare performance of all portfolios vs benchmark (full period)
all_returns <- merge(returns_minvar,
                     returns_maxsharpe,
                     returns_equal,
                     ob_returns_xts)

colnames(all_returns) <- c("Min Variance",
                           "Max Sharpe",
                           "Equal Weight",
                           "Benchmark")

table.AnnualizedReturns(all_returns, Rf = 0.02/12)


#(18) Split returns into in-sample and out-of-sample periods
in_sample <- returns_xts["2015/2019"]
out_sample <- returns_xts["2020/2024"]


#(19) Run optimisation on in-sample data only
in_opt_minvar <- optimize.portfolio(in_sample,
                                    portfolio_minvar,
                                    optimize_method = "ROI")

in_opt_maxsharpe <- optimize.portfolio(in_sample,
                                       portfolio_maxsharpe,
                                       optimize_method = "ROI",
                                       maxSR = TRUE)

print(in_opt_minvar)
print(in_opt_maxsharpe)


#(20) Calculate in-sample performance using in-sample weights
in_returns_minvar <- Return.portfolio(in_sample,
                                      weights = extractWeights(in_opt_minvar))

in_returns_maxsharpe <- Return.portfolio(in_sample,
                                         weights = extractWeights(in_opt_maxsharpe))

in_returns_equal <- Return.portfolio(in_sample,
                                     weights = weights_equal)


#(21) Calculate out-of-sample performance using the SAME in-sample weights
out_returns_minvar <- Return.portfolio(out_sample,
                                       weights = extractWeights(in_opt_minvar))

out_returns_maxsharpe <- Return.portfolio(out_sample,
                                          weights = extractWeights(in_opt_maxsharpe))

out_returns_equal <- Return.portfolio(out_sample,
                                      weights = weights_equal)


#(22) Compare in-sample vs out-of-sample performance

# In-sample
in_all_returns <- merge(in_returns_minvar,
                        in_returns_maxsharpe,
                        in_returns_equal)
colnames(in_all_returns) <- c("Min Variance", "Max Sharpe", "Equal Weight")
table.AnnualizedReturns(in_all_returns, Rf = 0.02/12)

# Out-of-sample
out_all_returns <- merge(out_returns_minvar,
                         out_returns_maxsharpe,
                         out_returns_equal)
colnames(out_all_returns) <- c("Min Variance", "Max Sharpe", "Equal Weight")
table.AnnualizedReturns(out_all_returns, Rf = 0.02/12)


#(23) Visualise full period performance (PerformanceAnalytics built-in chart)
charts.PerformanceSummary(all_returns,
                          Rf = 0.02/12,
                          main = "Portfolio Performance 2015-2024")

# In-sample and out-of-sample versions (saved separately - PerformanceAnalytics
# does not support side-by-side layout for this chart type)
charts.PerformanceSummary(in_all_returns,
                          Rf = 0.02/12,
                          main = "In-Sample 2015-2019")

charts.PerformanceSummary(out_all_returns,
                          Rf = 0.02/12,
                          main = "Out-of-Sample 2020-2024")


#(24) ggplot2 cumulative returns chart - full period
all_returns_clean <- na.omit(all_returns)

cumulative_returns <- data.frame(
  date = index(all_returns_clean),
  coredata(all_returns_clean)) %>%
  mutate(
    Min.Variance = cumprod(1 + Min.Variance) - 1,
    Max.Sharpe = cumprod(1 + Max.Sharpe) - 1,
    Equal.Weight = cumprod(1 + Equal.Weight) - 1,
    Benchmark = cumprod(1 + Benchmark) - 1)

cumulative_long <- cumulative_returns %>%
  pivot_longer(cols = -date,
               names_to = "portfolio",
               values_to = "cumulative_return")

ggplot(data = cumulative_long,
       aes(x = date, y = cumulative_return, colour = portfolio)) +
  geom_line(linewidth = 1) +
  scale_y_continuous(labels = scales::percent) +
  theme_minimal() +
  labs(title = "Portfolio Cumulative Returns Over Time",
       x = "Date",
       y = "Cumulative Return",
       color = "Portfolio Type")


#(25) ggplot2 cumulative returns chart - out-of-sample only
all_returns_out <- merge(out_returns_minvar,
                         out_returns_equal,
                         out_returns_maxsharpe,
                         ob_returns_xts["2020/2024"])

colnames(all_returns_out) <- c("Min Variance",
                               "Equal Weight",
                               "Max Sharpe",
                               "Benchmark")

table.AnnualizedReturns(all_returns_out, Rf = 0.02/12)

all_returns_out_clean <- na.omit(all_returns_out)

cumulative_returns_out <- data.frame(
  date = index(all_returns_out_clean),
  coredata(all_returns_out_clean)) %>%
  mutate(
    Min.Variance = cumprod(1 + Min.Variance) - 1,
    Equal.Weight = cumprod(1 + Equal.Weight) - 1,
    Max.Sharpe = cumprod(1 + Max.Sharpe) - 1,
    Benchmark = cumprod(1 + Benchmark) - 1)

cumulative_long_out <- cumulative_returns_out %>%
  pivot_longer(cols = -date,
               names_to = "portfolio",
               values_to = "cumulative_return")

ggplot(data = cumulative_long_out,
       aes(x = date, y = cumulative_return, colour = portfolio)) +
  geom_line(linewidth = 1) +
  scale_y_continuous(labels = scales::percent) +
  theme_minimal() +
  labs(title = "Out-of-Sample Portfolio Performance (2020-2024)",
       x = "Date",
       y = "Cumulative Return",
       color = "Portfolio Type")


#(26) Correlation matrix
correlation_matrix <- cor(returns_xts)
print(round(correlation_matrix, 2))


#(27) Correlation heatmap
corrplot(correlation_matrix,
         method = "color",
         type = "upper",
         addCoef.col = "black",
         tl.col = "black",
         tl.srt = 45)


#(28) Drawdown tables
table.Drawdowns(returns_minvar, top = 3)
table.Drawdowns(returns_maxsharpe, top = 3)
table.Drawdowns(returns_equal, top = 3)
table.Drawdowns(ob_returns_xts, top = 3)