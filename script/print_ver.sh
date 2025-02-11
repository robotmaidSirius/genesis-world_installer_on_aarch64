#!/bin/bash

echo ========================================
echo "* cmake Usage         : $(cmake --version | head -n 1) "
echo "* gcc Usage           : $(gcc --version | head -n 1)"
echo "* g++ Usage           : $(g++ --version | head -n 1)"
echo "* clang Usage         : $(clang --version | head -n 1)"
echo "* clang++ Usage       : $(clang++ --version | head -n 1)"

echo ========================================
echo "* Memory Usage "
free -h | tail -n 2

echo ========================================
lsb_release -a
#cat /etc/os-release

echo ========================================
jetson_release
# apt show nvidia-jetpack

echo ========================================
echo "* python Usage        : $(python --version | head -n 1)"
echo "* numpy Usage         : $(pip show numpy | grep Version | head -n 1)"
echo "* taichi Usage        : $(pip show taichi | grep Version)"
echo "* CoACD Usage         : $(pip show coacd | grep Version)"
echo "* vtk Usage           : $(pip show vtk | grep Version)"
echo "* libigl Usage        : $(pip show libigl | grep Version)"
echo "* tetgen Usage        : $(pip show tetgen | grep Version)"
echo "* pymeshlab Usage     : $(pip show pymeshlab | grep Version)"
echo "* pyvista Usage       : $(pip show pyvista | grep Version)"
echo "* genesis-world Usage : $(pip show genesis-world | grep Version)"

echo ========================================
echo "* pytorch Usage       : $(python -c "import torch;print(torch.__version__);")"
echo "    cuDNN version     : $(python -c "import torch;print(torch.backends.cudnn.version());")"
echo "    CUDA available    : $(python -c "import torch;print(torch.cuda.is_available());")"
echo "*   torchvision Usage : $(python -c "import torchvision;print(torchvision.__version__);")"
echo "*   torchaudio Usage  : $(python -c "import torchaudio;print(torchaudio.__version__);")"
echo "* OpenCV Usage        : $(python -c "import cv2;print(cv2.__version__);")"
#echo "* tensorflow Usage    : $(python -c "import tensorflow;print(tensorflow.__version__);")"
