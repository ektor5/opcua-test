#!/usr/bin/python3

import time
import asyncio
import logging
import struct
import sys
import csv

from asyncua import Client
#from asyncua.ua import uaprotocol_auto

logging.basicConfig(level=logging.INFO)
_logger = logging.getLogger('asyncua')

subs_timeout = 300
address = "192.168.10.2"
csvfile = "/dev/null"

if len(sys.argv) > 1 :
    subs_timeout = int(sys.argv[1])
if len(sys.argv) > 2 :
    address = str(sys.argv[2])
if len(sys.argv) > 3 :
    csvfile = str(sys.argv[3])

assert (int(subs_timeout) > 0),"timeout less than absolute zero!"
assert (len(address) > 0 ), "address not valid"
assert (len(csvfile) > 0 ), "filename not valid"

class SubHandler(object):

    def __init__(self,f,log,nodemap):
        self.f = f
        self.log = log
        self.m = nodemap

    def datachange_notification(self, node, val, data):

        now = time.time()
        delay = now - val

        self.log.info("%s: New data change event: %s, %f", time.ctime(now), node, delay)
                #str(data.monitored_item.Value.SourceTimestamp))

        self.f.writerow([now, self.m[node.nodeid], delay])

    def event_notification(self, event):
        _logger.info("New event", event)

async def run():
    url = 'opc.tcp://' + address + ':4840/freeopcua/server/'
    cfile = open(csvfile, 'w', newline='')
    writer = csv.writer(cfile, delimiter=' ', quotechar='|', quoting=csv.QUOTE_MINIMAL)

    try:
        async with Client(url=url) as client:
            root = client.get_root_node()
            _logger.info("Root node is: %r", root)
            objects = client.get_objects_node()
            _logger.info("Objects node is: %r", objects)
            sensor = await objects.get_child("2:MyObject")

            childs = await sensor.get_children()
            _logger.info("Children of sensor are: %r", childs)

            nodemap  = {}

            subs = childs
            for i in subs:
                name = await i.get_description();
                nodemap[i.nodeid] = name.Text;

            sub = await client.create_subscription(subs_timeout,
                    SubHandler(writer,_logger,nodemap))

            await sub.subscribe_data_change(subs)
            while True:
                await asyncio.sleep(0.5)
                cfile.flush()
                if not sub:
                    raise Exception("sub died")
                if not client:
                    raise Exception("client died")

    except Exception:
        _logger.exception('error')
        cfile.close()

if __name__ == "__main__":
    loop = asyncio.get_event_loop()
    loop.set_debug(True)
    loop.run_until_complete(run())

