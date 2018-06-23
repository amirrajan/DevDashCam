clang gaze.c `pkg-config --cflags --libs tobii_research` -I ./64/lib -o gaze-cli
LD_LIBRARY_PATH=./64/lib ./gaze-cli
