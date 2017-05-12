/***************************************************************************
 *   X11::GUITest::record                                                  *
 *                                                                         *
 *   Copyright (C) 2007 by Marc Koderer / ecos GmbH                        *
 *   mkoderer@cpan.org                                                     *
 *                                                                         *
 *   This program is free software; you can redistribute it and/or modify  *
 *   it under the terms of the GNU General Public License as published by  *
 *   the Free Software Foundation; either version 2 of the License, or     *
 *   (at your option) any later version.                                   *
 *                                                                         *
 *   This program is distributed in the hope that it will be useful,       *
 *   but WITHOUT ANY WARRANTY; without even the implied warranty of        *
 *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the         *
 *   GNU General Public License for more details.                          *
 *                                                                         *
 *   You should have received a copy of the GNU General Public License     *
 *   along with this program; if not, write to the                         *
 *   Free Software Foundation, Inc.,                                       *
 *   59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.             *
 ***************************************************************************/

/*
Code based on xneelib Version 2.06 is marked with [xneelib].
Its modified under terms of GPLv2
*/

#ifndef X11_guitest_record
#define X11_guitest_record

#ifdef HAVE_CONFIG_H
#include <config.h>
#endif 
#include <X11/Xproto.h>

#include <X11/Xlibint.h>  
#include <X11/Xmd.h>
#include <X11/keysym.h>
#include <X11/keysymdef.h>
#include <stdio.h>
#include <stdlib.h>
#include <X11/Xos.h>
#include <X11/Xlib.h>
#include <X11/Xutil.h>
#include <X11/Xproto.h>
#include <X11/extensions/record.h>
#include <ctype.h>
#include "datastructure.h"

/*
Should be defined in X11/extensions/record.h ---
[xneelib]
*/

typedef union {
  unsigned char    type ;
  xEvent           event ;
  xResourceReq     req   ;
  xGenericReply    reply ;
  xError           error ;
  xConnSetupPrefix setup;
} XRecordDatum ;



/*Perl dispatch function */
void PerlCallback (int cat, int type, unsigned int time, int x, int y, long WinID, long PWinID);
void PerlCallbackText (int cat, int type, unsigned int time, int x, int y, char* data);
void PerlCallbackKey (int cat, int type, unsigned int time, int x, int y, long key);

/*Main dispatch function*/
void dispatch (XPointer xd,XRecordInterceptData *data);

/*Setup range defaults and allocates the memory*/
void init_range_defaults();


static int SetupXDisplay(void);
static int UnSetupXDisplay(void);

/*Disables the record*/
static int InternalDisableRecordContext(void);

#endif
