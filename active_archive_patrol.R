###############################################################################
# Designed to monitor Proteomics Active Archive
###############################################################################
require(dplyr)
require(tidyr)
require(lubridate)
require(rdrop2)

# Cat: date an time of the scan attempt for log
print(Sys.time())
setwd("C:/Users/ozan/Desktop/Ozan_R_utilities/Development/JurkatQCscraper/active_archive_patrol/Active-archive-patrol")
old_dir <- getwd()
d<-paste(old_dir,"/Logs/Log_files_",Sys.Date(),sep = "") 
if(!exists(d)){dir.create(d)}

# Check if the active.archive.rds file exists
if(file.exists("active.archive.rds")){
        # If exists, archive.file = readRDS(active.archive.rds)
        archive.file <- readRDS(active.archive.rds)
}else{
        # If does not exist, archive.file = NULL
        archive.file <- NULL
}


directories <- c("//flynn-cifs/proteomics_active_archive/Beaker_archive",
                 "//flynn-cifs/proteomics_active_archive/Beaker2Comp_Archive",
                 "//flynn-cifs/proteomics_active_archive/Curie_archive",
                 "//flynn-cifs/proteomics_active_archive/Franklin_archive",
                 "//flynn-cifs/proteomics_active_archive/galileo2_archive",
                 "//flynn-cifs/proteomics_active_archive/galileo_archive",
                 "//flynn-cifs/proteomics_active_archive/Hubble_archive",
                 "//flynn-cifs/proteomics_active_archive/Hubble2_archive",
                 "//flynn-cifs/proteomics_active_archive/McClintock_archive",
                 "//flynn-cifs/proteomics_active_archive/Tesla_archive",
                 "//flynn-cifs/proteomics_active_archive/Yoda_archive")
#####################################
# Scan the active archive directory
#####################################
# Search for .raw files, determine the list of raw files
# raw.file.list = list of new raw files

raw.file.list <- unlist(sapply(directories,function(x){dir(path = x,pattern = ".raw$" ,
                     recursive = T, full.names = T)}))

parse.rawfile.information <- function(raw.file.list, archive.file){
# If !is.NULL(archive.file) 
if(!is.null(archive.file)){
        # Compare the raw.file.list with the directories in the archive.file
        # Determine which are the new ones to be scanned (temp.scan.list = "these new files")
        # Cat: Make a log of newly scanned files in the current scan
        
}else{
        temp.scan.list <- raw.file.list      
}        

# Forms a neat data frame that already contains most of the information                        
temp.file.info <- file.info(temp.scan.list)

# Extract and attach the actual file.name from the path
temp.file.info$file.name <- 
                    # and time stamp information
                    # Extract Instrument,User,Weekday,LC label,Make a call for status: Operational or Downtime
                    # Hold and returns this as temp.active.archive  
                    }

                    # Save temp.active.archive as active.archive.rds into working directory
                    # Push active.archive.rds into dropbox API




# Create a scan time object
# Push scan time object into dropbox API
