#!/bin/bash
# Author - James Corteciano

# Don't change these settings
export AWS_ACCESS_KEY=YOUR-ACCESS-KEY-HERE
export AWS_SECRET_KEY=YOUR-SECRET-KEY-HERE
export EC2_HOME=/opt/aws/ec2

# Sydney
export EC2_URL=https://ec2.ap-southeast-2.amazonaws.com
export EC2_REGION=ap-southeast-2

# Singapore
#export EC2_URL=https://ec2.ap-southeast-1.amazonaws.com
#export EC2_REGION=ap-southeast-1

export JAVA_HOME=/usr/lib/jvm/jre

###
## C / root drive - Daily backup
###
c_daily_backup() {
		## Settings
		TAGKEY="Backup-Retention"
		TAGVALUE="C"
		BACKUP_SCHED_TYPE="DAILY" #AMI pattern name for backup
		BACKUPDATE=$(date +%FT%H.%M.%S) 
		DATE=$(date +%F)
		MAILFROM="AU EC2 Snapshot Backup <au.ec2.snapshot.backup@domain.com>"
		MAILTO="backup-monitor@domain.com"

		# Log files
		LOGPATH="/var/log/aws/backup/snapshots/au/${BACKUP_SCHED_TYPE}/${TAGVALUE}"
		SERVERS="${LOGPATH}/SERVERS.log"
		IIDSSTARTLIST="${LOGPATH}/IIDSSTARTLIST.log"
		SUMMARY="${LOGPATH}/summary.log"

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

		# collect volume id and server name
		for I_ID in $(cat ${IIDSSTARTLIST});
		do
			VOLID=$(/opt/aws/bin/ec2-describe-instances ${I_ID} | egrep "sda1|xvda" | awk '{print $3}')
			INAME=$(/opt/aws/bin/ec2-describe-instances ${I_ID} | grep Name | awk '{print $5}')
			echo "${VOLID} ${INAME} ${I_ID}" >> ${SERVERS}
		done

		# Backup started here
		for VOL_ID in $(awk '{print $1}' ${SERVERS});
		do
		    SERVERNAME=$(grep ${VOL_ID} ${SERVERS} | awk '{print $2}')
		    IID_NAME=$(grep ${VOL_ID} ${SERVERS} | awk '{print $3}')

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
			echo "Instance ID: ${IID_NAME}" >> ${SERVERLOG}
			echo "Instance Name: ${SERVERNAME}" >> ${SERVERLOG}
			echo "Volume ID: ${VOL_ID}" >> ${SERVERLOG}
			echo "Backup Started: $(date)" >> ${SERVERLOG}
			/opt/aws/bin/ec2-create-snapshot ${VOL_ID} --description "${SERVERNAME}(${TAGVALUE})-${BACKUP_SCHED_TYPE}-${BACKUPDATE}" >> ${SERVERLOG}
			echo "Backup Ended: $(date)" >> ${SERVERLOG}
			echo "----------------------------------" >> ${SERVERLOG}
			echo "" >> ${SERVERLOG}
			
			# print logs to summary file
			cat ${SERVERLOG} >> ${SUMMARY}

			# wait 2 seconds
		    	sleep 2s
		done

		# Email report
		mail -s "AU - Generated ${BACKUP_SCHED_TYPE} Snapshot Backup for (${TAGVALUE}) - ${DATE}" -r "${MAILFROM}" ${MAILTO} < ${SUMMARY}
}

#### 
#### MAIN OPERATION
####

c_daily_backup

## Exit after operation
exit $?
