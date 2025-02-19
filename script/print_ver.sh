#!/bin/bash
RESULT=0

echo ========================================
echo "* cmake Usage         : $(cmake --version | head -n 1) "
echo "* gcc Usage           : $(gcc --version | head -n 1)"
echo "* g++ Usage           : $(g++ --version | head -n 1)"
echo "* clang Usage         : $(clang --version | head -n 1)"
echo "* clang++ Usage       : $(clang++ --version | head -n 1)"
echo "* llvm-config Usage   : $(llvm-config --version)"
echo "      build mode      : $(llvm-config --build-mode)"
echo "      target build    : $(llvm-config --targets-built)"
echo "      has rtti        : $(llvm-config --has-rtti)"
echo "      assertion mode  : $(llvm-config --assertion-mode)"
echo "      host target     : $(llvm-config --host-target)"
echo "      include dir     : $(llvm-config --includedir)"
#echo "      cpp flags       : $(llvm-config --cppflags)"
#echo "      bin dir         : $(llvm-config --bindir)"
#echo "      build system    : $(llvm-config --build-system)"
#echo "      c flags         : $(llvm-config --cflags)"
#echo "      cxx flags       : $(llvm-config --cxxflags)"
#echo "      c make dir      : $(llvm-config --cmakedir)"
#echo "      components      : $(llvm-config --components)"
#echo "      ignore lib llvm : $(llvm-config --ignore-libllvm)"
#echo "      ld flags        : $(llvm-config --ldflags)"
#echo "      lib dir         : $(llvm-config --libdir)"
#echo "      lib files       : $(llvm-config --libfiles)"
#echo "      lib names       : $(llvm-config --libnames)"
#echo "      libs            : $(llvm-config --libs)"
#echo "      link shared     : $(llvm-config --link-shared)"
#echo "      link static     : $(llvm-config --link-static)"
#echo "      obj root        : $(llvm-config --obj-root)"
#echo "      prefix          : $(llvm-config --prefix)"
#echo "      shared mode     : $(llvm-config --shared-mode)"
#echo "      src root        : $(llvm-config --src-root)"
#echo "      system libs     : $(llvm-config --system-libs)"

echo ========================================
echo "* Memory Usage"
free -h | tail -n 2

echo ========================================
lsb_release -a
#cat /etc/os-release

echo ========================================
PRINT_TEXT=$(which jetson_release)
if [ "" != "${PRINT_TEXT}" ];then
    jetson_release | sed 's/\x1B\[[0-9;]*m//g'
fi
# apt show nvidia-jetpack

echo ========================================
echo "* pyenv Usage: $(pyenv --version)"
echo "    Virtual environment: ${VIRTUAL_ENV_PROMPT}"
echo "    Shims version      : $(pyenv version-name)"
echo "    Version file       : $(pyenv version-file)"
echo ========================================
echo "* python Usage        : $(python --version | head -n 1)"
echo "* genesis-world Usage : $(pip show genesis-world | grep Version)"
echo "* numpy Usage         : $(pip show numpy | grep Version | head -n 1)"
echo "* taichi Usage        : $(pip show taichi | grep Version)"
echo "* CoACD Usage         : $(pip show coacd | grep Version)"
echo "* vtk Usage           : $(pip show vtk | grep Version)"
echo "* libigl Usage        : $(pip show libigl | grep Version)"
echo "* tetgen Usage        : $(pip show tetgen | grep Version)"
echo "* pymeshlab Usage     : $(pip show pymeshlab | grep Version)"
echo "* pyvista Usage       : $(pip show pyvista | grep Version)"

echo "* black Usage         : $(pip show black | grep Version)"
echo "* freetype-py Usage   : $(pip show freetype-py | grep Version)"
echo "* lxml Usage          : $(pip show lxml | grep Version)"
echo "* moviepy Usage       : $(pip show moviepy | grep Version)"
echo "* mujoco Usage        : $(pip show mujoco | grep Version)"
echo "* numba Usage         : $(pip show numba | grep Version)"
echo "* OpenCV Usage        : $(pip show opencv-python | grep Version)"
echo "* OpenEXR Usage       : $(pip show OpenEXR | grep Version)"
echo "* psutil Usage        : $(pip show psutil | grep Version)"
echo "* pycollada Usage     : $(pip show pycollada | grep Version)"
echo "* pydantic Usage      : $(pip show pydantic | grep Version)"
echo "* PyGEL3D Usage       : $(pip show PyGEL3D | grep Version)"
echo "* pyglet Usage        : $(pip show pyglet | grep Version)"
echo "* pygltflib Usage     : $(pip show pygltflib | grep Version)"
echo "* PyOpenGL Usage      : $(pip show PyOpenGL | grep Version)"
echo "* scikit-image Usage  : $(pip show scikit-image | grep Version)"
echo "* screeninfo Usage    : $(pip show screeninfo | grep Version)"
echo "* six Usage           : $(pip show six | grep Version)"

echo ========================================
PRINT_TEXT=$(pip show torch | grep Version)
RESULT=$?
if [[ ${RESULT} -eq 0 ]];then
    echo "* pytorch Usage       : ${PRINT_TEXT}"
    echo "    CUDA version      : $(python -c "import torch;print(torch.version.cuda);")"
    echo "    cuDNN version     : $(python -c "import torch;print(torch.backends.cudnn.version());")"
    echo "    CUDA available    : $(python -c "import torch;print(torch.cuda.is_available());")"
    echo "    torchvision Usage : $(pip show torchvision | grep Version)"
    echo "    torchaudio Usage  : $(pip show torchaudio | grep Version)"
else
    echo "* pytorch Usage       : NOT installed"
    echo "[ERROR] pytorch is not installed." >&2
fi
echo "* OpenCV Usage        : $(python -c "import cv2;print(cv2.__version__);")"
#echo "* tensorflow Usage    : $(python -c "import tensorflow;print(tensorflow.__version__);")"

exit ${RESULT}
