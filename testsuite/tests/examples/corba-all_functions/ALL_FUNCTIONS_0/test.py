
from test_utils import *
import sys

if not client_server(r'../examples/corba/all_functions/client', r'',
                     r'../examples/corba/all_functions/server', r''):
    sys.exit(1)

