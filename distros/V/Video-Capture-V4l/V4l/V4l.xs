#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <sys/types.h>
#include <sys/time.h>
#include <unistd.h>
#include <sys/mman.h>

#include <string.h>
#include <pthread.h>
#include <linux/videodev.h>

#define NEED_newCONSTSUB
#include "../gppport.h"

#ifndef pTHX_
#define pTHX_
#endif

#define XSRETURN_bool(bool) if (bool) XSRETURN_YES; else XSRETURN_NO;

#define VBI_BPF (2048*32)

typedef struct video_capability *Video__Capture__V4l__Capability;
typedef struct video_channel *Video__Capture__V4l__Channel;
typedef struct video_audio *Video__Capture__V4l__Audio;
typedef struct video_picture *Video__Capture__V4l__Picture;
typedef struct video_tuner *Video__Capture__V4l__Tuner;

static void
attach_struct (SV *sv, size_t bytes)
{
  void *ptr;

  sv = SvRV (sv);
  Newz (0, ptr, bytes, void*);

  sv_magic (sv, 0, '~', 0, bytes);
  mg_find(sv, '~')->mg_ptr = ptr;
}

static SV *
new_struct (SV *sv, size_t bytes, const char *pkg)
{
  SV *rv = newRV_noinc (sv);
  attach_struct (rv, bytes);
  return sv_bless (rv, gv_stashpv ((char *)pkg, TRUE));
}

static void *
old_struct (SV *sv, const char *name)
{
  /* TODO: check name */
  return mg_find (SvRV(sv), '~')->mg_ptr;
}

static int
framesize (unsigned int format, unsigned int pixels)
{
  if (format==VIDEO_PALETTE_RGB565)	return pixels*2;
  if (format==VIDEO_PALETTE_RGB24)	return pixels*3;
  if (format==VIDEO_PALETTE_RGB555)	return pixels*2;
  if (format==VIDEO_PALETTE_HI240)	return pixels*1;
  if (format==VIDEO_PALETTE_GREY)	return pixels*1;
  if (format==VIDEO_PALETTE_RGB32)	return pixels*4;
  if (format==VIDEO_PALETTE_UYVY)	return pixels*2;
  if (format==VIDEO_PALETTE_YUYV)	return pixels*2;
  /* everything below is very probably WRONG */
  if (format==VIDEO_PALETTE_YUV410P)	return pixels*2;
  if (format==VIDEO_PALETTE_YUV411)	return pixels*2;
  if (format==VIDEO_PALETTE_YUV411P)	return pixels*2;
  if (format==VIDEO_PALETTE_YUV420)	return pixels*3/2;
  if (format==VIDEO_PALETTE_YUV420P)	return pixels*3/2;
  if (format==VIDEO_PALETTE_YUV422)	return pixels*2;
  if (format==VIDEO_PALETTE_YUV422P)	return pixels*2;
  if (format==VIDEO_PALETTE_PLANAR)	return pixels*2;
  if (format==VIDEO_PALETTE_RAW)	return pixels*8;
  return 0;
}

struct private {
  int fd;
  unsigned char *mmap_base;
  struct video_mbuf vm;
};

static int
private_free (pTHX_ SV *obj, MAGIC *mg)
{
  struct private *p = (struct private *)mg->mg_ptr;
  munmap (p->mmap_base, p->vm.size);
  return 0;
}

static MGVTBL vtbl_private = {0, 0, 0, 0, private_free};

static struct private *
find_private (SV *sv)
{
  HV *hv = (HV*)SvRV(sv);
  MAGIC *mg = mg_find ((SV*)hv, '~');

  if (!mg)
    {
      struct private p;
      p.fd = SvIV (*hv_fetch (hv, "fd", 2, 0));
      if (ioctl (p.fd, VIDIOCGMBUF, &p.vm) == 0)
        {
          p.mmap_base = (unsigned char *)mmap (0, p.vm.size, PROT_READ|PROT_WRITE, MAP_SHARED, p.fd, 0);
          if (p.mmap_base)
            {
              sv_magic ((SV*)hv, 0, '~', (char*)&p, sizeof p);
              mg = mg_find ((SV*)hv, '~');
              mg->mg_virtual = &vtbl_private;
            }
        }
    }

  return (struct private *) (mg ? mg->mg_ptr : 0);
}

