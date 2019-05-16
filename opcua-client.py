#!/usr/bin/python3

import time
import asyncio
import logging
import struct
import sys

from asyncua import Client
from asyncua.ua import uaprotocol_auto

#logging.basicConfig(level=logging.INFO)
_logger = logging.getLogger('asyncua')

subs_timeout = 300
address = "192.168.10.2"
if len(sys.argv) > 1 :
    subs_timeout = int(sys.argv[1])
if len(sys.argv) > 2 :
    address = str(sys.argv[2])
    
assert (int(subs_timeout) > 0),"timeout less than absolute zero!"
assert (len(address) > 0 ), "address not valid"

class SubHandler(object):

    def datachange_notification(self, node, val, data):
        print("New data change event", node, time.time()-val,
                str(data.monitored_item.Value.SourceTimestamp))

    def event_notification(self, event):
        print("New event", event)

async def run():
    url = 'opc.tcp://' + address + ':4840/freeopcua/server/'
    try:
        async with Client(url=url) as client:
            root = client.get_root_node()
            _logger.info("Root node is: %r", root)
            objects = client.get_objects_node()
            _logger.info("Objects node is: %r", objects)
            sensor = await objects.get_child("2:MyObject") 

            childs = await sensor.get_children()
            _logger.info("Children of sensor are: %r", childs)

            subs = childs

            sub = await client.create_subscription(subs_timeout, SubHandler())
            await sub.subscribe_data_change(subs)
            while True:
                await asyncio.sleep(10)
                if not sub:
                    raise Exception("sub died")
                if not client:
                    raise Exception("client died")

    except Exception:
        _logger.exception('error')
        await client.disconnect()

    finally:
        await client.disconnect()


if __name__ == "__main__":
    loop = asyncio.get_event_loop()
    loop.set_debug(True)
    loop.run_until_complete(run())

