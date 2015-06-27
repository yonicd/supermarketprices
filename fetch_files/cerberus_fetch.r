setwd("C:/Users/yoni/Documents/GitHub/supermarketprices/")  

library(plyr);library(dplyr);library(rvest);library(RSelenium);library(tidyr)
require(RSelenium)


fprof <- makeFirefoxProfile(list(browser.download.dir = tempdir(),
                                 browser.download.folderList = 2L,
                                 browser.download.manager.showWhenStarting = FALSE,
                                 browser.helperApps.neverAsk.saveToDisk = "application/x-gzip,text/xml"))

RSelenium::startServer()
remDr <- remoteDriver(extraCapabilities = fprof)
remDr$open(silent = F)
remDr$navigate("https://url.retail.publishedprices.co.il/login")
webElem <- remDr$findElement(using = 'id', value = "username")
webElem$setElementAttribute(attributeName = 'value',value = 'ramilevi')
remDr$executeScript("document.getElementById('login-button').click();", args = list())
Sys.sleep(2)

#Get all Links for Full data
  webElem <- remDr$findElement(using = 'id', value = "fileList")
  webElems<-webElem$findChildElements("css selector","a")
  links=unlist(sapply(webElems,function(x){x$getElementText()}))
  links=links[grepl("Full|Stores",links)]

  x=links[grepl("Stores",links)]
  remDr$findElement(using = 'link text', value = x)$clickElement()
  cerebus.doc=xmlParse(c(readLines(gzfile(paste(tempdir(),x,sep="\\")),encoding = "UTF-8"),"</Root>"))  
  
cerebus=function(chain,store,date=format(Sys.Date(),"%Y%m%d"),hour,type="Price"){
x=paste0(type,"Full",store,"0492000005-",store,"-",date,"00",hour,".gz")
remDr$findElement(using = 'link text', value = x)$clickElement()
cerebus.doc=xmlParse(c(readLines(gzfile(paste(tempdir(),x,sep="\\")),encoding = "UTF-8"),"</Root>"))
header=getNodeSet(cerebus.doc,"/Root/*[not(self::Items)]")
headerdf=as.data.frame(as.list(setNames(xmlSApply(header,xmlValue),xmlSApply(header,xmlName))))
cerebus.prices=xmlToDataFrame(getNodeSet(cerebus.doc,"/Root/Items/Item"))
cerebus.prices=merge(headerdf,cerebus.prices)%>%mutate_each(funs(iconv(.,"UTF-8")))

cerebus.doc=xmlParse(c(readLines(gzfile(paste(tempdir(),x,sep="\\")),encoding = "UTF-8"),"</Root>"))

header.s=getNodeSet(cerebus.doc,"/Root/*[not(self::Promotions)]")
headerdf.s=as.data.frame(as.list(setNames(xmlSApply(header.s,xmlValue),xmlSApply(header.s,xmlName))))

temp=getNodeSet(cerebus.doc,"/Root/Promotions/Promotion")
names(temp)=xmlSApply(temp,FUN = function(node) xmlValue(xmlChildren(node)$PromotionId))
promo.map=ldply(temp,.id="PromotionId",.progress = "text",
                .fun = function(node){
                          x0=xmlChildren(node)$PromotionItems
                          if(!is.null(x0)){xmlToDataFrame(x0)}
                      })
rm(temp)

promo.clubs=data.frame(ClubId=as.numeric(xmlSApply(getNodeSet(cerebus.doc,"/Root/Promotions/Promotion/Clubs"),xmlValue)))
promo.restrictions=xmlToDataFrame(getNodeSet(cerebus.doc,"/Root/Promotions/Promotion/AdditionalRestrictions"))
promo.id=xmlToDataFrame(getNodeSet(cerebus.doc,"/Root/Promotions/Promotion/PromotionId"))

promo.info=mdply(c(1:nrow(promo.id)),.fun = function(d){
  d1=getNodeSet(cerebus.doc,
                paste0("/Root/Promotions/Promotion[",d,"]/*[not(self::PromotionItems|self::AdditionalRestrictions|self::Clubs)]")
  )
  data.frame(value=iconv(unlist(xmlSApply(d1,xmlValue)),"UTF-8"),
             name=unlist(xmlSApply(d1,xmlName)))
})%>%spread(name, value)%>%select(-X1)

promo.info=data.frame(promo.info,promo.clubs,promo.restrictions,check.names = F)
rm(promo.id,promo.clubs,promo.restrictions)

promo.map=left_join(promo.map,promo.info,by="PromotionId")
cerebus.promo=merge(headerdf.s,promo.map)
rm(headerdf.s,header.s,promo.map,promo.info)

file.remove(paste(tempdir(),links[2],sep="\\"))
return(list(cerebus.prices=cerebus.prices,cerebus.promo=cerebus.promo))
}

remDr$closeall()