mkdir -p build
cd build

if [ "$1" = "test" ]
    then
    cmake .. -DBUILD_TESTS=ON
    else
    cmake ..
fi

make VERBOSE=1
