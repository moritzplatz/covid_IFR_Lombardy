##################################################
## Set workind directory and load packages
##################################################

# Set the working directory to the local folder to which the git was downloaded
setwd("/Github/covid_IFR_Lombardy/")

required_packages <- c("OECD", "rjags", "R2OpenBUGS", "coda", "data.table", "MCMCvis", "viridis", "ggsci", "RColorBrewer", "stargazer", "animation", "latex2exp")
not_installed <- required_packages[!(required_packages %in% installed.packages()[ , "Package"])]    # Determine missing packages
if(length(not_installed)) install.packages(not_installed)                                           # Install missing packages

suppressWarnings(lapply(required_packages, require, character.only = TRUE))


#########################
## Make figures 
#########################
# Load necessary packages and set wd to the github folder
# Please make sure all packages are loaded
source(file = "code/setWdLoadPackages.R")
# Run Bayesian estimations
source("code/bayesianIFRestimate.R")

baseSize <- 20

###############################################################
# Deaths by day in 2015-2019 and 2020
###############################################################

ggplot() + 
  geom_line(data = plotDeaths, aes(x = date, y = meanDailyDeathsBeforeAll, colour = "2015-19 average deaths") , linetype = "dashed") + 
  geom_line(data = plotDeaths, aes(x = date, y = deaths2020All, colour = "2020 deaths")) + 
  scale_color_manual(values = c(
    '2015-19 average deaths' = 'blue',
    '2020 deaths' = 'black')) +
  theme_bw(base_size = baseSize) + 
  xlab("") + 
  ylab("") + 
  geom_hline(yintercept = 0) +  
  theme(legend.position = c(0.25, 0.8)) +
  theme(legend.margin = margin(t = 0, unit='cm')) +
  theme(legend.title = element_blank()) +
  geom_vline(xintercept = as.Date("2020-02-20"), color = "red") +
  theme(panel.grid.minor = element_blank())

ggsave(filename = "output/deathsByDate.pdf")
ggsave(filename = "../../Users/grinaldi/Dropbox/Apps/Overleaf/covid19 IFR/figures/deathsByDate.pdf")


###############################################################
# Bayesian estimates of infection fatality rates
###############################################################

IFRPlot <- rbindlist(lapply(postTown, function(x) as.data.table(x[,8:14])))
ageRanges <- unique(dataLikelihoodTown$ageRange)
names(IFRPlot) <- ageRanges
IFRPlot <- melt(IFRPlot)
IFRPlot[, value := value*100] # Change to percentage

ggplot(IFRPlot, aes(variable, value)) +
  geom_boxplot(outlier.shape = NA) +
  scale_y_sqrt(breaks = c(0,.01, .1, .2, .5, 1, 2, 5, 10), limits = c(0, 15)) +
  theme_bw(base_size = baseSize) +
  xlab("Age Range") + 
  ylab("Infection Fatality Rate (%)") +
  geom_hline(yintercept = 0) +
  theme(panel.grid.minor = element_blank())

ggsave(filename = "output/IFRbyAge.pdf")
ggsave(filename = "../../Users/grinaldi/Dropbox/Apps/Overleaf/covid19 IFR/figures/IFRbyAge.pdf")

###############################################################
# Fatality rates for different assumptions on infection rates
###############################################################

# Construct overall ifr 
ageRangeShare <- unique(demographicData[, c("ageRange", "ageRangeShare")]) 
overallIFR <- merge(graphDataAll, ageRangeShare, by = "ageRange")
overallIFR <- overallIFR[, list(sum(`2.5%` * ageRangeShare), sum(`50%` * ageRangeShare), sum(`97.5%` * ageRangeShare)), by = prop]
overallIFR[, ageRange := "Overall", ]
names(overallIFR)[2:4] <- c("2.5%", "50%", "97.5%")
overallIFR <- overallIFR[, c("2.5%", "50%", "97.5%", "ageRange", "prop")]
graphDataAll <- rbind(graphDataAll, overallIFR)
graphDataAll[, `2.5%` := 100 * `2.5%`]  # change to percentage
graphDataAll[, `50%` := 100 * `50%`] 
graphDataAll[, `97.5%` := 100 * `97.5%`] 
graphDataAll[, prop := 100 * prop] 
# Custom palette
palCustom <- c( "#4575B4", "#91BFDB", "greenyellow", "khaki", "orange", rev(brewer.pal(n = 7, name = "RdYlBu"))[6:7] ,  "#000000")

