#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <inttypes.h>
#include "tobii_research_eyetracker.h"
#include "tobii_research_streams.h"
#include "tobii_research_calibration.h"

static
void sleep_ms (int time)
{
  usleep(time * 1000);
}

void
gaze_data_callback (TobiiResearchGazeData* gaze_data, void* user_data)
{
   memcpy(user_data,
	  gaze_data,
	  sizeof(*gaze_data));
}

void
gaze_data_example (TobiiResearchEyeTracker* eyetracker)
{
  TobiiResearchGazeData gaze_data;

  TobiiResearchStatus status =
    tobii_research_subscribe_to_gaze_data(eyetracker,
					  gaze_data_callback,
					  &gaze_data);

  if (status != TOBII_RESEARCH_STATUS_OK) { return; }

  while (1) {
    sleep_ms(500);

    printf("%f,%f\n",
	   gaze_data.left_eye.gaze_point.position_on_display_area.x,
	   gaze_data.left_eye.gaze_point.position_on_display_area.y);
    fflush(stdout);
  }

  status =
    tobii_research_unsubscribe_from_gaze_data(eyetracker,
					      gaze_data_callback);
}

int main ()
{
  TobiiResearchEyeTrackers* eyetrackers = NULL;

  TobiiResearchStatus result;

  size_t i = 0;

  result = tobii_research_find_all_eyetrackers(&eyetrackers);

  if (result != TOBII_RESEARCH_STATUS_OK) {
    printf("Finding trackers failed. Error: %d\n",
	   result);

    return result;
  }

  for (i = 0; i < eyetrackers->count; i++) {
    TobiiResearchEyeTracker* eyetracker =
      eyetrackers->eyetrackers[i];
  }

  TobiiResearchEyeTracker* first_tracker =
    eyetrackers->eyetrackers[0];

  gaze_data_example(first_tracker);

  return 0;
}
