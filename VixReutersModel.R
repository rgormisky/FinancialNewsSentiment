events.data <- read.csv("C:/Users/Rob/Desktop/OID 311/GroupProject/FinancialNewsSentiment-master/raweventlist.csv", header=F,
                        stringsAsFactors = F)
for (i in 1:nrow(events.data)) {
  events.data[i, 1] <- reformat.date(events.data[i, 1])
}
vix.data <- read.csv("C:/Users/Rob/Desktop/OID 311/GroupProject/FinancialNewsSentiment-master/VIXCLS.csv", header=T,
                        stringsAsFactors = F)
for (i in 1:nrow(vix.data)) {
  if (vix.data[i, 2] == ".") {
    vix.data[i, 2] <- vix.data[i-1, 2]
  }
}
colnames(events.data) <- c("date", "word.count", "pos", "neg", "ticker")

#Order: 
# 1: Total, 2: Govt, 3: Treasury, 4: Agency, 5: Credit Total, 6: Corporate, 7: Financial Inst,
# 8: Banking, 9: Brokerages, 10: Finance Co, 11: Insurance, 12: REITs, 13: Other Financial,
# 14: Total Industrial, 15: Basic Industry, 16: Capgoods, 17: Consumer Cyclical, 18: Consumer Non-cyclical,
# 19: Energy, 20: Tech, 21: Transportation, 22: Communications, 23: Other industrial, 24: Total Utility, 
# 25: Electric, 26: Natural Gas, 27: Other Utility, 28: Total Non-Corporate, 29: Supranationals, 30: Sovereigns,
# 31: Foreign Agency, 32: Foreign Local Govt
sector.data <- read.csv("C:/Users/Rob/Desktop/OID 311/GroupProject/FinancialNewsSentiment-master/sectorOAS.csv", header=T,
                        stringsAsFactors = F)[-(1:10), -1]
returns.data <- read.csv("C:/Users/Rob/Desktop/OID 311/GroupProject/FinancialNewsSentiment-master/returns.csv", header=F,
                         stringsAsFactors = F)
#sector.data[, 64] is last column of relevant data

reformat.date <- function(date) {
  MMDDYYYY <- strsplit(date, "/")[[1]]
  month <- MMDDYYYY[1]
  days <- MMDDYYYY[2]
  year <- MMDDYYYY[3]
  return(paste(year, month, days, sep= '-'))
}

incr.date <- function(date){
  days.of.month <- c(31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31)
  
  MMDDYYYY <- strsplit(date, "-")[[1]]
  year <- as.numeric(MMDDYYYY[1])
  month <- as.numeric(MMDDYYYY[2])
  days <- as.numeric(MMDDYYYY[3]) + 1
  
  if (year %% 4 == 0) {
    days.of.month[2] <- 29
  }
  if (days > days.of.month[month]) {
    month <- month + 1
    days <- 1
  }
  if (month > 12) {
    year <- year + 1
    month <- 1
  }
  
  if (month < 10) {
    month.str <- paste0("0", as.character(month))
  } else {
    month.str <- as.character(month)
  }
  if (days < 10) {
    days.str <- paste0("0", as.character(days))
  } else {
    days.str <- as.character(days)
  }
  year.str <- as.character(year)
  return(paste(year.str, month.str, days.str, sep= "-"))
}

decr.date <- function(date) {
  days.of.month <- c(31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31)
  
  MMDDYYYY <- strsplit(date, "-")[[1]]
  year <- as.numeric(MMDDYYYY[1])
  month <- as.numeric(MMDDYYYY[2])
  days <- as.numeric(MMDDYYYY[3]) - 1
  
  if (year %% 4 == 0) {
    days.of.month[2] <- 29
  }
  if (days < 1) {
    month <- month - 1
    if (month < 1) {
      year <- year - 1
      month <- 12
    }
    days <- days.of.month[month]
  }
  
  if (month < 10) {
    month.str <- paste0("0", as.character(month))
  } else {
    month.str <- as.character(month)
  }
  if (days < 10) {
    days.str <- paste0("0", as.character(days))
  } else {
    days.str <- as.character(days)
  }
  year.str <- as.character(year)
  return(paste(year.str, month.str, days.str, sep= "-"))
}