typedef unsigned char u8;
typedef unsigned int UI;

#define get_field(field) (*hv_fetch ((HV*)SvRV (self), #field, strlen(#field), 0))

/* only one thread currently */
typedef struct vbi_frame {
  struct vbi_frame *next;
  int size;
  char data[VBI_BPF];
} vbi_frame;
static vbi_frame *vbi_head, *vbi_tail,
                 *vbi_free;
static int vbi_fd;
static UI vbi_max;
static pthread_t vbi_snatcher;
static pthread_mutex_t vbi_lock = PTHREAD_MUTEX_INITIALIZER;
static pthread_cond_t vbi_cond = PTHREAD_COND_INITIALIZER;

static void *
vbi_snatcher_thread (void *arg)
{
  /* try to become a realtime process. */
#ifdef _POSIX_THREAD_PRIORITY_SCHEDULING
  {
    struct sched_param sp;

    sp.sched_priority = (sched_get_priority_max (SCHED_FIFO)
                         + sched_get_priority_min (SCHED_FIFO)) / 2 - 1;
    pthread_setschedparam (pthread_self (), SCHED_FIFO, &sp);
  }
#endif
  for(;;)
    {
      vbi_frame *next;

      pthread_mutex_lock (&vbi_lock);
      if (vbi_free)
        {
          next = vbi_free;
          vbi_free = vbi_free->next;
          pthread_mutex_unlock (&vbi_lock);

          next->next = 0;
          next->size = read (vbi_fd, next->data, VBI_BPF);

          pthread_mutex_lock (&vbi_lock);

          if (vbi_tail)
            vbi_tail->next = next;
          else
            vbi_head = vbi_tail = next;

          vbi_tail = next;
          vbi_max--;

          pthread_cond_signal (&vbi_cond);
          pthread_mutex_unlock (&vbi_lock);
        }
      else 
        {
          static struct timespec to = { 0, 1000000000 / 70 }; /* skip almost a frame */

          pthread_mutex_unlock (&vbi_lock);
          pthread_testcancel ();
          nanosleep (&to, 0);
        }
    }
}

MODULE = Video::Capture::V4l		PACKAGE = Video::Capture::V4l::VBI

PROTOTYPES: ENABLE

SV *
field(self)
	SV *	self
        CODE:
        int fd = SvIV(get_field(fd));

        if (vbi_fd == fd)
          {
            vbi_frame *next;

            pthread_mutex_lock (&vbi_lock);
            while (!vbi_head)
              pthread_cond_wait (&vbi_cond, &vbi_lock);

            RETVAL = newSVpvn (vbi_head->data, vbi_head->size);

            vbi_max++;
            next = vbi_head->next;

            vbi_head->next = vbi_free;
            vbi_free = vbi_head;

            vbi_head = next;

            if (!next)
              vbi_tail = vbi_head;

            pthread_mutex_unlock (&vbi_lock);
          }
        else
          {
            int len;

            RETVAL = newSVpvn ("", 0);
            SvGROW (RETVAL, VBI_BPF);
            len = read (fd, SvPV_nolen (RETVAL), VBI_BPF);
            SvCUR_set (RETVAL, len);
          }

	OUTPUT:
        RETVAL

