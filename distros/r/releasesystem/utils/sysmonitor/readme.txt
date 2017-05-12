README for sysmonitor and syscheck.cgi

# copyright 1996-2000 by hewlett-packard company
# may be distributed under the terms of the artistic license

sysmonitord
-----------

Sysmonitord is a system monitor daemon that reads a configuration file
syscheck.rc and periodically verifies the existance of the urls and
processes listed therein.  Each process or URL is listed one line at a
time in the following format within syscheck.rc:

id;semaphore file;process regex;url;fail/restart command;email; subject 
line; threshold; error regex; operating hours

id            : arbitrary (and unique) id for this process or URL
semaphore file: the absolute path of a semaphore file which will be created
		if the process or URL is in an error condition
process regex : the regular expression (perl format) which must match a 
		process as returned from a 'ps' command.  Note that the 
		process referenced should have a unique enough name so that
		false positives are not an issue.  Also note that the path
		used to execute the monitored process will change its
		listing in the ps list.
url           : The URL to check (ie, http://www.dmo.hp.com/test)
command       : The absolute path for a command that can optionally be
		called on a fail or success condition. On a failure condition,
		the format will be:
		command 0 semaphore  
		a success condition will be:
		command 1 semaphore
		(where semaphore is the actual filename of the semaphore)
email         : The email address to send error/success messages (optional)
subject line  : The subject line for the email.  This is not the complete
		subject.  It is after other information regarding the state
		of the process and which process id is failing.  This can
		be used as a unique id to key off of for sorting in an
		email program.
threshold     : Will not notify (email or command) until fails <threshold> 
		consecutive times 
error regex   : error condition is generated if regex is true for the HTML 
		page returned 

operating hours : Not yet implemented - Represents any arbitrary period of time.
		  See the Time Period Specification below.

A '#' at the beginning of the line can be used to designate a comment line.
A failure condition means a missing URL or process.
A success condition means a reappearance of a previously failed URL/process.

Changing configuration while sysmonitord is running
---------------------------------------------------

Sending a HUP signal to sysmonitord while it is running wil cause it to re-read
it's configuration file and restart monitoring activities

Eg: kill -HUP <pid>

TIME PERIOD SPECIFICATION

The format of a time period is documented in detail in the perl module 
Time::Period but is summarized here for completeness. You can type 
"perldoc Time::Period" for more details on this format.

***
Please note that ANY errors such as typos will cause the sysmonitor process to 
execute indefinitely.  For example the time spec: wd {Mun} will cause the
process to always execute(ignore the time specification), as will such typos 
as wX {Mon-Fri} or min{0-29a}
***

The period is specified as a string which adheres to the format 

        sub-period[, sub-period...]

or the string "none" or whitespace. The string "none" isnt case sensitive.

If the period is blank, then any time period is valid.
If the period is ``none'', then no time period is valid. 

A sub-period is of the form 

        scale {range [range ...]} [scale {range [range ...]}]


Scale must be one of nine different scales (or their equivalent codes): 

        Scale  | Scale | Valid Range Values
               | Code  |
        *******|*******|************************************************
        year   |  yr   | n     where n is an integer 0<=n<=99 or n>=1970
        month  |  mo   | 1-12  or  jan, feb, mar, apr, may, jun, jul,
               |       |           aug, sep, oct, nov, dec
        week   |  wk   | 1-6
        yday   |  yd   | 1-365
        mday   |  md   | 1-31
        wday   |  wd   | 1-7   or  su, mo, tu, we, th, fr, sa
        hour   |  hr   | 0-23  or  12am 1am-11am 12noon 12pm 1pm-11pm
        minute |  min  | 0-59
        second |  sec  | 0-59


The same scale type may be specified multiple times. Additional scales simply 
extend the range defined by previous scales of the same type. 

The range for a given scale must be a valid value in the form of 

        v
or 
        v-v

For the range specification v-v, if the second value is larger than the first 
value, the range wraps around (unless the scale specification is year which
never wraps). 

EXAMPLES

To specify a time period from Monday through Friday, 9am to 5pm, use a period 
such as: wd {Mon-Fri} hr {9am-4pm}

When specifing a range by using -, it is best to think of - as meaning through. 
It is 9am through 4pm, which is just before 5pm. 

To specify a time period from Monday through Friday, 9am to 5pm on Monday, 
Wednesday, and Friday, and 9am to 3pm on Tuesday and Thursday, use a period 
such as: wd {Mon Wed Fri} hr {9am-4pm}, wd{Tue Thu} hr {9am-2pm}

To specify a time period that extends Mon-Fri 9am-5pm, but alternates weeks in 
a month, use a period such as: wk {1 3 5} wd {Mon Wed Fri} hr {9am-4pm}

The following period specifies winter: mo {Nov-Feb}
All the following are equivalent to the previous example: 

mo {Jan-Feb Nov-Dec}
mo {jan feb nov dec}
mo {Jan Feb}, mo {Nov Dec}
mo {Jan Feb} mo {Nov Dec}

To specify a period that describes every other half-hour, use: minute { 0-29 }
To specify the morning, use: hour { 12am-11am }
Note that 11am is not 11:00:00am, but rather 11:00:00am - 11:59:59am. 

To specify 5 second blocks use: sec {0-4 10-14 20-24 30-34 40-44 50-54}
To specify every 1st half-hour on alternating week days, and 2nd half-hour 
the rest of the week, use: wd {1 3 5 7} min {0-29}, wd {2 4 6} min {30-59}
	
	

syscheck.cgi 
------------

This can be used in conjunction with sysmonitord.  This CGI is called
with the following variable inputs:
a,b,c  

c = id of process listed in syscheck.rc (explained above)
a = success URL redirect (if process or url is OK, CGI will redirect
    the user to the URL passed in 'a'.)
b = fail URL redirect (if process or url has failed, CGI will redirect
    the user to the URL passed in 'b'.)

