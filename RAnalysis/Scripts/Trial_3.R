#project-geoduck-oa
#Data from Roberts et al NOAA OA
#last modified 20160320 H Putnam


rm(list=ls()) # removes all prior objects

#Read in required libraries
library("seacarb") #seawater carbonate chemistry
library("reshape") #reshape data
library("plotrix") #functions in tapply

#############################################################
setwd("/Users/hputnam/MyProjects/Geoduck_Epi/project-geoduck-oa/RAnalysis/Data/") #set working directory

#Required Data files
#pH_Calibration_Files/
#SW_Chem_Trial3.csv
#Cell_Counts_Trial3.csv
#Larval_Counts_Trial3.csv

#SEAWATER CHEMISTRY ANALYSIS FOR DISCRETE MEASUREMENTS

##### pH Tris Calibration Curves #####
#For conversion equations for pH from mV to total scale using tris standard

path <-("/Users/hputnam/MyProjects/Geoduck_Epi/project-geoduck-oa/RAnalysis/Data/pH_Calibration_Files/")

#list all the file names in the folder to get only get the csv files
file.names<-list.files(path = path, pattern = "csv$")

pH.cals <- data.frame(matrix(NA, nrow=length(file.names), ncol=4, dimnames=list(file.names,c("Date", "Intercept", "Slope","R2")))) #generate a 3 column dataframe with specific column names

for(i in 1:length(file.names)) { # for every file in list start at the first and run this following function
  Calib.Data <-read.table(file.path(path,file.names[i]), header=TRUE, sep=",", na.string="NA", as.is=TRUE) #reads in the data files
  model <-lm(mVTris ~ TTris, data=Calib.Data) #runs a linear regression of mV as a function of temperature
  coe <- coef(model) #extracts the coeffecients
  R <- summary(model)$r.squared #extracts the R2
  pH.cals[i,2:3] <- coe #inserts coef in the dataframe
  pH.cals[i,4] <- R #inserts R2 in the dataframe
  pH.cals[i,1] <- substr(file.names[i],1,8) #stores the file name in the Date column
}

colnames(pH.cals) <- c("Calib.Date",  "Intercept",  "Slope", "R2")
pH.cals

# read in total alkalinity, temperature, and salinity
SW.chem <- read.csv("SW_Chem_Trial3.csv", header=TRUE, sep=",", na.strings="NA") #load data with a header, separated by commas, with NA as NA

#merge with Seawater chemistry file
SW.chem <- merge(pH.cals, SW.chem, by="Calib.Date")

#constants for use in pH calculation 
R <- 8.31447215 #gas constant in J mol-1 K-1 
F <-96485.339924 #Faraday constant in coulombs mol-1

mvTris <- SW.chem$Temperature*SW.chem$Slope+SW.chem$Intercept #calculate the mV of the tris standard using the temperature mv relationships in the measured standard curves 
STris<-27.5 #salinity of the Tris
phTris<- (11911.08-18.2499*STris-0.039336*STris^2)*(1/(SW.chem$Temperature+273.15))-366.27059+ 0.53993607*STris+0.00016329*STris^2+(64.52243-0.084041*STris)*log(SW.chem$Temperature+273.15)-0.11149858*(SW.chem$Temperature+273.15) #calculate the pH of the tris (Dickson A. G., Sabine C. L. and Christian J. R., SOP 6a)
SW.chem$pH.Total<-phTris+(mvTris/1000-SW.chem$pH.MV/1000)/(R*(SW.chem$Temperature+273.15)*log(10)/F) #calculate the pH on the total scale (Dickson A. G., Sabine C. L. and Christian J. R., SOP 6a)

##### Seacarb Calculations #####

#Calculate CO2 parameters using seacarb
carb.output <- carb(flag=8, var1=SW.chem$pH.Total, var2=SW.chem$TA/1000000, S= SW.chem$Salinity, T=SW.chem$Temperature, P=0, Pt=0, Sit=0, pHscale="T", kf="pf", k1k2="l", ks="d") #calculate seawater chemistry parameters using seacarb

carb.output$ALK <- carb.output$ALK*1000000 #convert to µmol kg-1
carb.output$CO2 <- carb.output$CO2*1000000 #convert to µmol kg-1
carb.output$HCO3 <- carb.output$HCO3*1000000 #convert to µmol kg-1
carb.output$CO3 <- carb.output$CO3*1000000 #convert to µmol kg-1
carb.output$DIC <- carb.output$DIC*1000000 #convert to µmol kg-1

