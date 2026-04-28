library(haven)
library(Rcpp)
library(tidyverse)

setwd("...")

fideli=read_dta("0Data/info_for_dvf2017.dta")
dvf=read_dta("0Data/dvf_total.dta")
insee_postal=read_dta("0Data/correspondance-code-insee-code-postal.dta")

#Correct the postal codes database
list_postal=insee_postal%>%mutate(ADRESS_POSTAL=substr(ADRESS_POSTAL,1,5))
a=insee_postal%>%mutate(ADRESS_POSTAL=substr(ADRESS_POSTAL,7,11))%>%filter(ADRESS_POSTAL!="")
list_postal=rbind(list_postal,a)
a=insee_postal%>%mutate(ADRESS_POSTAL=substr(ADRESS_POSTAL,13,17))%>%filter(ADRESS_POSTAL!="")
list_postal=rbind(list_postal,a)
a=insee_postal%>%mutate(ADRESS_POSTAL=substr(ADRESS_POSTAL,19,23))%>%filter(ADRESS_POSTAL!="")
list_postal=rbind(list_postal,a)
a=insee_postal%>%mutate(ADRESS_POSTAL=substr(ADRESS_POSTAL,25,29))%>%filter(ADRESS_POSTAL!="")
list_postal=rbind(list_postal,a)
a=insee_postal%>%mutate(ADRESS_POSTAL=substr(ADRESS_POSTAL,31,35))%>%filter(ADRESS_POSTAL!="")
list_postal=rbind(list_postal,a)

insee_postal=list_postal

fideli=fideli%>%
  rename("ADRESS_INSEE"="depcom2")%>%
  rename("DATE_CONST"="date_const")%>%
  rename("ADRESS_RIVOLI"="rue1")%>%
  rename("ROOMS"="nbpiec")%>%
  rename("NB_SDB"="NBSDB")%>%
  rename("NB_WC"="NBWC")%>%
  rename("DATE_OWNERSHIP"="DATEACTE")%>%
  rename("ADRESS_NUMBER"="noimm1")%>%
  rename("SURFACE"="SURFTOT")



###Modify FIDELI
fideli=left_join(fideli,insee_postal,by="ADRESS_INSEE")
fideli=fideli%>%mutate(ROOMS=as.numeric(ROOMS)-NB_WC-NB_SDB)%>%
  mutate(ADRESS_NUMBER=as.numeric(ADRESS_NUMBER))%>%
  mutate(NATLOC=ifelse(NATLOC=="MA",1,
                       ifelse(NATLOC=="ME",1,2)))%>%
  select(-NB_WC,-NB_SDB,-ADRESS_INSEE)

fideli=fideli%>%
  mutate(DATE_OWNERSHIP=as.numeric(substr(DATE_OWNERSHIP,5,8)))



###Modify DVF
dvf=dvf%>%mutate(DATE_OWNERSHIP_DVF=substr(DATE_OWNERSHIP_FULL,1,4))
a=dvf%>%filter(DATE_OWNERSHIP_DVF<=2016)

###Here I want to select the most recent acquisition date for each dwelling
dates_to_keep=a%>%group_by(ADRESS_POSTAL_DVF,ADRESS_RIVOLI_DVF,ADRESS_NUM_DVF,ADRESS_BIS_DVF,NATLOC_DVF,SURFACE_DVF)%>%
  summarise(DATE_OWNERSHIP_FULL=max(DATE_OWNERSHIP_FULL))
dates_to_keep=cbind(dates_to_keep,seq(1,nrow(dates_to_keep)))
names(dates_to_keep)[8]="ID"

#Merge with prices
b=left_join(dates_to_keep,a,by=c("ADRESS_POSTAL_DVF","ADRESS_RIVOLI_DVF","ADRESS_NUM_DVF","ADRESS_BIS_DVF","NATLOC_DVF","SURFACE_DVF","DATE_OWNERSHIP_FULL"))

#Take out missing values and duplicates
b=b%>%
  filter(ADRESS_POSTAL_DVF!="")%>%
  unique(.)

dvf=b

#Convert all variables to numbers
dvf=dvf%>%mutate(DATE_OWNERSHIP_DVF=as.numeric(DATE_OWNERSHIP_DVF))%>%
  ungroup()

