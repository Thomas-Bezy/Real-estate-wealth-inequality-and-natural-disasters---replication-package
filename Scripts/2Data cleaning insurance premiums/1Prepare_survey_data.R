library(haven)
library(Rcpp)
library(tidyverse)
library(fastDummies)
library(readxl)
`%notin%`<-Negate(`%in%`)


setwd("..")

#Import baseline datasets
assu <- read_sas("BdF_raw_datasets/assu_casd_2017.sas7bdat", NULL)
men <- read_sas("BdF_raw_datasets/menage_casd_2017.sas7bdat", NULL)
dwelling <- read_sas("BdF_raw_datasets/depmen_casd_2017.sas7bdat", NULL)
rev_ind <- read_sas("BdF_raw_datasets/revind_dom_casd_2017.sas7bdat",NULL)
depts=read.table("depts2017.txt", header=TRUE)%>%select(REGION,DEP)


#Have the list of IDs
ids=assu%>%
  select(IDENT_MEN)%>%
  unique(.)

#Find insurance spending for principal, secondary housing and car insurance
assu_princ=assu%>%
  filter(Natassu==1)%>% #Select housing insurance for primary housing
  select(IDENT_MEN,MASSU_D,Perassua)%>%
  mutate(Perassua2=1/(Perassua/12))%>%  #Change the coefficient multiplicateur to put every amount representative of the same period of time
  mutate(MASSU_D=MASSU_D*Perassua2)%>%
  select(-Perassua,-Perassua2)
names(assu_princ)[2]="ASSU_PRINC"

assu_sec=assu%>%
  filter(Natassu==2)%>% #Select housing insurance for secondary housing
  select(IDENT_MEN,MASSU_D,Perassua)%>%
  mutate(Perassua2=1/(Perassua/12))%>%  #Change the coefficient multiplicateur to put every amount representative of the same period of time
  mutate(MASSU_D=MASSU_D*Perassua2)%>%
  select(-Perassua,-Perassua2)
names(assu_sec)[2]="ASSU_SEC"

assu_car=assu%>%
  filter(Natassu%in%c(3:24))%>%
  select(IDENT_MEN,MASSU_D,Perassua)%>%
  mutate(Perassua2=1/(Perassua/12))%>%  #Change the coefficient multiplicateur to put every amount representative of the same period of time
  mutate(MASSU_D=MASSU_D*Perassua2)%>%
  select(-Perassua,-Perassua2)%>%
  group_by(IDENT_MEN)%>%
  summarise(MASSU_D=sum(MASSU_D))
names(assu_car)[2]="ASSU_CAR"



#Dwellings characteristics
dwelling_char=dwelling%>%select(IDENT_MEN,Htl,Nbphab,SURFHAB_D,Stalog,PRIXRP_D,Prixrs,Stalog,Ancons,Htl)%>%
  mutate(RENTER=ifelse(Stalog%in%c(4,5),1,0))%>%
  select(-Stalog)%>%
  filter(Htl%in%c(1,2))%>%
  rename("CONS"="Ancons")%>%
  filter(CONS%notin%c(10,98,99))%>%
  dummy_cols(select_columns = "CONS")%>%
  rename("NATLOC"="Htl")
  
  


#Select relevent data for the prediction

#Income: REVDISP
#Number of dwellings: NRHC
#Number of people in the household: NPERS
#Weight: pondmen
#Number of consumption units in the household: COEFFUC
#Highest degree: dip14pr
#Highest degree, detailed: DIPDETPR



rev=men%>%select(IDENT_MEN,REVACT,PREST_FAM_TOT, REVPAT, REVEXC,REVSOC,REVTOT,REVDISP,NRHC,NPERS,COEFFUC,DIPDETPR,pondmen,DEP)%>%
  rename("PONDMEN"="pondmen")%>%
  mutate(DECILE=ifelse(REVDISP>=63210,10,
                    ifelse(REVDISP<63210&REVDISP>=49350,9,
                    ifelse(REVDISP<49350&REVDISP>=41290,8,
                    ifelse(REVDISP<41290&REVDISP>=35060,7,
                    ifelse(REVDISP<35060&REVDISP>=30040,6,
                    ifelse(REVDISP<30040&REVDISP>=25390,5,
                    ifelse(REVDISP<25390&REVDISP>=21120,4,
                    ifelse(REVDISP<21120&REVDISP>=17470,3,
                    ifelse(REVDISP<17470&REVDISP>=13630,2,
                    ifelse(REVDISP<13630,1,NA)))))))))))%>% #Create deciles
  mutate(QUINTILE=ifelse(DECILE%in%c(1,2),1,
                  ifelse(DECILE%in%c(3,4),2,
                  ifelse(DECILE%in%c(5,6),3,
                  ifelse(DECILE%in%c(7,8),4,
                  ifelse(DECILE%in%c(9,10),5,NA))))))%>% #Create quintiles
  mutate(NIVVIE=REVDISP/COEFFUC)%>%
  left_join(depts,by="DEP")%>%
  dummy_cols(select_columns = "REGION")%>%
  select(-DEP,-REGION)