carb.output <- cbind(SW.chem$Measure.Date,  SW.chem$Tank,  SW.chem$Treatment, carb.output) #combine the sample information with the seacarb output
colnames(carb.output) <- c("Date",  "Tank",  "Treatment",	"flag",	"Salinity",	"Temperature",	"Pressure",	"pH",	"CO2",	"pCO2",	"fCO2",	"HCO3",	"CO3",	"DIC", "TA",	"Aragonite.Sat", 	"Calcite.Sat") #Rename columns to describe contents
carb.output <- subset(carb.output, select= c("Date",  "Tank",  "Treatment",	"Salinity",	"Temperature",		"pH",	"CO2",	"pCO2",	"HCO3",	"CO3",	"DIC", "TA",	"Aragonite.Sat"))

##### Descriptive Statistics #####
#Tanks
mean_pCO2=tapply(carb.output$pCO2, carb.output$Tank, mean)
se_pCO2=tapply(carb.output$pCO2, carb.output$Tank, std.error)
mean_Temp=tapply(carb.output$Temperature, carb.output$Tank, mean)
se_Temp=tapply(carb.output$Temperature, carb.output$Tank, std.error)
mean_Sal=tapply(carb.output$Salinity, carb.output$Tank, mean)
se_Sal=tapply(carb.output$Salinity, carb.output$Tank, std.error)
mean_TA=tapply(carb.output$TA, carb.output$Tank, mean)
se_TA=tapply(carb.output$TA, carb.output$Tank, std.error)
mean_pH=tapply(carb.output$pH, carb.output$Tank, mean)
se_pH=tapply(carb.output$pH, carb.output$Tank, std.error)
mean_DIC=tapply(carb.output$DIC, carb.output$Tank, mean)
se_DIC=tapply(carb.output$DIC, carb.output$Tank, std.error)

#Treatments
gmean_pCO2 <- tapply(carb.output$pCO2, carb.output$Treatment, mean)
gse_pCO2 <- tapply(carb.output$pCO2, carb.output$Treatment, std.error)
gmean_Temp <- tapply(carb.output$Temperature, carb.output$Treatment, mean)
gse_Temp <- tapply(carb.output$Temperature, carb.output$Treatment, std.error)
gmean_Sal <- tapply(carb.output$Salinity, carb.output$Treatment, mean)
gse_Sal <- tapply(carb.output$Salinity, carb.output$Treatment, std.error)
gmean_TA <- tapply(carb.output$TA, carb.output$Treatment, mean)
gse_TA <- tapply(carb.output$TA, carb.output$Treatment, std.error)
gmean_pH <- tapply(carb.output$pH, carb.output$Treatment, mean)
gse_pH <- tapply(carb.output$pH, carb.output$Treatment, std.error)
gmean_DIC <- tapply(carb.output$DIC, carb.output$Treatment, mean)
gse_DIC <- tapply(carb.output$DIC, carb.output$Treatment, std.error)

mean.carb.output <- rbind(gmean_pCO2, gse_pCO2, gmean_pH, gse_pH, gmean_Temp, gse_Temp, gmean_Sal, gse_Sal, gmean_TA, gse_TA, gmean_DIC, gse_DIC)
mean.carb.output <- as.data.frame(mean.carb.output)
row.names(mean.carb.output) <- c("mean pCO2", "SE pCO2", "mean pH", "SE pH", "mean Temperature", "SE Temperature", "mean Salinity", "SE Salinity", "mean Total Alkalinity", "SE Total Alkalinity", "mean DIC", "SE DIC")
mean.carb.output$Variables <- row.names(mean.carb.output)
write.table (mean.carb.output, file="/Users/hputnam/MyProjects/Geoduck_Epi/project-geoduck-oa/RAnalysis/Output/Seawater_chemistry_table_Output_Trial3.csv", sep=",", row.names = FALSE)

##### Cell Counts #####

cell.counts <- read.csv("Cell_Counts_Trial3.csv", header=TRUE, sep=",", na.strings="NA") #load data with a header, separated by commas, with NA as NA
cell.counts$Avg.Cells <- rowMeans(cell.counts[,c("Count1",  "Count2")], na.rm = TRUE) #calculate average of counts
cell.counts$cells.ml <- cell.counts$Avg.Cells/cell.counts$Volume.Counted #calculate density

#Tanks
mean_cells=tapply(cell.counts$cells.ml, cell.counts$Tank, mean, na.rm = TRUE)
se_cells=tapply(cell.counts$cells.ml, cell.counts$Tank, std.error, na.rm = TRUE)

#Treatments
gmean_cells <- tapply(cell.counts$cells.ml, cell.counts$Treatment, mean, na.rm = TRUE)
gse_cells <- tapply(cell.counts$cells.ml, cell.counts$Treatment, std.error, na.rm = TRUE)

