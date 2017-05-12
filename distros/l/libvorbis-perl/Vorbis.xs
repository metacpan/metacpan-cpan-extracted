#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <vorbis/vorbisfile.h>

typedef int Ogg__Vorbis;

static int
not_here(char *s)
{
    croak("%s not implemented on this architecture", s);
    return -1;
}

static double
constant(char *name, int arg)
{
    errno = 0;
    switch (*name) {
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}


MODULE = Ogg::Vorbis    PACKAGE = Ogg::Vorbis   PREFIX = ov_

PROTOTYPES: DISABLE

double
constant(name,arg)
	char *		name
	int		arg

OggVorbis_File*
new(CLASS)
        char *CLASS
        CODE:
        RETVAL = (OggVorbis_File*) malloc(sizeof(OggVorbis_File));
        OUTPUT:
        RETVAL

void
DESTROY(self)
	OggVorbis_File *self
    CODE:
	safefree(self);

int
ov_clear(self)
        OggVorbis_File *self

int
ov_open(self, file, initial="", ibytes=0)
        OggVorbis_File *self
        FILE *file
        char *initial
        long ibytes
        CODE:
        /* we swapped file and self for an OO interface */
        RETVAL = ov_open(file, self, initial, ibytes);
        OUTPUT:
        RETVAL

long
ov_streams(self)
        OggVorbis_File *self

long
ov_seekable(self)
        OggVorbis_File *self

long
ov_bitrate(self, i=-1)
        OggVorbis_File *self
        int i

long
ov_serialnumber(self, i=-1)
        OggVorbis_File *self
        int i

long
ov_bitrate_instant(self)
        OggVorbis_File *self

ogg_int64_t
ov_raw_total(self, i=-1)
        OggVorbis_File *self
        int i

ogg_int64_t
ov_pcm_total(self, i=-1)
        OggVorbis_File *self
        int i

double
ov_time_total(self, i=-1)
        OggVorbis_File *self
        int i

int
ov_raw_seek(self, pos)
        OggVorbis_File *self
        long pos

int
ov_pcm_seek_page(self, pos)
        OggVorbis_File *self
        ogg_int64_t pos

int
ov_pcm_seek(self, pos)
        OggVorbis_File *self
        ogg_int64_t pos

int
ov_time_seek(self, seconds)
        OggVorbis_File *self
        double seconds

int
ov_time_seek_page(self, seconds)
        OggVorbis_File *self
        double seconds

ogg_int64_t
ov_raw_tell(self)
        OggVorbis_File *self

ogg_int64_t
ov_pcm_tell(self)
        OggVorbis_File *self

double
ov_time_tell(self)
        OggVorbis_File *self

vorbis_info *
ov_info(self, link=-1)
        OggVorbis_File *self
        int link

HV *
ov_comment(self, link=-1)
        OggVorbis_File *self
        int link
        PREINIT:
        char *key, *val;
        int i, keylen, vallen;
        vorbis_comment *comments;
        SV *temp;
        CODE:
        /* fetch the comments */
        comments = ov_comment(self, link);
        RETVAL = newHV();
        /* store the comments in a hash */
        for (i=0; i < comments->comments; i++) {
            key = comments->user_comments[i];
            if (val = strchr(key, '=')) {
                keylen = val - key;
                *(val++) = '\0';
                vallen = comments->comment_lengths[i] - keylen - 1;
                hv_store(RETVAL, key, keylen, newSVpv((char*)val, vallen), 0);
                *(--val) = '=';
            } else {
                fprintf(stderr, "warning: invalid comment field #%d\n", i);
            }
        }
        OUTPUT:
        RETVAL

long
ov_read(self, buffer, length, bigendianp, word, sgned, bitstream)
        OggVorbis_File* self
        SV* buffer
        int length
        int bigendianp
        int word
        int sgned
        int &bitstream
        CODE:
        /* If buffer is a string, read from the string */
        if (SvPOKp(buffer)) {
            RETVAL = ov_read(self, (char*)SvPV(buffer,PL_na), length,
                             bigendianp, word, sgned, &bitstream);
        } else {
        /* otherwise buffer is a reference, de-reference it */
            RETVAL = ov_read(self, (char*)SvRV(buffer), length,
                             bigendianp, word, sgned, &bitstream);
        }
        OUTPUT:
        RETVAL
        bitstream


MODULE = Ogg::Vorbis    PACKAGE = Ogg::Vorbis::Info   PREFIX = ov_info_

int
ov_info_version(self)
        vorbis_info *self;
        CODE:
        RETVAL = self->version;
        OUTPUT:
        RETVAL

int
ov_info_channels(self)
        vorbis_info *self;
        CODE:
        RETVAL = self->channels;
        OUTPUT:
        RETVAL

int
ov_info_rate(self)
        vorbis_info *self;
        CODE:
        RETVAL = self->rate;
        OUTPUT:
        RETVAL

int
ov_info_bitrate_upper(self)
        vorbis_info *self;
        CODE:
        RETVAL = self->bitrate_upper;
        OUTPUT:
        RETVAL

int
ov_info_bitrate_nominal(self)
        vorbis_info *self;
        CODE:
        RETVAL = self->bitrate_nominal;
        OUTPUT:
        RETVAL

int
ov_info_bitrate_lower(self)
        vorbis_info *self;
        CODE:
        RETVAL = self->bitrate_lower;
        OUTPUT:
        RETVAL

