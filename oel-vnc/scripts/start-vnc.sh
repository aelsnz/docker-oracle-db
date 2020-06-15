#!/bin/bash -e
#
# DESCRIPTION:
#   Start xterm in Xframebuffer with Fluxbox and VNC running
#   optional start SSH
#   password must exist in ~/vnc/passwd 
#
# To enable bash Debugging, uncomment next line:
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
   ${program} [-s]

EOF
exit 1
}

###########################################
#  Function to clean up....
###########################################
trap_err () {
   echo '....'
   echo 'Caught signal....cleaning up...'
   kill -s SIGTERM $XVFB_PID
   wait $XVFB_PID
   echo "done... exit"
   exit 999
}


###########################################
#  Function to setup environment
###########################################
setup_parameters ()
{
    ## VNC related settings
    SCREEN_WIDTH=1360
    SCREEN_HEIGHT=1020
    SCREEN_DEPTH=24
  
    ## Add path to enable fluxbox
    export PATH=/usr/local/fluxbox/bin:$PATH
    
    ## set display to high number using custom 99.0
    DISPLAY=:99.0
  
    ## set geometry for VNC session
    GEOMETRY="$SCREEN_WIDTH""x""$SCREEN_HEIGHT""x""$SCREEN_DEPTH"
  
    ## Make sure no other old VNC lock files around
    rm -f /tmp/.X*lock
  
    ## Set SERVERNUM (main display number)
    SERVERNUM=$(get_server_num)
  
    ## Just something useful to output the IP 
    echo $HOSTNAME - $(echo $(ip addr show dev eth0 | sed -nr 's/.*inet ([^ ]+).*/\1/p') | cut -f 1 -d '/')
}


###########################################
#  Function to show display main number only
###########################################
function get_server_num() {
    echo $(echo $DISPLAY | sed -r -e 's/([^:]+)?:([0-9]+)(\.[0-9]+)?/\2/')
}

###########################################
#  Function start ssh daemon if you require it
###########################################
start_sshd ()
{
     echo "Starting SSHD..."
     # Add optional SSH options
     sudo rm -f /etc/ssh/ssh_host_ecdsa_key /etc/ssh/ssh_host_rsa_key /etc/ssh/ssh_host_dsa_key
     sudo ssh-keygen -q -N "" -t dsa -f /etc/ssh/ssh_host_ecdsa_key 
     sudo ssh-keygen -q -N "" -t rsa -f /etc/ssh/ssh_host_rsa_key 
     sudo ssh-keygen -q -N "" -t dsa -f /etc/ssh/ssh_host_dsa_key 
     sudo ssh-keygen -q -N "" -t ed25519 -f /etc/ssh/ssh_host_ed25519_key
     sudo sed -i "s/#UsePrivilegeSeparation.*/UsePrivilegeSeparation no/g" /etc/ssh/sshd_config 
     sudo sed 's@session\s*required\s*pam_loginuid.so@session optional pam_loginuid.so@g' -i /etc/pam.d/sshd
     rm -rf ~/.ssh
     ssh-keygen -t dsa -P '' -f ~/.ssh/id_dsa
     ## Starting SSHD now...
     sudo /usr/sbin/sshd 
     ps -ef|grep ssh |grep -v grep
     echo "... done"
}


###########################################
#  Function that starts xvfb
###########################################
start_xvfb ()
{
      ## Emulate a X Virtual framebuffer
      #  In this example xterm is started as the main process - if this is killed/exited the session will terminate!
      #
      xvfb-run -n $SERVERNUM --server-args="-screen 0 $GEOMETRY -ac +extension RANDR" xterm &
      XVFB_PID=$!
      ## it is runn in background and pid is captured into XVFB_PID
}

###########################################
#  Function that starts window manager (fluxbox)
###########################################
start_window_manager ()
{
    ## Now starting Window Manager - FluxBox which is small and lightweight
    #
    fluxbox -display $DISPLAY -log /tmp/fluxbox.log &
}


###########################################
#  Function that starts VNC
###########################################
start_vnc ()
{
    ## Start x11vnc which is a small fast VNC server running on port 5900
    #  password is in ~/vnc/passwd 
    x11vnc -usepw -ncache_cr -forever -shared -rfbport 5900 -display $DISPLAY -o /tmp/x11vnc.log &
    # wait $!
}


###########################################
########
## Main Section
########
###########################################

trap trap_err SIGKILL SIGTERM SIGHUP SIGINT

## set environment
#
setup_parameters

## read arguments and validate them
#
while test $# -gt 0
do
   case ${1} in 
   -s)     ## Optional - check if ssh should be enabled Y or N
           v_start_sshd="Y"                 
           ;;
   *)      usage
           ;;
   esac
   shift
done


################################
## Now start processes depending on arguments provided
################################

  ## if ssh should be enabled, start it:
  #
  if [ "${v_start_sshd}" = Y ]; then
    start_sshd
  fi 

start_xvfb
 sleep 3
start_window_manager
 sleep 3
start_vnc 

## Wait forever - basically until xterm is closed and everything is then stopped
wait $XVFB_PID 
