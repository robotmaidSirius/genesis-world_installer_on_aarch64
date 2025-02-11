#!/bin/bash
## TODO: インストールできるか未検証
INSTALL_VER=4.8.0
INSTALL_ROOT=~/genesis

while [[ $# -gt 0 ]]; do
  case "$1" in
    -h|--help)
        echo "Usage: $0 -v|--ver [version] -p|--root [path]"
        exit 0;;
    -v=*|--ver=*)
        INSTALL_VER=${1#*=}
        shift;;
    -v|--ver)
        shift
        INSTALL_VER=$1
        shift;;
    -p=*|--root=*)
        INSTALL_ROOT=${1#*=}
        shift;;
    -p|--root)
        shift
        INSTALL_ROOT=$1
        shift;;
    *) echo "Unknown parameter passed: $1"; shift;;
  esac
done
# ========================================

mkdir -p ${INSTALL_ROOT}
pushd "${INSTALL_ROOT}" >/dev/null 2>&1

sudo find / -name " *opencv* " -exec rm -i {} \;
sudo apt purge libopencv-dev libopencv-python libopencv-samples libopencv*

pkg-config --modversion opencv

```bash
sudo apt-get update
sudo apt-get install -y build-essential cmake git libgtk2.0-dev pkg-config libavcodec-dev
sudo apt-get install -y libavformat-dev libswscale-dev
sudo apt-get install -y libgstreamer1.0-dev libgstreamer-plugins-base1.0-dev
sudo apt-get install -y python2.7-dev python3.6-dev python-dev python-numpy python3-numpy
sudo apt-get install -y libtbb2 libtbb-dev libjpeg-dev libpng-dev libtiff-dev libdc1394-22-dev
sudo apt-get install -y libv4l-dev v4l-utils qv4l2 v4l2ucp
sudo apt-get update
```


```bash
curl -L https://github.com/opencv/opencv/archive/4.1.1.zip -o opencv-4.1.1.zip
curl -L https://github.com/opencv/opencv_contrib/archive/4.1.1.zip -o opencv_contrib-4.1.1.zip
unzip opencv-4.1.1.zip
unzip opencv_contrib-4.1.1.zip
cd opencv-4.1.1/
sed -i 's/include <Eigen\/Core>/include <eigen3\/Eigen\/Core>/g' modules/core/include/opencv2/core/private.hpp
mkdir release && cd release/
```


```bash
cmake -D WITH_CUDA=ON -D CUDA_ARCH_BIN="5.3,6.2,7.2" -D CUDA_ARCH_PTX="" -D OPENCV_EXTRA_MODULES_PATH=../../opencv_contrib-4.1.1/modules -D WITH_GSTREAMER=ON -D WITH_LIBV4L=ON -D BUILD_opencv_python2=ON -D BUILD_opencv_python3=ON -D BUILD_TESTS=OFF -D BUILD_PERF_TESTS=OFF -D BUILD_EXAMPLES=OFF -D CMAKE_BUILD_TYPE=RELEASE -D CMAKE_INSTALL_PREFIX=/usr/local ..
make -j $(nproc)
sudo make install

echo 'export PYTHONPATH=$PYTHONPATH:'$PWD'/python_loader/' >> ~/.bashrc
source ~/.bashrc
```



popd >/dev/null 2>&1


sudo apt update
sudo apt upgrade

sudo apt -y install cmake cmake-curses-gui
sudo apt -y install python3-dev python3-pip
sudo apt -y install libtbb-dev
sudo apt -y install libhdf5-dev libhdf5-serial-dev gfortran libtesseract-dev libleptonica-dev libatlas-base-dev liblapacke-dev
sudo apt -y install libeigen3-dev
sudo apt -y install libjpeg9-dev libpng-dev libpng++-dev
#sudo apt -y install libjasper-dev
sudo apt -y install libtiff5-dev libtiff-dev
sudo apt -y install ffmpeg
sudo apt -y install libavcodec-dev libavformat-dev libswscale-dev libdc1394-22-dev libavresample-dev
sudo apt -y install libvorbis-dev libxvidcore-dev libx264-dev libxvidcore-dev
sudo apt -y install libopencore-amrnb-dev libopencore-amrwb-dev
sudo apt -y install libxine2-dev libv4l-dev
sudo apt -y install libgstreamer1.0-dev libgstreamer-plugins-base1.0-dev gstreamer1.0-plugins-*
sudo apt -y install libgtk2.0-dev
sudo apt -y install libgtk-3-dev libcanberra-gtk*
# sudo apt -y install libqtgui4 libqtwebkit4 libqt4-test libqt4-dev libqt4-opengl-dev python3-pyqt5

## workaround for libhdf5 ##
# sudo ln -s /usr/lib/arm-linux-gnueabihf/libhdf5_serial.so /usr/lib/arm-linux-gnueabihf/libhdf5.so
# sudo ln -s /usr/lib/arm-linux-gnueabihf/libhdf5_serial_hl.so /usr/lib/arm-linux-gnueabihf/libhdf5_hl.so



### OpenCVコードの取得 ###

WORK_DIR="${HOME}/software"
mkdir -p ${WORK_DIR}
cd ${WORK_DIR}

cvVersion="4.2.0"

git clone https://github.com/opencv/opencv.git ${WORK_DIR}/opencv
cd opencv
git checkout $cvVersion
cd ..

### opencv_contribもビルドしたい場合 ###
git clone https://github.com/opencv/opencv_contrib.git ${WORK_DIR}/opencv_contrib
cd opencv_contrib
git checkout $cvVersion
cd ..

### Openビルド設定 ###
cd ${WORK_DIR}/opencv
mkdir build
cd build

cmake \
    -D CMAKE_BUILD_TYPE=RELEASE \
    -D CMAKE_INSTALL_PREFIX=/usr/local \
    -D OPENCV_GENERATE_PKGCONFIG=ON \
    -D ENABLE_NEON=ON \
    -D WITH_TBB=ON \
    -D WITH_V4L=ON \
    -D WITH_GSTREAMER=ON \
    -D WITH_FFMPEG=ON \
    -D WITH_QT=OFF \
    -D WITH_GTK=ON \
    -D WITH_GTK3=ON \
    -D WITH_CUDA=ON \
    -D OPENCV_EXTRA_MODULES_PATH=../../opencv_contrib/modules \
    ..

### OpenCVビルド、インストール ###
make -j $(nproc)
sudo make install
sudo ldconfig

export PATH=/usr/local/cuda-11.4/bin:$PATH
export PATH=$PATH:/usr/local/nodejs/bin


export BODYPOSE3D_HOME=/opt/nvidia/deepstream/deepstream/sources/apps/sample_apps/deepstream_reference_apps/deepstream-bodypose-3d

#OpenCV_4.2.0
export PKG_CONFIG_PATH=/home/jetson/opencv4/lib/pkgconfig
export LD_LIBRARY_PATH=/home/jetson/opencv4/lib
export OpenCV_CONFIG_PATH=/home/jetson/opencv4/lib/pkgconfig

export LD_LIBRARY_PATH=/usr/local/cuda-11.4/lib64:$LD_LIBRARY_PATH

exit ${RESULT}
