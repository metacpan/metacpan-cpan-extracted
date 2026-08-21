/* X11::GUITest ($Id: main.c 253 2026-08-19 22:37:51Z ctrondlp $)
 *  
 * Copyright (c) 2003-2026  Dennis K. Paulsen, All Rights Reserved.
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
#include <popt.h>
#include <math.h>
#include <unistd.h>
#include <locale.h> /* setlocale(); libintl.h doesn't reliably pull this in */
#include <X11/Xutil.h>
#include "record.h"
#include "record_event.h"
#include "KeyUtil.h"
#include "script_file.h"
#include "Common.h"
#include "main.h"


static char *scriptFile = NULL;
static char *exitKey = "ESC";
static KeySym exitKeySym = 0;
static BOOL excludeDelays = FALSE;
static int waitSeconds = DEFAULT_WAIT_SECS;
static int delayThresholdMs = DEFAULT_DELAY_MS;
static int granularity = MAX_GRANULARITY;
static struct record_event lastEvent = {0};
static char buttonName[MAX_MBUTTON_NAME] = "\0";
static char keyBuffer[MAX_KEY_BUFFER] = "\0";


int main (int argc, char *argv[]) 
{
    poptContext optCon = {0};

    // International support
    setlocale(LC_MESSAGES, "");
#ifdef HAVE_GETTEXT
    bindtextdomain(APP_NAME, APP_TEXTDOMAIN);
    textdomain(APP_NAME);
#endif

    // Parse arguments
    struct poptOption optTbl[] = {
        {"script", 's', POPT_ARG_STRING, &scriptFile, 0, _("Script file to create"), NULL},
        {"wait", 'w', POPT_ARG_INT | POPT_ARGFLAG_SHOW_DEFAULT, &waitSeconds, 0, _("Seconds to wait before recording"), NULL},
        {"delaythreshold", 'd', POPT_ARG_INT | POPT_ARGFLAG_SHOW_DEFAULT, &delayThresholdMs, 0, _("Event delay (ms) threshold to account for / record"), NULL},
        {"exitkey", 'e', POPT_ARG_STRING | POPT_ARGFLAG_SHOW_DEFAULT, &exitKey, 0, _("Exit key to stop recording"), NULL},
        {"nodelay", 'n', POPT_ARG_NONE, &excludeDelays, 0, _("Don't include user delays"), NULL},
        {"granularity", 'g', POPT_ARG_INT | POPT_ARGFLAG_SHOW_DEFAULT, &granularity, 0, _("Level of granularity, mouse move frequency, 1-10"), NULL},
        POPT_AUTOHELP
        POPT_TABLEEND
    };
    optCon = poptGetContext(NULL, argc, (const char **)argv, optTbl, 0);
    if (argc <= 1) {
        PrintAppInfo();
        poptPrintHelp(optCon, stderr, 0);
        exit(1);
    }
    while (poptGetNextOpt(optCon) >= 0) {}
    poptFreeContext(optCon);

    // Check arguments
    if (scriptFile == NULL || !*scriptFile) {
        fprintf(stderr, _("No script file specified.\n"));
        exit(1);
    }
    if (!GetKeySym(exitKey, &exitKeySym)) {
        fprintf(stderr, _("Invalid exit key defined.\n"));
        exit(1);
    }
    if (waitSeconds < MIN_WAIT_SECONDS || waitSeconds > MAX_WAIT_SECONDS) {
        fprintf(stderr, _("Invalid wait defined (supplied %d, but needs 1-%d).\n"), 
                waitSeconds, MAX_WAIT_SECONDS);
        exit(1);
    }
    if (granularity < MIN_GRANULARITY || granularity > MAX_GRANULARITY) {
        fprintf(stderr, _("Invalid granularity defined (supplied %d, but needs %d-%d).\n"), 
                granularity, MIN_GRANULARITY, MAX_GRANULARITY);
        exit(1);
    }
    if (delayThresholdMs < MIN_DELAY_MS || delayThresholdMs > MAX_DELAY_MS) {
        fprintf(stderr, _("Invalid delay theshold defined (supplied %d, but needs %d-%d).\n"), 
                delayThresholdMs, MIN_DELAY_MS, MAX_DELAY_MS);
        exit(1);
    }

    if (!OpenScript(scriptFile)) {
        exit(1);
    }

    // Starting up...
    usleep(waitSeconds * 1000000);
    printf(_("Recording Started, press %s to exit.\n"), exitKey);

    WriteScript("#!/usr/bin/perl\n\n");
    WriteScript("use X11::GUITest qw/:ALL/;\n");
    WriteScript("use strict;\n");
    WriteScript("use warnings;\n\n\n");
    WriteScript(_("# Begin (Recorder Version %s).\n"), APP_VERSION);

    ////
    RecordEvents(ProcessEvent);
    ////

    WriteScript(_("\n\n# End.\n"));
    CloseScript();

    printf(_("\nRecording Finished.\n"));
    exit(0);
}

static void PrintAppInfo(void)
{
    printf("%s (%s: %s)\n\n", APP_NAME, _("Version"), APP_VERSION);
}

static BOOL GetMouseButtonFromIndex(int index, char *button)
{
    if (button == NULL) {
        return FALSE;
    }
    *button = NUL;

    if (index == 1) {
        strcpy(button, "M_LEFT");
    } else if (index == 2) {
        strcpy(button, "M_MIDDLE");
    } else if (index == 3) {
        strcpy(button, "M_RIGHT");
    } else if (index == 4) {
        strcpy(button, "M_UP");
    } else if (index == 5) {
        strcpy(button, "M_DOWN");
    } else {
        return FALSE;
    }

    return TRUE;
}

