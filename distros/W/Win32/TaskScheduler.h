//standard MS headers
#include <windows.h>
#include <ole2.h>
#include <mstask.h>
#include <msterr.h>
#include <wtypes.h>
#include <tchar.h>

//#include <wchar.h>
//#include <initguid.h>

// perl headers
#include <EXTERN.h>
#include <perl.h>
#include <XSub.h>
#include "TConvert.h"
#include "misc.h"

#ifndef TASKSCHEDULER
#define TASKSCHEDULER

#define TASKS_TO_RETRIEVE     5
#define TOTAL_RUN_TIME_TO_FETCH     10

// set to 1 to enable debugging information
#define TSK_DEBUG 0

// define some hanby stuff for working with
// triggers

#define MY_TASK_SUNDAY "TASK_SUNDAY"
#define MY_TASK_SUNDAY_LEN 11;

#define MY_TASK_MONDAY "TASK_MONDAY"
#define MY_TASK_MONDAY_LEN 11

#define MY_TASK_TUESDAY "TASK_TUESDAY"
#define MY_TASK_TUESDAY_LEN 12

#define MY_TASK_WEDNESDAY "TASK_WEDNESDAY"
#define MY_TASK_WEDNESDAY_LEN 14

#define MY_TASK_THURSDAY "TASK_THURSDAY"
#define MY_TASK_THURSDAY_LEN 13

#define MY_TASK_FRIDAY "TASK_FRIDAY"
#define MY_TASK_FRIDAY_LEN 11

#define MY_TASK_SATURDAY "TASK_SATURDAY"
#define MY_TASK_SATURDAY_LEN 13

#define MY_TASK_FIRST_WEEK "TASK_FIRST_WEEK"
#define MY_TASK_FIRST_WEEK_LEN 15

#define MY_TASK_SECOND_WEEK "TASK_SECOND_WEEK"
#define MY_TASK_SECOND_WEEK_LEN 16

#define MY_TASK_THIRD_WEEK "TASK_THIRD_WEEK"
#define MY_TASK_THIRD_WEEK_LEN 15

#define MY_TASK_FOURTH_WEEK "TASK_FOURTH_WEEK"
#define MY_TASK_FOURTH_WEEK_LEN 16

#define MY_TASK_LAST_WEEK "TASK_LAST_WEEK"
#define MY_TASK_LAST_WEEK_LEN 14

#define MY_TASK_JANUARY "TASK_JANUARY"
#define MY_TASK_JANUARY_LEN 12

#define MY_TASK_FEBRUARY "TASK_FEBRUARY"
#define MY_TASK_FEBRUARY_LEN 13

#define MY_TASK_MARCH "TASK_MARCH"
#define MY_TASK_MARCH_LEN 10

#define MY_TASK_APRIL "TASK_APRIL"
#define MY_TASK_APRIL_LEN 10

#define MY_TASK_MAY "TASK_MAY"
#define MY_TASK_MAY_LEN 8

#define MY_TASK_JUNE "TASK_JUNE"
#define MY_TASK_JUNE_LEN 9

#define MY_TASK_JULY "TASK_JULY"
#define MY_TASK_JULY_LEN 9

#define MY_TASK_AUGUST "TASK_AUGUST"
#define MY_TASK_AUGUST_LEN 11

#define MY_TASK_SEPTEMBER "TASK_SEPTEMBER"
#define MY_TASK_SEPTEMBER_LEN 14

#define MY_TASK_OCTOBER "TASK_OCTOBER"
#define MY_TASK_OCTOBER_LEN 12

#define MY_TASK_NOVEMBER "TASK_NOVEMBER"
#define MY_TASK_NOVEMBER_LEN 13

#define MY_TASK_DECEMBER "TASK_DECEMBER"
#define MY_TASK_DECEMBER_LEN 13

#define MY_TASK_FLAG_INTERACTIVE "TASK_FLAG_INTERACTIVE"
#define MY_TASK_FLAG_INTERACTIVE_LEN 21

#define MY_TASK_FLAG_DELETE_WHEN_DONE "TASK_FLAG_DELETE_WHEN_DONE"
#define MY_TASK_FLAG_DELETE_WHEN_DONE_LEN 26

#define MY_TASK_FLAG_DISABLED "TASK_FLAG_DISABLED"
#define MY_TASK_FLAG_DISABLED_LEN 18

#define MY_TASK_FLAG_START_ONLY_IF_IDLE "TASK_FLAG_START_ONLY_IF_IDLE"
#define MY_TASK_FLAG_START_ONLY_IF_IDLE_LEN 28

#define MY_TASK_FLAG_KILL_ON_IDLE_END "TASK_FLAG_KILL_ON_IDLE_END"
#define MY_TASK_FLAG_KILL_ON_IDLE_END_LEN 26

#define MY_TASK_FLAG_DONT_START_IF_ON_BATTERIES "TASK_FLAG_DONT_START_IF_ON_BATTERIES"
#define MY_TASK_FLAG_DONT_START_IF_ON_BATTERIES_LEN 36