# Convert news data into daily time series
curr.day <- "2015-04-27" # manually confirmed first day of corpus
matches <- which(events.data[, 1] == curr.day)
if (length(matches) == 0) {
  row <- list(curr.day, 0, 0, 0)
} else {
  match.df <- events.data[matches, ]
  word.count <- sum(match.df[, 'word.count'])
  pos.count <- sum(match.df[, 'pos'])
  neg.count <- sum(match.df[, 'neg'])
  row <- list(curr.day, word.count, pos.count, neg.count)
}
event.df <- data.frame(row, stringsAsFactors = F)
colnames(event.df) <- c('date', 'word.count', 'pos', 'neg')
for (i in 1:836){
  curr.day <- incr.date(curr.day)
  matches <- which(events.data[, 1] == curr.day)
  if (length(matches) == 0) {
    row <- list(curr.day, 0, 0, 0)
  } else {
    match.df <- events.data[matches, ]
    word.count <- sum(match.df[, 'word.count'])
    pos.count <- sum(match.df[, 'pos'])
    neg.count <- sum(match.df[, 'neg'])
    row <- list(curr.day, word.count, pos.count, neg.count)
  }
  event.df <- rbind(event.df, row)
}

model.data <- cbind(event.df[1, ], "vix"= as.numeric(vix.data[1, 2]))
for (i in 2:nrow(vix.data)) {
  if (vix.data[i, 2] == ".") {
    next
  }
  event.idx <- which(vix.data[i, 1] == event.df[, 1]) 
  model.row <- cbind(event.df[event.idx, ], "vix"= as.numeric(vix.data[i, 2]))
  model.data <- rbind(model.data, model.row)
}

bad.idx <- which(model.data[, 3] + model.data[, 4] < 5)
model.data.filt <- model.data[-bad.idx, ]

head(model.data.filt)

friday.idx <- rep(0, (nrow(model.data) %/% 5) + 4)
offset.idx <- rep(4, length(friday.idx))
ii <- 1
target.date <- '2015-05-01'
while (ii <= length(friday.idx)) {
  offset.temp <- 0
  target.idx <- which(model.data[, 'date'] == target.date)
  while (length(target.idx) == 0) {
    target.date <- decr.date(target.date)
    target.idx <- which(model.data[, 'date'] == target.date)
    offset.temp <- offset.temp + 1  
  }
  friday.idx[ii] <- target.idx
  offset.idx[ii] <- 4 - offset.temp
  ii <- ii + 1
  for (j in 1:(7+offset.temp)) {
    target.date <- incr.date(target.date)  
  }
}

model.data.weekly <- data.frame(list("date"= model.data[5, 1],
                                     "word.count"= sum(model.data[1:5, 2]),
                                     "pos"= sum(model.data[1:5, 3]),
                                     "neg"= sum(model.data[1:5, 4]),
                                     "d.vix"= model.data[5, 5]),
                                stringsAsFactors = F)
for (i in 2:length(friday.idx)) {
  weekly.row <- list("date"= model.data[friday.idx[i], 1],
                     "word.count"= sum(model.data[(friday.idx[i] - offset.idx[i]):friday.idx[i], 2]),
                     "pos"= sum(model.data[(friday.idx[i] - offset.idx[i]):friday.idx[i], 3]),
                     "neg"= sum(model.data[(friday.idx[i] - offset.idx[i]):friday.idx[i], 4]),
                     "d.vix"= model.data[friday.idx[i], 5])
  model.data.weekly <- rbind(model.data.weekly, weekly.row)
}

reg.data <- data.frame("date"= model.data.weekly[1,1],
                            "SentimentRat"= (model.data.weekly[1,3] - model.data.weekly[1,4]) / model.data.weekly[1,2],
                            "d.vix" = model.data.weekly[1,5],
                            stringsAsFactors = F)
for (i in 2:nrow(model.data.weekly)) {
  reg.row <- list("date"= model.data.weekly[i,1],
                  "SentimentRat"= (model.data.weekly[i,3] - model.data.weekly[i,4]) / model.data.weekly[i,2],
                  "d.vix" = model.data.weekly[i,5])
  reg.data <- rbind(reg.data, reg.row)
}

