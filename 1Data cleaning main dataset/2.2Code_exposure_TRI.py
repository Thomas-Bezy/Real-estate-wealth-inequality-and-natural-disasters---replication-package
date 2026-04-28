from qgis import processing

#In this code, the objective is to overlap the dwelling level data with exposure to flooding
#I loop across the 130 TRI zones

#Decide the dataset that will be merged
dataset='fideli'

#This is to start the whole loop
x=1

while(x<=130):
    
    #Clip TRI data
    layer1 = r'C:\Users\Public\Documents\Thomas\Insurance\0Data\Map_TRI.gpkg'
    layer2 = r'C:\Users\Public\Documents\Thomas\Insurance\0Data\Boundaries_separate_files\TRI_boundary\boundary_tri_'+str(x)+'.gpkg'
    result = r'C:\Users\Public\Documents\Thomas\Insurance\0Data\Boundaries_separate_files\TRI_exposure\exposure_'+str(x)+'.gpkg'
    processing.run("native:clip", {'INPUT':layer1, 'OVERLAY':layer2, 'OUTPUT':result})
    
    n=1
    #n<=4 for fideli
    while(n<=3): 
    
        #Clip fideli data - fideli_loc_metro
        layer1 = r'C:\Users\Public\Documents\Thomas\Insurance\0Data\_'+str(dataset)+'_loc_'+str(n)+'.gpkg'
        layer2 = r'C:\Users\Public\Documents\Thomas\Insurance\0Data\Boundaries_separate_files\TRI_boundary\boundary_tri_'+str(x)+'.gpkg'
        result = r'C:\Users\Public\Documents\Thomas\Insurance\0Data\Boundaries_separate_files\TRI_'+str(dataset)+'\_'+str(dataset)+'_metro'+str(n)+'_'+str(x)+'.gpkg'
        processing.run("native:clip", {'INPUT':layer1, 'OVERLAY':layer2, 'OUTPUT':result})
    
        #Join attributes by location
        layer1 = r'C:\Users\Public\Documents\Thomas\Insurance\0Data\Boundaries_separate_files\TRI_'+str(dataset)+'\_'+str(dataset)+'_metro'+str(n)+'_'+str(x)+'.gpkg'
        layer2 = r'C:\Users\Public\Documents\Thomas\Insurance\0Data\Boundaries_separate_files\TRI_exposure\exposure_'+str(x)+'.gpkg'
        result = r'C:\Users\Public\Documents\Thomas\Insurance\0Data\Boundaries_separate_files\TRI_'+str(dataset)+'_w_exposure_depth\_'+str(dataset)+'_w_exposure'+str(n)+'_'+str(x)+'.gpkg'
        
        processing.run("qgis:joinattributesbylocation",\
        {'INPUT':layer1,\
        'JOIN':layer2,\
        'PREDICATE':[0],\
        'JOIN_FIELDS':[],\
        'DISCARD_NONMATCHING':False,\
        'PREFIX':'',\
        'OUTPUT':result})
        n=n+1
    
    x=x+1
        
 