void
backlog(self,backlog)
  	SV *	self
        unsigned int	backlog
        CODE:
{
        while (vbi_max != backlog)
          {
            vbi_frame *f;

            pthread_mutex_lock (&vbi_lock);

            if (vbi_max < backlog)
              {
                f = malloc (sizeof (vbi_frame));
                f->next = vbi_free;
                vbi_free = f;
                vbi_max++;
              }
            else
              {
                if (vbi_free)
                  {
                    f = vbi_free;
                    vbi_free = vbi_free->next;
                    free (f);
                    vbi_max--;
                  }
              }

            pthread_mutex_unlock (&vbi_lock);
          }

        if (backlog)
          {
            if (!vbi_fd)
              {
                vbi_fd = SvIV(get_field(fd));
                pthread_create (&vbi_snatcher, 0, vbi_snatcher_thread, 0);
              }
          }
        else
          {
            if (vbi_fd)
              {
                pthread_cancel (vbi_snatcher);
                pthread_join (vbi_snatcher, 0);
                vbi_fd = 0;
              }

            /* no locking necessary, in theory */
            while (vbi_head)
              {
                vbi_frame *next = vbi_head->next;

                free (vbi_head);
                vbi_head = next;
              }

            vbi_tail = 0;
          }
}

int
queued(self)
	CODE:
        if (vbi_fd)
          {
            /* FIXME: lock/unlock */
            pthread_mutex_lock (&vbi_lock);
            RETVAL = !!vbi_head;
            pthread_mutex_unlock (&vbi_lock);
          }
        else
          RETVAL = 1;
	OUTPUT:
        RETVAL

MODULE = Video::Capture::V4l		PACKAGE = Video::Capture::V4l		

SV *
capture(sv,frame,width,height,format = VIDEO_PALETTE_RGB24)
	SV	*sv
        unsigned int	frame
        unsigned int	width
        unsigned int	height
        unsigned int	format
        CODE:
{
        struct private *p;
        if ((p = find_private (sv)))
          {
            struct video_mmap vm;
            vm.frame  = frame;
            vm.height = height;
            vm.width  = width;
            vm.format = format;
            if (ioctl (p->fd, VIDIOCMCAPTURE, &vm) == 0)
              {
                SV *fr = newSV (0);
                SvUPGRADE (fr, SVt_PV);
                SvREADONLY_on (fr);
                SvPVX (fr) = p->mmap_base + p->vm.offsets[frame];
                SvCUR_set (fr, framesize (format, width*height));
                SvLEN_set (fr, 0);
                SvPOK_only (fr);
                RETVAL = fr;
              }
            else
              XSRETURN_EMPTY;
          }
        else
          XSRETURN_EMPTY;
}
        OUTPUT:
        RETVAL

void
sync(sv,frame)
	SV	*sv
        int	frame
        PPCODE:
{
        struct private *p;
        if ((p = find_private (sv))
            && ioctl (p->fd, VIDIOCSYNC, &frame) == 0)
          XSRETURN_YES;
        else
          XSRETURN_EMPTY;
}

unsigned long
_freq (fd,fr)
  	int fd
        unsigned long fr
        CODE:
        if (items > 1)
          {
            fr = ((fr<<4)+499)/1000;
            ioctl (fd, VIDIOCSFREQ, &fr);
          }
        if (GIMME_V != G_VOID)
          {
            if (ioctl (fd, VIDIOCGFREQ, &fr) == 0)
              RETVAL = (fr*1000+7)>>4;
            else
              XSRETURN_EMPTY;
          }
        else
          XSRETURN (0);
        OUTPUT:
        RETVAL


SV *
_capabilities_new(fd)
	int	fd
        CODE:
        RETVAL = new_struct (newSViv (fd), sizeof (struct video_capability), "Video::Capture::V4l::Capability");
        OUTPUT:
        RETVAL

SV *
_channel_new(fd)
	int	fd
        CODE:
        RETVAL = new_struct (newSViv (fd), sizeof (struct video_channel), "Video::Capture::V4l::Channel");
        OUTPUT:
        RETVAL

