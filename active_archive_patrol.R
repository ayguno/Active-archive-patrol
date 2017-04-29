###############################################################################
# Designed to monitor Proteomics Active Archive
###############################################################################

# Cat: date an time of the scan attempt for log

# Check if the active.archive.rds file exists

        # If does not exist, parse the active.archive.rds file

                # Scan the active archive directory
                # Search for .raw files, determine the list of raw files
                    
                    # FUNCTION(x){ 
                    # Loop over these files
                        # Make sure they are real raw. files, not pseudo images
                                # Cat: if files will be ignored make a log of them
                        # If they are real raw files; Extract file name and time stamp
                                # Cat : if the files will be scanned make a log of them
                    # Exit the loop        
                    # Concatenate the file.name and time stamp information
                    # Extract Instrument,User,Weekday,LC label,Make a call for status: Operational or Downtime
                    # Hold and returns this as temp.active.archive  }

                    # Save temp.active.archive as active.archive.rds into working directory
                    # Push active.archive.rds into dropbox API




# Create a scan time object
# Push scan time object into dropbox API
