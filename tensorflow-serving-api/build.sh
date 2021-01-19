#!/bin/bash
# *****************************************************************
# (C) Copyright IBM Corp. 2019, 2021. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
# *****************************************************************
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
