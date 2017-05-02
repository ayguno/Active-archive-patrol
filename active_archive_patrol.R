###############################################################################
# Designed to monitor Proteomics Active Archive
# 1. Generate the archive file
# 2. Orchestrate the script with the archive file
# 3. Push archive adn scan time log into dropbox API
# 4. Plan for the logs and cats
# 5. Perform a test schedule run
# 6. Inspect 
###############################################################################
require(dplyr)
require(tidyr)
require(lubridate)
require(rdrop2)
require(stringr)

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
temp.file.info$path.name <- row.names(temp.file.info)
temp.file.info$file.name <- basename(row.names(temp.file.info))
# and time stamp information: use ctime as the reference for acquistion time
temp.file.info$weekday <- weekdays(temp.file.info$ctime)

###########################
# Extract Instrumentlabels
###########################

# First extract names that are distinguished by file name initials
initial<-substr(temp.file.info$file.name,1,1)
instrument_names <- c("Beaker","Curie","Franklin","Galileo",
                      "McClintock","Tesla","Yoda")
names(instrument_names) <- substr(instrument_names,1,1)

temp.file.info$instrument <- unlist(sapply(initial,function(x){
        match.vector<- names(instrument_names) %in% x
        temp<- ifelse(sum(match.vector) == 1, instrument_names[match.vector],"UNKNOWN")
}))

# Next assign the Hubble2 names to the respective files
H2<-which(grepl("^H2L|^H2M|^H2Z|^H2_|^H2S|^H2E",temp.file.info$file.name))
temp.file.info$instrument[H2] <- "Hubble2"

# Finally, for the remaining UNKNOWN instrument names extract the implied instrument
# name from the path name. This time also include the Hubble
name.scanner <- c(instrument_names,tolower(instrument_names),"Hubble","hubble")
temp.file.info$instrument[temp.file.info$instrument == "UNKNOWN"] <- unlist(sapply(temp.file.info$path.name[temp.file.info$instrument == "UNKNOWN"],
                                                                                   function(x){
                                                                                       name.scan.match <- unlist(sapply(name.scanner,function(y){
                                                                                               grepl(y,x)
                                                                                       }))
                                                                                       temp.name <- ifelse(sum(name.scan.match) > 0, name.scanner[name.scan.match][1],"UNKNOWN")
                                                                                       return(temp.name)


                                                                                                                                                                       }))
##############################################################################################
# If !is.NULL(archive.file) 
if(!is.null(archive.file)){
# rBind the archive with temp.file.info (don't forget to first drop the time.difference_days and status columns from the archive)
        
}
###############################################################################################

# returns this as temp.file.info
return(temp.file.info)
                    
                     
}

# Call parse.rawfile.information to compile the latest data
temp.file.info <- parse.rawfile.information(raw.file.list, archive.file)

####################################################
# Make a call for status: Operational or Downtime
####################################################
# Start with sorting the data
temp.file.info <- temp.file.info %>% arrange(instrument,desc(ctime))
all.instruments <- unique(temp.file.info$instrument)

temp.file.status.info <- NULL
for(i in seq_along(all.instruments)){
        temp.instrument.status <- temp.file.info[temp.file.info$instrument == all.instruments[i],]
        status = NULL
        time.difference = NULL
        for(j in seq_along(temp.instrument.status$ctime)){
                ##################################################
                # Collect the difference between runs in hours 
                ##################################################
                time.difference_days[j] <- julian(temp.instrument.status$ctime[j]) - julian(temp.instrument.status$ctime[j+1])        
                # Call any time difference more than 5h (0.2083333 day) as "DOWNTIME"
                status[j] <- ifelse(time.difference[j] > 0.2083333, "DOWNTIME","OPERATIONAL")
        }
        #Call the first acquistion for each instrument as: "OPERATIONAL"
        time.difference[length(time.difference)] <- 0
        status[length(status)] <- "OPERATIONAL"
        temp.instrument.status$time.difference <- time.difference
        temp.instrument.status$status <- status
        
        # rbind the data from different instruments
        temp.file.status.info <- rbind(temp.file.status.info,temp.instrument.status)
}
                    


# Save temp.file.status.info as active.archive.rds into working directory

cat("Saving the active.archive.rds ")
saveRDS(temp.file.status.info, file = "active.archive.rds") # Save to working directory   
write.csv(file = "active.archive.csv",temp.file.status.info, row.names =F) # Save .csv version to working directory

# Push active.archive.rds into dropbox API




# Create a scan time object
# Push scan time object into dropbox API