##### Larval Counts #####
larval.counts <- read.csv("Larval_Counts_Trial3.csv", header=TRUE, sep=",", na.strings="NA") #load data with a header, separated by commas, with NA as NA
larval.counts$Avg.Live <- rowMeans(larval.counts[,c("Live1",  "Live2",  "Live3")], na.rm = TRUE) #calculate average of counts
larval.counts$Avg.Dead <- rowMeans(larval.counts[,c("Dead1",  "Dead2",  "Dead3")], na.rm = TRUE) #calculate average of counts
larval.counts$Live.cells.ml <- larval.counts$Avg.Live/larval.counts$Volume.Counted.ml #calculate density
larval.counts$Dead.cells.ml <- larval.counts$Avg.Dead/larval.counts$Volume.Counted.ml #calculate density
larval.counts$total.live.larvae <- larval.counts$Live.cells.ml*larval.counts$Vol.Tripour
larval.counts$total.dead.larvae <- larval.counts$Dead.cells.ml*larval.counts$Vol.Tripour
larval.counts$per.mort <- ((larval.counts$total.dead.larvae/(larval.counts$total.live.larvae+larval.counts$total.dead.larvae))*100)
lar.tot <- aggregate(total.live.larvae ~ Day, data=larval.counts, sum)
tank.lar.tot <- aggregate(total.live.larvae ~ Day + Tank, data=larval.counts, sum)
mortality <- aggregate(per.mort ~ Day + Combo + Treatment, data=larval.counts, mean) 

#Tanks
mean_larvae=tapply(larval.counts$total.live.larvae , list(larval.counts$Day, larval.counts$Tank), mean, na.rm = TRUE)
se_larvae=tapply(larval.counts$total.live.larvae , list(larval.counts$Day, larval.counts$Tank), std.error, na.rm = TRUE)

#Treatments
gmean_larvae <- tapply(larval.counts$total.live.larvae , list(larval.counts$Day, larval.counts$Treatment), mean, na.rm = TRUE)
gmean_larvae_samp <- tapply(larval.counts$total.live.larvae , list(larval.counts$Day, larval.counts$Treatment), mean, na.rm = TRUE)
gse_larvae <- tapply(larval.counts$total.live.larvae , list(larval.counts$Day, larval.counts$Treatment), std.error, na.rm = TRUE)
gmean_larvae <- as.data.frame(gmean_larvae)

##### Plot Tank and Treatment mean ± se #####
pdf("/Users/hputnam/MyProjects/Geoduck_Epi/project-geoduck-oa/RAnalysis/Output/running_carbonate_chemistry_tanks_Trial3.pdf")
par(cex.axis=0.8, cex.lab=0.8, mar=c(5, 5, 4, 2),mgp=c(3.7, 0.8, 0),las=1, mfrow=c(3,3),oma=c(0,0,2,0))

#Tanks
plot(c(1,6),c(0,5000),type="n",ylab=expression(paste("pCO"["2"])), xlab=expression(paste("Tank")))
plotCI(x=c(1,2,3,4,5,6), y=mean_pCO2,uiw=se_pCO2, liw=se_pCO2,add=TRUE,gap=0.001)

plot(c(1,6),c(6.6,7.5),type="n",ylab=expression(paste("pH")), xlab=expression(paste("Tank")))
plotCI(x=c(1,2,3,4,5,6), y=mean_pH,uiw=se_pH, liw=se_pH,add=TRUE,gap=0.001)

plot(c(1,6),c(12,15),type="n",ylab=expression(paste("Temperature °C")), xlab=expression(paste("Tank")))
plotCI(x=c(1,2,3,4,5,6), y=mean_Temp,uiw=se_Temp, liw=se_Temp,add=TRUE,gap=0.001)

plot(c(1,6),c(25,29),type="n",ylab=expression(paste("Salinity")), xlab=expression(paste("Tank")))
plotCI(x=c(1,2,3,4,5,6), y=mean_Sal,uiw=se_Sal, liw=se_Sal,add=TRUE,gap=0.001)

plot(c(1,6),c(1800,2200),type="n",ylab=expression(paste("Total Alkalinity µmol kg"^"-1")), xlab=expression(paste("Tank")))
plotCI(x=c(1,2,3,4,5,6), y=mean_TA,uiw=se_TA, liw=se_TA,add=TRUE,gap=0.001)

plot(c(1,6),c(1800,2400),type="n",ylab=expression(paste("DIC µmol kg"^"-1")), xlab=expression(paste("Tank")))
plotCI(x=c(1,2,3,4,5,6), y=mean_DIC,uiw=se_DIC, liw=se_DIC,add=TRUE,gap=0.001)

