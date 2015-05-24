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
# shufersal.url="http://pricesprodpublic.blob.core.windows.net/stores/Stores7290027600007-000-201505240201.gz?sv=2014-02-14&sr=b&sig=nRDnNmBf5oAls1CmRCzau0%2Fp2%2FAdRbG0cW0zRKyMiCo%3D&se=2015-05-24T04%3A00%3A13Z&sp=r"
# temp <- tempfile()
# download.file(shufersal.url,temp,quiet = T,mode="wb")
# shufersal.doc=xmlParse(c(readLines(gzfile(temp),encoding = "UTF-8"),"</root>"))
shufersal.doc=xmlParse("https://github.com/yonicd/supermarketprices/raw/master/shufersal/Stores7290027600007-000-201505240201.xml")
header=getNodeSet(shufersal.doc,"/asx:abap/asx:values/*[not(self::STORES)]")
headerdf=as.data.frame(as.list(setNames(xmlSApply(header,xmlValue),xmlSApply(header,xmlName))))
shufersal.stores=xmlToDataFrame(getNodeSet(shufersal.doc,"/asx:abap/asx:values/STORES/STORE"))
shufersal.stores=merge(headerdf,shufersal.stores)
rm(list=ls(pattern = "header"))
#unlink(temp)

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
shufersal.promo.files=shufersal.files%>%filter(type=="PromoFull")
options(warn=-1)
shufersal.promo=ddply(shufersal.promo.files,.(type,url),.fun = function(x){
temp <- tempfile()
download.file(x$url,temp,quiet = T,mode="wb")
shufersal.doc=xmlParse(c(readLines(gzfile(temp),encoding = "UTF-8"),"</root>"))
#shufersal.doc=xmlParse("shufersal/PromoFull7290027600007-001-201505220341.xml")
promo.items.s=xmlToDataFrame(nodes=getNodeSet(shufersal.doc,"/root/Promotions/Promotion/PromotionItems/Item"))
header.s=getNodeSet(shufersal.doc,"/root/*[not(self::Promotions)]")
headerdf.s=as.data.frame(as.list(setNames(xmlSApply(header.s,xmlValue),xmlSApply(header.s,xmlName))))
shufersal.promo=merge(headerdf.s,promo.items.s)

promo.info.s=getNodeSet(shufersal.doc,"/root/Promotions/Promotion/*[not(self::PromotionItems)]")
promo.info.df.s=data.frame(value=iconv(unlist(xmlSApply(promo.info.s,xmlValue)),"UTF-8"),
                         name=unlist(xmlSApply(promo.info.s,xmlName)))
x=which(promo.info.df.s$name=="PromotionId")
x.c=which(promo.info.df.s$name=="Clubs")
promo.info.df.s$id=rep(c(1:length(x)),x.c-x+1)
promo.info.df.s=promo.info.df.s%>%spread(name, value)%>%select(-id)
rm(x,x.c)

promo.size.s=NULL
for(i in 1:nrow(promo.info.df.s)) promo.size.s=c(promo.size.s,sum(xmlSApply(
  getNodeSet(shufersal.doc,paste0("/root/Promotions/Promotion[",i,"]/PromotionItems/Item")),
  length)))
promo.size.s=data.frame(PromotionId=xmlSApply(getNodeSet(shufersal.doc,"/root/Promotions/Promotion/PromotionId"),xmlValue),size=promo.size.s)
shufersal.promo$PromotionId=as.character(rep(promo.size.s$PromotionId,promo.size.s$size))
shufersal.promo=left_join(shufersal.promo,promo.info.df.s,by=c("PromotionId"))
unlink(temp)
return(shufersal.promo)
},.progress = "text")%>%mutate_each(funs(iconv(.,"UTF-8")))
options(warn=0)

shufersal.full.day=list(stores=shufersal.stores,prices=shufersal.prices,promotions=shufersal.promo)
