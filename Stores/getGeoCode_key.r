getGeoCode.key=function (gcStr,key,verbose = 0) 
{
  gcStr <- enc2utf8(gsub(" ", "%20", gcStr))
  connectStr <- paste("https://maps.google.com/maps/api/geocode/json?key=",key,"&sensor=false&address=", 
                      gcStr, sep = "")
  if (verbose) 
    cat("fetching ", connectStr, "\n")
  con <- url(connectStr)
  data.json <- RJSONIO::fromJSON(paste(readLines(con), collapse = ""))
  close(con)
  data.json <- unlist(data.json)
  lat <- data.json["results.geometry.location.lat"]
  lng <- data.json["results.geometry.location.lng"]
  gcodes <- as.numeric(c(lat, lng))
  names(gcodes) <- c("lat", "lon")
  return(gcodes)
}