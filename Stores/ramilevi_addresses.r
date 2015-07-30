library(RSelenium)
RSelenium::startServer()
remDr <- remoteDriver()
remDr$open(silent = F)

remDr$navigate("http://www.rami-levy.co.il/default.asp?catid={90F60861-0E57-4709-AC3F-224740ED8198}")

webElem=remDr$findElement(using = "xpath",value ="/html/body/table/tbody/tr[1]/td/table/tbody/tr[3]/td[2]/table")
webElems<-webElem$findChildElements("css selector","a")
links=unlist(sapply(webElems,function(x){x$getElementAttribute('href')}))

base="/html/body/table/tbody/tr[1]/td/table/tbody/tr[3]/td[1]/table/tbody/tr/td[1]/table[2]/tbody"
base10="/html/body/table/tbody/tr[1]/td/table/tbody/tr[3]/td/table[4]/tbody/tr/td/table/tbody"
base11="/html/body/table/tbody/tr[1]/td/table/tbody/tr[3]/td[1]/table/tbody/tr/td[1]/table/tbody"

link.df=data.frame(links=links,base=base)
link.df$base=as.character(link.df$base)
link.df$base[11]=base11
link.df$base[10]=base10

out=ddply(link.df%>%slice(-10),.(links),.fun = function(l){
  remDr$navigate(l$links)
  webElem=remDr$findElement(using = "xpath",value =l$base)
  webElems=webElem$findChildElements(using = "css selector","td")
  rl.stores=unlist(sapply(webElems,function(x){x$getElementText()}))
  out=data.frame(x=rl.stores[str_detect(rl.stores,"\n")])
  return(out)
}
)

data.frame(storename=sapply(str_split(rl.stores[str_detect(rl.stores,"\n")],'\n'),'[',1),
address=sapply(str_split(rl.stores[str_detect(rl.stores,"\n")],'\n'),'[',2))%>%View


x1=ldply(x,
         .fun = function(x0){
                    x0=x0[!str_trim(x0)%in%c("פרטים נוספים","סניף כתובת","הסניף סגור במוצאי שבת וחג.")]
                    x0=str_trim(x0)
                    x0[1]=gsub("סניף",'',x0[1])
                    if(length(x0)<3){
                     data.frame(city=x0[1],address=x0[2],stringsAsFactors = F)
                    }else{
                      data.frame(city=x0[1],address=paste(x0[c(2,3)],collapse=" "),stringsAsFactors = F)
                    }
              }
         )%>%filter(!is.na(address))

