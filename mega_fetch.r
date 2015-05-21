library(rvest);library(XML);library(plyr);library(dplyr)
url.base="http://publishprice.mega.co.il"
mega.files=html(paste(url.base,format(Sys.Date(),"%Y%m%d"),sep="/"))%>%html_nodes("a")%>%html_text()


mega.files=mdply(c("Price","Promo","Store"),.fun = function(x){
               df.out=data.frame(type=x,url=paste(url.base,format(Sys.Date(),"%Y%m%d"),
                 mega.files[grepl(".gz",mega.files)&grepl(x,mega.files)],sep="/"))})[,-1]

mega.files$url=as.character(mega.files$url)

mega.price.files=mega.files%>%filter(type=="Price")

options(warn=-1)
mega.prices=ddply(mega.price.files,.(type,url),.fun = function(x){
  temp <- tempfile()
  download.file(x$url,temp,quiet = T)
  mega.out=xmlToDataFrame(xmlParse(readLines(gzfile(temp),encoding="UTF-8")))[-1,-1]
  unlink(temp)
  return(mega.out)},.progress = "text")%>%mutate_each(funs(iconv(.,"UTF-8")))
options(warn=0)

names(mega.prices)[c(3:6)]=names(mega.stores)[c(1:4)]

mega.prices=left_join(mega.prices,mega.stores,by=names(mega.stores)[c(1:4)])


#Promo files
mega.promo.files=mega.files%>%filter(type=="Promo")%>%slice(c(1:5))
options(warn=-1)
mega.promo=ddply(mega.promo.files,.(type,url),.fun = function(x){
  temp <- tempfile()
  download.file(x$url,temp,quiet = T)
  doc=xmlInternalTreeParse(readLines(gzfile(temp),encoding="UTF-8"),options=HUGE)
  promo.items=xmlToDataFrame(nodes=getNodeSet(doc,"/Promotions/Promotion/PromotionItems"))
  promo.desc=xmlToDataFrame(nodes=getNodeSet(doc,"/Promotions/Promotion/Promotion"))
  header=getNodeSet(doc,"/Promotions/*[not(self::Promotion)]")
  headerdf=as.data.frame(as.list(setNames(xmlSApply(header,xmlValue),xmlSApply(header,xmlName))))
  mega.out=merge(headerdf,promo.items)
  unlink(temp)
  return(mega.out)},.progress = "text")%>%mutate_each(funs(iconv(.,"UTF-8")))%>%select(-Header)
options(warn=0)



promo.items=xmlToDataFrame(nodes=getNodeSet(doc,"/Promotions/Promotion/PromotionItems"))
promo.clubs=xmlToDataFrame(nodes=getNodeSet(doc,"/Promotions/Clubs/PromotionItems"))

temp=getNodeSet(doc,"/Promotions/Promotion/*[not(self::PromotionItems)]")
tempdf=data.frame(value=iconv(unlist(xmlSApply(temp,xmlValue)),"UTF-8"),name=unlist(xmlSApply(temp,xmlName)))%>%arrange(name)
tempdf$id=rep(seq(1,nrow(tempdf)/length(unique(tempdf$name))),length(unique(tempdf$name)))
tempdf=tempdf%>%spread(name, value)

mega.promo=merge(headerdf,promo.items)

