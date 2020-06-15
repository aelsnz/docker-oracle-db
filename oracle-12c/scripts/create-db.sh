#!/bin/bash
#
# Description: 
#  A sampmle Script to Create 12.1.0.2 Database
#  This sample script use a basic password as Demo123 - that should be adjusted
#  or passed in as parameter - todo.
#
# set -x
#

trap trap_err SIGINT

###########################################
#  Function to echo usage
###########################################
usage ()
{
  program=`basename $0`

cat <<EOF
Usage:
   ${program}
    -d  [Database name]                               example:  -d DEV
    -c  [Create as CDB? Y|N - default N]              example:  -c Y
    -p  [If CDB what is pdb prefix]                   example:  -p PDBX
    -o  [Oracle Managed Files Y|N - default N]        example:  -o Y  
    -e  [Exit on task completion Y|N - default N]     example:  -e Y    
                 
   Note: exit on task completion will stop contianer following database creation.  If you want to keep container running
         then set exit on task completion to N (No) example "-e N" and the alert log will be tailed indefinately
         
   example:
    Create CDB called DEV with PDB called PDBX         - ./${program} -d DEV -c Y -p PDBX 
    Create CDB called DEV with default PDB             - ./${program} -d DEV -c Y 
    Create NON-CDB called DEV, use OMF                 - ./${program} -d DEV -c N -o Y       
             
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
#  Function check if the database is running (pmon process is checked)
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
#  Function create_cdb - to create a Container Database (CDB)
###########################################
create_cdb ()
{

dbca -createDatabase \
-templateName General_Purpose.dbc \
-gdbName ${1} \
-sid ${1} \
-createAsContainerDatabase true \
-numberOfPDBs 1 \
-pdbName ${2} \
-pdbAdminPassword Demo123 \
-datafileDestination /u01/app/oracle/oradata \
-storageType FS \
-recoveryAreaDestination /u01/app/oracle/fast_recovery_area \
-automaticMemoryManagement false \
-totalMemory 1024 \
-sysPassword Demo123 \
-systemPassword Demo123 \
-characterSet AL32UTF8 \
-emConfiguration DBEXPRESS \
-emExpressPort 5500 \
-enableArchive true \
-redoLogFileSize 100 \
-useOMF ${3} \
-silent

}

###########################################
#  Function create_db
###########################################
create_db ()
{

dbca -createDatabase \
-templateName General_Purpose.dbc \
-gdbName ${1} \
-sid ${1} \
-datafileDestination /u01/app/oracle/oradata \
-storageType FS \
-recoveryAreaDestination /u01/app/oracle/fast_recovery_area \
-automaticMemoryManagement false \
-totalMemory 1024 \
-sysPassword Demo123 \
-systemPassword Demo123 \
-characterSet AL32UTF8 \
-emConfiguration DBEXPRESS \
-emExpressPort 5500 \
-enableArchive true \
-redoLogFileSize 100 \
-useOMF ${2} \
-silent

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

  addLog "Listner Created"
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
     ## Do we need to create a container database...
     if [ "${v_container}" = "Y" ]; then
          create_cdb ${db} ${v_pdb} ${v_omf}
     else
          create_db ${db} ${v_omf}
     fi
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
v_pdb="PDB"
v_container="N"
v_omf="false"  
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
   -c)
           shift
           if [ "${1}" = "Y" ] || [ "${1}" = "N" ]; then
              v_container=${1}
           else
              usage
           fi
           ;;
           
   -p)
           ## optional - if "-c N" was specified then no container, if "-c Y" then default is PDB otherwise specify PDB name with -p
           shift
           v_pdb=${1}
           ;;
           
   -o)     ## optional - enable OMF  Y or not N - default No - N
           shift
           if [ "${1}" = "Y" ] ; then
              v_omf="true"
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


