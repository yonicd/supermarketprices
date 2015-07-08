setwd("C:/Users/yoni/Documents/GitHub/supermarketprices/")  

library(plyr);library(dplyr);library(rvest);library(RSelenium);library(tidyr)
require(RSelenium)

cerebus.stores=c("tivtaam","doralon","osherad","hazihinam","keshet","ramilevi","superdosh","yohananof")


fprof <- makeFirefoxProfile(list(browser.download.dir = tempdir(),
                                 browser.download.folderList = 2L,
                                 browser.download.manager.showWhenStarting = FALSE,
                                 browser.helperApps.neverAsk.saveToDisk = "application/x-gzip,text/xml"))

RSelenium::startServer()
remDr <- remoteDriver(extraCapabilities = fprof)
remDr$open(silent = F)
remDr$navigate("https://url.retail.publishedprices.co.il/login")
webElem <- remDr$findElement(using = 'id', value = "username")
webElem$setElementAttribute(attributeName = 'value',value = cerebus.stores[2])
remDr$executeScript("document.getElementById('login-button').click();", args = list())
Sys.sleep(2)

#Get all Links for Full data
#   webElem <- remDr$findElement(using = 'id', value = "fileList")
#   webElems<-webElem$findChildElements("css selector","a")
#   links=unlist(sapply(webElems,function(x){x$getElementText()}))
  links=htmlParse(remDr$getPageSource(),asText = T)%>%
  html_nodes('#fileList')%>%
  html_nodes('a')%>%html_text()
  links=links[grepl("Full|Stores",links)]

  x=links[grepl("Stores",links)]
  remDr$findElement(using = "xpath",value = paste0("//*[@id='",x,"']/td[5]/a/span"))$clickElement()
  remDr$findElement(using = 'name', value = "dl-file-btn")$clickElement()
  cerebus.doc=xmlParse(paste(tempdir(),x,sep="\\"))  
  header=getNodeSet(cerebus.doc,"/Root/*[not(self::SubChains)]")
  headerdf=as.data.frame(as.list(setNames(xmlSApply(header,xmlValue),xmlSApply(header,xmlName))))
  cerebus.stores=cerebus.stores=xmlToDataFrame(getNodeSet(cerebus.doc,"/Root/SubChains/SubChain/Stores/Store"))
  cerebus.stores=merge(headerdf,cerebus.stores)%>%mutate_each(funs(iconv(.,"UTF-8")))
  rm(list=ls(pattern = "header"))
  
cerebus=function(chain,store,date=format(Sys.Date(),"%Y%m%d"),hour,type="Price"){
  x=links[grepl(paste0("-",store,"-"),links)]
  #Prices
    remDr$findElement(using = 'link text', value = x[1])$clickElement()
    Sys.sleep(2)
    cerebus.doc=xmlParse(c(readLines(gzfile(paste(tempdir(),x[1],sep="\\")),encoding = "UTF-8"),"</Root>"))
    header=getNodeSet(cerebus.doc,"/Root/*[not(self::Items)]")
    headerdf=as.data.frame(as.list(setNames(xmlSApply(header,xmlValue),xmlSApply(header,xmlName))))
    cerebus.prices=xmlToDataFrame(getNodeSet(cerebus.doc,"/Root/Items/Item"))
    cerebus.prices=merge(headerdf,cerebus.prices)%>%mutate_each(funs(iconv(.,"UTF-8")))
  #Promotions
    remDr$findElement(using = 'link text', value = x[2])$clickElement()
    sleep(2)
    cerebus.doc=xmlParse(c(readLines(gzfile(paste(tempdir(),x[2],sep="\\")),encoding = "UTF-8"),"</Root>"))
    
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
  
  file.remove(paste(tempdir(),x,sep="\\"))
  return(list(cerebus.prices=cerebus.prices,cerebus.promo=cerebus.promo))
}

remDr$closeall()