# VIX MODELS
library(lmtest)
vix.model <- lm(d.vix ~ SentimentRat, data= reg.data)
summary(vix.model); dwtest(vix.model)

lag.data <- data.frame('date'= reg.data[2, 1],
                       'SentimentRat'= reg.data[1, 2],
                       'vix.lag1'= reg.data[1, 3],
                       'd.vix' = reg.data[2, 3],
                       stringsAsFactors = F)
for (i in 3:nrow(reg.data)) {
  lag.row <- list('date'= reg.data[i, 1],
                  'SentimentRat'= reg.data[i-1, 2],
                  'vix.lag1'= reg.data[i-1, 3],
                  'd.vix' = reg.data[i, 3])
  lag.data <- rbind(lag.data, lag.row)
}

lag.model <- lm(d.vix ~ SentimentRat + vix.lag1, data= lag.data)
summary(lag.model); dwtest(lag.model)

lag.model.novix <- lm(d.vix ~ SentimentRat, data= lag.data)
summary(lag.model.novix); dwtest(lag.model.novix)

vixonly.model <- lm(d.vix ~ vix.lag1, data= lag.data)
summary(vixonly.model); dwtest(vixonly.model)

sse.reduced <- sum(vixonly.model$residuals^2)
sse.full <- sum(lag.model$residuals^2)
Fstat <- (sse.reduced - sse.full) / (sse.full / (length(lag.model$fitted.values) - 1))

# Target F-stat of between 2.75 and 3.92 for between 5% and 10% p-value 
anova(vixonly.model, lag.model)

# SPREAD MODELS
oas.data1 <- sector.data[, seq(9, 63, by=2)] #starts with credit industry
oas.data <- oas.data1[-((nrow(oas.data1) - 8):nrow(oas.data1)), ]
for (i in 1:ncol(oas.data)) {
  oas.data[, i] <- as.numeric(oas.data[, i])
}
cnames <- c("Cred", "OAS", "FinInst", "Bank", "Broke", "FinCo", "Insur", "REIT", "OthFin", 
            "TotInd", "BasInd", "CapGood", "ConCyc", "ConNC", "Ener", "Tech", "Trans",
            "Comm", "OthInd", "TotUt", "Elec", "NatGas", "OthUt", "TotNoCo", "Supra", "Sov",
            "ForAg", "ForGov")
colnames(oas.data) <- cnames

corp.data <- cbind(lag.data, oas.data[-nrow(oas.data), ], "Corp.lag1" = oas.data[-1, "OAS"])

corp.full <- lm("OAS ~ SentimentRat + vix.lag1", data= corp.data)
corp.reduced <- lm(OAS ~ vix.lag1, data= corp.data)
anova(corp.reduced, corp.full)
summary(corp.full); dwtest(corp.full)

corp.sentonly <- lm(Corp ~ SentimentRat, data= corp.data)
summary(corp.sentonly); dwtest(corp.sentonly)

library(sandwich)
corp.vcov <- NeweyWest(corp.full, lag= 1)
coeftest(corp.full, corp.vcov)

basis.plot <- function(model, title) {
  plot(model$residuals, type= "l", col= "blue", main= title, xlab= "Weeks since 4/24/15", ylab= "Basis Risk (bps)")
  lines(rep(0, length(model$residuals)))
  sd.err <- summary(model)$sigma
  lines(rep(sd.err, length(model$residuals)), col='red')
  lines(rep(-sd.err, length(model$residuals)), col='red') 
}

# list elements are lists of (lm call, summary, dwtest, Newey-West coeftest)
model.list <- vector(mode= "list", length= length(cnames))
formula.tail <- " ~ SentimentRat + vix.lag1"
for (i in 1:length(cnames)) {
  formula <- paste0(cnames[i], formula.tail)
  spread.model <- lm(formula, data= corp.data)
  spread.summary <- summary(spread.model)
  durbwat.test <- dwtest(spread.model)
  spread.vcov <- NeweyWest(spread.model, lag= 1)
  model.list[[i]] <- list(spread.model, spread.summary, durbwat.test, coeftest(spread.model, spread.vcov))
}