plot(c(1,6),c(40000,70000),type="n", ylab=expression(paste("Algal Feed (Cells ml"^"-1",")")), xlab=expression(paste("Tank")))
plotCI(x=c(1,2,3,4,5,6), y=mean_cells,uiw=se_cells, liw=se_cells,add=TRUE,gap=0.001)

#plot(tank.lar.tot$total.live.larvae ~ tank.lar.tot$Day*tank.lar.tot$Tank, ylab=expression(paste("Number of Larvae")), xlab=expression(paste("Tank")))
title("Tank Conditions Trial 3", outer=TRUE)
dev.off()


pdf("/Users/hputnam/MyProjects/Geoduck_Epi/project-geoduck-oa/RAnalysis/Output/running_carbonate_chemistry_treatments_Trial3.pdf")
par(cex.axis=0.8, cex.lab=0.8, mar=c(5, 5, 4, 2),mgp=c(3.7, 0.8, 0),las=1, mfrow=c(3,3),oma=c(0,0,2,0))

#Treatments
plot(c(1,2),c(0,5000), xaxt = "n", type="n",ylab=expression(paste("pCO"["2"])), xlab=expression(paste("Treatment")))
axis(1, at=1:2, labels=c("pH 7.01", "pH 7.38"))
plotCI(x=c(1,2), y=gmean_pCO2,uiw=gse_pCO2, liw=gse_pCO2,add=TRUE,gap=0.001, pch=20, col=c("red", "pink"))

plot(c(1,2),c(6.6,7.5), xaxt = "n", type="n",ylab=expression(paste("pH")), xlab=expression(paste("Treatment")))
axis(1, at=1:2, labels=c("pH 7.01", "pH 7.38"))
plotCI(x=c(1,2), y=gmean_pH,uiw=gse_pH, liw=gse_pH,add=TRUE,gap=0.001, pch=20, col=c("red", "pink"))

plot(c(1,2),c(12,15), xaxt = "n", type="n",ylab=expression(paste("Temperature °C")), xlab=expression(paste("Treatment")))
axis(1, at=1:2, labels=c("pH 7.01", "pH 7.38"))
plotCI(x=c(1,2), y=gmean_Temp,uiw=gse_Temp, liw=gse_Temp,add=TRUE,gap=0.001, pch=20, col=c("red", "pink"))

plot(c(1,2),c(25,29), xaxt = "n", type="n",ylab=expression(paste("Salinity")), xlab=expression(paste("Treatment")))
axis(1, at=1:2, labels=c("pH 7.01", "pH 7.38"))
plotCI(x=c(1,2), y=gmean_Sal,uiw=gse_Sal, liw=gse_Sal,add=TRUE,gap=0.001, pch=20, col=c("red", "pink"))

plot(c(1,2),c(1800,2200), xaxt = "n", type="n",ylab=expression(paste("Total Alkalinity µmol kg"^"-1")), xlab=expression(paste("Treatment")))
axis(1, at=1:2, labels=c("pH 7.01", "pH 7.38"))
plotCI(x=c(1,2), y=gmean_TA,uiw=gse_TA, liw=gse_TA,add=TRUE,gap=0.001, pch=20, col=c("red", "pink"))

plot(c(1,2),c(1800,2400), xaxt = "n", type="n",ylab=expression(paste("DIC µmol kg"^"-1")), xlab=expression(paste("Treatment")))
axis(1, at=1:2, labels=c("pH 7.01", "pH 7.38"))
plotCI(x=c(1,2), y=gmean_DIC,uiw=gse_DIC, liw=gse_DIC,add=TRUE,gap=0.001, pch=20, col=c("red", "pink"))

plot(c(1,2),c(50000,80000), xaxt = "n", type="n", ylab=expression(paste("Algal Feed (Cells ml"^"-1",")")), xlab=expression(paste("Treatment")))
axis(1, at=1:2, labels=c("pH 7.01", "pH 7.38"))
plotCI(x=c(1,2), y=gmean_cells,uiw=gse_cells, liw=gse_cells,add=TRUE,gap=0.001, pch=20, col=c("red", "pink"))

#total larvae in tanks
boxplot(total.live.larvae~Treatment*Day,data=larval.counts,col=c("red","pink"), xaxt = "n", varwidth=T, frame.plot=TRUE, ylab=expression(paste("Number of Live Larvae")))
#axis(1, at=c(1.5, 3.5, 5.5), labels=c("Day2", "Day4", "Day5"))
#legend("topright", c("pH 7.01","pH 7.38"), fill=c("red","pink"), bty="n", cex=0.6) 
#axis.break(2,450000,style="slash") 