SV *
_tuner_new(fd)
	int	fd
        CODE:
        RETVAL = new_struct (newSViv (fd), sizeof (struct video_tuner), "Video::Capture::V4l::Tuner");
        OUTPUT:
        RETVAL

SV *
_audio_new(fd)
	int	fd
        CODE:
        RETVAL = new_struct (newSViv (fd), sizeof (struct video_audio), "Video::Capture::V4l::Audio");
        OUTPUT:
        RETVAL

SV *
_picture_new(fd)
	int	fd
        CODE:
        RETVAL = new_struct (newSViv (fd), sizeof (struct video_picture), "Video::Capture::V4l::Picture");
        OUTPUT:
        RETVAL

MODULE = Video::Capture::V4l		PACKAGE = Video::Capture::V4l::Capability

void
get(sv)
	SV *	sv
        CODE:
        XSRETURN_bool (ioctl (SvIV (SvRV (sv)), VIDIOCGCAP, old_struct (sv, "Video::Capture::V4l::Capability")) == 0);

MODULE = Video::Capture::V4l		PACKAGE = Video::Capture::V4l::Channel

void
get(sv)
	SV *	sv
        CODE:
        XSRETURN_bool (ioctl (SvIV (SvRV (sv)), VIDIOCGCHAN, old_struct (sv, "Video::Capture::V4l::Channel")) == 0);

void
set(sv)
	SV *	sv
        CODE:
        XSRETURN_bool (ioctl (SvIV (SvRV (sv)), VIDIOCSCHAN, old_struct (sv, "Video::Capture::V4l::Channel")) == 0);

MODULE = Video::Capture::V4l		PACKAGE = Video::Capture::V4l::Tuner

void
get(sv)
	SV *	sv
        CODE:
        XSRETURN_bool (ioctl (SvIV (SvRV (sv)), VIDIOCGTUNER, old_struct (sv, "Video::Capture::V4l::Tuner")) == 0);

void
set(sv)
	SV *	sv
        CODE:
        XSRETURN_bool (ioctl (SvIV (SvRV (sv)), VIDIOCSTUNER, old_struct (sv, "Video::Capture::V4l::Tuner")) == 0);

MODULE = Video::Capture::V4l		PACKAGE = Video::Capture::V4l::Audio

void
get(sv)
	SV *	sv
        CODE:
        XSRETURN_bool (ioctl (SvIV (SvRV (sv)), VIDIOCGAUDIO, old_struct (sv, "Video::Capture::V4l::Audio")) == 0);

void
set(sv)
	SV *	sv
        CODE:
        XSRETURN_bool (ioctl (SvIV (SvRV (sv)), VIDIOCSAUDIO, old_struct (sv, "Video::Capture::V4l::Audio")) == 0);

MODULE = Video::Capture::V4l		PACKAGE = Video::Capture::V4l::Picture

void
get(sv)
	SV *	sv
        CODE:
        XSRETURN_bool (ioctl (SvIV (SvRV (sv)), VIDIOCGPICT, old_struct (sv, "Video::Capture::V4l::Picture")) == 0);

void
set(sv)
	SV *	sv
        CODE:
        XSRETURN_bool (ioctl (SvIV (SvRV (sv)), VIDIOCSPICT, old_struct (sv, "Video::Capture::V4l::Picture")) == 0);

# accessors/mutators
INCLUDE: ./genacc |

MODULE = Video::Capture::V4l		PACKAGE = Video::Capture::V4l		

PROTOTYPES: ENABLE

