#!/bin/bash
## TODO: Installation is unverified
INSTALL_VER=4.8.0
INSTALL_ROOT=~/genesis
INSTALL_WITH_APT=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    -h|--help)
        echo "Usage: $0 -v|--ver [version] -p|--root [path]"
        exit 0;;
    --with_apt)
        INSTALL_WITH_APT=1
        shift;;
    -v=*|--ver=*)
        INSTALL_VER=${1#*=}
        shift;;
    -v|--ver)
        shift
        INSTALL_VER=$1
        shift;;
    -p=*|--root=*)
        if [ "" != "${1#*=}" ];then
            INSTALL_ROOT=${1#*=}
        fi
        shift;;
    -p|--root)
        shift
        if [ "" != "$1" ];then
            INSTALL_ROOT=$1
        fi
        shift;;
    *) echo "[WARNING] Unknown parameter passed: $1" >&2; shift;;
  esac
done
if [ "" == "${INSTALL_VER}" ];then
    echo "[WARNING] Since no version was specified, the installation was skipped." >&2
    exit 0
fi
# pkg-config --modversion opencv
CURRENT_VER=$(python -c "import cv2;print(cv2.__version__)")
if [[ "${CURRENT_VER}" =~ "${INSTALL_VER#v}" ]]; then
    echo "[SKIP] ${CURRENT_VER} is already installed"
    exit 0
fi

INSTALL_URL_OPENCV=https://github.com/opencv/opencv/archive/${INSTALL_VER#v}.zip
INSTALL_URL_OPENCV_CONTRIB=https://github.com/opencv/opencv_contrib/archive/${INSTALL_VER#v}.zip
INSTALL_DIR_OPENCV=${INSTALL_ROOT}/opencv
RESULT=0
# ========================================

if [ ${INSTALL_WITH_APT} -eq 1 ]; then
    sudo apt -y purge *libopencv*
    # sudo find / -name " *opencv* " -exec rm -i {} \;
    sudo apt install -y build-essential git libgtk2.0-dev pkg-config libavcodec-dev cmake-curses-gui
    sudo apt install -y libavformat-dev libswscale-dev
    sudo apt install -y libgstreamer1.0-dev libgstreamer-plugins-base1.0-dev gstreamer1.0-plugins-*
    sudo apt install -y python2.7-dev python3.6-dev python-dev python-numpy python3-numpy
    sudo apt install -y libtbb2 libtbb-dev libjpeg-dev libpng-dev libpng++-dev libtiff-dev libdc1394-22-dev
    sudo apt install -y libv4l-dev v4l-utils qv4l2
    #sudo apt install -y v4l2ucp

    sudo apt install -y libhdf5-dev libhdf5-serial-dev gfortran libtesseract-dev libleptonica-dev libatlas-base-dev liblapacke-dev
    sudo apt install -y libeigen3-dev libpng-dev libpng++-dev
    #sudo apt install -y libjasper-dev libjpeg9-dev
    sudo apt install -y libtiff5-dev libtiff-dev
    sudo apt install -y ffmpeg
    sudo apt install -y libavresample-dev
    sudo apt install -y libvorbis-dev libxvidcore-dev libx264-dev libxvidcore-dev
    sudo apt install -y libopencore-amrnb-dev libopencore-amrwb-dev
    sudo apt install -y libxine2-dev
    sudo apt install -y libgtk-3-dev libcanberra-gtk*
    #sudo apt install -y libqtgui4 libqtwebkit4 libqt4-dev libqt4-test libqt4-dev libqt4-opengl-dev python3-pyqt5
fi

# sudo ln -s /usr/lib/arm-linux-gnueabihf/libhdf5_serial.so /usr/lib/arm-linux-gnueabihf/libhdf5.so
# sudo ln -s /usr/lib/arm-linux-gnueabihf/libhdf5_serial_hl.so /usr/lib/arm-linux-gnueabihf/libhdf5_hl.so
# ========================================

