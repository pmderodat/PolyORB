
from test_utils import *
import sys

if not client_server(r'../examples/corba/echo/dynclient', r'scenarios/polyorb_conf/soap.conf',
                     r'../examples/corba/echo/server', r'scenarios/polyorb_conf/soap.conf'):
    sys.exit(1)