BOOT:
{
	HV *stash = gv_stashpvn("Video::Capture::V4l", 19, TRUE);

	newCONSTSUB(stash,"AUDIO_BASS",	newSViv(VIDEO_AUDIO_BASS));
	newCONSTSUB(stash,"AUDIO_MUTABLE",	newSViv(VIDEO_AUDIO_MUTABLE));
	newCONSTSUB(stash,"AUDIO_MUTE",	newSViv(VIDEO_AUDIO_MUTE));
	newCONSTSUB(stash,"AUDIO_TREBLE",	newSViv(VIDEO_AUDIO_TREBLE));
	newCONSTSUB(stash,"AUDIO_VOLUME",	newSViv(VIDEO_AUDIO_VOLUME));
	newCONSTSUB(stash,"CAPTURE_EVEN",	newSViv(VIDEO_CAPTURE_EVEN));
	newCONSTSUB(stash,"CAPTURE_ODD",	newSViv(VIDEO_CAPTURE_ODD));
	newCONSTSUB(stash,"MAX_FRAME",	newSViv(VIDEO_MAX_FRAME));
	newCONSTSUB(stash,"MODE_AUTO",	newSViv(VIDEO_MODE_AUTO));
	newCONSTSUB(stash,"MODE_NTSC",	newSViv(VIDEO_MODE_NTSC));
	newCONSTSUB(stash,"MODE_PAL",	newSViv(VIDEO_MODE_PAL));
	newCONSTSUB(stash,"MODE_SECAM",	newSViv(VIDEO_MODE_SECAM));
	newCONSTSUB(stash,"PALETTE_COMPONENT",	newSViv(VIDEO_PALETTE_COMPONENT));
	newCONSTSUB(stash,"PALETTE_GREY",	newSViv(VIDEO_PALETTE_GREY));
	newCONSTSUB(stash,"PALETTE_HI240",	newSViv(VIDEO_PALETTE_HI240));
	newCONSTSUB(stash,"PALETTE_PLANAR",	newSViv(VIDEO_PALETTE_PLANAR));
	newCONSTSUB(stash,"PALETTE_RAW",	newSViv(VIDEO_PALETTE_RAW));
	newCONSTSUB(stash,"PALETTE_RGB24",	newSViv(VIDEO_PALETTE_RGB24));
	newCONSTSUB(stash,"PALETTE_RGB32",	newSViv(VIDEO_PALETTE_RGB32));
	newCONSTSUB(stash,"PALETTE_RGB555",	newSViv(VIDEO_PALETTE_RGB555));
	newCONSTSUB(stash,"PALETTE_RGB565",	newSViv(VIDEO_PALETTE_RGB565));
	newCONSTSUB(stash,"PALETTE_UYVY",	newSViv(VIDEO_PALETTE_UYVY));
	newCONSTSUB(stash,"PALETTE_YUV410P",	newSViv(VIDEO_PALETTE_YUV410P));
	newCONSTSUB(stash,"PALETTE_YUV411",	newSViv(VIDEO_PALETTE_YUV411));
	newCONSTSUB(stash,"PALETTE_YUV411P",	newSViv(VIDEO_PALETTE_YUV411P));
	newCONSTSUB(stash,"PALETTE_YUV420",	newSViv(VIDEO_PALETTE_YUV420));
	newCONSTSUB(stash,"PALETTE_YUV420P",	newSViv(VIDEO_PALETTE_YUV420P));
	newCONSTSUB(stash,"PALETTE_YUV422",	newSViv(VIDEO_PALETTE_YUV422));
	newCONSTSUB(stash,"PALETTE_YUV422P",	newSViv(VIDEO_PALETTE_YUV422P));
	newCONSTSUB(stash,"PALETTE_YUYV",	newSViv(VIDEO_PALETTE_YUYV));
	newCONSTSUB(stash,"SOUND_LANG1",	newSViv(VIDEO_SOUND_LANG1));
	newCONSTSUB(stash,"SOUND_LANG2",	newSViv(VIDEO_SOUND_LANG2));
	newCONSTSUB(stash,"SOUND_MONO",	newSViv(VIDEO_SOUND_MONO));
	newCONSTSUB(stash,"SOUND_STEREO",	newSViv(VIDEO_SOUND_STEREO));
	newCONSTSUB(stash,"TUNER_LOW",	newSViv(VIDEO_TUNER_LOW));
	newCONSTSUB(stash,"TUNER_MBS_ON",	newSViv(VIDEO_TUNER_MBS_ON));
	newCONSTSUB(stash,"TUNER_NORM",	newSViv(VIDEO_TUNER_NORM));
	newCONSTSUB(stash,"TUNER_NTSC",	newSViv(VIDEO_TUNER_NTSC));
	newCONSTSUB(stash,"TUNER_PAL",	newSViv(VIDEO_TUNER_PAL));
	newCONSTSUB(stash,"TUNER_RDS_ON",	newSViv(VIDEO_TUNER_RDS_ON));
	newCONSTSUB(stash,"TUNER_SECAM",	newSViv(VIDEO_TUNER_SECAM));
	newCONSTSUB(stash,"TUNER_STEREO_ON",	newSViv(VIDEO_TUNER_STEREO_ON));
	newCONSTSUB(stash,"TYPE_CAMERA",	newSViv(VIDEO_TYPE_CAMERA));
	newCONSTSUB(stash,"TYPE_TV",	newSViv(VIDEO_TYPE_TV));
	newCONSTSUB(stash,"VC_AUDIO",	newSViv(VIDEO_VC_AUDIO));
	newCONSTSUB(stash,"VC_TUNER",	newSViv(VIDEO_VC_TUNER));
	newCONSTSUB(stash,"TYPE_CAPTURE",	newSViv(VID_TYPE_CAPTURE));
	newCONSTSUB(stash,"TYPE_CHROMAKEY",	newSViv(VID_TYPE_CHROMAKEY));
	newCONSTSUB(stash,"TYPE_CLIPPING",	newSViv(VID_TYPE_CLIPPING));
	newCONSTSUB(stash,"TYPE_FRAMERAM",	newSViv(VID_TYPE_FRAMERAM));
	newCONSTSUB(stash,"TYPE_MONOCHROME",	newSViv(VID_TYPE_MONOCHROME));
	newCONSTSUB(stash,"TYPE_OVERLAY",	newSViv(VID_TYPE_OVERLAY));
	newCONSTSUB(stash,"TYPE_SCALES",	newSViv(VID_TYPE_SCALES));
	newCONSTSUB(stash,"TYPE_SUBCAPTURE",	newSViv(VID_TYPE_SUBCAPTURE));
	newCONSTSUB(stash,"TYPE_TELETEXT",	newSViv(VID_TYPE_TELETEXT));
	newCONSTSUB(stash,"TYPE_TUNER",	newSViv(VID_TYPE_TUNER));
}

