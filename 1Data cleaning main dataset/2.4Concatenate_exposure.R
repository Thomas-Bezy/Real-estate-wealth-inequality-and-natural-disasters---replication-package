library(haven)
library(Rcpp)
library(tidyverse)
library(sf)

setwd("...")


######################################
######## TRI - flood exposure ########
######################################

#create the dataset in which we will put the data
tri=c()

#Loop over the 3 different datasets
for (k in 1:3){
  
  #Loop over the 130 TRI areas
  data_list=c(1:130)
 

  #Import each dataset and rbind
  for (i in data_list){
    print(paste("Dataset is ",k,"/4 and TRI is ",i,"/",max(data_list),sep=""))
    temp=data_frame(read_sf(paste("Boundaries_separate_files/TRI_fideli_w_exposure/_fideli_w_exposure",k,"_",i,".gpkg",sep="")))%>%
      select(id_log,TRI_TYPE,SCENARIO,DEPTH,x,y)%>%
      mutate(ID_TRI=i)
    
    #rbind if not missing
    if (nrow(temp)>0){
      tri=rbind(tri,temp)
    }else{}
    
  }
}

#Export data
write_dta(tri,"_fideli_w_tri_without_dem.dta")





############################
######## Subsidence ########
############################

#create the dataset in which we will put the data
rga=data.frame()


#####FIRST DATASET

#Loop because there are 3 different datasets
for (k in 1:3){
  
  #Import each dataset and rbind for the 1200 first cantons
  for (i in c(1:1200)){
    print(paste("Dataset is ",k,"/3 and RGA is ",i,"/",1200,sep=""))   #Number of cantons: 3728
    temp=data_frame(read_sf(paste("Boundaries_separate_files/RGA_fideli_w_exposure/_fideli_w_exposure",k,"_",i,".gpkg",sep="")))%>%
      select(-geom,-fid_2)
    if (nrow(temp)>0){
      rga=rbind(rga,temp)
    }else{}
  }
}

#Export the first dataset
write_dta(rga,"_fideli_w_rga_without_dem1.dta")

#####SECOND DATASET

rga=data.frame()


#Loop because there are 3 different datasets
for (k in 1:3){
  
  #Import each dataset and rbind for the 1600 next cantons
  for (i in c(1201:2800)){
    print(paste("Dataset is ",k,"/3 and RGA is ",i-1200,"/",1600,sep=""))   #Number of cantons: 3728
    temp=data_frame(read_sf(paste("Boundaries_separate_files/RGA_fideli_w_exposure/_fideli_w_exposure",k,"_",i,".gpkg",sep="")))%>%
      select(-geom,-fid_2)
    if (nrow(temp)>0){
      rga=rbind(rga,temp)
    }else{}
  }
}

#Export the second dataset
write_dta(rga,"_fideli_w_rga_without_dem2.dta")



#####THIRD DATASET

rga=data.frame()


#Loop because there are 3 different datasets
for (k in 1:3){
  
  #Import each dataset and rbind for the 929 last cantons
  for (i in c(2801:3728)){
    print(paste("Dataset is ",k,"/3 and RGA is ",i-2800,"/",929,sep=""))   #Number of cantons: 3728
    temp=data_frame(read_sf(paste("Boundaries_separate_files/RGA_fideli_w_exposure/_fideli_w_exposure",k,"_",i,".gpkg",sep="")))%>%
      select(x,y,id_log,NIVEAU,-geom)
    if (nrow(temp)>0){
      rga=rbind(rga,temp)
    }else{}
  }
}

#Export the third dataset
write_dta(rga,"_fideli_w_rga_without_dem3.dta")

