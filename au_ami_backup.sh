#!/bin/bash
# Author - James Corteciano

# Don't change these settings
export AWS_ACCESS_KEY=YOUR-ACESS-KEY-HERE
export AWS_SECRET_KEY=YOUR-SECRET-KEY-HERE
export EC2_HOME=/opt/aws/ec2
export EC2_URL=https://ec2.ap-southeast-2.amazonaws.com
export EC2_REGION=ap-southeast-2
export JAVA_HOME=/usr/lib/jvm/jre

###
## W - Daily backup
###
w_daily_backup() {
		## Settings
		TAGKEY="Backup-Retention"
		TAGVALUE="W"
		AMILABELNAME="(${TAGVALUE})"
		AMIPATTERN="DAILY" #AMI pattern name for backup
		BACKUPDATE=$(date +%FT%H.%M.%S) 
		DATE=$(date +%F)
		MAILFROM="AU AMI Backup <auamibackup@domain.com>"
		MAILTO=monitor-backup@domain.com

		# Log file 
		LOGPATH="/var/log/aws/backup/ami/au/${AMIPATTERN}/${TAGVALUE}"
		SERVERS="${LOGPATH}/SERVERS.log"
		IIDSLOG="${LOGPATH}/IIDS.log"
		IIDSSTARTLIST="${LOGPATH}/IIDSSTARTLIST.log"
		SUMMARY="${LOGPATH}/summary.log"

		## The fun begins....

		# Create if log directories are not existed
		if [ ! -d "${LOGPATH}/archivelogs" ];
		 then
			mkdir -p ${LOGPATH}/archivelogs
		fi
		if [ ! -d "${LOGPATH}/archivelogs/existlogs" ];
		 then
		        mkdir -p ${LOGPATH}/archivelogs/existlogs
		fi

		# Create if logs are existed
		if [ -f ${SERVERS} ];
		 then
			mv ${SERVERS} ${LOGPATH}/archivelogs/existlogs/SERVERS_${DATE}.log
		fi
		if [ -f ${IIDSLOG} ]; 
		 then
		        mv ${IIDSLOG} ${LOGPATH}/archivelogs/existlogs/IIDS_${DATE}.log
		fi
		if [ -f ${IIDSSTARTLIST} ];
		 then
		        mv ${IIDSSTARTLIST} ${LOGPATH}/archivelogs/existlogs/IIDSSTARTLIST_${DATE}.log
		fi
		if [ -f ${SUMMARY} ]; 
		 then  
		        mv ${SUMMARY} ${LOGPATH}/archivelogs/existlogs/summary_${DATE}.log
		fi

		# Collect Servers with specified AMI label name pattern
		/opt/aws/bin/ec2-describe-tags -H | grep "${TAGKEY}" | grep "${TAGVALUE}" | awk '{print $3}' > ${IIDSSTARTLIST}

		# collect instance id and servername
		for SERBER in $(cat ${IIDSSTARTLIST});
		do
			/opt/aws/bin/ec2-describe-instances ${SERBER} | grep Name | awk '{print $3,$5}' >> ${SERVERS}
		done

		# Backup AMI'S
		for IID in $(cat ${IIDSSTARTLIST});
		do
		        SERVERNAME=$(grep ${IID} ${SERVERS} | awk '{print $2}')

		    # Create if directory is not existed
		    if [ ! -d ${LOGPATH}/"${SERVERNAME}" ];
		      then
		            mkdir -p ${LOGPATH}/"${SERVERNAME}"/existlogs
		    fi
			if [ ! -d ${LOGPATH}/"${SERVERNAME}"/existlogs ];
			 then
				 mkdir ${LOGPATH}/"${SERVERNAME}"/existlogs
			fi

		        SERVERLOG="${LOGPATH}/${SERVERNAME}/serverlog.log"

			# Create if server.log file is still exist
			if [ -f ${SERVERLOG} ];
			 then
				mv ${SERVERLOG} ${LOGPATH}/"${SERVERNAME}"/existlogs/serverlog_${DATE}.log
			fi

			# Backup begins here
			echo "Instance Name: ${SERVERNAME}" >> ${SERVERLOG}
			echo "Instance ID: ${IID}" >> ${SERVERLOG}
			echo "Backup Started: $(date)" >> ${SERVERLOG}
			/opt/aws/bin/ec2-create-image ${IID} --name "${SERVERNAME}${AMILABELNAME}-${AMIPATTERN}-${BACKUPDATE}" --no-reboot >> ${SERVERLOG}
			echo "Backup Ended: $(date)" >> ${SERVERLOG}
			echo "----------------------------------" >> ${SERVERLOG}
			echo "" >> ${SERVERLOG}
			
			# print logs to summary file
			cat ${SERVERLOG} >> ${SUMMARY}

			# wait 2 seconds
		    	sleep 2s
		done

		# Email report
		mail -s "AU - AMI ${AMIPATTERN} Backup Alert Report for ${AMILABELNAME} - ${DATE}" -r "${MAILFROM}" ${MAILTO} < ${SUMMARY}
}



