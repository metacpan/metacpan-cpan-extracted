/* X11::GUITest ($Id: record.h 231 2014-01-11 14:26:57Z ctrondlp $)
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
#ifndef RECORD_H
#define RECORD_H
#include <X11/extensions/record.h>
#include "record_event.h"

int RecordEvents(void (*handleEvent)(struct record_event));
void StopRecording(void);

void sigint_handler(int sig);
void SetLastTime(void);
void SetCurrentTime(void);
void EventCallback(XPointer p, XRecordInterceptData *idata);
long GetDelay(void); 
 
#endif /* #ifndef RECORD_H */
