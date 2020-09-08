# *****************************************************************
#
# Licensed Materials - Property of IBM
#
# (C) Copyright IBM Corp. 2019, 2020 All Rights Reserved.
#
# US Government Users Restricted Rights - Use, duplication or
# disclosure restricted by GSA ADP Schedule Contract with IBM Corp.
#
# *****************************************************************
#!/bin/bash

set -vex

BUILD_OPTS=""

if [[ "${ARCH}" == 'ppc64le' ]]; then
    export CC_OPT_FLAGS="-mcpu=power8 -mtune=power8"
else
    BUILD_OPTS+=" --config=release"
fi

ln -s $GCC $PREFIX/gcc
ln -s $GXX $PREFIX/g++
export GCC_HOST_COMPILER_PATH=${CC}
if [ "${build_type}" = "cuda" ]; then
  BUILD_OPTS+=" --config=cuda --copt=-fPIC"
  export TF_NEED_CUDA=1
  export TF_NEED_TENSORRT=1
  export TF_CUDA_VERSION="${cudatoolkit%.*}"
  export TF_CUDNN_VERSION=${cudnn:0:1} #First digit only
  export TF_TENSORRT_VERSION=${tensorrt:0:1}
  export TF_NCCL_VERSION=${nccl:0:1}
  export TF_CUDA_PATHS=${PREFIX}
  export TF_CUDA_COMPUTE_CAPABILITIES=3.7,6.0,7.0,7.5
elif [ "${build_type}" = "mkl" ]; then
  BUILD_OPTS+=" --config=mkl"
fi

export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:${PREFIX}/lib

bazel build ${BUILD_OPTS} \
    --action_env PYTHON_BIN_PATH="$PYTHON" \
    --action_env PYTHON_LIB_PATH="$SP_DIR" \
    --python_path="$PYTHON" \
    --color=yes \
    --curses=no \
    --verbose_failures \
    --output_filter=DONT_MATCH_ANYTHING \
    tensorflow_serving/model_servers:tensorflow_model_server

# Allow Conda to modify the built binrary
chmod u+w bazel-bin/tensorflow_serving/model_servers/tensorflow_model_server

# Install the tensorflow_model_server binary
mkdir -p "${PREFIX}"/bin
cp bazel-bin/tensorflow_serving/model_servers/tensorflow_model_server "${PREFIX}"/bin

rm $PREFIX/gcc
rm $PREFIX/g++
bazel clean --expunge
bazel shutdown
