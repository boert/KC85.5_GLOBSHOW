#! /usr/bin/env python3

import sys

filename = sys.argv[1]
startline = 990
linestep = 10

index = 0
line = startline

with open( filename, 'rb') as f:
    bytes = f.read()
    for b in bytes:
        if ( index % 16) == 0:
            print( "%d DATA " % ( line), end = '')
            line += linestep
        if ( index % 16) == 15:
            print( "%d" % b)
        else:
            print( "%d," % b, end = '')
        index += 1

    print()
    print()
    print( "%d Bytes" % len( bytes))