ind.idx <- which(cnames == 'Supra')
ind.model <- model.list[[ind.idx]][[1]]
basis.plot(ind.model)
ind.model$residuals[length(ind.model$residuals)] / sd(ind.model$residuals)

cheapness <- function(week) {
  cheapness <- rep(0, length(cnames))
  for (i in 1:length(cheapness)) {
    ind.model <- model.list[[i]][[1]]
    cheapness[i] <- ind.model$residuals[week] / summary(ind.model)$sigma
  }
  return(rbind(cnames, cheapness))
}

totalreturns.data <- returns.data[-((nrow(returns.data) - 8):nrow(returns.data)), seq(1, ncol(returns.data) - 1, by= 2)]
totalreturns.cnames <- c("Total", "Govt", "Treasury", "Agency", "Cred", "Corp", "FinInst", "Bank", "Broke", 
               "FinCo", "Insur", "REIT", "OthFin", "TotInd", "BasInd", "CapGood", "ConCyc", "ConNC", 
               "Ener", "Tech", "Trans", "Comm", "OthInd", "TotUt", "Elec", "NatGas", "OthUt", 
               "TotNoCo", "Supra", "Sov", "ForAg", "ForGov", "Secur", "MBS", "AgFix", "GNMA30",
               "Conv30", "Conv15", "Conv20", "AgHyb", "3/1", "5/1", "7/1", "CMBS", "NonAg", "AgCMBS",
               "TotABS", "ABS", "ABCred", "ABAuto", "ABUtil", "Other")
colnames(totalreturns.data) <- totalreturns.cnames
totalreturns.clean <- totalreturns.data[, -41]
totalreturns.clean[102:103, 13] <- rep(totalreturns.data[101, 13], 2)

mv.data <- sector.data[-((nrow(sector.data) - 8):nrow(sector.data)), seq(2, ncol(sector.data) - 1, by= 2)]
colnames(mv.data) <- totalreturns.cnames
for (i in 1:ncol(mv.data)) {
  mv.data[, i] <- as.numeric(gsub(",", "", mv.data[, i]))
}

mv.bad.idx <- which(is.na(mv.data), arr.ind= T)
mv.data[mv.bad.idx[1:7, 1], mv.bad.idx[1, 2]] <- mv.data[mv.bad.idx[1,1] - 1, mv.bad.idx[1, 2]]
mv.data[mv.bad.idx[8:nrow(mv.bad.idx), 1], mv.bad.idx[8, 2]] <- mv.data[mv.bad.idx[8,1] - 1, mv.bad.idx[8, 2]]

level1.cols <- c("Govt", "FinInst", "TotInd", "TotUt", "TotNoCo", "Secur")
index.alloc <- mv.data[, level1.cols] / mv.data[, "Total"]
apply(index.alloc, 2, sd)
# Determine allocation to corporate credit
# 5% reduction in corp credit alloc for every sd of basis risk
my.alloc <- matrix(rep(0, nrow(index.alloc)*ncol(index.alloc)), nrow= nrow(index.alloc))
for (i in 1:nrow(lag.data)) {
  cheap.mat <- cheapness(i)
  corp.col.idx <- which(cheap.mat[1, ] == "Corp")
  corp.cheapness <- cheap.mat[2, corp.col.idx]
  corp.adjustment <- .1 * as.numeric(corp.cheapness)
  corp.alloc <- sum(index.alloc[i+1, c("FinInst", "TotInd", "TotUt")])
  fin.adjustment <- corp.adjustment * (index.alloc[i+1, "FinInst"] / corp.alloc)
  fin.alloc <- fin.adjustment + index.alloc[i+1, "FinInst"]
  totind.adjustment <- corp.adjustment * (index.alloc[i+1, "TotInd"] / corp.alloc)
  totind.alloc <- totind.adjustment + index.alloc[i+1, "TotInd"]
  totut.adjustment <- corp.adjustment * (index.alloc[i+1, "TotUt"] / corp.alloc)
  totut.alloc <- totut.adjustment + index.alloc[i+1, "TotUt"]
  
  my.remaining <- 1 - (corp.alloc + corp.adjustment)
  index.remaining <- 1 - corp.alloc
  govt.alloc <- my.remaining * (index.alloc[i+1, "Govt"] / index.remaining)
  totnoco.alloc <- my.remaining * (index.alloc[i+1, "TotNoCo"] / index.remaining)
  secur.alloc <- my.remaining * (index.alloc[i+1, "Secur"] / index.remaining)
  
  my.alloc[i+1, ] <- c(govt.alloc, fin.alloc, totind.alloc, totut.alloc, totnoco.alloc, secur.alloc)
}
# No prediction for first period
for (i in 1:ncol(my.alloc)) {
  my.alloc[1, i] <- index.alloc[1, i]
}

