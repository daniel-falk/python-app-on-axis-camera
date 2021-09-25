#!/bin/bash

source /opt/axis/acapsdk/environment-setup-cortexa9hf-neon-poky-linux-gnueabi
export LDSHARED="$CC -shared"

echo "Using compiler: $CC"
echo "Link with: $LDSHARED"

python setup.py build_ext --inplace
# The shared object get it's name from the host version of python it was built with,
# this should be done in a better/safer way. For now, rename to the suffix we get from
# running 'from distutils.sysconfig import get_config_var; print(get_config_var('EXT_SUFFIX'))'
# in the emulated python interpreter.
mv dummy_data.*.so dummy_data.cpython-36m-arm-linux-gnueabihf.so
