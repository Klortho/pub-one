#!/bin/bash

PUB1DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
CLASSPATH=`cat "$PUB1DIR/classpath.txt"`
CLASSPATH="$PUB1DIR"/target/classes:$CLASSPATH

java -DPUB1DIR="$PUB1DIR" gov.ncbi.pub1.Transform $*
