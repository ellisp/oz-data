# This script downloads files from the internet, particularly ABS.  Some big downloads here.

# convenience function that only downloads files if they don't already exist (so we can run this script without
# repeating all those expensive downloads)
download_if_fresh <- function(fn, destfile, mode = "wb"){
  if(!destfile %in% list.files(recursive = TRUE)){
    download.file(fn, destfile = destfile, mode = mode)
  }
}

#=========================Downloads=====================

#-------------------Statistical areas-------------------------
download_if_fresh("http://www.abs.gov.au/AUSSTATS/subscriber.nsf/log?openagent&1270055001_sa1_2016_aust_shape.zip&1270.0.55.001&Data%20Cubes&6F308688D810CEF3CA257FED0013C62D&0&July%202016&12.07.2016&Latest",
              destfile = "raw-data/sa1.zip", mode = "wb")

download_if_fresh("http://www.abs.gov.au/AUSSTATS/subscriber.nsf/log?openagent&1270055001_sa2_2016_aust_shape.zip&1270.0.55.001&Data%20Cubes&A09309ACB3FA50B8CA257FED0013D420&0&July%202016&12.07.2016&Latest",
              destfile = "raw-data/sa2.zip", mode = "wb")

download_if_fresh("http://www.abs.gov.au/AUSSTATS/subscriber.nsf/log?openagent&1270055001_sa3_2016_aust_shape.zip&1270.0.55.001&Data%20Cubes&43942523105745CBCA257FED0013DB07&0&July%202016&12.07.2016&Latest",
              destfile = "raw-data/sa3.zip", mode = "wb")

download_if_fresh("http://www.abs.gov.au/AUSSTATS/subscriber.nsf/log?openagent&1270055001_sa4_2016_aust_shape.zip&1270.0.55.001&Data%20Cubes&C65BC89E549D1CA3CA257FED0013E074&0&July%202016&12.07.2016&Latest",
              destfile = "raw-data/sa4.zip", mode = "wb")


#----------------------------remoteness-------------------
# From http://www.abs.gov.au/AUSSTATS/abs@.nsf/DetailsPage/1270.0.55.005July%202016?OpenDocument


download_if_fresh("http://www.abs.gov.au/ausstats/subscriber.nsf/log?openagent&1270055005_cg_postcode_2017_ra_2016.zip&1270.0.55.005&Data%20Cubes&14E68CB22C937EBCCA258251000C8C1B&0&July%202016&16.03.2018&Latest",
              destfile = "raw-data/postcode-remoteness.zip", mode = "wb")

download_if_fresh("http://www.abs.gov.au/ausstats/subscriber.nsf/log?openagent&1270055005_ra_2016_aust_shape.zip&1270.0.55.005&Data%20Cubes&ACAA23F3B41FA7DFCA258251000C8004&0&July%202016&16.03.2018&Latest",
              destfile = "raw-data/remoteness-shape.zip", mode = "wb")

#------------------------Non-ABS categories--------------------
# http://www.abs.gov.au/AUSSTATS/abs@.nsf/DetailsPage/1270.0.55.003July%202016?OpenDocument
# This includes electoral boundaries, local government boundaries, etc.

download_if_fresh("http://www.abs.gov.au/ausstats/subscriber.nsf/log?openagent&1270055003_poa_2016_aust_shape.zip&1270.0.55.003&Data%20Cubes&4FB811FA48EECA7ACA25802C001432D0&0&July%202016&13.09.2016&Previous",
              destfile = "raw-data/postcodes.zip", mode = "wb")
              

download_if_fresh("http://www.abs.gov.au/AUSSTATS/subscriber.nsf/log?openagent&1270055003_lga_2016_aust_shape.zip&1270.0.55.003&Data%20Cubes&7951843398FB3F4ECA25833D000EAE34&0&July%202016&07.11.2018&Previous",
                 destfile = "raw-data/oz-lga.zip", mode = "wb")

#=======================unzipping==========================
zips <- list.files("raw-data", pattern = "\\.zip$", full.names = TRUE)
for(z in zips){
  unzip(z, exdir = "raw-data")
}
