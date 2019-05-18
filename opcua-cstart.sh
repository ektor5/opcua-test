#!/bin/bash

set -e

SERVER_ADDRESS="192.168.10.2"
CLIENT="./opcua-client.py"

TMP=$(mktemp /tmp/opcuatest-XXXXX)

tshark -i enp2s0 -f 'tcp port 4840' -a duration:$2 -w $TMP.pcap 1>&2 &
TSHARK=$!

${CLIENT} $1 $SERVER_ADDRESS $TMP.csv 1>&2 &
CLIENT_PID=$!

wait $TSHARK && kill -INT $CLIENT_PID
wait $CLIENT_PID

echo $TMP
