rm(list = ls())
setwd("~/Desktop/SEM 3/MAS 766/Project")

#Load and view data 
data <- read.csv("~/Desktop/SEM 3/MAS 766/Project/Data/SP500Quarterly.csv")
View(data)

#load required packages 
library(lubridate)
library(dplyr)
library(forecast)

#Augment latest data 
Latest <- read.csv("~/Desktop/SEM 3/MAS 766/Project/Data/Latest.csv")
#new <- data.frame('Year' = Latest$Date, 'SPINDEX' = Latest$Adj.Close, )

#extract month from date 
Latest$month <- month(as.POSIXlt(as.Date(Latest$Date), format="%Y/%m/%d"))

#subset quarterly data
filtered_Latest <- filter(Latest, month == 3 | month == 6  | month == 9 | month == 12)
View(filtered_Latest)

#remove the 2006 year data since it is already preset 
filtered_Latest <- filtered_Latest[5:nrow(filtered_Latest),]

#extract month from year column in original data 
data$year <- month(as.POSIXlt(as.Date(Latest$Date), format="%Y/%m/%d"))

#extract year=
data$YEAR <- as.character(data$YEAR)
data$year <- substr(data$YEAR, start = 1, stop = 4)
filtered_Latest$year <- year(as.POSIXlt(as.Date(filtered_Latest$Date), format="%Y/%m/%d"))

data$YEAR <- NULL

#subset year and adj close since these are the only two  columns necessary 
filtered_Latest <- subset(filtered_Latest, select = c('year','Adj.Close'))
View(filtered_Latest)

#rename column 
filtered_latest <- filtered_Latest %>% 
  rename(
    SPINDEX = Adj.Close  
  )
View(filtered_latest)

#create new columns to match the original data columns 
filtered_latest$DIFFINDEX <- c(0,diff(filtered_latest$SPINDEX, 1))
filtered_latest$LNSPINDEX <- log(filtered_latest$SPINDEX)
filtered_latest$DIFFLNSP <- c(0,diff(filtered_latest$LNSPINDEX, 1))

#rbind join to create the fial dataset 
final_df <- rbind(data,filtered_latest)
View(final_df)
write.csv(final_df,'~/Desktop/SEM 3/MAS 766/Project/final_df.csv')


library(ggplot2)
#plotting

#S&P index plot from 1936 to 2020

plot(final_df$year,final_df$SPINDEX, type = 'l', xlab = 'year', ylab = 'SPINDEX(dollars)',main = 'S&P Quarterly Index from 1936-2020')


#difference S&P index plot from 1936 to 2020
plot(final_df$year,final_df$DIFFINDEX, type = 'l', xlab = 'year', ylab = 'SPINDEX(dollars)',main = 'Differenced S&P Quarterly Index from 1936-2020')

#Log S&P index plot from 1936 to 2020
plot(final_df$year,final_df$LNSPINDEX, type = 'l', xlab = 'year', ylab = 'Log SPINDEX',main = 'Log S&P Quarterly Index from 1936-2020')

#differenced Log S&P index plot from 1936 to 2020
plot(final_df$year,final_df$DIFFLNSP, type = 'l', xlab = 'year', ylab = 'Difference Log SPINDEX',main = 'Differenced Log S&P Quarterly Index from 1936-2020')


# comparison plot
par(mfrow=c(2,2))
#S&P index plot from 1936 to 2020

plot(final_df$year,final_df$SPINDEX, type = 'l', xlab = 'year', ylab = 'SPINDEX(dollars)')


#difference S&P index plot from 1936 to 2020
plot(final_df$year,final_df$DIFFINDEX, type = 'l', xlab = 'year', ylab = 'SPINDEX(dollars)')

#Log S&P index plot from 1936 to 2020
plot(final_df$year,final_df$LNSPINDEX, type = 'l', xlab = 'year', ylab = 'Log SPINDEX')

#differenced Log S&P index plot from 1936 to 2020
plot(final_df$year,final_df$DIFFLNSP, type = 'l', xlab = 'year', ylab = 'Difference Log SPINDEX')



