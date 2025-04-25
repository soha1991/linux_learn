if [[ "$(uname)" == "Linux" ]]; then
    make ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu-
elif [[ "$(uname)" == "Darwin" ]]; then
    make ARCH=arm64 CROSS_COMPILE=aarch64-rpi3-linux-gnu-
fi
