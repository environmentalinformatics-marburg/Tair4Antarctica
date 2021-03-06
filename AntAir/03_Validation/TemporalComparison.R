
rm(list=ls())
library(caret)
library(raster)
library(rgdal)
library(viridis)
library(sptm)
#mainpath <- "/mnt/sd19007/users/hmeyer/Antarctica/ReModel2017/"
mainpath <- "/media/hanna/data/Antarctica/ReModel2017/"
datapath <- paste0(mainpath,"/data/")
rdatapath <- paste0(datapath, "/RData/")
rasterdata <- paste0(datapath,"/raster/")
Shppath <- paste0(datapath,"/ShapeLayers/")
modelpath <- paste0(datapath, "/modeldat/")
predpath <- paste0(datapath, "/predictions/")
MODISpath <- paste0(mainpath,"/MODISLST/")
vispath <- datapath <- paste0(mainpath,"/visualizations/")

tmppath <- paste0(mainpath,"/tmp/")
rasterOptions(tmpdir = tmppath)

models <- c("rf","gbm","lm","pls","nnet")




scaling <- function(predictors,scaleStats){
  for (i in 1:ncol(predictors)){
    rowID <- which(row.names(scaleStats)==names(predictors)[i])
    predictors[,i] <- (predictors[,i]-scaleStats$mean[rowID])/scaleStats$sd[rowID]
  }
  return(predictors)
}



plot_ext <- list()
results_external <- c()
for (modeltype in models){
  model <- get(load(paste0(modelpath,"model_final_",modeltype,".RData")))
  testdat <- get(load(paste0(modelpath,"testingDat.RData")))
  testdat$LSTmean <- (testdat$LST_day+testdat$LST_night)/2
  if (modeltype=="pls"||modeltype=="nnet"){
    testdat[,which(names(testdat)%in%names(model$trainingData))] <- data.frame(
      scaling(testdat[,which(names(testdat)%in%names(model$trainingData))],model$scaleStats))
  }
  testdat$prediction <- predict(model,testdat)
  
  dat <- testdat[,names(testdat)%in%c("Temperature","prediction")]
  
  pdf(paste0(vispath,"/externalvalidation_",modeltype,".pdf"),width=6,height=5)
 print(ggplot(testdat, aes(Temperature,prediction)) + 
    stat_binhex(bins=100)+
    xlim(min(dat),max(dat))+ylim(min(dat),max(dat))+
    xlab("Measured Tair (°C)")+
    ylab("Predicted Tair (°C)")+
    geom_abline(slope=1, intercept=0,lty=2)+
    scale_fill_gradientn(name = "data points", 
                         #trans = "log", 
                         #breaks = 10^(0:3),
                         colors=viridis(10)))
 dev.off()
 
 save(testdat,file=paste0(vispath,"/external_validation_",modeltype,".RData"))
 
 
  results_external <- rbind(results_external, 
                   data.frame("model"=modeltype,
                              round(regressionStats(prd = dat$prediction,obs=dat$Temperature)[,c(3:7)],2)))
}

write.csv(results_external,
          paste0(vispath,"/externalvalidation.csv"))

