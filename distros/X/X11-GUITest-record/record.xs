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
It is modified under terms of GPLv2
*/


#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include "datastructure.h"
#include "record.h"
#include <stdio.h>
#include <stdlib.h>



static Display *dpy = NULL;

/* To set DEBUG call SetRecordDEBUG */
static int DEBUG = 0;


static XRecordRange* range;
static XRecordRange* first_range;
static int num_ranges = 0;


static XRecordRange** ranges=NULL;
static XRecordContext context=0;

static int reply_counter = 0;

/*
init_range_defaults

- Setting up first range with default values
*/

void init_range_defaults()
    {
    first_range  = XRecordAllocRange();
    
    memset (first_range, 0, sizeof(XRecordRange));

    /*Default settings (dont need them) */

    
    /*
    first_range->delivered_events.first       = 0;
    first_range->delivered_events.last        = 0;
    first_range->core_requests.first          = 0;
    first_range->core_requests.last           = 0;
    first_range->errors.first                 = 0;
    first_range->errors.last                  = 0;
    first_range->core_replies.first           = 0;
    first_range->core_replies.last            = 0;
    first_range->ext_requests.ext_major.first = 0;
    first_range->ext_requests.ext_major.last  = 0;
    first_range->ext_requests.ext_minor.first = 0;
    first_range->ext_requests.ext_minor.last  = 0;
    first_range->ext_replies.ext_major.first  = 0;
    first_range->ext_replies.ext_major.last   = 0;
    first_range->ext_replies.ext_minor.first  = 0;
    first_range->ext_replies.ext_minor.last   = 0;
    first_range->device_events.first          = 0;
    first_range->device_events.last           = 0;
    */

    /*[xneelib]*/
    ranges =(XRecordRange**) Xcalloc (1, sizeof(XRecordRange*));
    

    ranges[0] = first_range;
    
    range = first_range;
    
    }


/*
dispatch

- Is called if a record infomation is dispatched. It will call a perl callback function
  if type is usable.

in: - XPointer xd
    - InterceptedData *data
    
*/

void dispatch (XPointer xd,XRecordInterceptData *data )
    {
    int                  data_type = 0;
    XRecordDatum         *xrec_data ;
    char*                text_cpy;
    
    xrec_data = (XRecordDatum*) (data->data);
    
    if (DEBUG == 1){printf ("DBG: Dispatchcall\n");}
    
    if(data->data_len!=0)
    {
       data_type = (int) xrec_data->type;
    }
    
    
    switch(data->category)
    {
    case XRecordFromClient:
        /*---- Requests*/
        if (DEBUG == 1){printf ("DBG: XRecordFromClient (Request) data_type: %i request_type %s length %li\n", data_type,print_request(data_type),data->data_len);}
    
    
        if (data_type == X_CreateWindow || data_type == X_DestroyWindow) 
            {
            PerlCallback(data->category,
                         data_type,
			 data->server_time,
                         ((xCreateWindowReq*) data->data)->x,
                         ((xCreateWindowReq*) data->data)->y,
                         ((xCreateWindowReq*) data->data)->wid,0);
            break;
            }
        if (data_type == X_PolyText8) 
            {
            /* form Xproto.h : 
               length in 4 bytes quantities
               of whole request, including this header */   
            
            /*Some strings arent nulltermiated - so we have to copy it
            */
            if (!(text_cpy = (char *) malloc ( ((data->data_len*4)+1))))
               {
               printf ("X11::GUITest::record runs out of memory\n");
               exit (1);
               }
               
            memcpy( (void*) text_cpy, (void*) data->data, ((data->data_len*4)));
            
            text_cpy[data->data_len*4] = '\0';
            
            /*PolyText8 overhead is 18 Bytes */
            PerlCallbackText(data->category,
                            data_type,
			    data->server_time,
                            ((xPolyTextReq*) data->data)->x,
                            ((xPolyTextReq*) data->data)->y,
                            (char *)&text_cpy[18]);
            break;
            }
        else 
            {
            PerlCallback(data->category,
                         data_type,data->server_time,0,0,0,0);
            }
                            
      break;
    case XRecordFromServer:
        /*----- Events */
        if (data_type == MotionNotify)
            {
            PerlCallback(data->category,
                         data_type,
			 data->server_time,
                         xrec_data->event.u.keyButtonPointer.rootX, 
                         xrec_data->event.u.keyButtonPointer.rootY,
                         xrec_data->event.u.keyButtonPointer.child,
                         xrec_data->event.u.keyButtonPointer.root);

            break;
               
           }
    if (data_type == KeyPress || data_type == KeyRelease ||
        data_type == ButtonPress || data_type == ButtonRelease)
        {
        PerlCallbackKey(data->category,
                        data_type,
			data->server_time,
                        0,
                        0,
                        xrec_data->event.u.u.detail);
        
        break;
       }
      else 
         {
         PerlCallback(data->category,
                      data_type,data->server_time,0,0,0,0);
         }
    break;
    case XRecordClientStarted:
      if (DEBUG == 1){printf ("DBG: Client started \n");}
      break;
    case XRecordClientDied:
      if (DEBUG == 1){printf ("DBG: Client died \n");}
      break;
    case XRecordStartOfData:
      if (DEBUG == 1){ printf ("DBG: Start of data\n");}
      break;
    case XRecordEndOfData:
      if (DEBUG == 1){printf ("DBG: End of data\n");}
      break;
    default:
      if (DEBUG == 1){printf ("DBG: Warning: unknown category type: %i \n",data->category);}
      break;
    }
    XRecordFreeData(data);
    }



