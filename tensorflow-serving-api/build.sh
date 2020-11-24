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

bazel clean --expunge
bazel shutdown

SCRIPT_DIR=$RECIPE_DIR/../buildscripts
# Pick up additional variables defined from the conda build environment
$SCRIPT_DIR/set_python_path_for_bazelrc.sh $SRC_DIR/tensorflow_serving

# Build the bazelrc
$SCRIPT_DIR/set_tf_serving_bazelrc.sh $SRC_DIR/tensorflow_serving

bazel --bazelrc=$SRC_DIR/tensorflow_serving/tensorflow-serving.bazelrc build \
    --curses=yes \
    --output_filter=DONT_MATCH_ANYTHING \
    tensorflow_serving/tools/pip_package:build_pip_package

bazel-bin/tensorflow_serving/tools/pip_package/build_pip_package $SRC_DIR/tensorflow_serving_pkg
pip install --no-deps  $SRC_DIR/tensorflow_serving_pkg/tensorflow_serving_api-*.whl

bazel clean --expunge
bazel shutdown
