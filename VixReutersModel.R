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
oas.data <- sector.data[-((nrow(oas.data) - 8):nrow(oas.data)), seq(9, 63, by=2)] #starts with credit industry
for (i in 1:ncol(oas.data)) {
  oas.data[, i] <- as.numeric(oas.data[, i])
}
cnames <- c("Cred", "Corp", "FinInst", "Bank", "Broke", "FinCo", "Insur", "REIT", "OthFin", 
            "TotInd", "BasInd", "CapGood", "ConCyc", "ConNC", "Ener", "Tech", "Trans",
            "Comm", "OthInd", "TotUt", "Elec", "NatGas", "OthUt", "TotNoCo", "Supra", "Sov",
            "ForAg", "ForGov")
colnames(oas.data) <- cnames

corp.data <- cbind(lag.data, c(oas.data[-nrow(oas.data), ]))
corp.full <- lm(Corp ~ SentimentRat + vix.lag1, data= corp.data)
corp.reduced <- lm(Corp ~ vix.lag1, data= corp.data)
anova(corp.reduced, corp.full)
summary(corp.model); dwtest(corp.model)