#Create a function for whether I found the right indicator or not
progress_fct=function(data){
  if(sum(data,na.rm=TRUE)==1){
    progress="Merge"
  } else if(sum(data,na.rm=TRUE)>1){
    progress="Multiple Merges"
  } else if(sum(data,na.rm=TRUE)==0){
    progress="Still to merge"
  }
  #print(progress)
  assign('progress',progress,envir=.GlobalEnv)
}




adresses_fideli=fideli%>%select(ADRESS_POSTAL,ADRESS_RIVOLI,ADRESS_NUMBER)%>%
  mutate(FULL_ADRESS=paste0(ADRESS_POSTAL,ADRESS_RIVOLI,ADRESS_NUMBER))%>%
  select(FULL_ADRESS)
adresses_fideli=as.vector(adresses_fideli)

dvf_selected=dvf



#Set the thresholds
thresholds=c(0)

for (i in 1:300) {
  thresholds=rbind(thresholds,round((nrow(dvf_selected))/300*i))
}

thresholds=as.vector(thresholds)



progress_list=c()
dpt="00"
postal_code="00000"

for (t in 1:300){
  
  #At every round, I restart the databases
  to_merge=data.frame()
  df=data.frame()
  
  for (i in (thresholds[t]+1):thresholds[(t+1)]) {
    
    #here I select the observation to merge
    adress=dvf_selected[i ,]%>%select(ADRESS_POSTAL_DVF,ADRESS_RIVOLI_DVF,ADRESS_NUM_DVF)%>%
      as.matrix()
    
    char=dvf_selected[i ,]%>%select(ROOMS_DVF,SURFACE_DVF,DATE_OWNERSHIP_DVF,NATLOC_DVF)%>%
      as.matrix()
    
    #Take only the postal code for all remaining observations to reduce length of computation
    if (dpt!=substr(adress[1],1,2)){
      fideli_dpt=fideli%>%filter(substr(ADRESS_POSTAL,1,2)==substr(adress[1],1,2))
      dpt=substr(adress[1],1,2)
    }else{}
    
    if (postal_code!=adress[1]){
      fideli_postal=fideli_dpt%>%filter(ADRESS_POSTAL==adress[1])
      postal_code=fideli_postal$ADRESS_POSTAL%>%unique(.)
      if (length(postal_code)==0){
        postal_code="00000"
      }
    }else{}
    
    #Here I take all potential residing households in Fideli
    a=fideli_postal%>%filter(ADRESS_POSTAL==adress[1]&ADRESS_RIVOLI==adress[2]&ADRESS_NUMBER==adress[3])
    
    
    #I create an indicator of difference for surface, I then only keep surface gaps inferior to 10
    a=a%>%mutate(ROOMS=abs(ROOMS-char[1]))%>%
      mutate(SURFACE=abs(SURFACE-char[2]))%>%
      mutate(DATE_OWNERSHIP=abs(DATE_OWNERSHIP-char[3]))%>%
      mutate(NATLOC=abs(NATLOC-char[4]))
    
    #Restart the surface count and the indicator for whether the observation is matched
    surf=0
    progress_ind=0
    
    #If no observation is found 
    if (nrow(a)==0){
      progress_ind=1
      progress="No observation"
    }
    
    
    
    
    #if multiple observations are found
    while (progress_ind<1)#Loop for different surface values 
    {
      
      #I first determine if there is an observation that fits everything
      a=a%>%mutate(MERGE=ifelse(SURFACE<=surf&NATLOC==0&ROOMS%in%c(0,NA)&DATE_OWNERSHIP%in%c(0,NA),1,0))
      stage=0
      progress_fct(a$MERGE)
      
      #If it is not the case, I make vary date movein, then rooms then floor
      if (progress=="Still to merge")#Move in vary by 1
      {
        a=a%>%mutate(MERGE=ifelse(SURFACE<=surf&NATLOC==0&ROOMS%in%c(0,NA)&DATE_OWNERSHIP%in%c(1,NA),1,0))
        progress_fct(a$MERGE)
        stage=1
      }else{}
      
      if (progress=="Still to merge")#Rooms vary by 1
      {
        a=a%>%mutate(MERGE=ifelse(SURFACE<=surf&NATLOC==0&ROOMS%in%c(1,NA)&DATE_OWNERSHIP%in%c(0,NA),1,0))
        progress_fct(a$MERGE)
        stage=2
      }else{}
      
      if (progress=="Still to merge")#Rooms vary by 2
      {
        a=a%>%mutate(MERGE=ifelse(SURFACE<=surf&NATLOC==0&ROOMS%in%c(2,NA)&DATE_OWNERSHIP%in%c(0,NA),1,0))
        progress_fct(a$MERGE)
        stage=3
      }else{}   
      
      
      if (progress=="Still to merge")#Rooms vary by 3
      {
        a=a%>%mutate(MERGE=ifelse(SURFACE<=surf&NATLOC==0&ROOMS%in%c(3,NA)&DATE_OWNERSHIP%in%c(0,NA),1,0))
        progress_fct(a$MERGE)
        stage=4
      }else{}  
      
      if (progress=="Still to merge")#Abstract from ownership date
      {
        a=a%>%mutate(MERGE=ifelse(SURFACE<=surf&NATLOC==0&ROOMS%in%c(0,NA),1,0))
        progress_fct(a$MERGE)
        stage=5
      }else{}  
      
      #increase the surface threshold by 1
      surf=surf+1
      
      #Indicate that it is no more useful to run the loop
      if(progress!="Still to merge"|surf==5){
        progress_ind=1
      }
      
    }#Arrow for the while function for surface
    
    
    #If only one observation is found and the previous matching did not work
    if (nrow(a)==1&progress=="Still to merge"){
      progress_ind=1
      progress="Merge - Single obs"
      a=a%>%mutate(MERGE=0)
    }
    
    
    
    #Allocate the observation to every dataset
    if (progress=="Merge") #If the observation is matched among multiple options
    {
      df=rbind(df,a%>%filter(MERGE==1)%>%mutate(STAGE=stage,SURF=surf-1)%>%
                 mutate(PRICE=dvf$PRICE[i]))
      print(paste("Merge",i,"completed"))
    }else if (progress=="Merge - Single obs") #If the observation is matched because there was no other option
    {
      df=rbind(df,a%>%filter(MERGE==0)%>%mutate(STAGE=NA,SURF=NA)%>%
                 mutate(PRICE=dvf$PRICE[i]))
      print(paste("Merge",i,"completed - single"))
    }else if (progress=="Multiple Merges") #If the observation is matched multiple times
    {
      a=a%>%filter(MERGE==1)
      a=a%>%mutate(MERGE=nrow(a),STAGE=stage,SURF=surf-1)%>%
        mutate(PRICE=dvf$PRICE[i])
      df=rbind(df,a)
      print(paste("Merge",i,"Multiple Merges"))
    }else if (progress=="Still to merge") #If the algorithm did not find any match
    {to_merge=rbind(to_merge,a%>%mutate(MERGE_NUMBER=i))
    print(paste("Merge",i,progress))
    }else{print(paste("Merge",i,progress))} #If the observation was not found in Fideli
    
    
    progress_list=rbind(progress_list, progress)
    
    if (i %in% thresholds[2:301]){
      merged=df%>%filter(MERGE%in%c(0,1))
      multiple=df%>%filter(MERGE>=2)
      
      write_dta(merged,paste0("0Data/dvf_merged2017/df_merged_part",t,".dta"))
      write_dta(multiple,paste0("0Data/dvf_merged2017/df_multiple_part",t,".dta"))
      write_dta(to_merge,paste0("0Data/dvf_merged2017/df_tomerge_part",t,".dta"))
    }else{}
    
    
  }#Arrow for the value of i: the row that is taken from ANIL
}


100*table(progress_list)/nrow(progress_list)



df_final=data.frame()
for (t in 1:300) {
  temp=read_dta(paste0("0Data/dvf_merged2017/df_merged_part",t,".dta"))
  df_final=rbind(df_final,temp)
  print(t)
}
df_final=df_final%>%select(id_log,PRICE,STAGE,SURF)

write_dta(df_final,"0Data/id_log_prices2017.dta")




