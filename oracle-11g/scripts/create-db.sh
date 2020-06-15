#!/bin/bash
#
# Script to Create 11.2.0.4 Database
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
    -e  [Exit on task completion Y|N - default N]  example:  -e Y    
                 
   Note: exit on task completion will stop contianer following database creation.  If you want to keep container running
         then set exit on task completion to N (No) example "-e N" and the alert log will be tailed indefinately
         
   example:
    Create Database called DEV, enable archivelog mode  - ./${program} -d DEV -a Y       
             
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
     exit 1
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
-automaticMemoryManagement false \
-totalMemory 850 \
-emConfiguration NONE \
-sysPassword kiwi123 \
-systemPassword kiwi123 \
-sampleSchema false \
-datafileDestination /u01/app/oracle/oradata \
-recoveryAreaDestination  /u01/app/oracle/fast_recovery_area \
-initparams java_jit_enabled=false \
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

   ## Should we exit on completion or continue tailing alert log...
   if [ "${v_exit_on_completion}" = "N" ]; then
     adrci_rdbms_home=`adrci exec="show homes" | grep -e rdbms -e asm`
     adrci exec="set home ${adrci_rdbms_home}; show alert -tail -f" 
   else        
     stop_db ${db}
     adrci_rdbms_home=`adrci exec="show homes" | grep -e rdbms -e asm`
     adrci exec="set home ${adrci_rdbms_home}; show alert -tail 20"  
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
v_exit_on_completion="N"

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
           
   -e)     ## set flag to exit on completion of tasks or to tail the alert log indefinately following completion
           shift
           if [ "${1}" = "Y" ] || [ "${1}" = "N" ]; then
              v_exit_on_completion=${1}
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


