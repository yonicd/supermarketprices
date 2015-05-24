# Israel Supermarket Chain Data 
Read daily suprmarket data in all israel chain stores from GZ wrapped XML to data.frames.

For now Mega and Shufersal have been coded
  - Use mega_fetch.r to read Mega data 
  - Use shufersal_fetch.r to read Shufersal data
  
The code in mega_gis.r is the raw code to create a function in which the user input the distance willing to travel from current geocode and all stores are filtered accordingly.
  - Data is read for only those stores
  - User can filter basket of items wishes to purchase
  - The gas cost is taken into account as a function of distance from the geocode in the final price (price from transportation auuthority site)
  
The folder stat_poly_gis contains th shp file to make maps and show statistics by definitons of statistic area of the central beauru of statistics
  

