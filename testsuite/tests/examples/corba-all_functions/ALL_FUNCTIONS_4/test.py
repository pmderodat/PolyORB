
from test_utils import *
import sys

if not client_server(r'../examples/corba/all_functions/client', r'scenarios/polyorb_conf/giop_1_0.conf',
                     r'../examples/corba/all_functions/server', r'scenarios/polyorb_conf/giop_1_0.conf'):
    sys.exit(1)
