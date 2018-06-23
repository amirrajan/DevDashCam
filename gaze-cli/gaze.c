#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <inttypes.h>
#include "tobii_research_eyetracker.h"
#include "tobii_research_streams.h"
#include "tobii_research_calibration.h"

#if _WIN32 || _WIN64
#include <windows.h>
static void sleep_ms(int time) {
  Sleep(time);
}
#else
#include <unistd.h>
static void sleep_ms(int time) {
  usleep(time * 1000);
}
#endif
void gaze_data_callback(TobiiResearchGazeData* gaze_data, void* user_data) {
  memcpy(user_data, gaze_data, sizeof(*gaze_data));
}

void gaze_data_example(TobiiResearchEyeTracker* eyetracker) {
  TobiiResearchGazeData gaze_data;
  char* serial_number;
  tobii_research_get_serial_number(eyetracker, &serial_number);
  /* printf("Subscribing to gaze data for eye tracker with serial number %s.\n", serial_number); */
  tobii_research_free_string(serial_number);
  TobiiResearchStatus status = tobii_research_subscribe_to_gaze_data(eyetracker, gaze_data_callback, &gaze_data);
  if (status != TOBII_RESEARCH_STATUS_OK)
    return;
  /* Wait while some gaze data is collected. */
  sleep_ms(500);
  status = tobii_research_unsubscribe_from_gaze_data(eyetracker, gaze_data_callback);
  /* printf("Unsubscribed from gaze data with status %i.\n", status); */
  /* printf("Last received gaze package:\n"); */
  /* printf("System time stamp: %"  PRId64 "\n", gaze_data.system_time_stamp); */
  /* printf("Device time stamp: %"  PRId64 "\n", gaze_data.device_time_stamp); */
  printf("%f,%f\n",
	 gaze_data.left_eye.gaze_point.position_on_display_area.x,
	 gaze_data.left_eye.gaze_point.position_on_display_area.y);
  /* printf("Right eye 3d gaze origin in user coordinates (%f, %f, %f)\n", */
  /* 	 gaze_data.right_eye.gaze_origin.position_in_user_coordinates.x, */
  /* 	 gaze_data.right_eye.gaze_origin.position_in_user_coordinates.y, */
  /* 	 gaze_data.right_eye.gaze_origin.position_in_user_coordinates.z); */
}

int main()
{
  TobiiResearchEyeTrackers* eyetrackers = NULL;
  TobiiResearchStatus result;
  size_t i = 0;
  result = tobii_research_find_all_eyetrackers(&eyetrackers);
  if (result != TOBII_RESEARCH_STATUS_OK) {
    printf("Finding trackers failed. Error: %d\n", result);
    return result;
  }
  for (i = 0; i < eyetrackers->count; i++) {
    TobiiResearchEyeTracker* eyetracker = eyetrackers->eyetrackers[i];
    char* address;
    char* serial_number;
    char* device_name;
    tobii_research_get_address(eyetracker, &address);
    tobii_research_get_serial_number(eyetracker, &serial_number);
    tobii_research_get_device_name(eyetracker, &device_name);
    /* printf("%s\t%s\t%s\n", address, serial_number, device_name); */
    tobii_research_free_string(address);
    tobii_research_free_string(serial_number);
    tobii_research_free_string(device_name);
  }
  /* printf("Found %d Eye Trackers \n\n", (int)eyetrackers->count); */

  TobiiResearchEyeTracker* first_tracker = eyetrackers->eyetrackers[0];
  gaze_data_example(first_tracker);

  return 0;
}
