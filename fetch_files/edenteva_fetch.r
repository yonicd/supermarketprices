library(rvest);library(XML);library(stringr);library(plyr);library(dplyr);

#Organize URLs
url.base="http://operations.edenteva.co.il/Prices"
edenteva.files=html(paste(url.base,"index",sep="/"))%>%html_nodes("a")%>%html_text()
edenteva.files=mdply(c("PriceFull","Stores"),.fun = function(x){
  df.out=data.frame(type=x,url=paste(url.base,edenteva.files[grepl(".zip",edenteva.files)&grepl(x,edenteva.files)],sep="/"))})%>%
  select(-X1)%>%mutate(url=as.character(url))

edenteva.store.files=edenteva.files%>%filter(type=="Stores")
x=edenteva.store.files[1,]
edenteva.stores=ddply(edenteva.store.files,.(type,url),.fun = function(x){
  options(warn=-1)
  temp <- tempfile()
  download.file(x$url,temp,quiet = T,mode="wb")
  edenteva.doc=xmlParse(readLines(unzip(temp),encoding="windows=1255"),encoding="windows-1255")
  unlink(temp)
  header=getNodeSet(edenteva.doc,"/Root/*[not(self::Stores)]")
  headerdf=as.data.frame(as.list(setNames(xmlSApply(header,xmlValue),xmlSApply(header,xmlName))))
  edenteva.stores=xmlToDataFrame(getNodeSet(edenteva.doc,"/Root/Stores/Store"))
  edenteva.stores=merge(headerdf,edenteva.stores)
  rm(list=ls(pattern = "header"))
  options(warn=0)
  return(edenteva.stores)
})

edenteva.price.files=edenteva.files%>%filter(type=="PriceFull")
edenteva.stores=ddply(edenteva.store.files,.(type,url),.fun = function(x){
  options(warn=-1)
  temp <- tempfile()
  download.file(x$url,temp,quiet = T,mode="wb")
  edenteva.doc=readLines(unzip(temp),encoding="windows=1255")
  edenteva.doc=gsub('[&]', '&amp;',edenteva.doc)
  edenteva.doc=xmlParse(edenteva.doc,encoding="windows-1255")
  unlink(temp)
  header=getNodeSet(edenteva.doc,"/Root/*[not(self::Items)]")
  headerdf=as.data.frame(as.list(setNames(xmlSApply(header,xmlValue),xmlSApply(header,xmlName))))
  edenteva.prices=xmlToDataFrame(getNodeSet(edenteva.doc,"/Root/Items/Item"))
  edenteva.prices=merge(headerdf,edenteva.prices)
  return(edenteva.prices)
  options(warn=0)
})