static void HandleDelay(unsigned long delay)
{
    if (excludeDelays == FALSE) {
        /* delayThresholdMs stays a plain int (see main.h/main()) since
         * popt's POPT_ARG_INT writes through an int* -- it's already
         * validated to MIN_DELAY_MS..MAX_DELAY_MS (non-negative) in
         * main(), so this cast can't turn a negative value huge. */
        if (delay > (unsigned long)delayThresholdMs) {
            float secs = ((float)delay / 1000); // ms to secs
            WriteScript("WaitSeconds(%0.3f);\n", secs);
        }
    }
}

static void HandleKeyBuffer(BOOL forceKeyFlush)
{
    int len = strlen(keyBuffer);
    if (forceKeyFlush || len >= KEY_BUFFER_THRESHOLD) {
        if (len > 0) {
            WriteScript("SendKeys('%s');\n", keyBuffer);
            *keyBuffer = '\0'; // clear
        }
    }
}

/* Appends str to keyBuffer, flushing the buffer out as its own SendKeys()
 * call first if str wouldn't otherwise fit. str is expected to be one
 * complete syntactic keyUnit (e.g. "{KeyName}" or "mod("); callers must
 * not split a keyUnit across multiple calls, or a flush here could break
 * it across two separate SendKeys() calls in the recorded script. */
static void AppendKeyBuffer(const char *str)
{
    size_t curlen = 0, addlen = 0, avail = 0;

    if (str == NULL || *str == '\0') {
        return;
    }
    addlen = strlen(str);
    curlen = strlen(keyBuffer);

    if (curlen + addlen >= MAX_KEY_BUFFER) {
        HandleKeyBuffer(TRUE);
        curlen = strlen(keyBuffer); /* Now 0, barring a single str that
                                     * alone exceeds MAX_KEY_BUFFER. */
    }

    avail = MAX_KEY_BUFFER - curlen - 1; /* Leave room for the NUL. */
    strncat(keyBuffer, str, avail);
}

static void ProcessEvent(struct record_event ev) 
{
    if (ev.type == KEY) {
        // TODO: Granular delay between buffered key events
        BOOL forceKeyFlush = (ev.delay > MAX_KEYDELAY_BEFOREFLUSH_MS);
        HandleKeyBuffer(forceKeyFlush);
        HandleDelay(ev.delay);
        
        // Are we exiting?
        /* ev.data holds a KeySym on the KEY path (see record_event.h);
         * compare as KeySym rather than plain long so this doesn't
         * become a signed/unsigned mismatch. */
        if ((KeySym)ev.data == exitKeySym) {
            HandleKeyBuffer(TRUE);
            StopRecording();
            return;
        }

        const char *nam = GetKeyName(ev.data);
        if (nam != NULL) {
            const char *mod = GetModifierCode(ev.data);
            char keyUnit[MAX_KEY_BUFFER] = "\0";

            if (mod != NULL) {
                //// handle modifiers
                if (ev.state == DOWN) {
                    snprintf(keyUnit, sizeof(keyUnit), "%s(", mod);
                } else {
                    snprintf(keyUnit, sizeof(keyUnit), ")");
                }
                AppendKeyBuffer(keyUnit);
            } else {
                //// handle other keys
                if (ev.state == UP) {
                    //printf("Key: %s (%s)\n", nam, mod);
                    if (strlen(nam) > 1) {
                        // special key
                        snprintf(keyUnit, sizeof(keyUnit), "{%s}", nam);
                    } else if (nam[0] == '\'') { // escape this
                        snprintf(keyUnit, sizeof(keyUnit), "\\%s", nam);
                    } else {
                        snprintf(keyUnit, sizeof(keyUnit), "%s", nam);
                    }
                    AppendKeyBuffer(keyUnit);
                }
            }
        } else {
            WriteScript(_("# [Unhandled Key %ld/%d]\n"), ev.data, ev.state);
        }   
    } else { // Mouse, etc.
        HandleKeyBuffer(TRUE); // Flush out others events...
        HandleDelay(ev.delay);

        if (ev.type == MOUSEMOVE) {
            if (!IsMouseMoveTooGranular(ev)) {
                WriteScript("MoveMouseAbs(%d, %d);\n", ev.posX, ev.posY);
            }
        } else if (ev.type == MOUSEBUTTON) {
            /* MOUSEBUTTON events only ever carry a small button index
             * (1-5) in data, never a KeySym, so this narrowing is safe. */
            GetMouseButtonFromIndex((int)ev.data, buttonName);
            if (!*buttonName) {
                WriteScript(_("# [Unhandled Mouse Button %ld/%d]\n"), ev.data, ev.state);
            } else {
                // TODO: Simplify to 'ClickMouseButton' where possible...
                if (ev.state == UP) {
                    WriteScript("ReleaseMouseButton(%s);\n", buttonName);
                } else {
                    WriteScript("PressMouseButton(%s);\n", buttonName);
                }
            }
        } else {
            //printf("Unhandled event type: %d\n", ev.type);
        }   
    }
    memcpy(&lastEvent, &ev, sizeof(struct record_event));
}

static BOOL IsMouseMoveTooGranular(struct record_event ev)
{
    if (lastEvent.type != MOUSEMOVE) {
        return(FALSE); // must be mousemove -> mousemove to count
    } else {
        // TODO: Adjust
        /* granularity stays a plain int (see main.h/main()) since popt's
         * POPT_ARG_INT writes through an int* -- it's already validated
         * to MIN_GRANULARITY..MAX_GRANULARITY in main(), so threshold is
         * always in [0, MAX_GRANULARITY-1] and this cast is safe. */
        int threshold = (int)MAX_GRANULARITY / granularity - 1;
        if (ev.delay < (unsigned long)threshold) {
            return(TRUE);
        }
    }
    return(FALSE);
}
