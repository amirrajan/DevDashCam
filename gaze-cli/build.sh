mkdir -p ~/.devdashcam
if [ ! -f "$HOME/.devdashcam/se_license_key_process_devdashcam" ]; then
  cp ../Licenses/se_license_key_process_devdashcam ~/.devdashcam/
fi

clang gaze.c -arch x86_64 -I. -o "Dev Dash Cam" -L./lib -ltobii_research

sudo cp ./lib/libtobii_research.dylib /usr/local/lib
sudo cp ./Dev\ Dash\ Cam /usr/local/bin/

./Dev\ Dash\ Cam
