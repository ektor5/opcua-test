#!/bin/bash

set -e
set -x

SERVER="opcua-server.py"
CLIENT="opcua-client.py"
CSTART="opcua-cstart.sh"

SERVER_PATH="/home/uddeholm"
CLIENT_PATH="/home/uddeholm"

#SERVER_ADDRESS="uddeholm@uddeholm2-udoo-x86.local"
#CLIENT_ADDRESS="uddeholm@uddeholm-udoo-x86.local"
SERVER_ADDRESS="uddeholm@192.168.0.105"
CLIENT_ADDRESS="uddeholm@192.168.0.104"

VARS=$1
RFR_RATE=$2
RQS_RATE=$3
RUN_TIME=$4

log() {
  # args: string
  local COLOR=${GREEN}${BOLD}  
  local MOD="-e"

  case $1 in
    err) COLOR=${RED}${BOLD}
      shift ;;
    pre) MOD+="n" 
      shift ;;
    fat) COLOR=${RED}${BOLD}
      shift ;;
    *) ;;
  esac

  echo $MOD "${COLOR}${*}${RST}"

}

remote () {
	kill -0 $SERVER_PID || error
	if (( $# ))
	then
		cat <<< "$@" > $S_FIFO ;
	else
		cat > $S_FIFO
	fi
}

close(){
	log "CLEANING "
	if [ -n "$SERVER_PID" ] && [ -x "/proc/$SERVER_PID" ]
	then 
		kill -INT $SERVER_PID
	fi

	remote_end 'kill $SPID'
	
	if [ -x "$S_FIFO" ]
	then 
		rm $S_FIFO
	fi
}

remote_end () {

    #disable clean
    remote trap - INT EXIT QUIT ABRT TERM

    if (( $# ))
    then
	    remote "$@"
    else
	    cat | remote
    fi

    #close file descriptor, closes ssh connection
    exec 8>&-
}

#Upload
log "Uploading new version"
scp $SERVER ${SERVER_ADDRESS}:${SERVER_PATH}/ &
S=$!
scp $CLIENT $CSTART ${CLIENT_ADDRESS}:${CLIENT_PATH}/ &

wait $S $!

#start server
S_LOG="server.log"
S_FIFO="$(mktemp -u /tmp/fifo_tty-XXXXXX)"
mkfifo $S_FIFO

log "Starting serverconn"
ssh $SERVER_ADDRESS < $S_FIFO > $S_LOG 2>&1 &
SERVER_PID=$!

#keep fifo open
exec 8> $S_FIFO

#set remote clean
remote <<-LOL
		clean () {
			echo cleaning... ;
			cd ;
		} ;
	LOL
remote trap clean INT EXIT QUIT ABRT TERM

    
remote ${SERVER_PATH}/$SERVER $VARS $RFR_RATE \&
remote 'SPID=$!'

trap close INT
sleep 5 

if [ ! -x /proc/$SERVER_PID ]
then
	echo "server aborted"
	exit 1
fi

#start client
echo "Starting client"
TMP=$(ssh $CLIENT_ADDRESS \
	"${CLIENT_PATH}/$CSTART $RQS_RATE $RUN_TIME" )

if [ -z "$TMP" ]
then
	echo "error: TMP not valid"
	close
	exit 1
fi

echo "Downloading results..."
scp ${CLIENT_ADDRESS}:${TMP} \
	"opcua_v${VARS}_rf${RFR_RATE}_rq${RQS_RATE}_t${RUN_TIME}.log"

echo "Done. Killing server..."
close

exit 0
