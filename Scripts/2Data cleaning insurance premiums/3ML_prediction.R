library(haven)
library(Rcpp)
library(tidyverse)
library(haven)
library(Rcpp)
library(tidyverse)
library(scales)
library(ggthemes)
library(matrixStats)
library(glmnet)
library(SuperLearner)
library("mvtnorm")
library("xgboost")
library("randomForest")
`%notin%`<-Negate(`%in%`)

setwd("..")

df=read.csv("Data/BdF.csv")

#remove missings and rename variables
df=df%>%
  filter(!is.na(ASSU_OFFER_PRINC))%>%
  filter(!is.na(REVDISP))%>%
  filter(!is.na(COEFFUC))%>%
  filter(!is.na(SURFHAB_D))%>%
  filter(!is.na(RENTER))%>%
  rename("INCOME_TOTAL"="REVDISP")%>%
  rename("NB_UC"="COEFFUC")%>%
  rename("SURFACE"="SURFHAB_D")

#Select the variables we want for prediction
outcome=df%>%select(ASSU_OFFER_PRINC)%>%as.matrix()
explanatory=df%>%select(INCOME_TOTAL,NB_UC,SURFACE, RENTER,NATLOC,
                        CONS_1,CONS_2,CONS_3,CONS_4,CONS_5,CONS_6,CONS_7,CONS_8,CONS_9,
                        REGION_11,REGION_24,REGION_27,REGION_28,REGION_32,REGION_44,REGION_52,REGION_53,REGION_75,REGION_76,REGION_84,REGION_93,REGION_94,REGION_97)


#Run the ML algorithm
ridge=create.Learner("SL.glmnet", params=list(alpha=0),name_prefix="ridge")
lasso=create.Learner("SL.glmnet", params=list(alpha=1),name_prefix="lasso")

sl_libraries=c(ridge$names)

sl_princ=SuperLearner(Y=outcome,
                   X=explanatory,
                   family=gaussian(),
                   SL.library=sl_libraries,
                   cvControl = list(V=5))



#Import the full dataset
full_sample=read_dta("Data/data_for_ML.dta")

#rearrange column order
head(full_sample)
full_sample=cbind(full_sample[,1],full_sample[,3:4],full_sample[,2],full_sample[,5],full_sample[,6:29])


#Prediction with a loop: the dataset is too large, I split it into 10 smaller datasets and I loop the prediction of these 10 smaller datasets

pred_fin=c()
divisor=10

#Run the loop
for (i in 1:divisor) {
  
print(i)
  
#Filter rows
temp=full_sample[(1+(nrow(full_sample)/divisor)*(i-1)):((nrow(full_sample)/divisor)*i),]
temp_id=temp$id_log

#Predict
pred_princ=predict(sl_princ,temp,onlySL=T)

#Store prediction
pred=data.frame(temp$id_log,pred_princ$pred)
pred_fin=rbind(pred_fin,pred)

}



#Add the column that indicates whether the household is a renter or an owner (variable RENTER)
pred_fin=cbind(pred_fin,full_sample$RENTER)
names(pred_fin)=c("id_log","ASSU_PRINC","RENTER")



#Create a dataset for renters
renter=pred_fin%>%
  filter(RENTER==1)%>%
  rename("RENTER_ASSU_PRINC"="ASSU_PRINC")%>%
  select(id_log,RENTER_ASSU_PRINC)

#Export the data
write_dta(renter,"Data/premiums_renters.dta")



#Create a dataset for owners
owner=pred_fin%>%
  filter(RENTER==0)%>%
  rename("OWNER_ASSU_PRINC"="ASSU_PRINC")%>%
  select(id_log,OWNER_ASSU_PRINC)

#Export the data
write_dta(owner,"Data/premiums_owners.dta")