ggplot(graphDataAll[prop > 10, ], aes(x = prop)) +
  geom_line(aes(y = `2.5%`, color = ageRange), linetype = 2) +
  geom_line(aes(y = `50%`, color = ageRange), size = 1) +
  geom_line(aes(y = `97.5%`, color = ageRange), linetype = 2) +
  scale_y_sqrt(breaks = c(0,.01, .1, .2, .5, 1, 2, 5, 10, 20), limits = c(0, 30)) +
  theme_bw(base_size = baseSize) +
  xlab("Proportion Infected (%)") + 
  ylab("Infection Fatality Rate (%)") +
  geom_hline(yintercept = 0) +
  theme(panel.grid.minor = element_blank()) + 
  geom_ribbon(aes(ymin=`2.5%`,ymax=`97.5%`, fill = ageRange), alpha= 0.35)  +
  scale_fill_manual(values = palCustom, name = "Age Range") + 
  scale_color_manual(values = palCustom, name = "Age Range") 
  
ggsave(filename = "output/IFRbyProp.pdf")
ggsave(filename = "../../Users/grinaldi/Dropbox/Apps/Overleaf/covid19 IFR/figures/IFRbyProp.pdf")

###############################################################
# Appendix plot of trace and posterior densities
###############################################################

# diagnostic evaluation of posterior samples
priorDelta <- seq(0,0.1, length.out = 5000)
MCMCtrace(postTown,
          iter = 500,
          params = c("delta"),
          priors = priorDelta,
          main_den = c(TeX("Density $\\delta_{0-20}$"),
                       TeX("Density $\\delta_{21-40}$"),
                       TeX("Density $\\delta_{41-50}$"),
                       TeX("Density $\\delta_{51-60}$"),
                       TeX("Density $\\delta_{61-70}$"),
                       TeX("Density $\\delta_{71-80}$"),
                       TeX("Density $\\delta_{81+}$")),
          main_tr =  c(TeX("Trace $\\delta_{0-20}$"),
                       TeX("Trace $\\delta_{21-40}$"),
                       TeX("Trace $\\delta_{41-50}$"),
                       TeX("Trace $\\delta_{51-60}$"),
                       TeX("Trace $\\delta_{61-70}$"),
                       TeX("Trace $\\delta_{71-80}$"),
                       TeX("Trace $\\delta_{81+}$")),
          filename = "output/MCMCdelta.pdf"
          )

priorDeltaCovid <- seq(0,0.3, length.out = 5000)
MCMCtrace(postTown,
          iter = 500,
          params = c("deltaCovid"),
          priors = priorDeltaCovid,
          main_den = c(TeX("Density $\\delta^{Covid}_{0-20}$"),
                       TeX("Density $\\delta^{Covid}_{21-40}$"),
                       TeX("Density $\\delta^{Covid}_{41-50}$"),
                       TeX("Density $\\delta^{Covid}_{51-60}$"),
                       TeX("Density $\\delta^{Covid}_{61-70}$"),
                       TeX("Density $\\delta^{Covid}_{71-80}$"),
                       TeX("Density $\\theta^{Covid}_{81+}$")),
          main_tr =  c(TeX("Trace $\\delta^{Covid}_{0-20}$"),
                       TeX("Trace $\\delta^{Covid}_{21-40}$"),
                       TeX("Trace $\\delta^{Covid}_{41-50}$"),
                       TeX("Trace $\\delta^{Covid}_{51-60}$"),
                       TeX("Trace $\\delta^{Covid}_{61-70}$"),
                       TeX("Trace $\\delta^{Covid}_{71-80}$"),
                       TeX("Trace $\\theta^{Covid}_{81+}$")),
          filename = "output/MCMCdeltaCovid.pdf")

priorTheta <- qbeta(seq(0,1, length.out = 5000), 3, 2, ncp = 0, lower.tail = TRUE, log.p = FALSE)

MCMCtrace(postTown,
          iter = 500,
          priors = priorTheta,
          params = c("theta_i"),
          main_den = c(TeX("Density $\\theta_{Casalpusterlengo}$"),
                       TeX("Density $\\delta_{Castiglione d'Adda}$"),
                       TeX("Density $\\delta_{Codogno}$"),
                       TeX("Density $\\delta_{Fombio}$"),
                       TeX("Density $\\delta_{Maleo}$"),
                       TeX("Density $\\delta_{San Fiorano}$"),
                       TeX("Density $\\delta_{Somaglia}$"),
                       TeX("Density $\\delta_{Terranova dei Passerini}$")),
          main_tr =  c(TeX("Trace $\\theta_{Casalpusterlengo}$"),
                       TeX("Trace $\\delta_{Castiglione d'Adda}$"),
                       TeX("Trace $\\delta_{Codogno}$"),
                       TeX("Trace $\\delta_{Fombio}$"),
                       TeX("Trace $\\delta_{Maleo}$"),
                       TeX("Trace $\\delta_{San Fiorano}$"),
                       TeX("Trace $\\delta_{Somaglia}$"),
                       TeX("Trace $\\delta_{Terranova dei Passerini}$")),
          filename = "output/MCMCtheta.pdf")