#Join insurance data with income data
  
df1=left_join(ids,rev,by="IDENT_MEN")%>%
  left_join(assu_princ,by="IDENT_MEN")%>%
  left_join(assu_sec,by="IDENT_MEN")%>%
  left_join(assu_car,by="IDENT_MEN")%>%
  left_join(dwelling_char,by="IDENT_MEN")         #Join variables
  
  
  
#Create new variables (insurance per meter squared, ratio insurance over income...)
df2=df1%>%mutate(ASSU_PRINC_M2=ASSU_PRINC/SURFHAB_D)%>%
  mutate(ASSU_PRINC_M2=ifelse(is.na(ASSU_PRINC),NA,ASSU_PRINC_M2))%>%
  mutate(ASSU_CAR_NPERS=ASSU_CAR/NPERS)%>%
  mutate(ASSU_CAR_NPERS=ifelse(is.na(ASSU_CAR),NA,ASSU_CAR_NPERS))%>%
  mutate(ASSU_PRINC_0=replace_na(ASSU_PRINC,0))%>%
  mutate(ASSU_SEC_0=replace_na(ASSU_SEC,0))%>%
  mutate(ASSU_CAR_0=replace_na(ASSU_CAR,0))%>%        #Replace NAs by zeros for computations
  rowwise()%>%
  mutate(ASSU_TOT=sum(ASSU_PRINC_0,ASSU_SEC_0,ASSU_CAR_0))%>%
  mutate(RATIO_PRINC=ASSU_PRINC_0/REVTOT)%>%
  mutate(RATIO_SEC=ASSU_SEC_0/REVTOT)%>%
  mutate(RATIO_CAR=ASSU_CAR_0/REVTOT)%>%
  mutate(RATIO=ASSU_TOT/REVTOT)%>%
  mutate(RATIO_PRINC=ifelse(RATIO_PRINC>=0&RATIO_PRINC<=1,RATIO_PRINC,NA))%>%
  mutate(RATIO_SEC=ifelse(RATIO_SEC>=0&RATIO_SEC<=1,RATIO_SEC,NA))%>%
  mutate(RATIO_CAR=ifelse(RATIO_CAR>=0&RATIO_CAR<=1,RATIO_CAR,NA))%>%
  mutate(ASSU_OFFER_PRINC=ASSU_PRINC_0/1.12)%>%
  mutate(ASSU_OFFER_SEC=ASSU_SEC_0/1.12)%>%
  mutate(ASSU_OFFER_CAR=ASSU_CAR_0/1.06)%>%        #Create variables for amounts collected by insurance companies
  mutate(ASSU_OFFER=ASSU_OFFER_PRINC+ASSU_OFFER_SEC+ASSU_OFFER_CAR)%>%
  mutate(ASSU_CAT=0.12*ASSU_OFFER_PRINC+0.12*ASSU_OFFER_SEC+0.06*ASSU_OFFER_CAR)  #This is the amount given to CATNAT
  



#######Outliers
#Some respondents have very high ratio of insurance per meter squared
#I remove these respondents until the average insurance payment I get in m sample matches the one available online
#For individual houses: 429€ for owners, 256€ for renters
#For appartments: 244€ for owners, 166€ for renters

#The right threshold seems to be .70
threshold=quantile(df2%>%filter(ASSU_PRINC>0)%>%select(ASSU_PRINC_M2),.70,na.rm=TRUE)
df3=df2%>%filter(ASSU_PRINC_M2<threshold&ASSU_PRINC>0)

#I run this code to check the threshold
a=df3%>%
  filter(NATLOC==1)%>%
  group_by(RENTER)%>%
  summarize(ASSU_OFFER_PRINC_wm=weighted.mean(ASSU_OFFER_PRINC,w=PONDMEN,na.rm=TRUE),
            ASSU_OFFER_CAR_wm=weighted.mean(ASSU_OFFER_CAR,w=PONDMEN,na.rm=TRUE),
            ASSU_OFFER_PRINC_m=mean(ASSU_OFFER_PRINC,na.rm=TRUE),
            ASSU_OFFER_CAR_m=mean(ASSU_OFFER_CAR,na.rm=TRUE))






write.csv(df3,"Data/BdF.csv")








