#!/bin/bash

# Deleting the already filtered folder, and unzip a new
# folder that will be used for testing
rm -r FrankJones
unzip sample.zip
cp organize.sh FrankJones/organize.sh

# Moving myself into the newly created directory so that
# I can quickly run the script in there
#cd FrankJones
#exec bash
