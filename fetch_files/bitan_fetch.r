library(rvest);library(XML);library(stringr);library(plyr);library(dplyr);

#Organize URLs
url.base="http://www.ybitan.co.il"
bitan.files=html(paste(url.base,"pirce_update",sep="/"))%>%html_nodes("a")%>%html_text()
bitan.files=mdply(c("PriceFull","Stores"),.fun = function(x){
  df.out=data.frame(type=x,url=paste(url.base,"upload",bitan.files[grepl(".zip",bitan.files)&grepl(x,bitan.files)],sep="/"))})%>%
  select(-X1)%>%mutate(url=as.character(url))

bitan.store.files=bitan.files%>%filter(type=="Stores")
x=bitan.store.files[1,]
bitan.stores=ddply(bitan.store.files,.(type,url),.fun = function(x){
  options(warn=-1)
  temp <- tempfile()
  download.file(x$url,temp,quiet = T,mode="wb")
  bitan.doc=xmlParse(readLines(unzip(temp),encoding="windows=1255"),encoding="windows-1255")
  unlink(temp)
  header=getNodeSet(bitan.doc,"/Root/*[not(self::Stores)]")
  headerdf=as.data.frame(as.list(setNames(xmlSApply(header,xmlValue),xmlSApply(header,xmlName))))
  bitan.stores=xmlToDataFrame(getNodeSet(bitan.doc,"/Root/Stores/Store"))
  bitan.stores=merge(headerdf,bitan.stores)
  rm(list=ls(pattern = "header"))
  options(warn=0)
  return(bitan.stores)
})

bitan.price.files=bitan.files%>%filter(type=="PriceFull")
bitan.price=ddply(bitan.store.files,.(type,url),.fun = function(x){
  options(warn=-1)
  temp <- tempfile()
  download.file(x$url,temp,quiet = T,mode="wb")
  bitan.doc=readLines(unzip(temp),encoding="windows=1255")
  bitan.doc=gsub('[&]', '&amp;',bitan.doc)
  bitan.doc=xmlParse(bitan.doc,encoding="windows-1255")
  unlink(temp)
  header=getNodeSet(bitan.doc,"/Root/*[not(self::Items)]")
  headerdf=as.data.frame(as.list(setNames(xmlSApply(header,xmlValue),xmlSApply(header,xmlName))))
  bitan.prices=xmlToDataFrame(getNodeSet(bitan.doc,"/Root/Items/Item"))
  bitan.prices=merge(headerdf,bitan.prices)
  rm(list=ls(pattern = "header"))
  return(bitan.prices)
  options(warn=0)
})