void
bgr2rgb(fr)
	SV *	fr
        CODE:
{
        u8 *data, *end;

        end = SvEND (fr);

        for (data = SvPV_nolen (fr); data < end; data += 3)
          {
            data[0] ^= data[2];
            data[2] ^= data[0];
            data[0] ^= data[2];
          }
}
	OUTPUT:
        fr

SV *
reduce2(fr,w)
	SV *	fr
        UI w
        CODE:
{
        u8 *src, *dst, *end;

        src = SvPV_nolen (fr);
        dst = SvPV_nolen (fr);

        w *= 3;

        do
          {
            end = src + w;
            do
              {
                dst[1] = ((UI)src[0] + (UI)src[3]) >> 1; src++;
                dst[2] = ((UI)src[0] + (UI)src[3]) >> 1; src++;
                dst[0] = ((UI)src[0] + (UI)src[3]) >> 1; src++;
                src += 3;
                dst += 3;
              }
            while (src < end);
            src = end + w;
          }
        while (src < (u8*)SvEND (fr));

        SvCUR_set (fr, dst - (u8*)SvPV_nolen (fr));
}
	OUTPUT:
        fr

void
normalize(fr)
	SV *	fr
        CODE:
{
        u8 mfr = 255, max = 0;
        u8 *src, *dst, *end;

        end = SvEND (fr);
        dst = SvPV_nolen (fr);

        for (src = SvPV_nolen (fr); src < end; src++)
          {
            if (*src > max) max = *src;
            if (*src < mfr) mfr = *src;
          }

        if (max != mfr)
          for (src = SvPV_nolen (fr); src < end; )
              *dst++ = ((UI)*src++ - mfr) * 255 / (max-mfr);
}
	OUTPUT:
        fr

