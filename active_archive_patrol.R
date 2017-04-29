###############################################################################
# Designed to monitor Proteomics Active Archive
###############################################################################

# Check if the active.archive.rds file exists

        # If does not exist, parse the active.archive.rds file

                # Scan the active archive directory
                # Search for .raw files, determine the list of raw files
                    
                    # FUNCTION(x){ 
                    # Loop over these files
                        # Make sure they are real raw. files, not pseudo images
                        # If they are real raw files; Extract file name and time stamp
                    # Exit the loop        
                    # Concatenate the file.name and time stamp information
                    # Extract Instrument,User,Weekday,LC label,Make a call for status: Operational or Downtime
                    # Hold and returns this as temp.active.archive  }

        # Save temp.active.archive as active.archive.rds 