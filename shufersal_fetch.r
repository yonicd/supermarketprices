library(rvest);library(XML);library(stringr);library(plyr);library(dplyr);library(tidyr)

sapply_pb <- function(X, FUN, ...){
  env <- environment()
  pb_Total <- length(X)
  counter <- 0
  pb <- txtProgressBar(min = 0, max = pb_Total, style = 3)
  
  wrapper <- function(...){
    curVal <- get("counter", envir = env)
    assign("counter", curVal +1 ,envir=env)
    setTxtProgressBar(get("pb", envir=env), curVal +1)
    FUN(...)
  }
  res <- sapply(X, wrapper, ...)
  close(pb)
  res}

url.base="http://prices.shufersal.co.il/FileObject/UpdateCategory?catID=0&storeId=0&page="
max.page=as.numeric(gsub("[^1-9]","",html(paste0(url.base,1))%>%html_nodes(xpath="//div[@id='gridContainer']/table/tfoot/tr/td/a[6]")%>%html_attr("href")))
shufersal.files=unique(unlist(sapply_pb(c(1:max.page),function(i){html(paste0(url.base,i))%>%html_nodes("a")%>%html_attr("href")})))
shufersal.files=shufersal.files[grepl("http",shufersal.files)]
shufersal.files=mdply(c("Price","PriceFull","Promo","PromoFull","Store"),.fun = function(x){
  df.out=data.frame(type=x,url=shufersal.files[grepl(".gz",shufersal.files)&grepl(x,shufersal.files)])})%>%
  select(-X1)%>%mutate(url=as.character(url))

#Stores
shufersal.store.files=shufersal.files%>%filter(type=="Store")
temp <- tempfile()
download.file(shufersal.store.files$url,temp,quiet = T,mode="wb")
shufersal.doc=xmlParse(temp,encoding="UTF-8")
header=getNodeSet(shufersal.doc,"/asx:abap/asx:values/*[not(self::STORES)]")
headerdf=as.data.frame(as.list(setNames(xmlSApply(header,xmlValue),xmlSApply(header,xmlName))))
shufersal.stores=xmlToDataFrame(getNodeSet(shufersal.doc,"/asx:abap/asx:values/STORES/STORE"))
shufersal.stores=merge(headerdf,shufersal.stores)
rm(list=ls(pattern = "header"))
unlink(temp)

#Prices
shufersal.price.files=shufersal.files%>%filter(type=="PriceFull")
options(warn=-1)
shufersal.prices=ddply(shufersal.price.files,.(type,url),.fun = function(x){
temp <- tempfile()
download.file(x$url,temp,quiet = T,mode="wb")
shufersal.doc=xmlParse(c(readLines(gzfile(temp),encoding = "UTF-8"),"</root>"))
header=getNodeSet(shufersal.doc,"/root/*[not(self::Items)]")
headerdf=as.data.frame(as.list(setNames(xmlSApply(header,xmlValue),xmlSApply(header,xmlName))))
shufersal.prices=xmlToDataFrame(getNodeSet(shufersal.doc,"/root/Items/Item"))
shufersal.prices=merge(headerdf,shufersal.prices)
unlink(temp)
return(shufersal.prices)
},.progress = "text")%>%mutate_each(funs(iconv(.,"UTF-8")))
options(warn=0)

#Promotions
shufersal.promo.files=shufersal.files%>%filter(type=="PromoFull")%>%slice(c(2))
options(warn=-1)
shufersal.promo=ddply(shufersal.promo.files,.(type,url),.fun = function(x){
temp <- tempfile()
download.file(x$url,temp,quiet = T,mode="wb")
shufersal.doc=xmlParse(readLines(temp,encoding="UTF-8"))
unlink(temp)
promo.items.s=xmlToDataFrame(nodes=getNodeSet(shufersal.doc,"/root/Promotions/Promotion/PromotionItems/Item"))
header.s=getNodeSet(shufersal.doc,"/root/*[not(self::Promotions)]")
headerdf.s=as.data.frame(as.list(setNames(xmlSApply(header.s,xmlValue),xmlSApply(header.s,xmlName))))
shufersal.promo=merge(headerdf.s,promo.items.s)


promo.clubs=xmlToDataFrame(getNodeSet(shufersal.doc,"/root/Promotions/Promotion/Clubs"))
promo.restrictions=xmlToDataFrame(getNodeSet(shufersal.doc,"/root/Promotions/Promotion/AdditionalRestrictions"))
promo.id=xmlToDataFrame(getNodeSet(shufersal.doc,"/root/Promotions/Promotion/PromotionId"))

promo.info=mdply(c(1:nrow(promo.id)),.fun = function(d){
                 d1=getNodeSet(shufersal.doc,
                            paste0("/root/Promotions/Promotion[",d,"]/*[not(self::PromotionItems|self::AdditionalRestrictions|self::Clubs)]")
                            )
                 data.frame(value=iconv(unlist(xmlSApply(d1,xmlValue)),"UTF-8"),
                            name=unlist(xmlSApply(d1,xmlName)))
})%>%spread(name, value)%>%select(-X1)

promo.info=data.frame(promo.info,promo.clubs,promo.restrictions,check.names = F)
return(promo.info)},
.progress = "text")%>%mutate_each(funs(iconv(.,"UTF-8")))
options(warn=0)

shufersal.full.day=list(stores=shufersal.stores,prices=shufersal.prices,promotions=shufersal.promo)
