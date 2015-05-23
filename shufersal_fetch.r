#zipfile is corrupt when downloading through R and not manually
#shufersal.url='http://pricesprodpublic.blob.core.windows.net/price/Price7290027600007-001-201505220240.gz?sv=2014-02-14&sr=b&sig=98CWk2qVi%2BmzLgve5b81n1NUEFX8k0NfsbYwiXTZA4E%3D&se=2015-05-22T16%3A12%3A11Z&sp=r'
#temp <- tempfile()
#download.file(shufersal.url,temp,quiet = T)
#shufersal.docdoc=xmlInternalTreeParse(readLines(gzfile(temp),encoding="UTF-8"),options=HUGE)

#use example xml files in the git repo.

#Stores
shufersal.doc=xmlParse("shufersal/Stores7290027600007-000-201505220201.xml")
header=getNodeSet(shufersal.doc,"/asx:abap/asx:values/*[not(self::STORES)]")
headerdf=as.data.frame(as.list(setNames(xmlSApply(header,xmlValue),xmlSApply(header,xmlName))))
shufersal.stores=xmlToDataFrame(getNodeSet(shufersal.doc,"/asx:abap/asx:values/STORES/STORE"))
shufersal.stores=merge(headerdf,shufersal.stores)
rm(list=ls(pattern = "header"))

#Prices
shufersal.doc=xmlParse("shufersal/PriceFull7290027600007-001-201505220341.xml")
header=getNodeSet(shufersal.doc,"/root/*[not(self::Items)]")
headerdf=as.data.frame(as.list(setNames(xmlSApply(header,xmlValue),xmlSApply(header,xmlName))))
shufersal.prices=xmlToDataFrame(getNodeSet(shufersal.doc,"/root/Items/Item"))
shufersal.prices=merge(headerdf,shufersal.prices)
rm(list=ls(pattern = "header"))

#Promotions
shufersal.doc=xmlParse("shufersal/PromoFull7290027600007-001-201505220341.xml")
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

rm(list=ls(pattern = "promo"))

shufersal.full.day=list(stores=shufersal.stores,prices=shufersal.prices,promotions=shufersal.promo)
