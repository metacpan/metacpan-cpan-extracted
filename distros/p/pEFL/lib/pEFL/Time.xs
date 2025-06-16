#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

typedef struct _Efl_Time {
    int tm_sec;
    int tm_min;
    int tm_hour;
    int tm_mday;
    int tm_mon;
    int tm_year;
    int tm_wday;
    int tm_yday;
    int tm_isdst;
} EflTime;


MODULE = pEFL::Time		PACKAGE = pEFL::Time

EflTime *
new(class,sec,min,hour,mday,mon,year,wday,yday,isdst)
	char *class
	int sec 
	int min 
	int hour 
	int mday
	int mon 
	int year
	int wday
	int yday 
	int isdst
PREINIT:
	EflTime *tmpbuf;
CODE:
	New(0, tmpbuf, 1, EflTime);
	
	// Init EflTime struct
	tmpbuf->tm_sec = sec;
	tmpbuf->tm_min = min;
	tmpbuf->tm_hour = hour;
	tmpbuf->tm_mday = mday;
	tmpbuf->tm_mon = mon;
	tmpbuf->tm_year = year;
	tmpbuf->tm_wday = wday;
	tmpbuf->tm_yday = yday;
	tmpbuf->tm_isdst = isdst;
	
	RETVAL = tmpbuf;
OUTPUT: 
	RETVAL
	

MODULE = pEFL::Time		PACKAGE = pEFLTimePtr

int
tm_sec(time)
    EflTime *time
CODE:
    RETVAL = time->tm_sec;
OUTPUT:
    RETVAL

int
tm_min(time)
    EflTime *time
CODE:
    RETVAL = time->tm_min;
OUTPUT:
    RETVAL
    
int
tm_hour(time)
    EflTime *time
CODE:
    RETVAL = time->tm_hour;
OUTPUT:
    RETVAL
    
int
tm_mday(time)
    EflTime *time
CODE:
    RETVAL = time->tm_mday;
OUTPUT:
    RETVAL
    
int
tm_mon(time)
    EflTime *time
CODE:
    RETVAL = time->tm_mon;
OUTPUT:
    RETVAL
    
int
tm_year(time)
    EflTime *time
CODE:
    RETVAL = time->tm_year;
OUTPUT:
    RETVAL
    
int
tm_wday(time)
    EflTime *time
CODE:
    RETVAL = time->tm_wday;
OUTPUT:
    RETVAL
    
int
tm_yday(time)
    EflTime *time
CODE:
    RETVAL = time->tm_yday;
OUTPUT:
    RETVAL
    
int
tm_isdst(time)
    EflTime *time
CODE:
    RETVAL = time->tm_isdst;
OUTPUT:
    RETVAL