mkdir -p ${INSTALL_ROOT}
pushd "${INSTALL_ROOT}" >/dev/null 2>&1
    mkdir -p ${INSTALL_DIR_OPENCV}
    pushd "${INSTALL_DIR_OPENCV}" >/dev/null 2>&1

    ## wget opencv-${INSTALL_VER}.zip
    if [ ! -d "${INSTALL_DIR_OPENCV}/opencv-${INSTALL_VER}" ]; then
        echo wget ${INSTALL_URL_OPENCV} -O opencv-${INSTALL_VER}.zip
        wget ${INSTALL_URL_OPENCV} -O opencv-${INSTALL_VER}.zip
        RESULT=$?
        if [ ${RESULT} -ne 0 ]; then
            echo "[ERROR] Failed to download opencv-${INSTALL_VER}.zip" >&2
            exit ${RESULT}
        fi
        unzip -q opencv-${INSTALL_VER}.zip
        rm opencv-${INSTALL_VER}.zip
        if [ ! -e "${INSTALL_DIR_OPENCV}/opencv-${INSTALL_VER}" ]; then
            echo "[ERROR] Failed to extract opencv-${INSTALL_VER}.zip" >&2
            RESULT=1
            exit ${RESULT}
        fi
    fi
    ## wget opencv_contrib-${INSTALL_VER}.zip
    if [ ! -d "${INSTALL_DIR_OPENCV}/opencv_contrib-${INSTALL_VER}" ]; then
        echo wget ${INSTALL_URL_OPENCV_CONTRIB} -O opencv_contrib-${INSTALL_VER}.zip
        wget ${INSTALL_URL_OPENCV_CONTRIB} -O opencv_contrib-${INSTALL_VER}.zip
        RESULT=$?
        if [ ${RESULT} -ne 0 ]; then
            echo "[ERROR] Failed to download opencv_contrib-${INSTALL_VER}.zip" >&2
            exit ${RESULT}
        fi
        unzip -q opencv_contrib-${INSTALL_VER}.zip
        rm opencv_contrib-${INSTALL_VER}.zip
        if [ ! -e "${INSTALL_DIR_OPENCV}/opencv_contrib-${INSTALL_VER}" ]; then
            echo "[ERROR] Failed to extract opencv-${INSTALL_VER}.zip" >&2
            RESULT=1
            exit ${RESULT}
        fi
    fi

    ## Build opencv-${INSTALL_VER}
    if [ -d "${INSTALL_DIR_OPENCV}/opencv-${INSTALL_VER}" ]; then
        #sed -i 's/include <Eigen\/Core>/include <eigen3\/Eigen\/Core>/g' opencv-${INSTALL_VER}/modules/core/include/opencv2/core/private.hpp
        mkdir -p build
        pushd "build" >/dev/null 2>&1
            # Jetson Nano : CUDA_ARCH_BIN="5.3,6.2,7.2"
            cmake -D WITH_CUDA=ON \
                -D WITH_CUDNN=ON \
                -D CUDA_ARCH_BIN="7.2,8.7" \
                -D CUDA_ARCH_PTX="" \
                -D OPENCV_GENERATE_PKGCONFIG=ON \
                -D OPENCV_EXTRA_MODULES_PATH=../opencv_contrib-${INSTALL_VER}/modules \
                -D WITH_GSTREAMER=ON \
                -D WITH_LIBV4L=ON \
                -D BUILD_opencv_python3=ON \
                -D BUILD_TESTS=OFF \
                -D BUILD_PERF_TESTS=OFF \
                -D BUILD_EXAMPLES=OFF \
                -D CMAKE_BUILD_TYPE=RELEASE \
                -D CMAKE_INSTALL_PREFIX=/usr/local \
                        -D ENABLE_NEON=ON \
                        -D WITH_TBB=ON \
                        -D WITH_V4L=ON \
                        -D WITH_FFMPEG=ON \
                        -D WITH_QT=OFF \
                        -D WITH_GTK=ON \
                        -D WITH_GTK3=ON \
                ../opencv-${INSTALL_VER}
            RESULT=$?
            if [ ${RESULT} -eq 0 ]; then
                make -j $(nproc)
                RESULT=$?
            fi
            if [ ${RESULT} -eq 0 ]; then
                sudo make install
                RESULT=$?
            fi
            #if [ ${RESULT} -eq 0 ]; then
                #echo 'export LD_LIBRARY_PATH=/usr/local/lib:$LD_LIBRARY_PATH' >> ~/.bashrc
                #echo 'export PYTHONPATH=/usr/local/lib/python3.8/site-packages/:$PYTHONPATH' >> ~/.bashrc
                #export PKG_CONFIG_PATH=/home/jetson/opencv4/lib/pkgconfig
                #export LD_LIBRARY_PATH=/home/jetson/opencv4/lib
                #export OpenCV_CONFIG_PATH=/home/jetson/opencv4/lib/pkgconfig
                #echo "export PKG_CONFIG_PATH=/usr/local/lib/pkgconfig"
            #fi
            if [ ${RESULT} -eq 0 ]; then
                sudo ldconfig
            fi
        popd >/dev/null 2>&1
    else
        RESULT=1
    fi
    popd >/dev/null 2>&1
popd >/dev/null 2>&1

exit ${RESULT}
