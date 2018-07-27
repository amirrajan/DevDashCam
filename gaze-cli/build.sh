clang gaze.c -I. -o gaze-cli -L./lib -ltobii_research
LD_LIBRARY_PATH=./lib ./gaze-cli
