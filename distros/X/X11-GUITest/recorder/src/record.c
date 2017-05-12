/* X11::GUITest ($Id: record.c 231 2014-01-11 14:26:57Z ctrondlp $)
 *  
 * Copyright (c) 2003-2014  Dennis K. Paulsen, All Rights Reserved.
 * Email: ctrondlp@cpan.org
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License as
 * published by the Free Software Foundation; either version 2 of
 * the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, see <http://www.gnu.org/licenses>.
 *
 */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <signal.h>
#include <unistd.h>
#include <libintl.h>
#include <sys/time.h>
#include <X11/X.h>
#include <X11/XKBlib.h>
#include <X11/Xproto.h>
#include <X11/extensions/record.h>
#include <X11/keysym.h>
#include <X11/Xutil.h>
#include <X11/Intrinsic.h>
#include <X11/StringDefs.h>
#include "record_event.h"
#include "record.h"
#include "Common.h"

static BOOL shouldExit = FALSE;
static struct timeval lastTime = {0};
static struct timeval currentTime = {0};
static void (*HandleEvent)(struct record_event ev);
static XRecordContext rcon;
static Display *otherDisp = NULL;
static Display *disp = NULL;


int RecordEvents(void (*handleEvent)(struct record_event ev)) 
{
	XRecordClientSpec rcspec = {0};
	XRecordRange *xrr = NULL;
  	int major = 0, minor = 0;

	HandleEvent = handleEvent; // Register it

	signal(SIGINT, sigint_handler);

	SetLastTime();

	disp = XOpenDisplay(NULL);
 	if (disp == NULL) {
		fprintf(stderr, _("Unable to open display connection.\n"));
		return 1;
	}
	XSynchronize(disp, False);

	// Ensure extension available 
	if (!XRecordQueryVersion(disp, &major, &minor)) {
		fprintf(stderr, _("The record extension is unavailable.\n"));
		return 1;
	}

	xrr = XRecordAllocRange();
	if (xrr == NULL) {
		fprintf(stderr, _("Range allocation failed.\n"));
		return 1;
	}

	xrr->device_events.first = KeyPress;
	xrr->device_events.last = MotionNotify;
 	rcspec = XRecordAllClients;

	rcon = XRecordCreateContext(disp, 0, &rcspec, 1, &xrr, 1);
	if (!rcon) {
		fprintf(stderr, _("Unable to create context.\n"));
		return 1;
	}
		
	otherDisp = XOpenDisplay(NULL);
	if (otherDisp == NULL) {
		fprintf(stderr, _("Unable to open other display connection.\n"));
		return 1;
	}

	// Clean out X events in progress
	XFlush(disp);
	XFlush(otherDisp);

	// Record...
	if (!XRecordEnableContext(otherDisp, rcon, EventCallback, (XPointer)disp)) {
		fprintf(stderr, _("Enable context failed\n"));
		return 1;
	}
	// ...until StopRecording() is called.
	
	XFree(xrr);
	return 0;
}

void StopRecording(void)
{
	shouldExit = TRUE;
	XRecordDisableContext(disp, rcon);
	XRecordFreeContext(disp, rcon);
	//XCloseDisplay(otherDisp); // Note: N/A, blocks indefinitely 
	XCloseDisplay(disp);
}

void SetLastTime(void) 
{
	if (gettimeofday(&lastTime, NULL) != 0) {
		fprintf(stderr, _("unable to get time\n"));
	}
}

void SetCurrentTime(void) 
{
	if (gettimeofday(&currentTime, NULL) != 0) {
  		fprintf(stderr, _("unable to get time\n"));
	}
}

long GetDelay(void) 
{
	long secDiff = 0;
 	long usecDiff = 0;
	long final = 0;

	SetCurrentTime();
	/* Get delay between the previous event and this one */
	secDiff = (currentTime.tv_sec - lastTime.tv_sec);
	usecDiff = ((currentTime.tv_usec - lastTime.tv_usec) / 1000);
	final = ((secDiff * 1000) + usecDiff);
	SetLastTime();

	return final;
}

void EventCallback(XPointer p, XRecordInterceptData *idata) 
{
	if (shouldExit) {
		return;
	}

	if (XRecordFromServer == idata->category) {
		Display *disp = (Display *)p;
  		xEvent *xev = (xEvent *)idata->data;
		int type = xev->u.u.type;
		int keyPress = 0;
		struct record_event re = {0};

		re.delay = GetDelay();
		re.type = NOTYPE;
		re.state = NOSTATE;
		re.dataname = NULL;
		re.data = 0;

		switch (type) {
		case ButtonPress: 
			re.type = MOUSEBUTTON; 
			re.state = DOWN;
			re.data = xev->u.u.detail;		
			break;
   		case ButtonRelease:
			re.type = MOUSEBUTTON;
			re.state = UP;
			re.data = xev->u.u.detail;
			break;
		case KeyPress:
			keyPress = 1;
	    case KeyRelease:
	 		{
				//printf("key code: %d\n", xev->u.u.detail);
			    KeyCode kc = xev->u.u.detail;
			    KeySym ks = XkbKeycodeToKeysym(disp, kc, 0, 0);
				re.dataname = XKeysymToString(ks);
				re.data = ks;
				re.type = KEY;
				re.state = (keyPress == 1) ? DOWN : UP;
			}			
			break;
   		case MotionNotify:
			{
				re.type = MOUSEMOVE;
				re.posX = xev->u.keyButtonPointer.rootX;
			    re.posY = xev->u.keyButtonPointer.rootY;
			}
			break;
   		case EnterNotify:
	 	case LeaveNotify:
   		default:
			break;
		}
		////
		HandleEvent(re);
		////
	}
	if (idata != NULL) {
		XRecordFreeData(idata);	
	}
}

void sigint_handler(int sig) 
{
	StopRecording();
}

