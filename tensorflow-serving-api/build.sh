# *****************************************************************
#
# Licensed Materials - Property of IBM
#
# (C) Copyright IBM Corp. 2019, 2020. All Rights Reserved.
#
# US Government Users Restricted Rights - Use, duplication or
# disclosure restricted by GSA ADP Schedule Contract with IBM Corp.
#
# *****************************************************************
#!/bin/bash

set -vex

if [[ "${ARCH}" == 'ppc64le' ]]; then
    export CC_OPT_FLAGS="-mcpu=power8 -mtune=power8"
fi

bazel build \
    --color=yes \
    --curses=yes \
    --verbose_failures \
    --output_filter=DONT_MATCH_ANYTHING \
    --action_env PYTHON_BIN_PATH="$PYTHON" \
    --action_env PYTHON_LIB_PATH="$SP_DIR" \
    --python_path="$PYTHON" \
    tensorflow_serving/tools/pip_package:build_pip_package

bazel-bin/tensorflow_serving/tools/pip_package/build_pip_package $SRC_DIR/tensorflow_serving_pkg
pip install --no-deps  $SRC_DIR/tensorflow_serving_pkg/tensorflow_serving_api-*.whl

bazel clean --expunge
bazel shutdown
