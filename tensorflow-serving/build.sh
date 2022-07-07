#!/bin/bash
# *****************************************************************
# (C) Copyright IBM Corp. 2019, 2022. All Rights Reserved.
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

export BAZEL_LINKLIBS=-l%:libstdc++.a
ln -s $GCC $PREFIX/gcc
ln -s $GXX $PREFIX/g++
ln -s $LD $BUILD_PREFIX/bin/ld

# Pick up additional variables defined from the conda build environment
$SCRIPT_DIR/set_python_path_for_bazelrc.sh $SRC_DIR/tensorflow_serving
if [[ $build_type == "cuda" ]]
then
  # Pick up the CUDA and CUDNN environment
  $SCRIPT_DIR/set_tf_serving_nvidia_bazelrc.sh $SRC_DIR/tensorflow_serving $PY_VER
fi

# Build the bazelrc
$SCRIPT_DIR/set_tf_serving_bazelrc.sh $SRC_DIR/tensorflow_serving

BUILD_OPTS=" "
if [[ "${ARCH}" != 'ppc64le' ]]; then
  BUILD_OPTS+=" --config=release"
fi

if [ "${build_type}" = "mkl" ]; then
  BUILD_OPTS+=" --config=mkl"
fi

export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:${PREFIX}/lib
bazel clean --expunge
bazel shutdown

# On x86, use of new compilers (gcc8) gives "ModuleNotFoundError: No module named '_sysconfigdata_x86_64_conda_linux_gnu'"# This is due to the target triple difference with which python and conda-build are built. Below is the work around to this problem.
# Conda-forge's python-feedstock has a patch https://github.com/conda-forge/python-feedstock/blob/master/recipe/patches/0010-Add-support-for-_CONDA_PYTHON_SYSCONFIGDATA_NAME-if-.patch which may address this problem.

ARCH=`uname -m`
if [[ $ARCH == "x86_64" ]]; then
  cp $PREFIX/lib/python${PY_VER}/_sysconfigdata_x86_64_conda_cos6_linux_gnu.py $PREFIX/lib/python${PY_VER}/_sysconfigdata_x86_64_conda_linux_gnu.py
fi

bazel --bazelrc=$SRC_DIR/tensorflow_serving/tensorflow-serving.bazelrc build ${BUILD_OPTS} \
    --local_cpu_resources=HOST_CPUS-10 \
    --local_ram_resources=HOST_RAM*0.50 \
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