gap.boxplot(larval.counts$total.live.larvae ~ larval.counts$Treatment * larval.counts$Day, #means the values are plotted againsy variable
            gap=list(top=c(100000,480000),bottom=c(NA,NA)), ylab=expression(paste("Number of Live Larvae")),col=c("red","pink")) #specifies regions of Y axis to exclude
legend("topright", c("pH 7.01","pH 7.38"), fill=c("red","pink"), bty="n", cex=0.6) 



# Add data points
levelProportions <- c(1,1,1,1,1,1,1,1)
mylevels<-levels(larval.counts$Combo)
for(i in 1:length(mylevels))
{
  thislevel<-mylevels[i]
  thisvalues<-larval.counts[larval.counts$Combo==thislevel, "total.live.larvae"]
  
  # take the x-axis indices and add a jitter, proportional to the N in each level
  myjitter<-jitter(rep(i, length(thisvalues)), amount=levelProportions[i]/10)
  points(myjitter, thisvalues, pch=20, col=rgb(0,0,0,.2))   
}
# 
# #percent mortality in visual checks
# boxplot(per.mort~Treatment*Day,data=larval.counts,col=c("blue","red"), xaxt = "n", width=levelProportions, frame.plot=TRUE, ylab=expression(paste("% Mortality in Visual Checks")))
# axis(1, at=c(1.5, 3.5, 5.5, 7.5), labels=c("Day0", "Day2", "Day4", "Day6"))
# legend("topleft", c("Ambient","High"), fill=c("blue","red"), bty="n", cex=0.6) 
# 
# combos<-levels(as.factor(larval.counts$Combo))
# for(i in 1:length(combos))
# {
#   thislevel<-combos[i]
#   thisvalues<-larval.counts[larval.counts$Combo==thislevel, "per.mort"]
#   
#   # take the x-axis indices and add a jitter, proportional to the N in each level
#   myjitter<-jitter(rep(i, length(thisvalues)), amount=levelProportions[i]/10)
#   points(myjitter, thisvalues, pch=20, col=rgb(0,0,0,.2))   
# }
# 
title("Treatment Conditions Trial 3", outer=TRUE)
dev.off()

#Load WiSH data
wish.data <- read.csv("Wish_data_Trial3.csv", header=TRUE, sep=",", na.strings="NA") #load data with a header, separated by commas, with NA as NA
date.time <- sub("-",",", wish.data$Date...Time)
date.time <- strsplit(date.time, ",")
date.time <- data.frame(matrix(unlist(date.time), nrow=length(date.time), byrow=T),stringsAsFactors=FALSE)
temp.data <- wish.data[,grepl("Tank", colnames(wish.data))] #search for and subset columns containing the header name "Tank"
temp.data <- cbind(date.time, temp.data)
colnames(temp.data) <- c("Date", "Time", "Tank3", "Tank6", "Tank4", "Tank1", "Tank5", "Tank2")

sal.data <- wish.data[,grepl("Salinity", colnames(wish.data))] #search for and subset columns containing the header name "Tank"
sal.data <- sal.data[,grepl("Temperature", colnames(sal.data))] #search for and subset columns containing the header name "Tank"
sal.data <- cbind(date.time, sal.data)
colnames(sal.data) <- c("Date", "Time", "Salinity1", "Salinity2", "Salinity3", "Salinity4")

##Plot temp data
plot(temp.data$Tank1,type="l", col="pink", ylab=expression(paste("Temperature °C")), xlab=expression(paste("Time")), ylim=c(13,14.5))
lines(temp.data$Tank2, col="lightblue" )
lines(temp.data$Tank3, col="blue")
lines(temp.data$Tank4, col="red")
lines(temp.data$Tank5, col="darkred")
lines(temp.data$Tank6, col="darkblue")
legend("bottomleft", c("Tank1","Tank2", "Tank3","Tank4","Tank5", "Tank6" ), col=c("pink","lightblue", "blue", "red", "darkred", "darkblue"), bty="n", lwd=1, cex=0.6) 

##Plot salinity data
plot(sal.data$Salinity1,type="l", col="pink", ylab=expression(paste("Temperature °C")), xlab=expression(paste("Time")), ylim=c(20,30))
lines(sal.data$Salinity2, col="lightblue" )
lines(sal.data$Salinity3, col="blue")
lines(sal.data$Salinity4, col="red")
legend("bottomleft", c("Salinity1", "Salinity2", "Salinity3", "Salinity4"), col=c("pink","lightblue", "blue", "red"), bty="n", lwd=1, cex=0.6) 

