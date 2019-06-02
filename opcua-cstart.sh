#!/bin/bash

set -e

SERVER_ADDRESS="192.168.10.2"
CLIENT="./opcua-client.py"

TMP=$(mktemp /tmp/opcuatest-XXXXX)

tshark -i enp2s0 -f 'tcp port 4840' -w $TMP.pcap 1>&2 &
TSHARK=$!
sleep 1

${CLIENT} $1 $SERVER_ADDRESS $TMP.csv 1>&2 &
CLIENT_PID=$!

wait $CLIENT_PID && kill -INT $TSHARK

rm $TMP

echo $TMP