#create first lag variable for diff log  

lag1 <- c(NA,final_df$DIFFLNSP[1:nrow(final_df)-1])
plot(lag1,final_df$DIFFLNSP, xlab = 'lag1', ylab = 'Difference Log SPINDEX',main = 'Relationship between first lag of DIFFLNSP and DIFFLNSP')
abline(lm(final_df$DIFFLNSP ~ lag1))
#Summary statistics 

summary(final_df)
cor(lag1[2:length(lag1)],final_df$DIFFLNSP[2:nrow(final_df)])


#looking at zoomed in plot after year 2005
dev.off()

zoomed_data <- filter(final_df, year > 2005)
View(zoomed_data)
zoomed_data$year <- as.numeric(zoomed_data$year)
plot(zoomed_data$year,zoomed_data$SPINDEX, xlab = 'year', type = 'l', ylab = 'SPINDEX after 2005')

View(final_df)

#create dummy variable 

final_df$after2008 <- ifelse(final_df$year>= 2008 ,1,0)


data = subset(final_df, select = c('year','after2008','DIFFLNSP'))
View(data)

#reset index 
row.names(data) <- NULL

#### creating the lag variables 
lag <- 1
data$lag1 <- c(NA,data$DIFFLNSP[1:nrow(data)-1])
lag <- 2
data$lag2 <- c(rep(NA,lag),data$DIFFLNSP[1:(nrow(data)-lag)])
lag <- 4
data$lag4 <- c(rep(NA,lag),data$DIFFLNSP[1:(nrow(data)-lag)])


##AR(1) (all data)
lag <- 1
data1 <- data[(lag+1):nrow(data),]
View(data1)
#train <- data1[40:319,]
#test <- data1[320:nrow(data1),]
train <- data1[1:323,]
test <- data1[324:nrow(data1),]
View(train)
View(test)
model <- lm(DIFFLNSP~ lag1,train)
summary(model)

predictions <- predict(model,test)
accuracy(predictions,test$DIFFLNSP)



##AR(1) post world war 
lag <- 1
data1 <- data[(lag+1):nrow(data),]
View(data1)
train <- data1[40:319,]
test <- data1[320:nrow(data1),]
#train <- data1[1:323,]
#test <- data1[324:nrow(data1),]
View(train)
View(test)
model <- lm(DIFFLNSP  ~ lag1 + after2008,train)
summary(model)

predictions <- predict(model,test)
accuracy(predictions,test$DIFFLNSP)


## AR(2) (all data)

lag <- 2
data1 <- data[(lag+1):nrow(data),]
View(data1)
#train <- data1[40:319,]
#test <- data1[320:nrow(data1),]
train <- data1[1:323,]
test <- data1[324:nrow(data1),]
View(train)
View(test)
model <- lm(DIFFLNSP~ lag1 + lag2  + after2008,train)
summary(model)

predictions <- predict(model,test)
accuracy(predictions,test$DIFFLNSP)

##ARIMA

#using auto.arima 
train <- data[1:323,]
test <- data[324:nrow(data1),]
fit <- auto.arima(train$DIFFLNSP, seasonal=FALSE)
fit

#forecasting for number of periods h = nrow(test)
h = nrow(test)
fit %>% forecast(h=h) %>% autoplot(include=80)
predictions <- fit %>% forecast(h=h)
summary(fit)


#Manually trying different models to reduce the AIC and BIC 
fit2 <- Arima(train$DIFFLNSP, order = c(1,0,1))
fit2

#model 2
fit2 <- Arima(train$DIFFLNSP, order = c(2,0,2))
fit2

#model3
fit3 <- Arima(train$DIFFLNSP, order = c(3,0,3))
fit3

#Checking residuals 
checkresiduals(fit3)

#predicting on the best model 
predictions <- fit3 %>% forecast(h=h)
predictions

#plotting the forecasts 
fit3 %>% forecast(h=h) %>% autoplot(include=80)
accuracy(predictions,test$DIFFLNSP)

#unit root vizualisation
autoplot(fit2)

##################### END ########################



