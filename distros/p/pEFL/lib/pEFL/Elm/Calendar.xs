#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include <Elementary.h>


typedef Evas_Object ElmCalendar;
typedef Evas_Object EvasObject;
typedef Efl_Time EflTime;
typedef Eina_List EinaList;


MODULE = pEFL::Elm::Calendar		PACKAGE = pEFL::Elm::Calendar

ElmCalendar *
elm_calendar_add(parent)
    EvasObject *parent

MODULE = pEFL::Elm::Calendar		PACKAGE = ElmCalendarPtr     PREFIX = elm_calendar_

void
elm_calendar_mark_del(mark)
	Elm_Calendar_Mark *mark


void
elm_calendar_min_max_year_set(obj,min,max)
	ElmCalendar *obj
	int min
	int max


void
elm_calendar_min_max_year_get(obj,OUTLIST min,OUTLIST max)
	const ElmCalendar *obj
	int min
	int max

void
elm_calendar_first_day_of_week_set(obj,day)
	ElmCalendar *obj
	int day


int
elm_calendar_first_day_of_week_get(obj)
	const ElmCalendar *obj


void
elm_calendar_selectable_set(obj,selectable)
	ElmCalendar *obj
	int selectable


int
elm_calendar_selectable_get(obj)
	const ElmCalendar *obj


void
elm_calendar_interval_set(obj,interval)
	ElmCalendar *obj
	double interval


double
elm_calendar_interval_get(obj)
	const ElmCalendar *obj


void
elm_calendar_weekdays_names_set(obj,pl_weekdays)
	ElmCalendar *obj
	AV *pl_weekdays
PREINIT:
    char *c_weekdays[7];
    STRLEN len;
    int i;
CODE:
{
    char* c_weekdays[7];
    STRLEN len;

    len = av_len(pl_weekdays);
    if (len != 6) {
        croak("You must pass an array with 7 elements\n");
    }


    for (i=0; i <=6; i++) {
        SV **svp = av_fetch((AV *) pl_weekdays, i, 0);

        if (SvOK(*svp) && SvPOK(*svp) ) {
            char* string = SvPV(*svp, len);
            /* c_weekdays[i] = (char *) malloc(len * sizeof(char) );
            if (c_weekdays[i] == NULL) {
                croak("Segmentation fault\n");
            }
            */
            Newz(0, c_weekdays[i],len, char);

            strcpy(c_weekdays[i],string);
            printf("Saved: %s\n",c_weekdays[i]);
        }
    }

    elm_calendar_weekdays_names_set(obj,(const char **) c_weekdays);
}
CLEANUP:
    for (i=0; i<= 6; i++) {
        Safefree(c_weekdays[i]);
    }


AV*
elm_calendar_weekdays_names_get(obj)
    ElmCalendar *obj
PREINIT:
    const char **c_weekdays;
    AV *pl_weekdays;
    int i;
    char *string;
CODE:
{
    c_weekdays = elm_calendar_weekdays_names_get(obj);
    pl_weekdays = newAV();
    for (i=0; i<=6;i++) {
        string = c_weekdays[i];
        av_push(pl_weekdays,(newSVpvn(string, 2)));
    }
    RETVAL = (AV *) pl_weekdays;
}
OUTPUT:
    RETVAL

void
elm_calendar_select_mode_set(obj,mode)
	ElmCalendar *obj
	int mode


int
elm_calendar_select_mode_get(obj)
	const ElmCalendar *obj


# signature: ElmCalendar_Format_Cb format_function
void
_elm_calendar_format_function_set(obj,format_function)
	ElmCalendar *obj
	SV* format_function
CODE:
    croak("elm_calendar_format_function_set is not yet implemented.\n");


EinaList *
elm_calendar_marks_get(obj)
	const ElmCalendar *obj


void
elm_calendar_date_min_set(obj,min)
	ElmCalendar *obj
	const EflTime *min


EflTime *
elm_calendar_date_min_get(obj)
	const ElmCalendar *obj


void
elm_calendar_date_max_set(obj,max)
	ElmCalendar *obj
	const EflTime *max


EflTime *
elm_calendar_date_max_get(obj)
	const ElmCalendar *obj


void
elm_calendar_selected_time_set(obj,selected_time)
	ElmCalendar *obj
	EflTime *selected_time


Eina_Bool
elm_calendar_selected_time_get(obj,selected_time)
	const ElmCalendar *obj
	EflTime *selected_time


Elm_Calendar_Mark *
elm_calendar_mark_add(obj,mark_type,mark_time,repeat)
	ElmCalendar *obj
	const char *mark_type
	EflTime *mark_time
	int repeat


void
elm_calendar_marks_clear(obj)
	ElmCalendar *obj


void
elm_calendar_marks_draw(obj)
	ElmCalendar *obj


Eina_Bool
elm_calendar_displayed_time_get(obj,displayed_time)
	const ElmCalendar *obj
	EflTime *displayed_time
