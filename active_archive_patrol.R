###############################################################################
# Author: Ozan Aygun
# Date: 05/02/2017 
#
# Designed to monitor Proteomics Active Archive.
# Extracts the time, size and instrument information from the archived data.
# Makes a call for the status of the instrument (operational or downtime).
# Creates log files for the scan.
# Pushes the scanned data into the dropbox API for remote access.
# Schedule to run this script 24 times a day.
# 
# Update: Resolved a name bias between two instruments.
# 05/04/2017: this version captures the data more accurately and will be 
# replaced with the version that is scheduled for 1h runs.
#
###############################################################################

require(dplyr)
require(tidyr)
require(lubridate)
require(rdrop2)
require(stringr)



setwd("C:/Users/ozan/Desktop/Ozan_R_utilities/Development/JurkatQCscraper/active_archive_patrol/Active-archive-patrol")
old_dir <- getwd()
d<-paste("../Logs/Log_files_",Sys.Date(),"/",sep = "") 
if(!exists(d)){dir.create(d)}

# Cat: date an time of the scan attempt for log
cat("Scan started at: ",as.character(Sys.time()),"\n", file = paste(d,"scan_logs.txt"), append = TRUE )
print(paste("Scan started at: ",Sys.time(),"\n"))

# Check if the active.archive.rds file exists
if(file.exists("../active.archive.rds")){
        # If exists, archive.file = readRDS(active.archive.rds)
        archive.file <- readRDS("../active.archive.rds")
        print("--Active archive database is found. Only new files will be scanned.\n")
        cat("--Active archive database is found. Only new files will be scanned.\n",file = paste(d,"scan_logs.txt"), append = TRUE)
}else{
        # If does not exist, archive.file = NULL
        archive.file <- NULL
        print("--Active archive database is not found. All files will be scanned.\n")
        cat("--Active archive database is not found. All files will be scanned.\n",file = paste(d,"scan_logs.txt"), append = TRUE)
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

# If !is.NULL(archive.file) 
if(!is.null(archive.file)){
        # Compare the raw.file.list with the directories in the archive.file
        scan.match <- raw.file.list %in% archive.file$path.name
        if(sum(!scan.match) >0){ # If there is at least one new file to be scanned
                # Determine which are the new ones to be scanned (temp.scan.list = "these new files")
                temp.scan.list <- raw.file.list[!scan.match]
                # Cat: Make a log of newly scanned files in the current scan
                write.csv(file = paste(d,"New_files_found.csv"),temp.scan.list,row.names = FALSE,append = TRUE)  
        }
        
}else{  scan.match <- rep(FALSE,length(raw.file.list))
        temp.scan.list <- raw.file.list
        write.csv(file = paste(d,"New_files_found.csv"),temp.scan.list,row.names = FALSE, append = TRUE)
}

parse.rawfile.information <- function(raw.file.list, archive.file, temp.scan.list){
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
        
        # If the 4th letter in filename is not a number, label instrument name as: "UNKNOWN" and deal with it below
        fourth.letter <-substr(temp.file.info$file.name,4,4)
        fourth.letter.check <- unlist(sapply(fourth.letter,function(x){
                grepl("[0-9]",x)      
        }))
        temp.file.info$instrument[!fourth.letter.check] <- "UNKNOWN"
        
        
        # Next assign the Hubble2 names to the respective files
        # This approach seems to be biased!! Instead dealing with Hubble vs Hubble2 below.
                # H2<-which(grepl("^H2_|^H2[A-Z]",temp.file.info$file.name))
                # temp.file.info$instrument[H2] <- "Hubble2"
        
        Hubble2.name.scanner <- c("Hubble2","hubble2")
        temp.file.info$instrument[temp.file.info$instrument == "UNKNOWN"] <- unlist(sapply(temp.file.info$path.name[temp.file.info$instrument == "UNKNOWN"],
                                                                                   function(x){
                                                                                           name.scan.match <- unlist(sapply(Hubble2.name.scanner,function(y){
                                                                                                   grepl(y,x)
                                                                                           }))
                                                                                           temp.name <- ifelse(sum(name.scan.match) > 0, Hubble2.name.scanner[name.scan.match][1],"UNKNOWN")
                                                                                           return(temp.name) }))




       
        
        
        # Finally, for the remaining UNKNOWN instrument names extract the implied instrument
        # name from the path name. This time also include the Hubble and Hubble2
        name.scanner <- c(instrument_names,tolower(instrument_names),"Hubble","hubble")
        temp.file.info$instrument[temp.file.info$instrument == "UNKNOWN"] <- unlist(sapply(temp.file.info$path.name[temp.file.info$instrument == "UNKNOWN"],
                                                                                           function(x){
                                                                                               name.scan.match <- unlist(sapply(name.scanner,function(y){
                                                                                                       grepl(y,x)
                                                                                               }))
                                                                                               temp.name <- ifelse(sum(name.scan.match) > 0, name.scanner[name.scan.match][1],"UNKNOWN")
                                                                                               return(temp.name) }))
        
        ##############################################################################################
        # If !is.NULL(archive.file) 
        if(!is.null(archive.file)){
        # rBind the archive with temp.file.info (don't forget to first drop the time.difference_days and status columns from the archive)
        trimmed.archive.file <- dplyr::select(archive.file,-time.difference_days,-status)
        temp.file.info <- rbind(temp.file.info,trimmed.archive.file)
        }
        ###############################################################################################
        
        # returns this as temp.file.info
        return(temp.file.info)
                    
                     
}


if(sum(!scan.match) >0){# If there is at least one new file to be scanned
        cat("--Scanning for the newly generated raw files\n",file = paste(d,"scan_logs.txt"), append = TRUE)
        print("--Scanning for the newly generated raw files\n")
        # Call parse.rawfile.information to compile the latest data
        temp.file.info <- parse.rawfile.information(raw.file.list, archive.file,temp.scan.list)

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
                time.difference_days = NULL
                for(j in seq_along(temp.instrument.status$ctime)){
                        ##################################################
                        # Collect the difference between runs in hours 
                        ##################################################
                        time.difference_days[j] <- julian(temp.instrument.status$ctime[j]) - julian(temp.instrument.status$ctime[j+1])        
                        if(is.na(time.difference_days[j])){
                                time.difference_days[j] <- julian(temp.instrument.status$mtime[j]) - julian(temp.instrument.status$mtime[j+1])       
                        }
                        # Call any time difference more than 5h (0.2083333 day) as "DOWNTIME"
                        status[j] <- ifelse(time.difference_days[j] > 0.2083333, "DOWNTIME","OPERATIONAL")
                }
                #Call the first acqusition for each instrument as: "OPERATIONAL"
                time.difference_days[length(time.difference_days)] <- 0
                status[length(status)] <- "OPERATIONAL"
                
                #Dealing with the last acqusition to reflect latest status by the scan time
                time.difference_days[1] <- julian(Sys.time())-julian(temp.instrument.status$ctime[1])
                status[1] <- ifelse(time.difference_days[1] > 0.2083333, "DOWNTIME","OPERATIONAL")
                
                
                temp.instrument.status$time.difference_days <- time.difference_days
                temp.instrument.status$status <- status
                
                # rbind the data from different instruments
                temp.file.status.info <- rbind(temp.file.status.info,temp.instrument.status)
                print(paste("--All status assigned for instrument: ", all.instruments[i],"\n"))
                cat("--All status assigned for instrument: ", all.instruments[i],"\n",file = paste(d,"scan_logs.txt"), append = TRUE)
        }
        
        
        
        
        
                            
        #################################
        # Save the updated database
        #################################
        
        # Save temp.file.status.info as active.archive.rds into working directory
        print("Saving the active.archive.rds\n ")
        cat("Saving the active.archive.rds\n ",file = paste(d,"scan_logs.txt"), append = TRUE)
        saveRDS(temp.file.status.info, file = "../active.archive.rds") # Save to working directory   
        write.csv(file = "../active.archive.csv",temp.file.status.info, row.names =FALSE) # Save .csv version to working directory
        write.csv(file = paste(d,"active.archive.csv",sep = ""),temp.file.status.info,row.names = FALSE) #Save to latest log_file
        # Push active.archive.rds into dropbox API
        token<- readRDS("../droptoken.rds")
        drop_upload("../active.archive.rds",dtoken = token) #Upload the file to dropbox by using the available token 

}else{
        if(sum(!scan.match) == 0){
                cat("--No new raw files found in this scan skipping without further action.\n",file = paste(d,"scan_logs.txt"), append = TRUE)
                temp.scan.message <- "No new raw files found in this scan skipping without further action."
                write.csv(file = paste(d,"No_New_files_found.csv"),temp.scan.message,row.names = FALSE)
        }
}

# Create a scan time object
latest_active_archive_patrol <- data.frame(date=as.character(Sys.time()))
saveRDS(latest_active_archive_patrol,"../latest_active_archive_patrol.rds") # Save to retrieve latest scan information
# Push scan time object into dropbox API
token<- readRDS("../droptoken.rds")
drop_upload("../latest_active_archive_patrol.rds", dtoken = token) # Also save to dropbox

cat("Scan finished at: ",as.character(Sys.time()),"\n", file = paste(d,"scan_logs.txt"), append = TRUE )
print(paste("Scan finished at: ",as.character(Sys.time()),"\n"))