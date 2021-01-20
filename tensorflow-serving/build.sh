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

SCRIPT_DIR=$RECIPE_DIR/../buildscripts

# Determine architecture for specific settings
ARCH=`uname -p`

# Pick up additional variables defined from the conda build environment
$SCRIPT_DIR/set_python_path_for_bazelrc.sh $SRC_DIR/tensorflow_serving
if [[ $build_type == "cuda" ]]
then
  # Pick up the CUDA and CUDNN environment
  $SCRIPT_DIR/set_tf_serving_nvidia_bazelrc.sh $SRC_DIR/tensorflow_serving $PY_VER

  if [[ "${ARCH}" == 'x86_64' ]] && [[ $PY_VER < 3.8 ]]; then
    # Create symlink of libmemcpy-2.14.so from where it can be picked up by TF build
    # Avoid this for Python3.8 since this is related to TensorRT and TensorRT is
    # not available for Py38 yet.
    ln -s ${PREFIX}/lib/libmemcpy-2.14.so ${PREFIX}/lib64/libmemcpy-2.14.so
  fi
fi

# Build the bazelrc
$SCRIPT_DIR/set_tf_serving_bazelrc.sh $SRC_DIR/tensorflow_serving

BUILD_OPTS=" "
if [[ "${ARCH}" != 'ppc64le' ]]; then
  BUILD_OPTS+=" --config=release"
fi

ln -s $GCC $PREFIX/gcc
ln -s $GXX $PREFIX/g++


if [ "${build_type}" = "mkl" ]; then
  BUILD_OPTS+=" --config=mkl"
fi

export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:${PREFIX}/lib
bazel clean --expunge
bazel shutdown

bazel --bazelrc=$SRC_DIR/tensorflow_serving/tensorflow-serving.bazelrc build ${BUILD_OPTS} \
    --curses=no \
    --output_filter=DONT_MATCH_ANYTHING \
    tensorflow_serving/model_servers:tensorflow_model_server

# Allow Conda to modify the built binary
chmod u+w bazel-bin/tensorflow_serving/model_servers/tensorflow_model_server

# Install the tensorflow_model_server binary
mkdir -p "${PREFIX}"/bin
cp bazel-bin/tensorflow_serving/model_servers/tensorflow_model_server "${PREFIX}"/bin

rm $PREFIX/gcc
rm $PREFIX/g++
bazel clean --expunge
bazel shutdown
