#!/bin/bash
# *****************************************************************
#
# Licensed Materials - Property of IBM
#
# (C) Copyright IBM Corp. 2020. All Rights Reserved.
#
# US Government Users Restricted Rights - Use, duplication or
# disclosure restricted by GSA ADP Schedule Contract with IBM Corp.
#
# *****************************************************************
set -ex
BAZEL_RC_DIR=$1

#Determine architecture for specific options
ARCH=`uname -p`

## ARCHITECTURE SPECIFIC OPTIMIZATIONS
## These are settings and arguments to pass to GCC for
## optimization settings specific to the target architecture
##
OPTION_1=''
OPTION_2=''
if [[ "${ARCH}" == 'x86_64' ]]; then
    OPTION_1='-march=nocona'
    OPTION_2='-mtune=haswell'
fi
if [[ "${ARCH}" == 'ppc64le' ]]; then
    OPTION_1='-mcpu=power8'
    OPTION_2='-mtune=power8'
fi

SYSTEM_LIBS_PREFIX=$PREFIX
cat >> $BAZEL_RC_DIR/tensorflow-serving.bazelrc << EOF
import %workspace%/tensorflow_serving/python_configure.bazelrc
build:opt --copt="${OPTION_1}"
build:opt --copt="${OPTION_2}"
build:opt --host_copt="${OPTION_1}"
build:opt --host_copt="${OPTION_2}"
build --strip=always
build --color=yes
build --verbose_failures
build --spawn_strategy=standalone
EOF