###
## W - Weekly backup
###
w_weekly_backup() {
		TAGKEY="Backup-Retention"
		TAGVALUE="W"
		AMILABELNAME="(${TAGVALUE})"
		AMIPATTERN="WEEKLY" #AMI pattern name for backup
		BACKUPDATE=$(date +%FT%H.%M.%S) 
		DATE=$(date +%F)
		MAILFROM="AU AMI Backup <auamibackup@domain.com>"
		MAILTO=monitor-backup@domain.com

		# Log file 
		LOGPATH="/var/log/aws/backup/ami/au/${AMIPATTERN}/${TAGVALUE}"
		SERVERS="${LOGPATH}/SERVERS.log"
		IIDSLOG="${LOGPATH}/IIDS.log"
		IIDSSTARTLIST="${LOGPATH}/IIDSSTARTLIST.log"
		SUMMARY="${LOGPATH}/summary.log"

		## The fun begins....

		# Create if log directories are not existed
		if [ ! -d "${LOGPATH}/archivelogs" ];
		 then
			mkdir -p ${LOGPATH}/archivelogs
		fi
		if [ ! -d "${LOGPATH}/archivelogs/existlogs" ];
		 then
		        mkdir -p ${LOGPATH}/archivelogs/existlogs
		fi

		# Create if logs are existed
		if [ -f ${SERVERS} ];
		 then
			mv ${SERVERS} ${LOGPATH}/archivelogs/existlogs/SERVERS_${DATE}.log
		fi
		if [ -f ${IIDSLOG} ]; 
		 then
		        mv ${IIDSLOG} ${LOGPATH}/archivelogs/existlogs/IIDS_${DATE}.log
		fi
		if [ -f ${IIDSSTARTLIST} ];
		 then
		        mv ${IIDSSTARTLIST} ${LOGPATH}/archivelogs/existlogs/IIDSSTARTLIST_${DATE}.log
		fi
		if [ -f ${SUMMARY} ]; 
		 then  
		        mv ${SUMMARY} ${LOGPATH}/archivelogs/existlogs/summary_${DATE}.log
		fi

		# Collect Servers with specified AMI label name pattern
		/opt/aws/bin/ec2-describe-tags -H | grep "${TAGKEY}" | grep "${TAGVALUE}" | awk '{print $3}' > ${IIDSSTARTLIST}

		# collect instance id and servername
		for SERBER in $(cat ${IIDSSTARTLIST});
		do
			/opt/aws/bin/ec2-describe-instances ${SERBER} | grep Name | awk '{print $3,$5}' >> ${SERVERS}
		done


		# Backup AMI'S
		for IID in $(cat ${IIDSSTARTLIST});
		do
		        SERVERNAME=$(grep ${IID} ${SERVERS} | awk '{print $2}')

		    # Create if directory is not existed
		    if [ ! -d ${LOGPATH}/"${SERVERNAME}" ];
		     then
		            mkdir -p ${LOGPATH}/"${SERVERNAME}"/existlogs
		    fi
			if [ ! -d ${LOGPATH}/"${SERVERNAME}"/existlogs ];
			 then
				 mkdir ${LOGPATH}/"${SERVERNAME}"/existlogs
			fi

		        SERVERLOG="${LOGPATH}/${SERVERNAME}/serverlog.log"

			# Create if server.log file is still exist
			if [ -f ${SERVERLOG} ];
			 then
				mv ${SERVERLOG} ${LOGPATH}/"${SERVERNAME}"/existlogs/serverlog_${DATE}.log
			fi

			# Backup begins here
			echo "Instance Name: ${SERVERNAME}" >> ${SERVERLOG}
			echo "Instance ID: ${IID}" >> ${SERVERLOG}
			echo "Backup Started: $(date)" >> ${SERVERLOG}
			/opt/aws/bin/ec2-create-image ${IID} --name "${SERVERNAME}${AMILABELNAME}-${AMIPATTERN}-${BACKUPDATE}" --no-reboot >> ${SERVERLOG}
			echo "Backup Ended: $(date)" >> ${SERVERLOG}
			echo "----------------------------------" >> ${SERVERLOG}
			echo "" >> ${SERVERLOG}
			
			# print logs to summary file
			cat ${SERVERLOG} >> ${SUMMARY}

			# wait 2 seconds
		    	sleep 2s
		done

		# Email report
		mail -s "AU - AMI ${AMIPATTERN} Backup Alert Report for ${AMILABELNAME} - ${DATE}" -r "${MAILFROM}" ${MAILTO} < ${SUMMARY}
}


