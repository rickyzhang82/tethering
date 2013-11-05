mkdir -p build
cd build

if [ "$1" = "HAVE_COCOA" ]
    then
    cmake .. -DHAVE_COCOA=ON
    else
    cmake ..
fi

make VERBOSE=1