void
findmin(db,fr,start=0,count=0)
	SV *	db
        SV *	fr
        UI	start
        UI	count
        PPCODE:
{
	UI diff, min = -1;
        int mindata, data;
        u8 *src, *dst, *end, *efr;
        UI datasize = SvCUR (fr);
        UI framesize = datasize + sizeof(int);

        src = SvPV_nolen (db) + start * framesize;
        if (src < (u8*)SvPV_nolen (db) || src > (u8*)SvEND (db))
          src = SvPV_nolen (db);

        end = src + count * framesize;
        if (end <= src || end > (u8*)SvEND (db))
          end = SvEND (db);

        do
          {
            data = *((int *)src); src += sizeof (int);

            dst = SvPV_nolen (fr);
            efr = src + datasize;
            diff = 0;

            do
              {
                int dif = (int)*src++ - (int)*dst++;
                diff += dif*dif;
              }
            while (src < efr);

            if (min > diff)
              {
                min = diff;
                mindata = data;
              }
          }
        while (src < end);

        EXTEND (sp, 2);
        PUSHs (sv_2mortal (newSViv (mindata)));
        PUSHs (sv_2mortal (newSViv ((min << 8) / SvCUR (fr))));
}

void
linreg(array)
	SV *	array
        PPCODE:
{
	AV *xy = (AV*) SvRV (array);
	I32 i;
	I32 n = (av_len (xy)+1)>>1;
        double x_ = 0, y_ = 0;
        double sxy = 0, sxx = 0, syy = 0;

	for (i=0; i<n; i++)
          {
            x_ += SvNV(*av_fetch(xy, i*2  ,1));
            y_ += SvNV(*av_fetch(xy, i*2+1,1));
          }
        
        x_ /= n;
        y_ /= n;

	for (i=0; i<n; i++)
          {
            double x = SvNV(*av_fetch(xy, i*2  ,1));
            double y = SvNV(*av_fetch(xy, i*2+1,1));

            sxy += (x-x_)*(y-y_);
            sxx += (x-x_)*(x-x_);
            syy += (y-y_)*(y-y_);
          }
        
        {
          double rxy2 = sxy*sxy / (sxx*syy);
          double b = sxy / sxx;
          double a = y_ - b*x_;
          double r2 = (n-1)/(n-2)*syy*(1-rxy2);

          EXTEND (sp, 3);
          PUSHs (sv_2mortal (newSVnv (a )));
          PUSHs (sv_2mortal (newSVnv (b )));
          PUSHs (sv_2mortal (newSVnv (r2)));
        }
}

void
linreg1(array)
	SV *	array
        PPCODE:
{
	AV *xy = (AV*) SvRV (array);
	I32 i;
	I32 n = (av_len (xy)+1)>>1;
        double c = 0;
        double c2 = 0;

	for (i=0; i<n; i++)
          {
            double d = SvNV(*av_fetch(xy, i*2-1,1)) - SvNV(*av_fetch(xy, i*2,1));
            c += d;
          }
        
        c /= n;

	for (i=0; i<n; i++)
          {
            double d = c + SvNV(*av_fetch(xy, i*2,1)) - SvNV(*av_fetch(xy, i*2-1,1));
            c2 += d*d;
          }

        c2 /= n;
        
        EXTEND (sp, 3);
        PUSHs (sv_2mortal (newSVnv (c)));
        PUSHs (sv_2mortal (newSVnv (1)));
        PUSHs (sv_2mortal (newSVnv (c2)));
}

