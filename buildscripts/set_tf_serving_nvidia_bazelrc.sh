#!/bin/bash
# *****************************************************************
# (C) Copyright IBM Corp. 2020, 2021. All Rights Reserved.
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
set -ex
BAZEL_RC_DIR=$1

# Here "/usr/include" is added so that cublas headers can be located on baremetal.
CUDA_TOOLKIT_PATH=$CUDA_HOME,$PREFIX,"/usr/include"

# Determine architecture for specific settings
ARCH=`uname -p`

## CUDA OPTION 1: CUDA CAPABILITY LEVEL
## More information on Capability Levels found at: 
##  https://developer.nvidia.com/cuda-gpus
##
## Note 1: CUBINs are compatible within the same major architecture, 
## which means we only need to ship PTX to JIT for future architectures.
##
## Note 2: This has changed for TF 2.3. We can now designate which 
## architectures to include PTX code for:
##     - compute_<cuda_arch> : include PTX
##     - sm_<cuda_arch> : do not include PTX
##
##

CUDA_VERSION="${cudatoolkit%.*}"

cat > $BAZEL_RC_DIR/nvidia_components_configure.bazelrc << EOF
build --config=cuda
build --copt=-fPIC
build --action_env TF_NEED_CUDA=1
build --action_env TF_CUDA_VERSION=$CUDA_VERSION"
build --action_env TF_CUDNN_VERSION="${cudnn:0:1}" #First digit only
build --action_env TF_NCCL_VERSION="${nccl:0:1}"
build --action_env TF_CUDA_PATHS="$CUDA_TOOLKIT_PATH"
build --action_env CUDA_TOOLKIT_PATH="$CUDA_TOOLKIT_PATH"
build --action_env TF_CUDA_COMPUTE_CAPABILITIES="${cuda_levels_details}"          # Use centralized CUDA capability settings
build --action_env GCC_HOST_COMPILER_PATH="${CC}"
EOF

PY_VER=$2

# Temporarily disable TensorRT
#if [[ $PY_VER < 3.8 ]]; then
#cat >> $BAZEL_RC_DIR/nvidia_components_configure.bazelrc << EOF
#build:tensorrt --action_env TF_NEED_TENSORRT=1
#build --config=tensorrt
#build --action_env TF_TENSORRT_VERSION="${tensorrt:0:1}"
#EOF
#fi

cat > $BAZEL_RC_DIR/tensorflow-serving.bazelrc << EOF
import %workspace%/tensorflow_serving/nvidia_components_configure.bazelrc
EOF

