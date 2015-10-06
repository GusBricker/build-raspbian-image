#!/bin/bash

BannerEcho "OpenCV: Installing"

echo "OpenCV: Installing dependancies"
AptInstall build-essential git cmake pkg-config libjpeg8-dev libtiff4-dev ffmpeg libjasper-dev libpng12-dev libavcodec-dev libavformat-dev libswscale-dev libv4l-dev libgtk2.0-dev libatlas-base-dev gfortran python2.7-dev || return 1

echo "OpenCV: Getting OpenCV source"
# Not using 3.0.0 as it fails to build due to: http://stackoverflow.com/questions/31663498/opencv-3-0-0-make-error-with-ffmpeg
OPENCV_VERSION="959d5752926d1183f933c2583308b6d63bbbee41"
OPENCV_DIR=$(GetWorkspace opencv_src)
OPENCV_FILENAME="opencv_${OPENCV_VERSION}.tar.gz"
CheckDownload "https://github.com/Itseez/opencv/archive/${OPENCV_VERSION}.tar.gz" "${OPENCV_FILENAME}" || return 1
ExtractTar "${OPENCV_FILENAME}" "${OPENCV_DIR}"

echo "OpenCV: Getting OpenCV Contrib source"
OPENCV_CONTRIB_VERSION="3.0.0"
OPENCV_CONTRIB_DIR=$(GetWorkspace opencv_contrib_src)
OPENCV_CONTRIB_FILENAME="opencv_contrib_${OPENCV_CONTRIB_VERSION}.tar.gz"
CheckDownload "https://github.com/Itseez/opencv_contrib/archive/${OPENCV_CONTRIB_VERSION}.tar.gz" "${OPENCV_CONTRIB_FILENAME}" || return 1
ExtractTar "${OPENCV_CONTRIB_FILENAME}" "${OPENCV_CONTRIB_DIR}"

echo "OpenCV: Installing numpy"
PipInstall "numpy"

echo "OpenCV: Configuring OpenCV"
pushd ${OPENCV_DIR}
mkdir build
pushd build
cmake -D CMAKE_BUILD_TYPE=RELEASE \
    -D CMAKE_INSTALL_PREFIX=/usr/local \
    -D INSTALL_C_EXAMPLES=ON \
    -D INSTALL_PYTHON_EXAMPLES=ON \
    -D BUILD_OPENCV_PYTHON=ON \
    -D OPENCV_EXTRA_MODULES_PATH="${OPENCV_CONTRIB_DIR}" \
    -D BUILD_EXAMPLES=ON .. || return 1

echo "OpenCV: Building OpenCV"
make -j2 || return 1

echo "OpenCV: Install OpenCV"
make install || return 1
ldconfig || return 1

popd
popd

BannerEcho "OpenCV: Done"
