library(rvest);library(XML);library(stringr);library(plyr);library(dplyr);

#Organize URLs
  url.base="http://publishprice.mega.co.il"
  mega.files=html(paste(url.base,format(Sys.Date(),"%Y%m%d"),sep="/"))%>%html_nodes("a")%>%html_text()
  
  mega.files=mdply(c("Price","PriceFull","Promo","PromoFull","Store"),.fun = function(x){
                 df.out=data.frame(type=x,url=paste(url.base,format(Sys.Date(),"%Y%m%d"),
                   mega.files[grepl(".gz",mega.files)&grepl(x,mega.files)],sep="/"))})%>%
    select(-X1)%>%mutate(url=as.character(url))

#Store List
  mega.store.files=mega.files%>%filter(type=="Store")
  options(warn=-1)
  mega.stores=ddply(mega.store.files,.(type,url),.fun = function(x){
    temp <- tempfile()
    download.file(x$url,temp,quiet = T)
    mega.out=xmlToDataFrame(xmlParse(readLines(gzfile(temp),encoding="UTF-8")))[-1,-1]
    unlink(temp)
    return(mega.out)})%>%mutate_each(funs(iconv(.,"UTF-8")))%>%
    mutate(StoreURLId=str_pad(paste0(mega.stores$StoreId,mega.stores$BikoretNo),4,side = "left","0"))
  options(warn=0)


#Prices
  mega.price.files=mega.files%>%filter(type=="Price"&Full==1)
  options(warn=-1)
  mega.prices=ddply(mega.price.files,.(type,url),.fun = function(x){
    temp <- tempfile()
    download.file(x$url,temp,quiet = T)
    mega.out=xmlToDataFrame(xmlParse(readLines(gzfile(temp),encoding="UTF-8")))[-1,-1]
    unlink(temp)
    return(mega.out)},.progress = "text")%>%mutate_each(funs(iconv(.,"UTF-8")))
  options(warn=0)
  
  names(mega.prices)[c(3:6)]=names(mega.stores)[c(2:6)]
  mega.prices=left_join(mega.prices,mega.stores%>%select(-c(type,url)),by=names(mega.stores)[c(1:4)])


#Promotions
  mega.promo.files=mega.files%>%filter(type=="Promo"&Full==1)
  options(warn=-1)
  mega.promo=ddply(mega.promo.files,.(type,url),.fun = function(x){
    temp <- tempfile()
    download.file(x$url,temp,quiet = T)
    doc=xmlInternalTreeParse(readLines(gzfile(temp),encoding="UTF-8"),options=HUGE)
    promo.items=xmlToDataFrame(nodes=getNodeSet(doc,"/Promotions/Promotion/PromotionItems"))
    header=getNodeSet(doc,"/Promotions/*[not(self::Promotion)]")
    headerdf=as.data.frame(as.list(setNames(xmlSApply(header,xmlValue),xmlSApply(header,xmlName))))%>%select(-Header)
    mega.promo.main=merge(headerdf,promo.items)
    
    promo.info=getNodeSet(doc,"/Promotions/Promotion/*[not(self::PromotionItems)]")
    promo.info.df=data.frame(value=iconv(unlist(xmlSApply(promo.info,xmlValue)),"UTF-8"),
                             name=unlist(xmlSApply(promo.info,xmlName)))%>%arrange(name)
    promo.info.df$id=rep(seq(1,nrow(promo.info.df)/length(unique(promo.info.df$name))),length(unique(promo.info.df$name)))
    promo.info.df=promo.info.df%>%spread(name, value)%>%select(-id)

    promo.size=NULL
    for(i in 1:nrow(promo.info.df)) promo.size=c(promo.size,sum(xmlSApply(
      getNodeSet(doc,paste0("/Promotions/Promotion[",i,"]/PromotionItems")),
      length)))
    promo.size=data.frame(PromotionId=xmlSApply(getNodeSet(doc,"/Promotions/Promotion/PromotionId"),xmlValue),size=promo.size)
    mega.promo.main$PromotionId=as.character(rep(promo.size$PromotionId,promo.size$size))
    mega.promo.main=left_join(mega.promo.main,promo.info.df,by=c("PromotionId"))
    
    unlink(temp)
    return(mega.promo.main)},.progress = "text")
  options(warn=0)
  
  mega.full.day=list(stores=mega.stores,prices=mega.prices,promotions=mega.promo)
  
  save(mega.full.day,file="mega_20150521.rdata")
  