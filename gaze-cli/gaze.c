#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <inttypes.h>
#include "tobii_research_eyetracker.h"
#include "tobii_research_streams.h"
#include "tobii_research_calibration.h"
#include <wordexp.h>

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

void apply_license(TobiiResearchEyeTracker * eyetracker, const char * license_file_path) {
  #define NUM_OF_LICENSES 1
  char* license_key_ring[NUM_OF_LICENSES];
  FILE *license_file = fopen(license_file_path, "rb" );
  fseek(license_file, 0, SEEK_END);
  size_t file_size = (size_t)ftell(license_file);
  rewind(license_file);
  license_key_ring[0] = (char*)malloc(file_size);
  if(license_key_ring[0]) {
    fread( license_key_ring[0], sizeof(char), file_size, license_file );
  }
  fclose(license_file);
  TobiiResearchLicenseValidationResult validation_results;
  TobiiResearchStatus retval = tobii_research_apply_licenses(eyetracker, (const
									  void**)license_key_ring, &file_size, &validation_results, NUM_OF_LICENSES);
  free(license_key_ring[0]);
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

  /* wordexp_t exp_result; */
  /* wordexp("~/.devdashcam/license", &exp_result, 0); */

  /* apply_license(first_tracker, exp_result); */

  gaze_data_example(first_tracker);

  return 0;
}
