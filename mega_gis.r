library(RgoogleMaps);library(maptools);library(ggplot2);

mega.stores=mega.stores%>%mutate(full.address=paste(mega.stores$City,mega.stores$Address))

mega.stores=data.frame(mega.stores,t(sapply(mega.stores$full.address, getGeoCode)),row.names = NULL,check.names = F)

projxy=project(as.matrix(mega.stores[,c(18,17)]),proj= "+init=epsg:2039 +proj=tmerc +lat_0=31.73439361111111
        +lon_0=35.20451694444445 +k=1.0000067 +x_0=219529.584
        +y_0=626907.39 +ellps=GRS80 +towgs84=-48,55,52,0,0,0,0
        +units=m +no_defs")

colnames(projxy)=c("x","y")

mega.stores=data.frame(mega.stores,projxy,row.names = NULL,check.names = F)


isr_shp_poly <- readShapePoly("stat_polygon_gis/lamas_statistics08.shp",
                              IDvar = "OBJECTID",
                              proj4string = CRS("+init=epsg:2039"))

isr_poly_df <- as.data.frame(isr_shp_poly)


isr_points <- sp2tmap(isr_shp_poly)
names(isr_points) <- c("OBJECTID", "x", "y")
isr=left_join(isr_points,isr_poly_df,by=c("OBJECTID"))

ggplot(data = isr, aes(x=x, y=y)) +
  geom_polygon(color = "black", fill="white")+
  scale_fill_discrete(guide=F)+
  geom_point(data=mega.stores,aes(x=x,y=y),colour="red")

origin="31.8943287,35.0068778"
#  paste(mega.stores$lat[1],mega.stores$lon[1],sep=",")


gas.price=as.numeric(gsub("[^0-9.]","",
                          html("http://energy.gov.il/Subjects/Fuel/Pages/GxmsMniPricesAndTaxes.aspx",encoding = "UTF-8")%>%
                            html_nodes(xpath="//div[@id='ctl00_PlaceHolderMain_GovXParagraph1Panel_ctl00__ControlWrapper_RichHtmlField']/table/tbody/tr[2]/td[1]")%>%
                            html_text()))

mega.distance.price=function(origin,max.distance){
    mega.dist=ddply(mega.stores%>%select(StoreId,StoreName,lat,lon)%>%filter(!is.na(lat)),
                    .(StoreId,StoreName),
                    .fun=function(df){
                                      xml.url = paste0('http://maps.googleapis.com/maps/api/distancematrix/xml?origins=',origin,'&destinations=',paste(df$lat,df$lon,sep=","),'&mode=driving&sensor=false')
                                      dout=data.frame(lat=df$lat,lon=df$lon,
                                                 distance=as.numeric(xmlSApply(getNodeSet(xmlParse(xml.url,isURL = T),"/DistanceMatrixResponse/row/element/distance/value"),xmlValue)),
                                                 time=as.numeric(xmlSApply(getNodeSet(xmlParse(xml.url,isURL = T),"/DistanceMatrixResponse/row/element/duration/value"),xmlValue)))
                                      return(dout)},
                    .progress = "text")%>%mutate(dist.price=2*distance*gas.price/1e4)
    mega.dist.out=mega.dist%>%filter(distance/1e3<=max.distance)
return(mega.dist.out)}

mega.distance.price(origin,15)