#define MY_TASK_FLAG_KILL_IF_GOING_ON_BATTERIES "TASK_FLAG_KILL_IF_GOING_ON_BATTERIES"
#define MY_TASK_FLAG_KILL_IF_GOING_ON_BATTERIES_LEN 36

#define MY_TASK_FLAG_RUN_ONLY_IF_DOCKED "TASK_FLAG_RUN_ONLY_IF_DOCKED"
#define MY_TASK_FLAG_RUN_ONLY_IF_DOCKED_LEN 28

#define MY_TASK_FLAG_HIDDEN "TASK_FLAG_HIDDEN"
#define MY_TASK_FLAG_HIDDEN_LEN 16

#define MY_TASK_FLAG_RUN_IF_CONNECTED_TO_INTERNET "TASK_FLAG_RUN_IF_CONNECTED_TO_INTERNET"
#define MY_TASK_FLAG_RUN_IF_CONNECTED_TO_INTERNET_LEN 38

#define MY_TASK_FLAG_RESTART_ON_IDLE_RESUME "TASK_FLAG_RESTART_ON_IDLE_RESUME"
#define MY_TASK_FLAG_RESTART_ON_IDLE_RESUME_LEN 32

#define MY_TASK_FLAG_SYSTEM_REQUIRED "TASK_FLAG_SYSTEM_REQUIRED"
#define MY_TASK_FLAG_SYSTEM_REQUIRED_LEN 25

#define MY_TASK_TRIGGER_FLAG_HAS_END_DATE "TASK_TRIGGER_FLAG_HAS_END_DATE"
#define MY_TASK_TRIGGER_FLAG_HAS_END_DATE_LEN 30

#define MY_TASK_TRIGGER_FLAG_KILL_AT_DURATION_END "TASK_TRIGGER_FLAG_KILL_AT_DURATION_END"
#define MY_TASK_TRIGGER_FLAG_KILL_AT_DURATION_END_LEN 38

#define MY_TASK_TRIGGER_FLAG_DISABLED "TASK_TRIGGER_FLAG_DISABLED"
#define MY_TASK_TRIGGER_FLAG_DISABLED_LEN 26

#define MY_TASK_MAX_RUN_TIMES "TASK_MAX_RUN_TIMES"
#define MY_TASK_MAX_RUN_TIMES_LEN 18

#define MY_REALTIME_PRIORITY_CLASS "REALTIME_PRIORITY_CLASS"
#define MY_REALTIME_PRIORITY_CLASS_LEN 23

#define MY_HIGH_PRIORITY_CLASS "HIGH_PRIORITY_CLASS"
#define MY_HIGH_PRIORITY_CLASS_LEN 19

#define MY_NORMAL_PRIORITY_CLASS "NORMAL_PRIORITY_CLASS"
#define MY_NORMAL_PRIORITY_CLASS_LEN 21

#define MY_IDLE_PRIORITY_CLASS "IDLE_PRIORITY_CLASS"
#define MY_IDLE_PRIORITY_CLASS_LEN 19

#define MY_INFINITE "INFINITE"
#define MY_INFINITE_LEN 8

#define MY_BeginYear "BeginYear"
#define MY_BeginYear_LEN 9

#define MY_BeginMonth "BeginMonth"
#define MY_BeginMonth_LEN 10

#define MY_BeginDay "BeginDay"
#define MY_BeginDay_LEN 8

#define MY_EndYear "EndYear"
#define MY_EndYear_LEN 7

#define MY_EndMonth "EndMonth"
#define MY_EndMonth_LEN 8

#define MY_EndDay "EndDay"
#define MY_EndDay_LEN 6

#define MY_StartHour "StartHour"
#define MY_StartHour_LEN 9

#define MY_StartMinute "StartMinute"
#define MY_StartMinute_LEN 11

#define MY_MinutesDuration "MinutesDuration"
#define MY_MinutesDuration_LEN 15

#define MY_MinutesInterval "MinutesInterval"
#define MY_MinutesInterval_LEN 15

#define MY_Flags "Flags"
#define MY_Flags_LEN 5

#define MY_TriggerType "TriggerType"
#define MY_TriggerType_LEN 11

#define MY_Type "Type"
#define MY_Type_LEN 4

#define MY_RandomMinutesInterval "RandomMinutesInterval"
#define MY_RandomMinutesInterval_LEN 21

#define MY_DaysInterval "DaysInterval"
#define MY_DaysInterval_LEN 12

#define MY_WeeksInterval "WeeksInterval"
#define MY_WeeksInterval_LEN 13

#define MY_DaysOfTheWeek "DaysOfTheWeek"
#define MY_DaysOfTheWeek_LEN 13

#define MY_Days "Days"
#define MY_Days_LEN 4

#define MY_Months "Months"
#define MY_Months_LEN 6

#define MY_WhichWeek "WhichWeek"
#define MY_WhichWeek_LEN 9

#endif
