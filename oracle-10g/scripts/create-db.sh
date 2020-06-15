#!/bin/bash
#
# Description:  
#  A sample script to Create a Database
#  This sample script use a basic password as Demo123 - that should be adjusted
#  or passed in as parameter - todo.
# 
# set -x
#

trap trap_err SIGINT SIGTERM SIGKILL

###########################################
#  Function to echo usage
###########################################
usage ()
{
  program=`basename $0`

cat <<EOF
Usage:
   ${program}
    -d  [Database name]                            example:  -d DEV
    -a  [Enable Archivelog Mode Y|N - default N]   example:  -a Y
    -t  
                 
   example:
    Create Database called DEV, enable archivelog mode  - ./${program} -d DEV -a Y       

    if you want to run this as entrypoint, add the -t to tail the alert log after db creation
             
EOF
exit 1

}

############
#  Function to echo usage
############
trap_err () {
 echo '....'
 echo 'Caught SIGINT signal....cleaning up...'
 stop_db ${db}
 echo "done... exit"
 exit 999
}

###########################################
#  Function to setup parameter variables
###########################################
setup_parameters ()
{
  export NLS_DATE_FORMAT='DD:MM:YYYY:HH24:MI:SS'
  export DISABLE_HUGETLBFS=1
  log=/tmp/`basename $0`.log
  v_oratab=/etc/oratab
}

###########################################
#  Function to Add text to logfile
###########################################
addLog()
{
  echo "`date +%d-%h-%Y:%H:%M:%S` : ${1}" >> ${log}
  echo "`date +%d-%h-%Y:%H:%M:%S` : ${1}" 
}

###########################################
#  Function to change database environments
###########################################
set_env ()
{
 
   REC=`grep "^${1}" ${v_oratab} | grep -v "^#"`
   if test -z $REC
   then
     addLog "Database NOT in ${v_oratab}"
     ## using default home
     export ORACLE_BASE=/u01/app/oracle
     export ORACLE_HOME=/u01/app/oracle/product/10.2.0/db_1
     export PATH=$ORACLE_HOME/bin:$PATH
     export LD_LIBRARY_PATH=$ORACLE_HOME/lib:$LD_LIBRARY_PATH
     ORACLE_SID=${1} 
   else       
     addLog "Database in ${v_oratab} - setting environment"
     export ORAENV_ASK=NO
     export ORACLE_SID=${1}
     . oraenv >> /dev/null
     export ORAENV_ASK=YES
   fi
   
}


###########################################
#  Function check_db
###########################################
check_pmon ()
{
  addLog "Check pmon process for ${1}"
  PROC=`ps -ef | grep ora_pmon_${1} | grep -v grep | cut -c48-`

  if [ "X${PROC}" = "X" ]; then
    pmon_running="N"
    addLog ".... not running"
  else
    pmon_running="Y"
    addLog ".... is running OK"
  fi
}

###########################################
#  Function create_db
###########################################
create_db ()
{
dbca -createDatabase \
-templateName General_Purpose.dbc \
-gdbname ${1} \
-sid ${1}  \
-characterSet AL32UTF8  \
-memoryPercentage 20 \
-emConfiguration NONE \
-sysPassword Demo123 \
-systemPassword Demo123 \
-sampleSchema false \
-datafileDestination /u01/app/oracle/oradata \
-recoveryAreaDestination  /u01/app/oracle/fast_recovery_area \
-silent

}


###########################################
#  Function enable_archivelog_mode
###########################################
enable_archivelog_mode ()
{
  addLog "Enable Archivelog Mode."
  set_env ${1}
  check_pmon ${1}
  
  if [ "$pmon_running" = "Y" ]; then
  
sqlplus -s /nolog <<!EOF 
   connect / as sysdba  
   shutdown immediate; 
   startup mount;
   alter database archivelog;
   shutdown immediate;
   startup;
exit;
!EOF

    addLog "Enable Archivelog Mode Complete"

  else 
      
sqlplus -s /nolog <<!EOF 
   connect / as sysdba  
   startup mount;
   alter database archivelog;
   shutdown immediate;
   startup;
exit;
!EOF
    addLog "Enable Archivelog Mode Complete"
  fi

}


###########################################
#  Function start_mount_db
###########################################
create_listener ()
{
  addLog "Add Listener..."
  
echo "NAMES.DIRECTORY_PATH= (TNSNAMES, EZCONNECT)" > $ORACLE_HOME/network/admin/sqlnet.ora
  
cat <<EOF > $ORACLE_HOME/network/admin/listener.ora
LISTENER =
  (DESCRIPTION_LIST =
    (DESCRIPTION =
      (ADDRESS = (PROTOCOL = TCP)(HOST = localhost)(PORT = 1521))
      (ADDRESS = (PROTOCOL = IPC)(KEY = EXTPROC1521))
    )
  )
EOF

lsnrctl start

  addLog "Listener Created"
}

###########################################
#  Function stop_db
###########################################
stop_db ()
{
  addLog "Stop ${1} ..."
  set_env ${1}
  check_pmon ${1}
  
  if [ "$pmon_running" = "Y" ]; then
  
sqlplus -s /nolog <<!EOF
   connect / as sysdba
   shutdown immediate;
exit;
!EOF

    addLog "Shutdown Complete"
  else 
    addLog "Database not running - no need to shutdown"
  fi
}

###########################################
#  Function start_mount_db
###########################################
create_database ()
{
  addLog "Start Main Function"

  ## create the database listener first...
   create_listener
  
   if [ -z ${db} ]; then
     usage
   else
     create_db ${db}
   fi 
   ## Should archivelog be enabled....
   if [ "${v_archivelog_mode}" = "Y" ]; then
     enable_archivelog_mode ${db}
   fi
          
  addLog "End Database Creation Function"
}

##########################
##########################
####
#### MAIN PROGRAM SECTION
####
##########################
##########################

setup_parameters

db="DEV"
v_archivelog_mode="N"  

if test $# -lt 1
then
  usage
  exit 99
fi

while test $# -gt 0
do
   case ${1} in
   -d)
           shift
           db=${1}           
           ;;
           
   -a)     ## optioinal - enable archivelog mode Y or not N - default No - N
           shift
           if [ "${1}" = "Y" ] || [ "${1}" = "N" ]; then
              v_archivelog_mode=${1}
           else
              usage
           fi
           ;;
           
          
   "bash")
           /bin/bash
           exit 0
           ;;
           
   "true")
           /bin/true
           exit 0
           ;;

   -t)     
	   tail_alert="Y"
	   ;;
           
   -h)
           usage
           ;;
   -*)
           usage
           ;;
   *)      usage
           break
           ;;
   esac
   shift
done

## Call main function now
create_database

# In case you want to run as entrypoit, you can create the DB then tail the alert log
if [ "${tail_alert}" = "Y" ]; then
	tail -F -n 0 $ORACLE_BASE/admin/${db}/bdump/alert_${db}.log &
        PID=$!
        wait $PID
fi


