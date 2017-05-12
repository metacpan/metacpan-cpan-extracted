/*
Copyright (c) 2014  Timm Murray
All rights reserved.

Redistribution and use in source and binary forms, with or without 
modification, are permitted provided that the following conditions are met:

    * Redistributions of source code must retain the above copyright notice, 
      this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright 
      notice, this list of conditions and the following disclaimer in the 
      documentation and/or other materials provided with the distribution.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" 
AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE 
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE 
ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE 
LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR 
CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF 
SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS 
INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN 
CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) 
ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE 
POSSIBILITY OF SUCH DAMAGE.
*/
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"
#include "uav.h"

#include <libavcodec/avcodec.h>
#include <libswscale/swscale.h>
#include <SDL/SDL.h>


MODULE = UAV::Pilot::SDL::Video    PACKAGE = UAV::Pilot::SDL::Video


void
_draw_last_video_frame( self, overlay, dstrect, frame_sv)
        SV* self
        SDL_Overlay* overlay
        SDL_Rect* dstrect
        SV* frame_sv
    PPCODE:
        AVFrame* frame = (AVFrame*) SvIV( frame_sv );
        AVPicture pict;
        struct SwsContext * sws_context = sws_getContext(
            dstrect->w,
            dstrect->h,
            UAV_PIX_FMT,
            dstrect->w,
            dstrect->h,
            UAV_PIX_FMT,
            SWS_FAST_BILINEAR,
            NULL,
            NULL,
            NULL
        );

        if( sws_context == NULL ) {
            warn( "Could not get SWS context\n" );
            exit( 1 );
        }


        SDL_LockYUVOverlay( overlay );

        // Data comes from YUV420P source; U and V arrays swapped
        pict.data[0] = overlay->pixels[0];
        pict.data[1] = overlay->pixels[2];
        pict.data[2] = overlay->pixels[1];
        pict.linesize[0] = overlay->pitches[0];
        pict.linesize[1] = overlay->pitches[2];
        pict.linesize[2] = overlay->pitches[1];

        sws_scale( sws_context, (const uint8_t * const *) frame->data,
            frame->linesize, 0, dstrect->h, pict.data, pict.linesize );

        SDL_UnlockYUVOverlay( overlay );
        SDL_DisplayYUVOverlay( overlay, dstrect );

        sws_freeContext( sws_context );