/*Perl callback funtions*/


/*
PerlCallback

- PerlCallback function for all requests like X_CreateWindow etc.

    
*/

void PerlCallback (int cat, int type, unsigned int time ,int x, int y, long WinID, long PWinID)
    {
    dSP ;
    reply_counter++;

    ENTER ;
    SAVETMPS ;

    PUSHMARK(SP) ;
    
    XPUSHs(sv_2mortal(newSViv(cat)));
    XPUSHs(sv_2mortal(newSViv(type)));
    mXPUSHu(time);
    XPUSHs(sv_2mortal(newSViv(x)));
    XPUSHs(sv_2mortal(newSViv(y)));
    XPUSHs(sv_2mortal(newSViv(WinID)));
    XPUSHs(sv_2mortal(newSViv(PWinID)));
    PUTBACK ;
    
    if (DEBUG == 1){printf ("DBG: Call of PerlCallback Category: %d, Type %d, Time %u: X %d, Y %d, WinID %ld, PWinID %ld\n",
                            cat, type, time, x, y, WinID, PWinID);}
    
    call_pv("X11::GUITest::record::Callback", G_DISCARD);

    FREETMPS ;
    LEAVE ;
    }


/*
PerlCallbackText

- PerlCallback function for X_PolyText8

    
*/


void PerlCallbackText (int cat, int type, unsigned int time ,int x, int y, char* data)
    {
    dSP ;
    reply_counter++;

    ENTER ;
    SAVETMPS ;

    PUSHMARK(SP) ;
    
    XPUSHs(sv_2mortal(newSViv(cat)));
    XPUSHs(sv_2mortal(newSViv(type)));
    mXPUSHu(time);
    XPUSHs(sv_2mortal(newSViv(x)));
    XPUSHs(sv_2mortal(newSViv(y)));
    XPUSHs(sv_2mortal(newSVpv(data, 0)));
    PUTBACK ;
    
    if (DEBUG == 1){printf ("DBG: Call of PerlCallbackText Category: %d, Type %d, Time %u:  X %d, Y %d, Data %s\n",
                            cat, type, time, x, y, data);}
    
    call_pv("X11::GUITest::record::Callback", G_DISCARD);

    FREETMPS ;
    LEAVE ;
    }
    
/*
PerlCallbackText

- PerlCallback function for KeyPress and KeyRelease event

    
*/

void PerlCallbackKey (int cat, int type, unsigned int time, int x, int y, long key)
    {
    dSP ;
    reply_counter++;

    ENTER ;
    SAVETMPS ;

    PUSHMARK(SP) ;
    
    XPUSHs(sv_2mortal(newSViv(cat)));
    XPUSHs(sv_2mortal(newSViv(type)));
    mXPUSHu(time);
    XPUSHs(sv_2mortal(newSViv(x)));
    XPUSHs(sv_2mortal(newSViv(y)));
    XPUSHs(sv_2mortal(newSViv(key)));
    PUTBACK ;
    
    if (DEBUG == 1){printf ("DBG: Call of PerlCallbackKey Category: %d, Type %d, Time %u: X %d, Y %d, Key %ld\n",
                            cat, type, time, x, y, key);}
    
    call_pv("X11::GUITest::record::Callback", G_DISCARD);

    FREETMPS ;
    LEAVE ;
    }


