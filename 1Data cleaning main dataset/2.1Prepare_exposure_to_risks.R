library(haven)
library(Rcpp)
library(tidyverse)
library(sf)
library(writexl)
library(readxl)

setwd("...")


#####In this code, I create separate files to prepare for the merge in QGIS
###We create cantons (geographical) boundaries and risk exposure boundaries



#########################
######## CANTONS ########
#########################

#Canton level data available here: https://gadm.org/data.html
cantons=read_sf("FRA_adm/FRA_adm4.shp")%>%select(geometry)

#Create different files by municipalities
for (i in 1:nrow(cantons)){
  boundary=cantons[i,1]
  st_write(boundary,paste("Boundaries_separate_files/cantons_boundary/boundary_",i,".gpkg",sep=""),append = FALSE)
}


######################################
######## TRI - flood exposure ########
######################################

###Here I create a big map of exposure of TRIs

#Import data on flood exposure available here: https://www.georisques.gouv.fr/donnees/bases-de-donnees/zonages-inondation-rapportage-2020
#There are multiple datasets to merge for different levels of risk, I start by the first dataset to initialize the loop
tri=read_sf("tri_2020_sig_di/n_inondable_01_01for_s.shp")

#Select relevant variables, ht_min corresponds to flood depth
tri=tri%>%select(typ_inond,scenario,ht_min,datentree,datsortie,id_tri,geometry)

#Rename
names(tri)=c("TRI_TYPE","SCENARIO","FIRST_DATE","LAST_DATE","id_tri","geometry")

#List of datasets to append
data_list=c("01_02moy","01_03mcc","01_04fai","02_01for","02_02moy","02_04fai",
            "03_01for","03_01forcc_ct","03_02moy","03_03mcc_ct","03_03mcc","03_04fai","03_04faicc_ct")

#Append all the datasets
for (i in data_list){
  print(i)
  temp=read_sf(paste("tri_2020_sig_di/n_inondable_",i,"_s.shp",sep=""))
  temp=temp%>%select(typ_inond,scenario,ht_min,datentree,datsortie,id_tri,geometry)
  names(temp)=c("TRI_TYPE","SCENARIO","FIRST_DATE","LAST_DATE","id_tri","geometry")
  
  #Append
  tri=rbind(tri,temp)
}

#Export the full map
st_write(tri,"Map_TRI.gpkg",append=FALSE)



########TRI MAP COVERAGE########

###Here I first import TRI boundaries
#Import data
tri_delim=read_sf("tri_2020_sig_di/n_commune_s.shp")

#Create a dataset with IDs for each TRI
tri_id=data_frame(tri_delim)%>%mutate(COUNT=1)%>%
  group_by(id_tri)%>%summarise(COUNT=sum(COUNT))
tri_id=tri_id%>%cbind(c(1:nrow(tri_id)))%>%select(-COUNT)
names(tri_id)[2]="ID_TRI"

#Export TRI IDs
write_xlsx(tri_id,"TRI_IDs.xlsx")
write_dta(tri_id,"TRI_IDs.dta")

#Join TRI IDs with corresponding coordinates
tri_delim=tri_delim%>%left_join(tri_id,by="id_tri")%>%
  select(ID_TRI)

#Export different gpkg for each tri
for (i in 1:nrow(tri_id)){
  boundary=tri_delim%>%filter(ID_TRI==i)
  st_write(boundary,paste("Boundaries_separate_files/TRI_boundary/boundary_tri_",i,".gpkg",sep=""),append = FALSE)
}




############################
######## Subsidence ########
############################

#Import data available here: https://www.georisques.gouv.fr/donnees/bases-de-donnees/retrait-gonflement-des-argiles
rga=read_sf("ExpoArgile_Fxx_L93.shp")

rga=rga%>%select(NIVEAU,geom)

st_write(rga,"RGA.gpkg",append=FALSE)