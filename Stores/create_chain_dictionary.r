setwd("C:/Users/yoni/Documents/GitHub/supermarketprices/Stores")
load("stores_all.rdata")
load("chain_dictionary.rdata")

# Cerebus -----------------------------------------------------------------

cerebus.stores.list=c("tivtaam","doralon","osherad","hazihinam","keshet","ramilevi","superdosh","yohananof")

#Retrieve from Web
cerebus.stores=mdply(cerebus.stores.list,.fun = function(store.in){
webElem <- remDr$findElement(using = 'id', value = "username")
webElem$setElementAttribute(attributeName = 'value',value = store.in)
remDr$executeScript("document.getElementById('login-button').click();", args = list())
Sys.sleep(2)
#Get all Links for Full data
webElem <- remDr$findElement(using = 'id', value = "fileList")
#webElems<-webElem$findChildElements("css selector","a")
#links=unlist(sapply(webElems,function(x){x$getElementText()}))
links=htmlParse(remDr$getPageSource(),asText = T)%>%
        html_nodes('#fileList')%>%
        html_nodes('a')%>%html_text()
links=links[grepl("Full|Stores",links)]
x=links[grepl("Stores",links)]
if(!is.null(x)){
remDr$findElement(using = "xpath",value = paste0("//*[@id='",x,"']/td[5]/a/span"))$clickElement()
remDr$findElement(using = 'name', value = "dl-file-btn")$clickElement()
Sys.sleep(2)
cerebus.doc=xmlParse(paste(tempdir(),x,sep="\\"))  
header=getNodeSet(cerebus.doc,"/Root/*[not(self::SubChains)]")
headerdf=as.data.frame(as.list(setNames(xmlSApply(header,xmlValue),xmlSApply(header,xmlName))))
store.out=xmlToDataFrame(getNodeSet(cerebus.doc,"/Root/SubChains/SubChain/Stores/Store"))
store.out=merge(headerdf,store.out)%>%mutate_each(funs(iconv(.,"UTF-8")))
rm(list=ls(pattern = "header"))
}
remDr$goBack()
Sys.sleep(2)
return(store.out)
},.progress = "text")

cerberus.stores=mdply(x1$fullpath[x1$provider=="cerberus"],.fun = function(x){
  cerebus.doc=xmlParse(x)
  header=getNodeSet(cerebus.doc,"/Root/*[not(self::SubChains)]")
  headerdf=as.data.frame(as.list(setNames(xmlSApply(header,xmlValue),xmlSApply(header,xmlName))))
  store.out=xmlToDataFrame(getNodeSet(cerebus.doc,"/Root/SubChains/SubChain/Stores/Store"))
  store.out=merge(headerdf,store.out)%>%mutate_each(funs(iconv(.,"UTF-8")))
  rm(list=ls(pattern = "header"))
  return(store.out)
})%>%select(-X1)
names(cerberus.stores)=tolower(names(cerberus.stores))

# Shufersal -----------------------------------------------------------------

shufersal.doc=xmlParse(x1$fullpath[x1$chainname=="שופרסל"],encoding="UTF-8")
header=getNodeSet(shufersal.doc,"/asx:abap/asx:values/*[not(self::STORES)]")
headerdf=as.data.frame(as.list(setNames(xmlSApply(header,xmlValue),xmlSApply(header,xmlName))))
shufersal.stores=xmlToDataFrame(getNodeSet(shufersal.doc,"/asx:abap/asx:values/STORES/STORE"))
shufersal.stores=merge(headerdf,shufersal.stores)
rm(list=ls(pattern = "header"))
names(shufersal.stores)=tolower(names(shufersal.stores))

# Mega -----------------------------------------------------------------

mega.stores=xmlToDataFrame(xmlParse(readLines(x1$fullpath[x1$chainname=="רשת מגה"],encoding="UTF-8")))[-1,-1]%>%mutate_each(funs(iconv(.,"UTF-8")))
names(mega.stores)=tolower(names(mega.stores))

# Bitan -----------------------------------------------------------------

bitan.doc=xmlParse(x1$fullpath[x1$chainname=="יינות ביתן מרכז הרשת"],encoding="windows-1255")
header=getNodeSet(bitan.doc,"/Root/*[not(self::Stores)]")
headerdf=as.data.frame(as.list(setNames(xmlSApply(header,xmlValue),xmlSApply(header,xmlName))))
bitan.stores=xmlToDataFrame(getNodeSet(bitan.doc,"/Root/Stores/Store"))
bitan.stores=merge(headerdf,bitan.stores)
rm(list=ls(pattern = "header"))
names(bitan.stores)=tolower(names(bitan.stores))

# Eden Teva -----------------------------------------------------------------

edenteva.doc=xmlParse(x1$fullpath[x1$chainname=="עדן טבע מרקט"],encoding="windows-1255")
header=getNodeSet(edenteva.doc,"/Root/*[not(self::Stores)]")
headerdf=as.data.frame(as.list(setNames(xmlSApply(header,xmlValue),xmlSApply(header,xmlName))))
edenteva.stores=xmlToDataFrame(getNodeSet(edenteva.doc,"/Root/Stores/Store"))
edenteva.stores=merge(headerdf,edenteva.stores)
rm(list=ls(pattern = "header"))
names(edenteva.stores)=tolower(names(edenteva.stores))


# Nibit -------------------------------------------------------------------
nibit.stores=ddply(x1%>%filter(provider=="nibit"),.variables = .(chainname),.fun = function(df){
nibit.doc=xmlParse(df$fullpath,encoding="UTF-8")
xmlToDataFrame(getNodeSet(nibit.doc,"/Store/Branches/Branch"),stringsAsFactors = F)%>%select(-c(ChainName,Latitude,Longitude))
}
)
names(nibit.stores)=tolower(names(nibit.stores))

# Combine All -----------------------------------------------------------------

stores.all=rbind_list(bitan.stores,cerberus.stores,edenteva.stores,mega.stores,shufersal.stores,nibit.stores)

save(stores.all,file="stores_all.rdata")
write.csv(stores.all,file="stores_all.csv",row.names = FALSE)
write.csv(x1%>%select(-fullpath),file="chain_dictionary.csv",row.names = FALSE)
