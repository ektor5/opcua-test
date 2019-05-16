#!/bin/bash

set -e

SERVER_ADDRESS="192.168.10.2"
CLIENT_PATH="/home/uddeholm"
CLIENT="opcua-client.py"

TMP=$(mktemp /tmp/opcuatest-XXXXX)

tshark -i enp2s0 -f 'tcp port 4840' -a duration:$2 -w $TMP 1>&2 &
TSHARK=$!

${CLIENT_PATH}/${CLIENT} $1 $SERVER_ADDRESS $TMP 1>&2 &
CLIENT_PID=$!

wait $TSHARK && kill $CLIENT_PID

echo $TMP
