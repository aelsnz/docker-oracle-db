#!/bin/bash
#
# Basic Script to Manage 12.1.0.2 Database
# 
# set -x
#
###########################################
#  Function to echo usage
###########################################
usage ()
{
  program=`basename $0`

cat <<EOF
Usage:
   ${program}
        -d     [database SID]  example:  -d DEV
        -o     [operation ]    example:  -o start|stop|readonly|mount
         
   example:
        ${program} -d DEV -o start
         
EOF
exit 1

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
#  Function start_db
###########################################
start_db ()
{
  addLog "Start ${1} ..."
  set_env ${1}
  check_pmon ${1}
  if [ "$pmon_running" = "N" ]; then
  
sqlplus -s /nolog <<!EOF 
   connect / as sysdba
   startup;
exit;
!EOF

  addLog "Startup Complete"
  else 
    addLog "Database not running - no need to shutdown"
  fi
  
}

###########################################
#  Function start_nomount_db
###########################################
nomount_db ()
{
  addLog "Start ${1} nomount..."
  set_env ${1}
  check_pmon ${1}
  if [ "$pmon_running" = "Y" ]; then
  
sqlplus -s /nolog <<!EOF 
   connect / as sysdba
   shutdown immediate
   startup nomount;
exit;
!EOF
     addLog "Startup nomount Complete"
  else 

sqlplus -s /nolog <<!EOF 
   connect / as sysdba
   startup nomount;
exit;
!EOF
     addLog "Startup nomount Complete"     
  fi
  
}

###########################################
#  Function start_mount_db
###########################################
mount_db ()
{
  addLog "Start ${1} mount..."
  set_env ${1}
  check_pmon ${1}
  if [ "$pmon_running" = "Y" ]; then
  
sqlplus -s /nolog <<!EOF 
   connect / as sysdba  
   shutdown immediate; 
   startup mount;
exit;
!EOF

    addLog "Start mount Complete"

  else 
      
sqlplus -s /nolog <<!EOF 
   connect / as sysdba  
   shutdown immediate; 
   startup mount;
exit;
!EOF
    addLog "Start mount Complete"
  fi

}

###########################################
#  Function start_mount_db
###########################################
readonly_db ()
{
  addLog "Start ${1} readonly..."
  set_env ${1}
  check_pmon ${1}
  
  if [ "$pmon_running" = "N" ]; then
  
sqlplus -s /nolog <<!EOF 
   connect / as sysdba
   startup mount;
   alter database open read only;
exit;
!EOF

    addLog "Start read-only Complete"

  else 

    addLog "Database running - shutdown first"

sqlplus -s /nolog <<!EOF 
   connect / as sysdba
   shutdown immediate;
   startup mount;
   alter database open read only;
exit;
!EOF

    addLog "Start read-only Complete"
  fi

}

###########################################
#  Function start_mount_db
###########################################
manage_db ()
{
  addLog "Start Main Function"
  
   if [ -z ${v_option} ] || [ -z ${db} ]; then
     usage
   else
        case ${v_option} in
        start)      start_db ${db}
                   ;;
        stop)       stop_db ${db}
                   ;;
        mount)      mount_db ${db}                 
                   ;;
        nomount)    nomount_db ${db}
                   ;;
        readonly)   readonly_db ${db}
                   ;;
        esac
   fi 

  addLog "End Main Function"
}

##########################
##########################
####
#### MAIN PROGRAM SECTION
####
##########################
##########################

setup_parameters

db=""
v_option=""

if test $# -lt 2
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
   -o)
           shift
           v_option=${1}
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
manage_db