static int SetupXDisplay(void)
    {

    /* Get Display Pointer */
    dpy = XOpenDisplay(NULL);
    if (dpy == NULL) { croak ("Not able to open Display");
                       return -1;
                     } 
    return 0;
    
    }


static int UnSetupXDisplay(void)
    {
    if (dpy != NULL) 
       {
       return XCloseDisplay(dpy);
       }
    return 0;

    }


/*
InternalDisableRecordContext

- Disables the record context:
        - It will dispatch all open information to Perl
        - It will close the context
        - It will free the memory of the ranges 

    
*/

static int InternalDisableRecordContext(void)
    {
    Display* new;
    int x;
    int reply_counter_last = 0;


    if (context != 0)
      {
        if (DEBUG == 1) {printf ("DBG: Disabling context %li\n",context);}
    
        /*Dispatch all infos */
        reply_counter = 0;
        while (1)
            {
            /* perlcallback  function increments the reply_counter variable */
            XRecordProcessReplies (dpy);
            /* No change --> no data for perl*/
            if (reply_counter_last == reply_counter ) {break;}
            reply_counter_last = reply_counter;
            }
        
        /* Special thanks to _Joel Dice_ for the input.
           Create a new display context to disable
           the old one
        */
        
        new = XOpenDisplay (NULL);
    
        XRecordDisableContext(new,context);
        XRecordFreeContext(new,context);	 
        XCloseDisplay(new);
        context = 0;
        
        

      }
    if(ranges != NULL)
        {
        if (DEBUG == 1) {printf ("DBG: Freeing %d ranges\n",num_ranges);}
        for (x=num_ranges; x >= 0; x--)
            {
            XFree(ranges[x]);
 	    ranges[x] = NULL;
            }

        XFree(ranges);
        ranges = NULL;
        }
    
    num_ranges = 0;
    
    init_range_defaults();

    return 0;
    }



MODULE = X11::GUITest::record            PACKAGE = X11::GUITest::record
PROTOTYPES: DISABLE

=over 8

=item QueryVersion

Returns a string of the record extension version. 

=back

=cut

char*
QueryVersion()
CODE: 
    int maj,min,ret;
    
    char version[23];
    ret = XRecordQueryVersion(dpy,&maj,&min);
    if (ret == 0)
        {
        if (DEBUG == 1) {printf ("QueryVersion failed\nRecord extension is not enabled on X-Server\n");}
        RETVAL = NULL;
        return;
        }
    sprintf(version,"%d.%d",maj,min);

    RETVAL = version;
OUTPUT:
    RETVAL


void
InitRecordData()
CODE:
    init_range_defaults();
	

int 
InitDisplay()
CODE:
    RETVAL = SetupXDisplay();
OUTPUT:
    RETVAL
	

void 
DeInitRecordData()
CODE:
    int x;
     if(ranges != NULL)
        {
        if (DEBUG == 1) {printf ("DBG: Freeing %d ranges\n",num_ranges);}
        for (x=num_ranges; x >= 0; x--)
            {
            XFree(ranges[x]);
 	    ranges[x] = NULL;
            }

        XFree(ranges);
        ranges = NULL;
        }


int
DeInitDisplay()
CODE: 
    if (DEBUG == 1){printf ("DBG: Unset Display\n");}
    RETVAL = UnSetupXDisplay();
OUTPUT:
    RETVAL


=over 8

=item EnableRecordContext

Enables the corresponding record context. Returns the context string. If the
function fails it will return 0.

=back

=cut


int
EnableRecordContext()
CODE:	
    int datum_flags;
    XRecordClientSpec spec = XRecordAllClients;
    XPointer xd=NULL;
    void (*Pointer_func)(XPointer xd,XRecordInterceptData *data);
    Pointer_func = dispatch;
    datum_flags = XRecordFromServerTime | XRecordFromClientTime | XRecordFromClientSequence;

    // [xneelib]
    (void)XSynchronize(dpy, True);

    if(context != 0)
        {
        InternalDisableRecordContext();
        }
    if(ranges == NULL)
        {
        init_range_defaults();
        }
        
    if (DEBUG == 1) {printf ("DBG: Create context with range size: %d \n",num_ranges);}
    
    context = XRecordCreateContext(dpy,datum_flags,&spec, 1,ranges,num_ranges+1);
    if (DEBUG == 1) {printf ("DBG: Enabling context %li \n",context);}
    RETVAL = (int) XRecordEnableContextAsync(dpy,context,Pointer_func,xd);
