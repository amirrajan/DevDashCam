mkdir -p ~/.devdashcam
if [ ! -f "$HOME/.devdashcam/se_license_key_process_devdashcam" ]; then
  cp ../Licenses/se_license_key_process_devdashcam ~/.devdashcam/
fi

cp ./run-gaze-cli /usr/local/bin/

clang gaze.c -I. -o "Dev Dash Cam" -L./lib -ltobii_research
LD_LIBRARY_PATH=./lib ./Dev\ Dash\ Cam