system2(command = "pdfcrop", 
        args    = c("output/MCMCdelta.pdf", 
                    "output/MCMCdelta.pdf")) 

system2(command = "pdfcrop", 
        args    = c("output/MCMCdeltaCovid.pdf", 
                    "output/MCMCdeltaCovid.pdf")) 

system2(command = "pdfcrop", 
        args    = c("output/MCMCtheta.pdf", 
                    "output/MCMCtheta.pdf")) 


#############################################################
# Overall IFR from full model for various age groups
#############################################################

overallIFR <- merge(ageRangeShare, IFRPlot[, as.list(quantile(value, c(.025,.5,.975))), by = variable], by.x = "ageRange", by.y = "variable")
overallIFR <- overallIFR[, c(sum(ageRangeShare*`2.5%`), sum(ageRangeShare*`50%`) , sum(ageRangeShare*`97.5%`))]
sprintf("%.2f", overallIFR)

under60IFR <- merge(ageRangeShare, IFRPlot[, as.list(quantile(value, c(.025,.5,.975))), by = variable], by.x = "ageRange", by.y = "variable")
under60IFR <- under60IFR[ageRange %in% c("0-20", "21-40", "41-50", "51-60"), c(sum(ageRangeShare*`2.5%`), sum(ageRangeShare*`50%`) , sum(ageRangeShare*`97.5%`))/sum(ageRangeShare)]
sprintf("%.2f", under60IFR)

over60IFR <- merge(ageRangeShare, IFRPlot[, as.list(quantile(value, c(.025,.5,.975))), by = variable], by.x = "ageRange", by.y = "variable")
over60IFR <- over60IFR[! ageRange %in% c("0-20", "21-40", "41-50", "51-60"), c(sum(ageRangeShare*`2.5%`), sum(ageRangeShare*`50%`) , sum(ageRangeShare*`97.5%`))/sum(ageRangeShare)]
sprintf("%.2f", over60IFR)

over80IFR <- merge(ageRangeShare, IFRPlot[, as.list(quantile(value, c(.025,.5,.975))), by = variable], by.x = "ageRange", by.y = "variable")
over80IFR <- over80IFR[ageRange %in% c("81+"), c(sum(ageRangeShare*`2.5%`), sum(ageRangeShare*`50%`) , sum(ageRangeShare*`97.5%`))/sum(ageRangeShare)]

# Overall IFR assuming everyone got it
sprintf("%.2f", graphDataAll[ageRange == "Overall" & prop == 100, ])

# Overall infection rate of the area
infectionByTown <- cbind(demsData[, sum(tot2019), by = Denominazione], MCMCsum[8:14,])
names(infectionByTown)[2] <- c("population")
overallInfection <- infectionByTown[, list(sum(population*`50%`)/sum(population), sum(population*`2.5%`)/sum(population), sum(population*`97.5%`)/sum(population))]

#########################
## Make Tables
#########################

##################################
# Table of demographics and deaths
##################################
tableDemsDeaths <- dataLikelihoodTown[, c(-1)] # Remove town name
tableDemsDeaths <-  tableDemsDeaths[,lapply(.SD, sum, na.rm=TRUE), by= ageRange]
overallDemsDeaths <- tableDemsDeaths[, c(-1)]
overallDemsDeaths <- overallDemsDeaths[,lapply(.SD, sum, na.rm=TRUE), ]
overallDemsDeaths[, ageRange := "Overall"]
tableDemsDeaths <- rbind(tableDemsDeaths, overallDemsDeaths)

stargazer(tableDemsDeaths, summary = FALSE, rownames = FALSE)

##################################
# Table of model estimates
##################################
sprintf("%.4f", overallIFR)
sprintf("%.4f", under60IFR)
sprintf("%.4f", over60IFR)
table2Data <- MCMCsummary(postTown, params = c('delta','theta_i', "deltaCovid"), digits=4)

