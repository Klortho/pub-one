#!/bin/bash

# This runs the main() method of the gov.ncbi.pmc.pub_one.test.Transformer
# class, passing it the arguments given in `-Dexec.args`.
# The `exec:java` goal is defined in the pom.xml file.
# Since the Transform class is part of the test suite, running it depends on
# the `test-compile` phase.


IN_PATH=$1
REL_IN_DIR=`dirname $1`
ABS_IN_DIR=$( cd $REL_IN_DIR && pwd )
IN_FILE=`basename $1`
ARGS="$IN_FILE $2"

echo "IN_PATH = $IN_PATH"
echo "REL_IN_DIR = $REL_IN_DIR"
echo "ABS_IN_DIR = $ABS_IN_DIR"
echo "IN_FILE = $IN_FILE"
echo "ARGS = $ARGS"

mvn -q clean test-compile exec:java -Duser.dir="$ABS_IN_DIR" -Dexec.args="$IN_FILE $2"