###
## W - Monthly backup
###
w_monthly_backup() {
		## Settings
		TAGKEY="Backup-Retention"
		TAGVALUE="W"
		AMILABELNAME="(${TAGVALUE})"
		AMIPATTERN="MONTHLY" #AMI pattern name for backup
		BACKUPDATE=$(date +%FT%H.%M.%S) 
		DATE=$(date +%F)
		MAILFROM="AU AMI Backup <auamibackup@domain.com>"
		MAILTO=monitor-backup@domain.com

		# Log file 
		LOGPATH="/var/log/aws/backup/ami/au/${AMIPATTERN}/${TAGVALUE}"
		SERVERS="${LOGPATH}/SERVERS.log"
		IIDSLOG="${LOGPATH}/IIDS.log"
		IIDSSTARTLIST="${LOGPATH}/IIDSSTARTLIST.log"
		SUMMARY="${LOGPATH}/summary.log"

		## The fun begins....

		# Create if log directories are not existed
		if [ ! -d "${LOGPATH}/archivelogs" ];
		 then
			mkdir -p ${LOGPATH}/archivelogs
		fi
		if [ ! -d "${LOGPATH}/archivelogs/existlogs" ];
		 then
		        mkdir -p ${LOGPATH}/archivelogs/existlogs
		fi

		# Create if logs are existed
		if [ -f ${SERVERS} ];
		 then
			mv ${SERVERS} ${LOGPATH}/archivelogs/existlogs/SERVERS_${DATE}.log
		fi
		if [ -f ${IIDSLOG} ]; 
		 then
		        mv ${IIDSLOG} ${LOGPATH}/archivelogs/existlogs/IIDS_${DATE}.log
		fi
		if [ -f ${IIDSSTARTLIST} ];
		 then
		        mv ${IIDSSTARTLIST} ${LOGPATH}/archivelogs/existlogs/IIDSSTARTLIST_${DATE}.log
		fi
		if [ -f ${SUMMARY} ]; 
		 then  
		        mv ${SUMMARY} ${LOGPATH}/archivelogs/existlogs/summary_${DATE}.log
		fi

		# Collect Servers with specified AMI label name pattern
		/opt/aws/bin/ec2-describe-tags -H | grep "${TAGKEY}" | grep "${TAGVALUE}" | awk '{print $3}' > ${IIDSSTARTLIST}

		# collect instance id and servername
		for SERBER in $(cat ${IIDSSTARTLIST});
		do
			/opt/aws/bin/ec2-describe-instances ${SERBER} | grep Name | awk '{print $3,$5}' >> ${SERVERS}
		done

		# Backup AMI'S
		for IID in $(cat ${IIDSSTARTLIST});
		do
		        SERVERNAME=$(grep ${IID} ${SERVERS} | awk '{print $2}')

		    # Create if directory is not existed
		    if [ ! -d ${LOGPATH}/"${SERVERNAME}" ];
		      then
		            mkdir -p ${LOGPATH}/"${SERVERNAME}"/existlogs
		    fi
			if [ ! -d ${LOGPATH}/"${SERVERNAME}"/existlogs ];
			 then
				 mkdir ${LOGPATH}/"${SERVERNAME}"/existlogs
			fi

		        SERVERLOG="${LOGPATH}/${SERVERNAME}/serverlog.log"

			# Create if server.log file is still exist
			if [ -f ${SERVERLOG} ];
			 then
				mv ${SERVERLOG} ${LOGPATH}/"${SERVERNAME}"/existlogs/serverlog_${DATE}.log
			fi

			# Backup begins here
			echo "Instance Name: ${SERVERNAME}" >> ${SERVERLOG}
			echo "Instance ID: ${IID}" >> ${SERVERLOG}
			echo "Backup Started: $(date)" >> ${SERVERLOG}
			/opt/aws/bin/ec2-create-image ${IID} --name "${SERVERNAME}${AMILABELNAME}-${AMIPATTERN}-${BACKUPDATE}" --no-reboot >> ${SERVERLOG}
			echo "Backup Ended: $(date)" >> ${SERVERLOG}
			echo "----------------------------------" >> ${SERVERLOG}
			echo "" >> ${SERVERLOG}
			
			# print logs to summary file
			cat ${SERVERLOG} >> ${SUMMARY}

			# wait 2 seconds
		    	sleep 2s
		done

		# Email report
		mail -s "AU - AMI ${AMIPATTERN} Backup Alert Report for ${AMILABELNAME} - ${DATE}" -r "${MAILFROM}" ${MAILTO} < ${SUMMARY}
}



