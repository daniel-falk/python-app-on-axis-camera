#!/bin/bash
# Find a shared library in the system and copy it to a destination

LIB_NAME=$1
INSTALL_DIR=$2

# Find the binary for the library (avoid symlinks)
LIB=`find /usr/lib/ -name "$LIB_NAME*" -type f`

# Get the SO-name since this is what the applications link to,
# this is often not the same as the library binary name since
# praxis is to symlink for version compatibility
SO_NAME=`objdump -p $LIB | grep SO | awk '{print $2}'`

# Copy the binary to the destination as the SO-name
cp $LIB $INSTALL_DIR/$SO_NAME
