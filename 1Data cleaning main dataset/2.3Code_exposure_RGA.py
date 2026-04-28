from qgis import processing

#In this code, the objective is to overlap the dwelling level data with exposure to flooding
#I loop across the 3728 cantons

#Decide the dataset that will be merged (fideli or filosofi)
dataset='fideli'

#This is to start the whole loop
x=1

while(x<=3728):
    #This is to chose the starting number
    n=1

    #Clip RGA data
    layer1 = r'C:\Users\Public\Documents\Thomas\Insurance\0Data\RGA.gpkg'
    layer2 = r'C:\Users\Public\Documents\Thomas\Insurance\0Data\Boundaries_separate_files\cantons_boundary\boundary_'+str(x)+'.gpkg'
    result = r'C:\Users\Public\Documents\Thomas\Insurance\0Data\Boundaries_separate_files\RGA_exposure\exposure_'+str(x)+'.gpkg'
    processing.run("native:clip", {'INPUT':layer1, 'OVERLAY':layer2, 'OUTPUT':result})

    while(n<=3): 
    
        #Clip fideli data
        layer1 = r'C:\Users\Public\Documents\Thomas\Insurance\0Data\_'+str(dataset)+'_loc_'+str(n)+'.gpkg'
        layer2 = r'C:\Users\Public\Documents\Thomas\Insurance\0Data\Boundaries_separate_files\cantons_boundary\boundary_'+str(x)+'.gpkg'
        result = r'C:\Users\Public\Documents\Thomas\Insurance\0Data\Boundaries_separate_files\RGA_'+str(dataset)+'\_'+str(dataset)+'_metro'+str(n)+'_'+str(x)+'.gpkg'
        processing.run("native:clip", {'INPUT':layer1, 'OVERLAY':layer2, 'OUTPUT':result})
    
        #Join attributes by location
        layer1 = r'C:\Users\Public\Documents\Thomas\Insurance\0Data\Boundaries_separate_files\RGA_'+str(dataset)+'\_'+str(dataset)+'_metro'+str(n)+'_'+str(x)+'.gpkg'
        layer2 = r'C:\Users\Public\Documents\Thomas\Insurance\0Data\Boundaries_separate_files\RGA_exposure\exposure_'+str(x)+'.gpkg'
        result = r'C:\Users\Public\Documents\Thomas\Insurance\0Data\Boundaries_separate_files\RGA_'+str(dataset)+'_w_exposure\_'+str(dataset)+'_w_exposure'+str(n)+'_'+str(x)+'.gpkg'
        
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
    
    
    