###
## P - Daily backup
###
p_daily_backup() {
		## Settings
		TAGKEY="Backup-Retention"
		TAGVALUE="P"
		AMILABELNAME="(${TAGVALUE})"
		AMIPATTERN="DAILY" #AMI pattern name for backup
		BACKUPDATE=$(date +%FT%H.%M.%S) 
		DATE=$(date +%F)
		MAILFROM="AU AMI Backup <auamibackup@domain.com>"
		MAILTO=monitor-backup@domain.com

		# Log file 
		LOGPATH="/var/log/aws/backup/ami/au/${AMIPATTERN}/${TAGVALUE}"
		SERVERS="${LOGPATH}/SERVERS.log"
		IIDSLOG="${LOGPATH}/IIDS.log"
		IIDSSTARTLIST="${LOGPATH}/IIDSSTARTLIST.log"
		SUMMARY="${LOGPATH}/summary.log"

		## The fun begins....

		# Create if log directories are not existed
		if [ ! -d "${LOGPATH}/archivelogs" ];
		 then
			mkdir -p ${LOGPATH}/archivelogs
		fi
		if [ ! -d "${LOGPATH}/archivelogs/existlogs" ];
		 then
		        mkdir -p ${LOGPATH}/archivelogs/existlogs
		fi

		# Create if logs are existed
		if [ -f ${SERVERS} ];
		 then
			mv ${SERVERS} ${LOGPATH}/archivelogs/existlogs/SERVERS_${DATE}.log
		fi
		if [ -f ${IIDSLOG} ]; 
		 then
		        mv ${IIDSLOG} ${LOGPATH}/archivelogs/existlogs/IIDS_${DATE}.log
		fi
		if [ -f ${IIDSSTARTLIST} ];
		 then
		        mv ${IIDSSTARTLIST} ${LOGPATH}/archivelogs/existlogs/IIDSSTARTLIST_${DATE}.log
		fi
		if [ -f ${SUMMARY} ]; 
		 then  
		        mv ${SUMMARY} ${LOGPATH}/archivelogs/existlogs/summary_${DATE}.log
		fi

		# Collect Servers with specified AMI label name pattern
		/opt/aws/bin/ec2-describe-tags -H | grep "${TAGKEY}" | grep "${TAGVALUE}" | awk '{print $3}' > ${IIDSSTARTLIST}

		# collect instance id and servername
		for SERBER in $(cat ${IIDSSTARTLIST});
		do
			/opt/aws/bin/ec2-describe-instances ${SERBER} | grep Name | awk '{print $3,$5}' >> ${SERVERS}
		done

		# Backup AMI'S
		for IID in $(cat ${IIDSSTARTLIST});
		do
		        SERVERNAME=$(grep ${IID} ${SERVERS} | awk '{print $2}')

		        # Create if directory is not existed
		        if [ ! -d ${LOGPATH}/"${SERVERNAME}" ];
		        then
		                mkdir -p ${LOGPATH}/"${SERVERNAME}"/existlogs
		        fi
			if [ ! -d ${LOGPATH}/"${SERVERNAME}"/existlogs ];
			 then
				 mkdir ${LOGPATH}/"${SERVERNAME}"/existlogs
			fi

		        SERVERLOG="${LOGPATH}/${SERVERNAME}/serverlog.log"

			# Create if server.log file is still exist
			if [ -f ${SERVERLOG} ];
			 then
				mv ${SERVERLOG} ${LOGPATH}/"${SERVERNAME}"/existlogs/serverlog_${DATE}.log
			fi

			# Backup begins here
			echo "Instance Name: ${SERVERNAME}" >> ${SERVERLOG}
			echo "Instance ID: ${IID}" >> ${SERVERLOG}
			echo "Backup Started: $(date)" >> ${SERVERLOG}
			/opt/aws/bin/ec2-create-image ${IID} --name "${SERVERNAME}${AMILABELNAME}-${AMIPATTERN}-${BACKUPDATE}" --no-reboot >> ${SERVERLOG}
			echo "Backup Ended: $(date)" >> ${SERVERLOG}
			echo "----------------------------------" >> ${SERVERLOG}
			echo "" >> ${SERVERLOG}
			
			# print logs to summary file
			cat ${SERVERLOG} >> ${SUMMARY}

			# wait 2 seconds
		    	sleep 2s
		done

		# Email report
		mail -s "AU - AMI ${AMIPATTERN} Backup Alert Report for ${AMILABELNAME} - ${DATE}" -r "${MAILFROM}" ${MAILTO} < ${SUMMARY}
}