my.returns <- (totalreturns.clean[, level1.cols] / 100) * my.alloc
index.returns <- (totalreturns.clean[, level1.cols] / 100) * index.alloc

my.ret.t <- rep(0, nrow(my.returns))
index.ret.t <-  rep(0, nrow(my.returns))
for (i in 1:nrow(my.returns)) {
  my.ret.t[i] <- prod(apply(my.returns[1:i, ], 2, function(x) prod(1+x)))
  index.ret.t[i] <- prod(apply(index.returns[1:i, ], 2, function(x) prod(1+x)))
}

plot(1:length(my.ret.t), my.ret.t, type= "l", col= "red")
lines(1:length(my.ret.t), index.ret.t, type= "l", col= "blue")

annualized.excessreturns <- ((((my.ret.t[103] - index.ret.t[103]) + 1)^0.5) - 1) * 100

annualized.sd <- sd((my.ret.t - 1)*100) 

sd(my.ret.t) * 100

sharpe.ratio <- annualized.excessreturns / annualized.sd

library(ggplot2)
ggplot.df <- data.frame("time" = cbind(1:length(my.ret.t), "tradereturns"= my.ret.t, "indexreturns"= index.ret.t))



1015056820 * my.alloc[103, ];1015056820 *  index.alloc[103, ]

sentiment <- reg.data[, 2]
c(summary(sentiment), stdev= sd(sentiment))
hist(sentiment, 20)

gov.data1 <- sector.data[, 7] #starts with credit industry
gov.data <- as.numeric(gov.data1[-((length(gov.data1) - 8):length(gov.data1))])
gov.df <-  cbind(lag.data, "Gov"= gov.data[-length(gov.data)])
gov.model <- lm(Gov ~ SentimentRat+ vix.lag1, data = gov.df)
summary(gov.model); dwtest(gov.model)

sec.data1 <- sector.data[, 65] #starts with credit industry
sec.data <- as.numeric(sec.data1[-((length(sec.data1) - 8):length(sec.data1))])
sec.df <-  cbind(lag.data, "Sec"= sec.data[-length(sec.data)])
sec.model <- lm(Sec ~ SentimentRat+ vix.lag1, data = sec.df)
summary(sec.model); dwtest(sec.model)

basis.plot(corp.full, "IG Corporate Basis Risk")
plot(oas.data[, 'Corp'], type= "l", col= "blue", main= "Fitted vs. Actual OAS",
     xlab= "Weeks since 4/24/15", ylab= "OAS (bps)")
lines(corp.full$fitted.values, col= "red")
legend(65, 210, c("Fitted OAS", "Actual OAS"), col= c("red", "blue"), lty= c(1,1),
       lwd = c(2.5, 2.5))

ind.idx <- which(cnames == 'FinInst')
ind.model <- model.list[[ind.idx]][[1]]
basis.plot(ind.model, "Utilities Basis Risk")
ind.model$residuals[length(ind.model$residuals)] / sd(ind.model$residuals)

plot(my.ret.t, type= "l", col= "blue", main= "Spread Model Backtest",
     xlab= "Weeks since 4/24/15", ylab= "Cumulative Wealth")
lines(index.ret.t, col= "red")
legend(65, .995, c("Strategy", "Index"), col= c("blue", "red"), lty= c(1,1),
       lwd = c(2.5, 2.5))

rbind(cnames, cheapness(102))