OUTPUT: 
    RETVAL


int
CDisableRecordContext()
CODE:
    RETVAL = InternalDisableRecordContext();
OUTPUT:
    RETVAL


int
CGetRecordInfo()
CODE:
    reply_counter=0;	
    XRecordProcessReplies (dpy);
    if (reply_counter!=0) { RETVAL = 1;}
    else { RETVAL = 0;}
OUTPUT:
    RETVAL


=head1 FUNCTIONS (lower level)

The following functions are lower level functions to manipulate the record ranges.
For more detail see the X Record documentation:

=over 8

=item AddRecordRange

Adds a range to the corresponding context.


=back

=cut

void
AddRecordRange()
CODE:
    num_ranges++;
    if (DEBUG == 1) {printf ("DBG: Add new range %d\n",num_ranges);}
    ranges = (XRecordRange**) Xrealloc (ranges, (num_ranges+1)*sizeof(XRecordRange*));
    range  = XRecordAllocRange();
    memset (range, 0, sizeof(XRecordRange));
    ranges[num_ranges]=range;

=over 8

=item SetDeliveredEvents (first, last)

Sets the corresponding context to record delivered events from value first to last.

=back

=cut

void
SetDeliveredEvents(first, last)
    int first
    int last
CODE:
    range->delivered_events.first=first;
    range->delivered_events.last=last;
    
=over 8

=item SetCoreRequests (first, last)

Sets the corresponding context to record core requests from value first to last.

=back

=cut

void 
SetCoreRequests(first, last)
    int first
    int last
CODE:
    range->core_requests.first = first;
    range->core_requests.last  = last;

=over 8

=item SetDeviceEvents (first, last)

Sets the corresponding context to record device events from value first to last.

=back

=cut


void
SetDeviceEvents(first, last)
    int first
    int last
CODE:
    range->device_events.first = first;
    range->device_events.last  = last;

=over 8

=item SetErrors (first, last)

Sets the corresponding context to record device events from value first to last.

=back

=cut



void
SetErrors(first, last)
    int first
    int last
CODE:
    range->errors.first = first;
    range->errors.last  = last;
    
=over 8

=item SetCoreReplies (first, last)

See above.

=back

=cut

void
SetCoreReplies(first, last)
    int first
    int last
CODE:
    range->core_replies.first = first;
    range->core_replies.last  = last;

=over 8

=item SetExtRequestsMajor (first, last)

See above.

=back

=cut

void
SetExtRequestsMajor(first, last)
    int first
    int last
CODE:
    range->ext_requests.ext_major.first = first;
    range->ext_requests.ext_major.last  = last;

=over 8

=item SetExtRequestsMinor (first, last)

See above.

=back

=cut

void
SetExtRequestsMinor(first, last)
    int first
    int last
CODE:
    range->ext_requests.ext_minor.first = first;
    range->ext_requests.ext_minor.last  = last;

=over 8

=item SetExtRepliesMajor (first, last)

See above.

=back

=cut

void
SetExtRepliesMajor(first, last)
    int first
    int last
CODE:
    range->ext_replies.ext_major.first  = first;
    range->ext_replies.ext_major.last   = last;

=over 8

=item SetExtRepliesMinor (first, last)

See above.

=back

=cut

void
SetExtRepliesMinor(first, last)
    int first
    int last
CODE:
    range->ext_replies.ext_minor.first = first;
    range->ext_replies.ext_minor.last  = last;


void
CSetDEBUG(level)
    int level
CODE:
    printf("DBG: Set Debug to %i\n",level);
    DEBUG = level;

char*
ConvRequest2Text(type)
    int type
CODE:
    RETVAL = print_request(type);
OUTPUT:
    RETVAL

char*
ConvEvent2Text(type)
    int type
CODE:
    RETVAL = print_event(type);
OUTPUT:
    RETVAL


=head1 SEE ALSO

L<X11::GUITest> - For replaying the records

=head1 AUTHOR

Marc Koderer   E<lt>mkoderer@cpan.orgE<gt>,
Gerald Richter E<lt>richter@ecos.deE<gt> / ecos GmbH

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007 by Marc Koderer / ecos GmbH

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License.


=cut