###
## P - Weekly backup
###
p_weekly_backup() {
		TAGKEY="Backup-Retention"
		TAGVALUE="P"
		AMILABELNAME="(${TAGVALUE})"
		AMIPATTERN="WEEKLY" #AMI pattern name for backup
		BACKUPDATE=$(date +%FT%H.%M.%S) 
		DATE=$(date +%F)
		MAILFROM="AU AMI Backup <auamibackup@domain.com>"
		MAILTO=monitor-backup@domain.com

		# Log file 
		LOGPATH="/var/log/aws/backup/ami/au/${AMIPATTERN}/${TAGVALUE}"
		SERVERS="${LOGPATH}/SERVERS.log"
		IIDSLOG="${LOGPATH}/IIDS.log"
		IIDSSTARTLIST="${LOGPATH}/IIDSSTARTLIST.log"
		SUMMARY="${LOGPATH}/summary.log"

		## The fun begins....

		# Create if log directories are not existed
		if [ ! -d "${LOGPATH}/archivelogs" ];
		 then
			mkdir -p ${LOGPATH}/archivelogs
		fi
		if [ ! -d "${LOGPATH}/archivelogs/existlogs" ];
		 then
		        mkdir -p ${LOGPATH}/archivelogs/existlogs
		fi

		# Create if logs are existed
		if [ -f ${SERVERS} ];
		 then
			mv ${SERVERS} ${LOGPATH}/archivelogs/existlogs/SERVERS_${DATE}.log
		fi
		if [ -f ${IIDSLOG} ]; 
		 then
		        mv ${IIDSLOG} ${LOGPATH}/archivelogs/existlogs/IIDS_${DATE}.log
		fi
		if [ -f ${IIDSSTARTLIST} ];
		 then
		        mv ${IIDSSTARTLIST} ${LOGPATH}/archivelogs/existlogs/IIDSSTARTLIST_${DATE}.log
		fi
		if [ -f ${SUMMARY} ]; 
		 then  
		        mv ${SUMMARY} ${LOGPATH}/archivelogs/existlogs/summary_${DATE}.log
		fi

		# Collect Servers with specified AMI label name pattern
		/opt/aws/bin/ec2-describe-tags -H | grep "${TAGKEY}" | grep "${TAGVALUE}" | awk '{print $3}' > ${IIDSSTARTLIST}

		# collect instance id and servername
		for SERBER in $(cat ${IIDSSTARTLIST});
		do
			/opt/aws/bin/ec2-describe-instances ${SERBER} | grep Name | awk '{print $3,$5}' >> ${SERVERS}
		done

		# Backup AMI'S
		for IID in $(cat ${IIDSSTARTLIST});
		do
		        SERVERNAME=$(grep ${IID} ${SERVERS} | awk '{print $2}')

		        # Create if directory is not existed
		        if [ ! -d ${LOGPATH}/"${SERVERNAME}" ];
		        then
		                mkdir -p ${LOGPATH}/"${SERVERNAME}"/existlogs
		        fi
			if [ ! -d ${LOGPATH}/"${SERVERNAME}"/existlogs ];
			 then
				 mkdir ${LOGPATH}/"${SERVERNAME}"/existlogs
			fi

		        SERVERLOG="${LOGPATH}/${SERVERNAME}/serverlog.log"

			# Create if server.log file is still exist
			if [ -f ${SERVERLOG} ];
			 then
				mv ${SERVERLOG} ${LOGPATH}/"${SERVERNAME}"/existlogs/serverlog_${DATE}.log
			fi

			# Backup begins here
			echo "Instance Name: ${SERVERNAME}" >> ${SERVERLOG}
			echo "Instance ID: ${IID}" >> ${SERVERLOG}
			echo "Backup Started: $(date)" >> ${SERVERLOG}
			/opt/aws/bin/ec2-create-image ${IID} --name "${SERVERNAME}${AMILABELNAME}-${AMIPATTERN}-${BACKUPDATE}" --no-reboot >> ${SERVERLOG}
			echo "Backup Ended: $(date)" >> ${SERVERLOG}
			echo "----------------------------------" >> ${SERVERLOG}
			echo "" >> ${SERVERLOG}
			
			# print logs to summary file
			cat ${SERVERLOG} >> ${SUMMARY}

			# wait 2 seconds
		    	sleep 2s
		done

		# Email report
		mail -s "AU - AMI ${AMIPATTERN} Backup Alert Report for ${AMILABELNAME} - ${DATE}" -r "${MAILFROM}" ${MAILTO} < ${SUMMARY}
}



#### 
#### MAIN OPERATION
####

WEEKDAY_NAME_TODAY="$(date +"%a")"
TODAYS_MONTH=$(date +"%m")
MONTH_NEXT_WEEK=$(date -d 7days +"%m")

# For Label W
if [ ${WEEKDAY_NAME_TODAY} == "Fri" ];
    then
        if [ ${TODAYS_MONTH} != ${MONTH_NEXT_WEEK} ];
            then
                w_monthly_backup
            else   
                w_daily_backup
        fi
    else
        if [ ${WEEKDAY_NAME_TODAY} == "Sat" ];
            then
                w_weekly_backup
            else
            	w_daily_backup
        fi
fi

# For Label P
if [ ${WEEKDAY_NAME_TODAY} == "Fri" ];
	then
		p_weekly_backup
	else
		p_daily_backup
fi

# Exit after operation is done
exit $?
