library(sp);library(RgoogleMaps);
library(maptools);library(ggplot2);
library(rgdal);library(dplyr)
library(plyr)

  
load("stores_mega.rdata")
mega.stores$street.number=gsub("[^0-9/-]",'',mega.stores$Address)
mega.stores$street.name=gsub("[0-9/-]",'',mega.stores$Address)
mega.stores=mega.stores%>%mutate(full.address=paste(City,street.name,street.number))
mega.stores=data.frame(mega.stores,t(sapply(mega.stores$full.address, getGeoCode)),row.names = NULL,check.names = F)

projxy=project(as.matrix(mega.stores[,c(20,19)]),proj= "+init=epsg:2039 +proj=tmerc +lat_0=31.73439361111111
        +lon_0=35.20451694444445 +k=1.0000067 +x_0=219529.584
               +y_0=626907.39 +ellps=GRS80 +towgs84=-48,55,52,0,0,0,0
               +units=m +no_defs")

colnames(projxy)=c("x","y")


mega.stores=data.frame(mega.stores,projxy,row.names = NULL,check.names = F)

load("stores_shufersal.rdata")
shufersal.stores=shufersal.stores%>%mutate(full.address=paste(CITY,ADDRESS))
shufersal.stores=data.frame(shufersal.stores,t(sapply(shufersal.stores$full.address, getGeoCode)),row.names = NULL,check.names = F)

projxy=projxy[!duplicated(projxy),]
pts=SpatialPoints(projxy[complete.cases(projxy),],proj4string = CRS("+init=epsg:2039"))


isr_shp_poly <- readShapePoly("stat_polygon_gis/lamas_statistics08.shp",
                              IDvar = "OBJECTID",
                              proj4string = CRS("+init=epsg:2039"))


a=over(isr_shp_poly,pts,returnList = T)
a1=sapply(a,length)
pts.df=rbind(data.frame(row.id=unlist(a[a1==1]),x1=1),data.frame(row.id=unlist(a[a1>1]),x1=10))
pts.df$OBJECTID=floor(as.numeric(row.names(pts.df))/pts.df$x1)
pts.df=data.frame(pts.df,pts@coords,check.names = F,row.names = NULL)%>%select(-c(row.id,x1))
mega.stores=left_join(mega.stores,pts.df,by=c("x","y"))


isr_poly_df <- as.data.frame(isr_shp_poly)


isr_points <- sp2tmap(isr_shp_poly)
names(isr_points) <- c("OBJECTID", "x", "y")
isr=left_join(isr_points,isr_poly_df,by=c("OBJECTID"))

x=mega.stores%>%filter(City%in%c("רחובות","תל-אביב"))%>%mutate(CITY=as.numeric(as.character(factor(City,labels=c(8400,5000)))))

ggplot(data = isr%>%filter(CITY%in%c(5000,8400)), aes(x=x, y=y)) +
  geom_polygon(color = "black", fill="white")+
  scale_fill_discrete(guide=F)+facet_wrap(~CITY,scales="free")+
  geom_point(data=x,aes(x=x,y=y))

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
