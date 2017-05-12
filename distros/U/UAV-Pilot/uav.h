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
#ifndef UAV_H
#define UAV_H

#include <libavcodec/avcodec.h>


#define INBUF_SIZE 4096
#define AV_FRAME_DATA_SIZE 3
#define AV_FRAME_DATA_Y_CHANNEL 0
#define AV_FRAME_DATA_U_CHANNEL 1
#define AV_FRAME_DATA_V_CHANNEL 2
#define CODEC_ID CODEC_ID_H264
#define UAV_PIX_FMT PIX_FMT_YUV420P

/*
#define THROW_XS_ERROR(error_str) \
        ENTER;\
        SAVETMPS;\
        PUSHMARK(SP);\
        XPUSHs( sv_2mortal(newSVpv("UAV::Pilot::VideoException", 0)) );\
        XPUSHs( sv_2mortal(newSVpv("error", 0)) );\
        XPUSHs( sv_2mortal(newSVpv(error_str, 0)) );\
        PUTBACK;\
        call_method( "throw", G_DISCARD );\
        FREETMPS;\
        LEAVE;
*/
#define THROW_XS_ERROR(error_str)\
    warn( "Error: %s", error_str );\
    exit(1);


#endif /* ifndef UAV_H */
