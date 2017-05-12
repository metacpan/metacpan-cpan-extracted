#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <sys/types.h>
#include <unistd.h>
#include <sys/mman.h>

#include "../gppport.h"

/* loosely based on the program vbidecode.cc by Ralph Metzler */

typedef unsigned int UI;
typedef unsigned char u8;
typedef U16 u16;

/* calculates odd parity, medium-efficient */
static int
parodd(U32 data)
{
  u8 p4[16] = { 0,1,1,0, 1,0,0,1, 1,0,0,1, 0,1,1,0 };
  int parity = 1;

  do {
    parity ^= p4[data & 15];
    data >>= 4;
  } while (data);

  return parity;
}

static u8 invtab[256] = {
  0x00, 0x80, 0x40, 0xc0, 0x20, 0xa0, 0x60, 0xe0, 
  0x10, 0x90, 0x50, 0xd0, 0x30, 0xb0, 0x70, 0xf0, 
  0x08, 0x88, 0x48, 0xc8, 0x28, 0xa8, 0x68, 0xe8, 
  0x18, 0x98, 0x58, 0xd8, 0x38, 0xb8, 0x78, 0xf8, 
  0x04, 0x84, 0x44, 0xc4, 0x24, 0xa4, 0x64, 0xe4, 
  0x14, 0x94, 0x54, 0xd4, 0x34, 0xb4, 0x74, 0xf4, 
  0x0c, 0x8c, 0x4c, 0xcc, 0x2c, 0xac, 0x6c, 0xec, 
  0x1c, 0x9c, 0x5c, 0xdc, 0x3c, 0xbc, 0x7c, 0xfc, 
  0x02, 0x82, 0x42, 0xc2, 0x22, 0xa2, 0x62, 0xe2, 
  0x12, 0x92, 0x52, 0xd2, 0x32, 0xb2, 0x72, 0xf2, 
  0x0a, 0x8a, 0x4a, 0xca, 0x2a, 0xaa, 0x6a, 0xea, 
  0x1a, 0x9a, 0x5a, 0xda, 0x3a, 0xba, 0x7a, 0xfa, 
  0x06, 0x86, 0x46, 0xc6, 0x26, 0xa6, 0x66, 0xe6, 
  0x16, 0x96, 0x56, 0xd6, 0x36, 0xb6, 0x76, 0xf6, 
  0x0e, 0x8e, 0x4e, 0xce, 0x2e, 0xae, 0x6e, 0xee, 
  0x1e, 0x9e, 0x5e, 0xde, 0x3e, 0xbe, 0x7e, 0xfe, 
  0x01, 0x81, 0x41, 0xc1, 0x21, 0xa1, 0x61, 0xe1, 
  0x11, 0x91, 0x51, 0xd1, 0x31, 0xb1, 0x71, 0xf1, 
  0x09, 0x89, 0x49, 0xc9, 0x29, 0xa9, 0x69, 0xe9, 
  0x19, 0x99, 0x59, 0xd9, 0x39, 0xb9, 0x79, 0xf9, 
  0x05, 0x85, 0x45, 0xc5, 0x25, 0xa5, 0x65, 0xe5, 
  0x15, 0x95, 0x55, 0xd5, 0x35, 0xb5, 0x75, 0xf5, 
  0x0d, 0x8d, 0x4d, 0xcd, 0x2d, 0xad, 0x6d, 0xed, 
  0x1d, 0x9d, 0x5d, 0xdd, 0x3d, 0xbd, 0x7d, 0xfd, 
  0x03, 0x83, 0x43, 0xc3, 0x23, 0xa3, 0x63, 0xe3, 
  0x13, 0x93, 0x53, 0xd3, 0x33, 0xb3, 0x73, 0xf3, 
  0x0b, 0x8b, 0x4b, 0xcb, 0x2b, 0xab, 0x6b, 0xeb, 
  0x1b, 0x9b, 0x5b, 0xdb, 0x3b, 0xbb, 0x7b, 0xfb, 
  0x07, 0x87, 0x47, 0xc7, 0x27, 0xa7, 0x67, 0xe7, 
  0x17, 0x97, 0x57, 0xd7, 0x37, 0xb7, 0x77, 0xf7, 
  0x0f, 0x8f, 0x4f, 0xcf, 0x2f, 0xaf, 0x6f, 0xef, 
  0x1f, 0x9f, 0x5f, 0xdf, 0x3f, 0xbf, 0x7f, 0xff, 
};

static u8 unhamtab[256] = {
  0x01, 0xff, 0x81, 0x01, 0xff, 0x00, 0x01, 0xff, 
  0xff, 0x02, 0x01, 0xff, 0x0a, 0xff, 0xff, 0x07, 
  0xff, 0x00, 0x01, 0xff, 0x00, 0x80, 0xff, 0x00, 
  0x06, 0xff, 0xff, 0x0b, 0xff, 0x00, 0x03, 0xff, 
  0xff, 0x0c, 0x01, 0xff, 0x04, 0xff, 0xff, 0x07, 
  0x06, 0xff, 0xff, 0x07, 0xff, 0x07, 0x07, 0x87, 
  0x06, 0xff, 0xff, 0x05, 0xff, 0x00, 0x0d, 0xff, 
  0x86, 0x06, 0x06, 0xff, 0x06, 0xff, 0xff, 0x07, 
  0xff, 0x02, 0x01, 0xff, 0x04, 0xff, 0xff, 0x09, 
  0x02, 0x82, 0xff, 0x02, 0xff, 0x02, 0x03, 0xff, 
  0x08, 0xff, 0xff, 0x05, 0xff, 0x00, 0x03, 0xff, 
  0xff, 0x02, 0x03, 0xff, 0x03, 0xff, 0x83, 0x03, 
  0x04, 0xff, 0xff, 0x05, 0x84, 0x04, 0x04, 0xff, 
  0xff, 0x02, 0x0f, 0xff, 0x04, 0xff, 0xff, 0x07, 
  0xff, 0x05, 0x05, 0x85, 0x04, 0xff, 0xff, 0x05, 
  0x06, 0xff, 0xff, 0x05, 0xff, 0x0e, 0x03, 0xff, 
  0xff, 0x0c, 0x01, 0xff, 0x0a, 0xff, 0xff, 0x09, 
  0x0a, 0xff, 0xff, 0x0b, 0x8a, 0x0a, 0x0a, 0xff, 
  0x08, 0xff, 0xff, 0x0b, 0xff, 0x00, 0x0d, 0xff, 
  0xff, 0x0b, 0x0b, 0x8b, 0x0a, 0xff, 0xff, 0x0b, 
  0x0c, 0x8c, 0xff, 0x0c, 0xff, 0x0c, 0x0d, 0xff, 
  0xff, 0x0c, 0x0f, 0xff, 0x0a, 0xff, 0xff, 0x07, 
  0xff, 0x0c, 0x0d, 0xff, 0x0d, 0xff, 0x8d, 0x0d, 
  0x06, 0xff, 0xff, 0x0b, 0xff, 0x0e, 0x0d, 0xff, 
  0x08, 0xff, 0xff, 0x09, 0xff, 0x09, 0x09, 0x89, 
  0xff, 0x02, 0x0f, 0xff, 0x0a, 0xff, 0xff, 0x09, 
  0x88, 0x08, 0x08, 0xff, 0x08, 0xff, 0xff, 0x09, 
  0x08, 0xff, 0xff, 0x0b, 0xff, 0x0e, 0x03, 0xff, 
  0xff, 0x0c, 0x0f, 0xff, 0x04, 0xff, 0xff, 0x09, 
  0x0f, 0xff, 0x8f, 0x0f, 0xff, 0x0e, 0x0f, 0xff, 
  0x08, 0xff, 0xff, 0x05, 0xff, 0x0e, 0x0d, 0xff, 
  0xff, 0x0e, 0x0f, 0xff, 0x0e, 0x8e, 0xff, 0x0e, 
};

#define VBI_BPL		2048

#define FREQ_PAL	35.468950
#define FREQ_NTSC	28.636363
#define FREQ		FREQ_PAL

#define FREQ_VT_PAL	6.9375
#define FREQ_VT_NTSC	5.72725
#define FREQ_VT		FREQ_VT_PAL /* Replace by FREQ_VT_NTSC and pray that it works */
/*#define FREQ_VT 6.165*/ /* teletext-like signal on france, 0xe7 instead of 0x27 */
#define FREQ_CRYPT	4.5	/* found on premiere */
#define FREQ_VPS	2.5	/* probably only pal */
#define FREQ_VDAT	2.0	/* videodat */
#define FREQ_VC		0.77	/* videocrypt, just ignore */

#define VBI_VT		0x0001
#define VBI_VPS		0x0002
#define VBI_VDAT	0x0004
#define VBI_VC		0x0008
#define VBI_OTHER	0x0010
#define VBI_EMPTY	0x8000

typedef long FP;

#define FP_BITS		16
#define FP_0_5		D2FP(0.5)

#define D2FP(d)		((FP)((d) * (1<<FP_BITS) + 0.5))
#define I2FP(i)		((FP)(i) << FP_BITS)
#define FP2I(fp)	(((fp) + FP_0_5) >> FP_BITS)

#define VT_COLS		40
#define VT_LINES	36

typedef struct {
  UI types;		/* required types */

  int offset;		/* signal offset */
  int did_agc : 1;	/* did we already do agc this frame? */

  int y;		/* the line number */
  u8 *line;		/* the current line */
  FP step;		/* the bit step */
  FP pos;		/* position */
} decoder;

static void
decoder_init (decoder *dec, UI types)
{
  dec->types = types;
  dec->did_agc = 0;
}

static void
decoder_scan_start (decoder *dec, UI a, UI b)
{
  u8 *p = dec->line + a;
  UI med = 128 - dec->offset;
  do
    {
      if (*p >= med)
        break;
    }
  while (++p < dec->line + b);

  /* find maximum */
  while (p[1] > p[0])
    p++;

  dec->pos = I2FP (p - dec->line);
}
    

static u8
get_byte (decoder *dec)
{
  u8 byte;
  int bit = 8;

  /* if the next bit is a one bit, try to re-center the decoder on it */
  if ((dec->offset + dec->line[FP2I(dec->pos)]) & 0x80)
    {
      /*if (dec->line[FP2I(dec->pos)] < dec->line[FP2I(dec->pos)+1])
        dec->pos += I2FP(1);*/ /* why is this casuing checksum errors? */
      /*if (dec->line[FP2I(dec->pos)] < dec->line[FP2I(dec->pos)-1])
        dec->pos -= I2FP(1);*/
    }

  byte=0;
  do
    {
      byte >>= 1;
      byte |= ((dec->offset + dec->line[FP2I(dec->pos)]) & 0x80);
      dec->pos += dec->step;
    }
  while (--bit);

  return byte;
}

/* get shift-encoded byte */
static u8
get_byte_SE (decoder *dec)
{
  u8 byte;
  int bit = 8;

  do
    {
      byte >>= 1;
      byte |= (dec->line[FP2I(dec->pos)]
             > dec->line[FP2I(dec->pos + dec->step/2)]) << 7;
      dec->pos += dec->step;
    }
  while (--bit);

  /* if the next bit is a one bit, try to re-center the decoder on it */
  if (dec->line[FP2I(dec->pos)] > 128-dec->offset)
    {
      if (dec->line[FP2I(dec->pos)] > dec->line[FP2I(dec->pos)+1])
        dec->pos += I2FP(1);
      if (dec->line[FP2I(dec->pos)] < dec->line[FP2I(dec->pos)-1])
        dec->pos -= I2FP(1);
    }

  return byte;
}

static u8
unham4(u8 a)
{
  return unhamtab[a] & 15;
}

static u8
unham8(u8 a, u8 b)
{
  u8 c1 = unhamtab[a];
  u8 c2 = unhamtab[b];

  if ( (c1|c2) & 0x40)
    /* 2 bit error */;

  return (c1 & 15)
       | (c2 << 4);
}

static u16 unham16(u8 a, u8 b, u8 c)
{
   U32 d = (((c << 8) | b) << 8) | c;
   int A = parodd (d & 0x555555);
   int B = parodd (d & 0x666666);
   int C = parodd (d & 0x787878);
   int D = parodd (d & 0x007f80);
   int E = parodd (d & 0x7f8000);
   int F = parodd (d & 0xffffff);
   int bit;

   d = (((d >> 16) & 0x7f) << 11)
     | (((d >>  8) & 0x7f) <<  4)
     | (((d >>  4) & 0x07) <<  1)
     | (((d >>  2) & 0x01)      );

   if (A&B&C&D&E)
     return d;
   if (F)
     return -1; /* double bit error */

   /* correct the single bit error */
   return d ^ (1 << (31 - 16*E + 8*D + 4*C + 2*B + A));
}

#define rev(byte) (invtab [(u8)(byte)])

static SV *
decode_vps (u8 *data)
{
  AV *av  = newAV ();

  char name = rev (data[3]);

  av_push (av, newSViv (VBI_VPS));
  av_push (av, newSVpvn (&name, 1));
  av_push (av, newSViv (data[4] & 3)); /* "unknown", "stereo  ", "mono   ", "dual   " */
  /* ch, day, mon, hour, min */
  av_push (av, newSViv (data[ 4] <<12 & 0xf000
                      | data[10]      & 0x00c0
                      | data[12] <<10 & 0x0c00
                      | data[13] << 2 & 0x0300
                      | data[13]      & 0x003f));
  av_push (av, newSViv (rev (data[10]) >> 1 & 31));
  av_push (av, newSViv (rev (data[10]) << 3 & 8 | rev (data[11]) >> 5));
  av_push (av, newSViv (rev (data[11]) & 31));
  av_push (av, newSViv (rev (data[12]) >> 2));
  av_push (av, newSViv (rev (data[14])));

  return newRV_noinc ((SV*)av);
}

static SV *
decode_vt (u8 *data)
{
   AV *av  = newAV ();
   u8 mpag = unham8 (data[3], data[4]);
   u8 mag = mpag & 7;
   u8 pack = (mpag & 0xf8) >> 3;

   av_push (av, newSViv (VBI_VT));
   av_push (av, newSViv (mag));
   av_push (av, newSViv (pack));
   
   switch (pack)
     {
       /* ets300-706 */
       case 0:
         av_push (av, newSVpvn (data+5, 40));
         av_push (av, newSViv  (unham8 (data[5], data[6]) | (mag << 8)));
         av_push (av, newSViv  (unham8 (data[7], data[8])
                                | (unham8 (data[9], data[10]) << 8)
                                | (unham8 (data[11], data[12]) << 16)));
         break;
       case  1: case  2: case  3: case  4: case  5: case  6: case  7: case  8: case  9: case 10:
       case 11: case 12: case 13: case 14: case 15: case 16: case 17: case 18: case 19: case 20:
       case 21: case 22: case 23: case 24: case 25:
         av_push (av, newSVpvn (data+5, 40));
         break;
       case 26: case 27: case 28: case 29: /* enhancement packets */
         av_push (av, newSViv (unham4 (data[5])));
         av_push (av, newSViv (unham16 (data[ 6], data[ 7], data[ 8])));
         av_push (av, newSViv (unham16 (data[ 9], data[10], data[11])));
         av_push (av, newSViv (unham16 (data[12], data[13], data[14])));
         av_push (av, newSViv (unham16 (data[15], data[16], data[17])));
         av_push (av, newSViv (unham16 (data[18], data[19], data[20])));
         av_push (av, newSViv (unham16 (data[21], data[22], data[23])));
         av_push (av, newSViv (unham16 (data[24], data[25], data[26])));
         av_push (av, newSViv (unham16 (data[27], data[28], data[29])));
         av_push (av, newSViv (unham16 (data[30], data[31], data[32])));
         av_push (av, newSViv (unham16 (data[33], data[34], data[35])));
         av_push (av, newSViv (unham16 (data[36], data[37], data[38])));
         av_push (av, newSViv (unham16 (data[39], data[40], data[41])));
         av_push (av, newSViv (unham16 (data[42], data[43], data[44])));
         break;
       /* ets300-706 & ets300-231 */
       case 30:
         {
           UI dc = unham4 (data[5]);
           av_push (av, newSViv (dc));
           if ((dc >> 1) == 0)
             {
               av_push (av, newSViv (unham8 (data[6], data[7]) | (mag << 8)));
               av_push (av, newSViv (unham8 (data[8], data[9])
                                     | unham8 (data[10], data[11]) << 8));
               av_push (av, newSViv (rev (data[12]) << 8 | rev (data[13])));
             }
           else if ((dc >> 1) == 8)
             {
               /* pdc */
             }
         }
         break;
       case 31:
         {
           UI ft = unham4 (data[5]);
           UI al = unham4 (data[6]);
           UI i, addr = 0;

           /* ets300-708, IDL */
           /* http://sunsite.cnlab-switch.ch/ftp/mirror/internet-drafts/draft-ietf-ipvbi-tv-signal-00.txt */

           for(i=0; i<al&7; i++)
             addr = addr << 4 | unham4 (data[i+7]);

           av_push (av, newSViv (ft));
           av_push (av, newSViv (addr));
           break;
         }
       default:
         av_push (av, newSVpvn (data+5, 40));
     }
   return newRV_noinc ((SV*)av);
}

static SV *
decoder_decode_other (decoder *dec)
{
   AV *av  = newAV ();
   FP pos = dec->pos;
   u8 data[6];

   av_push (av, newSViv (VBI_OTHER));

   dec->step = D2FP (FREQ / FREQ_CRYPT); /* found on premiere */
   data [0] = get_byte (dec);
   data [1] = get_byte (dec);
   data [2] = get_byte (dec);
   if (data[0] == 0x55 && data[1] == 0xd0 && data[2] == 0x18)
     {
       /* premiere */
       av_push (av, newSViv (1));
     }
   else
     av_push (av, newSViv (0));

   return newRV_noinc ((SV*)av);
}

static SV *
decode_empty ()
{
   AV *av  = newAV ();
   av_push (av, newSViv (VBI_EMPTY));
   return newRV_noinc ((SV*)av);
}

static SV *
decoder_decode (decoder *dec, UI y, u8 *line)
{
  UI type;
  u8 data[45];			/* 45 bytes per line are max. */
  UI i;
  int did_agc;

  type = VBI_VT | VBI_EMPTY | VBI_OTHER | VBI_VC;	/* can be everywhere */
  if (y == 16 - 7) type |= VBI_VPS;
  if (y >  17 - 7) type |= VBI_VDAT;

  type &= dec->types;

  /* don't do anything unless we need to */
  if (type)
    {
      dec->line = line;
      dec->y = y;
      dec->pos = 0;

      did_agc = dec->did_agc;

      /* maybe do agc? */
      if (!dec->did_agc || y == 20-7)
	{
	  u8 *n = line + 120;
	  u8 max = 0, min = 255;
	  do
	    {
	      if (*n > max) max = *n;
	      if (*n < min) min = *n;
	    }
	  while (++n < line + 300);

          if (max > min + 30)
            {
              dec->offset = 128 - (((int)max + (int)min) >> 1);
              dec->did_agc = 1;
            }
	}

      if (dec->did_agc)
        {
          if (type & VBI_VT)
            {
              dec->step = D2FP (FREQ / FREQ_VT);
              decoder_scan_start (dec, 50, 350);

              data[0] = get_byte (dec);
              if ((data[0] & 0xfe) == 0x54)
                {
                  data[1] = get_byte (dec);
                  switch (data[1])
                    {
                    case 0x27:
                      dec->pos -= dec->step * 2;
                    case 0x4e:
                      dec->pos -= dec->step * 2;
                    case 0x9d:
                      dec->pos -= dec->step * 2;
                    case 0x75:
                      dec->pos -= dec->step * 2;
                    case 0xd5:
                      dec->pos -= dec->step * 2;
                      data[1] = 0x55;
                    case 0x55:
                      break;
                    default:
                      ; /* no teletext page */
                    }

                  if (data[1] == 0x55)
                    {
                      data[2] = get_byte (dec);
                      if (data[2] == 0x27 || data[2] == 0xe7)
                        {
                          for (i = 3; i < 45; i++)
                            data[i] = get_byte (dec);
                          return decode_vt (data);
                        }
                    }
                }
            }

          if (type & VBI_VPS)
            {
              decoder_scan_start (dec, 150, 260);
              dec->step = D2FP (FREQ / FREQ_VPS);	/* shift encoding, two "pixels"/bit (skip the 2nd) */
              data[0] = get_byte_SE (dec);
              if (data[0] == 0xff)
                {
                  data[1] = get_byte_SE (dec);
                  if (data[1] == 0x5d || data[1] == 0x5f)
                    {
                      for (i = 2; i < 16; i++)
                        data[i] = get_byte_SE (dec);
                      return decode_vps (data);
                    }
                }
            }

#if 0
          if (type & VBI_VDAT)
            {
              dec->step = D2FP (FREQ / FREQ_VDAT);
              decoder_scan_start (dec, 150, 200);
            }

          if (type & VBI_VC)
            {
              dec->step = D2FP (FREQ / FREQ_VC);
              decoder_scan_start (dec, 150, 200);
            }
#endif

          /* watch out for empty lines, test signals etc.. */
          if (type & VBI_OTHER)
            {
              dec->did_agc = did_agc; /* other signals do not affect agc, yet */

              dec->step = D2FP (FREQ);
              decoder_scan_start (dec, 100, 500);
              if (dec->pos < I2FP (450))
                return decoder_decode_other (dec);
            }
        }

      dec->did_agc = did_agc;

      if (type & VBI_EMPTY)
	return decode_empty ();
    }

  return 0;
}

/* vtx decoding routines taken from videotext-0.6.971023,
 * Copyright (c) 1994-96 Martin Buck */

#define VTX_COLMASK 0x07
#define VTX_BGMASK  (0x07 << 3)
#define VTX_G1      (1 << 6)
#define VTX_GRSEP   (1 << 8)
#define VTX_HIDDEN  (1 << 9)
#define VTX_BOX     (1 << 10)
#define VTX_FLASH   (1 << 11)
#define VTX_DOUBLE1 (1 << 12)
#define VTX_DOUBLE2 (1 << 13)
#define VTX_INVERT  (1 << 14)
#define VTX_DOUBLE  (VTX_DOUBLE1 | VTX_DOUBLE2)

static const u8 g0_to_iso_table[256] =
  "                                "
  " !\"#$%&'()*+,-./0123456789:;<=>?"
  "@ABCDEFGHIJKLMNOPQRSTUVWXYZAOU^#"
  "-abcdefghijklmnopqrstuvwxyzaous#"
  "                                "
  "                                "
  "                                "
  "                                ";

/* one-to-one copy */
static int
decode_vtpage (u8 *src, UI lines, u8 *chr, u16 *attr)
{
  UI line, col, pos, graphics, grhold, doubleht, nextattr = 0;
  u16 *lastattr, default_attrib = 7, next_attrib;
  u8 c, *lastchr, default_chr = ' ';
  UI lang;
  
  lang = 4;
  pos = 0;
  doubleht = 0;

  for (line = 0; line < lines; line++) {
    lastchr = &default_chr;
    lastattr = &default_attrib;
    graphics = grhold = 0;
    if (doubleht && pos > 40) {
      for (col = 0; col <= 39; col++) {
        if (attr[pos - 40] & VTX_DOUBLE1) {
          chr[pos] = chr[pos - 40];
          chr[pos - 40] = ' ';
          attr[pos] = (attr[pos - 40] & ~VTX_DOUBLE1) | VTX_DOUBLE2;
        } else {
          chr[pos] = ' ';
          attr[pos] = attr[pos - 40];
        }
        pos++;
      }
      doubleht = 0;
    } else {
      for (col = 0; col <= 39; col++) {
        c = src[pos];
        if (parodd(c)) {
          chr[pos] = 254;					/* Parity error */
          attr[pos] = 7;
          /* return 0 */ /*?*/
        } else if ((c & 0x7f) >= 32) {			/* Normal character */
          c &= 0x7f;
          if (!graphics || (c >= 64 && c <= 95)) {
            chr[pos] = g0_to_iso_table [c];
            attr[pos] = *lastattr;
          } else {
            chr[pos] = c + (c >= 96 ? 64 : 96);
            attr[pos] = *lastattr | VTX_G1;
          }
        } else {
          c &= 0x7f;
          chr[pos] = ((grhold && graphics ) ? *lastchr : ' ');
          if (c <= 7) {					/* Set alphanumerics-color */
            attr[pos] = *lastattr;
            next_attrib = (*lastattr & ~(VTX_COLMASK | VTX_HIDDEN)) + c;
            nextattr = 1;
            graphics = 0;
          } else if (c == 8 || c == 9) {			/* Flash on/off */
            attr[pos] = (*lastattr & ~VTX_FLASH) + VTX_FLASH * (c == 8);
          } else if (c == 10 || c == 11) {			/* End/start box */
            attr[pos] = (*lastattr & ~VTX_BOX) + VTX_BOX * (c == 11);
          } else if (c == 12 || c == 13) {			/* Normal/double height */
            attr[pos] = (*lastattr & ~VTX_DOUBLE1) + VTX_DOUBLE1 * (c == 13);
            if (c == 13)
              doubleht = 1;
          } else if (c == 14 || c == 15 || c == 27) {	/* SO, SI, ESC (ignored) */
            attr[pos] = *lastattr;
          } else if (c >= 16 && c <= 23) {			/* Set graphics-color */
            attr[pos] = *lastattr;
            next_attrib = (*lastattr & ~(VTX_COLMASK | VTX_HIDDEN)) + c - 16;
            nextattr = 1;
            graphics = 1;
          } else if (c == 24) {				/* Conceal display */
            attr[pos] = *lastattr | VTX_HIDDEN;
          } else if (c == 25 || c == 26) {			/* Contiguous/separated graphics */
            attr[pos] = (*lastattr & ~VTX_GRSEP) + VTX_GRSEP * (c == 26);
          } else if (c == 28) {				/* Black background */
            attr[pos] = *lastattr & ~VTX_BGMASK;
          } else if (c == 29) {				/* Set background */
            attr[pos] = (*lastattr & ~VTX_BGMASK) + ((*lastattr & VTX_COLMASK) << 3);
          } else if (c == 30 || c == 31) {			/* Hold/release graphics */
            attr[pos] = *lastattr;
            grhold = (c == 30);
            if (grhold && graphics)
              chr[pos] = *lastchr;
          } else {
            return 0;
          }
        }
        lastchr = chr + pos;
        if (nextattr) {
          lastattr = &next_attrib;
          nextattr = 0;
        } else {
          lastattr = attr + pos;
        }
        pos++;
      }
    }
  }
  return 1;
}

static SV *
decode_ansi (u8 *chr, u16 *atr)
{
  UI x;
  SV *sv = newSVpvn ("", 0);
  u16 o;

  for (x=0; x < VT_COLS; x++)
    {
      u16 a = *atr++;
      if (x == 0 || (a & 0x07) != (o & 0x07))
        sv_catpvf (sv, "\x1b[3%dm", a & 7);
      if (x == 0 || (a & 0x38) != (o & 0x38))
        sv_catpvf (sv, "\x1b[4%dm", (o & 0x38)>>3);
      if (x == 0 || (a & VTX_FLASH) != (o & VTX_FLASH))
        sv_catpvf (sv, "\x1b[%sm", a & VTX_FLASH ? "7" : "");

      sv_catpvf (sv, "%c", a & VTX_G1 ? 'x' : *chr);

      chr++;
      o = a;
    }

  sv_catpv (sv, "\x1b[37;40;0m");
  
  return sv;
}

#define valid_packet(sv) (SvPOK(packet) && SvCUR(packet) == 40)
#define consume_byte(store)				\
	if (bp >= 39)					\
	  {						\
            SV **sv = av_fetch(stream, pi, 0); pi++;	\
            if (!sv)					\
              goto eostream;				\
            packet = *sv;				\
            if (!valid_packet (pascket))			\
              goto skip;				\
            p = SvPV_nolen (packet);			\
            bp = 0;					\
          }						\
        (store) = p[++bp]

static void
decode_stream (AV *stream)
{
  dSP;

  while (av_len (stream) >= 0)
    {
      UI pi = 1;
      SV *packet = *av_fetch(stream, 0, 1);

      if (valid_packet (packet))
        {
          u8 *p = SvPV_nolen(packet);
          u8 bp = p[0] == 0xff ? p[1] : unham4 (p[0])*3+1;

          if (bp <= 12*3+1 && p[bp] == 0xa1)
            {
              u8 buf[4];

              consume_byte (buf[0]); consume_byte (buf[1]);
              consume_byte (buf[2]); consume_byte (buf[3]);

              {
                u16 sh = unham8 (buf[0], buf[1]) | unham8 (buf[2], buf[3]) << 8;
                u8  bt = sh & 0x1f;
                u16 bl = sh >> 5;
                SV *block = sv_2mortal (newSVpvn (&bt, 1));

                while (bl--)
                  {
                    consume_byte (buf[0]);
                    sv_catpvn (block, buf, 1);
                  }

                EXTEND (SP, 1);
                PUSHs (block);

                /* optimize, do only when still in first packet! */
                do {
                  if (bp >= 39)
                    break;

                  bp++;
                  if (p[bp] == 0xa1)
                    {
                      p[0] = 0xff;
                      p[1] = bp;
                      pi--;
                      break;
                    }
                } while (p[bp] = 0x5e);
              }
            }
        }

skip:
      while (pi--)
        SvREFCNT_dec(av_shift(stream));
    }
eostream:

  PUTBACK;
}

static u8 *
unham_block (u8 *src, UI len, u8 *dst, UI dlen)
{
  u16 sh = *src | (len-1)<<5;
  u8 sum = ( sh        & 15)
         + ((sh >>  4) & 15)
         + ((sh >>  8) & 15)
         + ((sh >> 12) & 15);
  
  if (len < 5)
    return 0;
  
  sum += unham8 (src[1], src[2]);
  src += 3; len -= 3;

  dlen--;

  if (len < dlen)
    return 0;

  while (dlen)
    {
      *dst = unham8 (src[0], src[1]);
      sum += (*dst >> 4) + (*dst & 15);
#if 0
      printf ("%02x ", *dst);
#endif
      dst++; src += 2; dlen--;
    }
#if 0
  printf ("\n");
  printf ("sh = %04x, len = %02x, sum = %02x\n", sh, len, sum);
#endif
  if (sum)
    return 0;

  return src;
}

/* must not be a macro, see nvec */
static U32
vec(u8 *d, UI bit, UI len)
{
  U32 word = bit >> 3;

  /*printf ("vec(%d,%d) %d (%d)\n",bit,len,(bit & 7) + len,(bit & 7) + len < 32);*/
  assert ((bit & 7) + len < 32);

  word = (d[word]        )
       | (d[word+1] <<  8)
       | (d[word+2] << 16)
       | (d[word+3] << 24);

  return (word >> (bit & 7)) & (((U32)1 << len) - 1);
}

#define hv_store_sv(name,value) hv_store (hv, #name, strlen(#name), (SV*)(value), 0)
#define hv_store_iv(name,value) hv_store_sv (name, newSViv (value))
#define nvec(bits) vec (c, (ofs += (bits)) - (bits), (bits))

#define decode_escape_sequences(av)		\
  {						\
    UI no_escapes = nvec (8);			\
    av = newAV ();				\
    while (no_escapes--)			\
      {						\
        AV *esc = newAV ();			\
        av_push (esc, newSViv (nvec (10)));	\
        av_push (esc, newSViv (nvec (6)));	\
        av_push (esc, newSViv (nvec (8)));	\
        av_push (av, newRV_noinc((SV*)esc));	\
      }						\
  }

#define decode_transparent_string(sv, len)	\
  {						\
    UI l = len;					\
    sv = newSVpvn (s, l);			\
    s += l;					\
    while (l--)					\
      SvPV_nolen (sv)[l] &= 0x7f;		\
  }

#define decode_descriptor_loop(av, ll)		\
  av = newAV ();				\
  while (ll--)					\
    {						\
      AV *desc = newAV ();			\
      av_push (desc, newSViv (nvec (6)));	\
      av_push (desc, newSViv (nvec (6)));	\
      av_push (desc, newSViv (nvec (8)));	\
      av_push (av, newRV_noinc((SV*)desc));	\
    }

static void
decode_epg (HV *hv, UI appid, u8 *c, u8 *s)
{
  UI ofs = 16;
  UI len;
  AV *av;
  SV *sv;

  hv_store_iv (ca_mode,    nvec(2));
  hv_store_iv (_copyright, nvec(1));

  ofs++; /* reserved */

  switch (appid)
    {
      case 1:
        {
          hv_store_iv (epg_version,	nvec( 6));
          hv_store_iv (epg_version_swo,	nvec( 6));
          hv_store_iv (no_navigation,	nvec(16));
          hv_store_iv (no_osd,		nvec(16));
          hv_store_iv (no_message,	nvec(16));
          hv_store_iv (no_navigation_swo,nvec(16));
          hv_store_iv (no_osd_swo,	nvec(16));
          hv_store_iv (no_message_swo,	nvec(16));
          len = nvec(8);
          hv_store_iv (this_network_op,	nvec( 8));
          decode_transparent_string (sv, nvec (5));
          hv_store_sv (service_name, sv);
          hv_store_iv (no_updates,	nvec( 1));

          ofs += 2;

          av = newAV ();
          while (len--)
            {
              HV *hv = newHV ();
              int LTO;
              hv_store_iv (cni,			nvec (16));
              LTO = nvec (7) * 15;
              if (nvec(1))
                LTO = -LTO;
              hv_store_iv (lto,	LTO);
              hv_store_iv (no_days,		nvec( 5));
              decode_transparent_string (sv,	nvec( 5));
              hv_store_sv (netwop_name,	sv);
              hv_store_iv (default_alphabet,	nvec( 7));
              hv_store_iv (prog_start_no,	nvec(16));
              hv_store_iv (prog_stop_no,	nvec(16));
              hv_store_iv (prog_stop_no_swo,	nvec(16));
              hv_store_iv (network_add_info,	nvec(11));
              
              av_push (av, newRV_noinc ((SV*)hv));
            }
          hv_store_sv (networks, newRV_noinc ((SV*)av));
          break;
        }
      case 2:
        {
          UI background_reuse;

          hv_store_iv (block_no,	nvec(16));
          hv_store_iv (audio_mode,	vec(c, ofs, 12) & 3);
          hv_store_iv (feature_flags,	nvec(12));
          hv_store_iv (netwop_no,	nvec( 8));
          hv_store_iv (start_time,	nvec(16));
          hv_store_iv (start_date,	nvec(16));
          hv_store_iv (stop_time,	nvec(16));
          hv_store_iv (_pil,		nvec(20));
          hv_store_iv (parental_rating,	nvec( 4));
          hv_store_iv (editorial_rating,nvec( 3));
          {
            UI no_themes =		nvec( 3);
            UI no_sortcrit =		nvec( 3);
            UI descriptor_looplength =	nvec( 6);
            background_reuse = nvec( 1);

            av = newAV ();
            while (no_themes--)
              av_push (av, newSViv (nvec (8)));
            hv_store_sv (themes, newRV_noinc((SV*)av));

            av = newAV ();
            while (no_sortcrit--)
              av_push (av, newSViv (nvec (8)));
            hv_store_sv (sortcrits, newRV_noinc((SV*)av));

            decode_descriptor_loop (av, descriptor_looplength);
            hv_store_sv (descriptors, newRV_noinc((SV*)av));

            ofs = (ofs+7) & ~7;

            decode_escape_sequences (av);
            hv_store_sv (title_escape_sequences, newRV_noinc((SV*)av));
            decode_transparent_string (sv, nvec (8));
            hv_store_sv (title, sv);
          }

          if (background_reuse)
            hv_store_iv (title_length, nvec (16));
          else
            {
              decode_escape_sequences (av);
              hv_store_sv (shortinfo_escape_sequences, newRV_noinc((SV*)av));
              decode_transparent_string (sv, nvec (8));
              hv_store_sv (shortinfo, sv);

              len = nvec (3);
              ofs += 2;
              switch (len)
                {
                  case 0:
                    decode_escape_sequences (av);
                    hv_store_sv (longinfo_escape_sequences, newRV_noinc((SV*)av));
                    decode_transparent_string (sv, nvec (8));
                    hv_store_sv (longinfo, sv);
                    break;
                  case 1:
                    decode_escape_sequences (av);
                    hv_store_sv (longinfo_escape_sequences, newRV_noinc((SV*)av));
                    decode_transparent_string (sv, nvec (10));
                    hv_store_sv (longinfo, sv);
                    break;
                  default:
                    printf ("UNKNOWN LONGINFO TYPE %d\n", len);
                }
            }

          break;
        }
      case 3:
        {
          UI descriptor_ll;
          hv_store_iv (block_no,	nvec(16));
          hv_store_iv (header_size,	nvec( 2));
          len =	nvec(4);
          hv_store_iv (message_size,	nvec( 3));
          ofs++;
          descriptor_ll = nvec(6);
          decode_descriptor_loop (av, descriptor_ll);
          hv_store_sv (descriptors, newRV_noinc((SV*)av));
          ofs = (ofs+7) & ~7;

          decode_escape_sequences (av);
          hv_store_sv (header_escape_sequences, newRV_noinc((SV*)av));

          decode_transparent_string (sv, nvec(8));
          hv_store_sv (header, sv);

          hv_store_iv (message_attribute,nvec(8));

          av = newAV ();
          while (len--)
            {
              AV *av2;
              UI len;
              HV *hv = newHV ();

              hv_store_iv (next_id,   nvec(16));
              hv_store_iv (next_type, nvec( 4));

              len = nvec(4);
              av2 = newAV ();
              while (len--)
                {
                  UI kind = nvec(8);
                  av_push (av2, newSViv (kind));
                  switch (kind)
                    {
                      case 0x02: case 0x10: case 0x11: case 0x18:
                      case 0x20: case 0x21: case 0x22: case 0x23: case 0x24: case 0x25: case 0x26: case 0x27:
                      case 0x30: case 0x31: case 0x32: case 0x33: case 0x34: case 0x35: case 0x36: case 0x37:
                      case 0x40: case 0x41:
                        av_push (av2, newSViv (nvec ( 8)));
                        break;

                      case 0x80: case 0x81:
                        av_push (av2, newSViv (nvec (16)));
                        break;

                      case 0xc0:
                        av_push (av2, newSViv (nvec (12)));
                        av_push (av2, newSViv (nvec (12)));
                        break;

                      case 0xc8: case 0xc9:
                        av_push (av2, newSViv (nvec (24)));
                        break;

                      default:
                        abort ();
                    }
                }
              hv_store_sv (attributes, newRV_noinc((SV*)av2));
              
              decode_escape_sequences (av2);
              hv_store_sv (header_escape_sequences, newRV_noinc((SV*)av2));
              decode_transparent_string (sv, nvec(8));
              hv_store_sv (event, sv);

              av_push (av, newRV_noinc((SV*)hv));
            }
          hv_store_sv (events, newRV_noinc((SV*)av));

          break;
        }
      case 4:
        {
          UI block_no = nvec (16);
          UI descriptor_ll;
          UI msg_len;
          hv_store_iv (block_no,	block_no);
          hv_store_iv (message_attribute,nvec(8));
          hv_store_iv (header_size,	nvec(3));
          hv_store_iv (message_size,	nvec(3));
          descriptor_ll = nvec(6);
          if (!block_no)
            {
              decode_escape_sequences (av);
              hv_store_sv (message_escape_sequences, newRV_noinc((SV*)av));
              msg_len = nvec(10);
              ofs += 6;
            }

          decode_escape_sequences (av);
          hv_store_sv (header_escape_sequences, newRV_noinc((SV*)av));

          decode_transparent_string (sv, nvec(8));
          hv_store_sv (header, sv);

          if (!block_no)
            {
              decode_transparent_string (sv, msg_len);
              hv_store_sv (message, sv);
            }

          decode_descriptor_loop (av, descriptor_ll);
          hv_store_sv (descriptors, newRV_noinc((SV*)av));
          break;
        }
      case 5:
        {
          UI descriptor_ll;
          hv_store_iv (block_no,	nvec(16));
          descriptor_ll = nvec(6);
          decode_descriptor_loop (av, descriptor_ll);
          hv_store_sv (descriptors, newRV_noinc((SV*)av));
          ofs = (ofs+7) & ~7;

          decode_escape_sequences (av);
          hv_store_sv (message_escape_sequences, newRV_noinc((SV*)av));

          decode_transparent_string (sv, nvec(10));
          hv_store_sv (message, sv);

          break;
        }
      default:
        printf ("UNKNOWN EPG DATATYPE ($%02x)\n", appid);
    }
}

static SV *
decode_block(u8 *b, UI len, AV *bi)
{
  dSP;
  u8 ctrl[1024];
  u8 bt = *b;

  if (bt == 0)
    {
      if ((b = unham_block (b, len, ctrl, (len-1)>>1 )))
        {
          UI app_no = ctrl[0];
          UI app;
          av_clear (bi);
          for (app=1; app<=app_no; app++)
            av_store (bi, app, newSViv (vec (ctrl, app*16-8, 16)));
        }
    }
  else if (len >= 5)
    {
      if (bt <= av_len (bi) && SvOK(*av_fetch (bi, bt, 0)))
        {
          u16 appid = SvIV (*av_fetch (bi, bt, 0));
          if (appid == 0) /* EPG */
            {
              if ((b = unham_block (b, len, ctrl, unham8 (b[3], b[4]) | (unham4 (b[5]) << 8) & 1023)))
                {
                  HV *hv = newHV ();
                  /* _now_ we have an epg structure. decode it */

                  appid = vec(ctrl,10,6);
                  EXTEND (SP, 2);
                  PUSHs (sv_2mortal (newSViv (appid)));
                  PUSHs (sv_2mortal (newRV_noinc ((SV*)hv)));

                  decode_epg (hv, appid, ctrl, b);
                }
              else
                printf ("checksum error found block %d, len %d, appid = %d (clen 0)\n", bt, len, appid);
            }
          else
            /* other applications not defined (to my knowledge) */;
        }
      else
        /* no bundle info: can't parse yet */;
    }
  
  PUTBACK;
}

MODULE = Video::Capture::VBI		PACKAGE = Video::Capture::VBI

PROTOTYPES: ENABLE

int
unham4(data)
	SV *	data
        CODE:
        STRLEN len;
        unsigned char *d = (unsigned char *)SvPV (data, len);

        if (len < 1)
          croak ("unham4: length must be at least 1");

        RETVAL = unham4 (*d);
        OUTPUT:
        RETVAL
        
int
unham8(data)
	SV *	data
        CODE:
        STRLEN len;
        unsigned char *d = (unsigned char *)SvPV (data, len);

        if (len < 2)
          croak ("unham8: length must be at least 2");

        RETVAL = unham8 (d[0], d[1]);
        OUTPUT:
        RETVAL
        
void
decode_field(field, types)
	SV *	field
        unsigned int	types
        PPCODE:
{
        UI lines = SvCUR(field) / VBI_BPL;
        UI line;
        decoder dec;

        decoder_init (&dec, types);

        EXTEND (SP, lines);
        for (line = 0; line < lines; line++)
          {
            SV *sv = decoder_decode (&dec, line, ((u8*)SvPV_nolen(field)) + line * VBI_BPL);
            if (sv)
              PUSHs (sv_2mortal (sv));
          }
}

SV *
decode_vps(char *data)

SV *
decode_vt(char *data)

void
decode_vtpage(data)
	SV *	data
        PPCODE:
{
        u8  chr[VT_COLS*VT_LINES];
        u16 atr[VT_COLS*VT_LINES];
        UI lines;
        
        if (!SvPOK(data))
          XSRETURN_EMPTY;

        lines = SvCUR(data) / VT_COLS;

        if (lines > VT_LINES)
          croak ("videotext cannot have more than %d lines (argument has %d lines)\n", VT_LINES, lines);
        
        Zero(chr, VT_COLS*VT_LINES, u8);
        Zero(atr, VT_COLS*VT_LINES, u16);
        if (decode_vtpage (SvPV_nolen(data), lines, chr, atr))
          {
            AV *av = newAV ();
            UI n;

            for (n = 0; n < VT_COLS*lines; n++)
              av_push (av, newSViv (atr[n]));

            EXTEND (SP, 2);
            PUSHs (sv_2mortal (newSVpvn (chr, VT_COLS*lines)));
            PUSHs (sv_2mortal (newRV_noinc ((SV*)av)));
          }
}

PROTOTYPES: DISABLE

void
decode_ansi(chr, atr)
	SV *	chr
        SV *	atr
        PPCODE:
{
        UI lines = SvCUR(chr) / VT_COLS;
        UI attr_i = 0;
        u8 *_chr = SvPV_nolen (chr);
        u16 _atr[VT_COLS];
        
        EXTEND (SP, lines);

        while (lines--)
          {
            UI attr_j;
            for(attr_j = 0; attr_j < VT_COLS; attr_j++)
              _atr[attr_j] = SvIV (*av_fetch ((AV*)SvRV (atr), attr_i+attr_j, 1));

            PUSHs (sv_2mortal (decode_ansi (_chr, _atr)));

            _chr += VT_COLS;
            attr_i += VT_COLS;
          }
}

unsigned int
bcd2dec(bcd)
  	unsigned int bcd
        CODE:
{
        UI digit = 1;
        RETVAL = 0;
        while (bcd)
          {
            if ((bcd & 15) > 9)
              XSRETURN_EMPTY;

            RETVAL += (bcd & 15) * digit;
            digit *= 10;
            bcd >>= 4;
          }
}
	OUTPUT:
        RETVAL

PROTOTYPES: ENABLE

MODULE = Video::Capture::VBI		PACKAGE = Video::Capture::VBI::EPG

void
decode_stream(stream)
	SV *	stream
        PPCODE:
        if (!SvROK(stream) || SvTYPE(SvRV(stream)) != SVt_PVAV)
          croak ("decode_epg stream works on arrayrefs");

	PUTBACK;
        decode_stream ((AV*)SvRV(stream));
        SPAGAIN;

SV *
decode_block(block, bundle)
	SV *	block
        SV *	bundle
        PPCODE:
	if (!SvROK(bundle) || SvTYPE(SvRV(bundle)) != SVt_PVAV)
          croak ("bundle info must be arrayref");

        PUTBACK;
        decode_block (SvPV_nolen(block), SvCUR(block), (AV*)SvRV(bundle));
        SPAGAIN;

BOOT:
{
	HV *stash = gv_stashpvn("Video::Capture::VBI", 19, TRUE);

	newCONSTSUB(stash,"VBI_VT",	newSViv(VBI_VT));
	newCONSTSUB(stash,"VBI_VPS",	newSViv(VBI_VPS));
	newCONSTSUB(stash,"VBI_VDAT",	newSViv(VBI_VDAT));
	newCONSTSUB(stash,"VBI_VC",	newSViv(VBI_VC));
	newCONSTSUB(stash,"VBI_EMPTY",	newSViv(VBI_EMPTY));
	newCONSTSUB(stash,"VBI_OTHER",	newSViv(VBI_OTHER));

	newCONSTSUB(stash,"VTX_COLMASK",newSViv(VTX_COLMASK));
	newCONSTSUB(stash,"VTX_GRSEP",	newSViv(VTX_GRSEP));
	newCONSTSUB(stash,"VTX_HIDDEN",	newSViv(VTX_HIDDEN));
	newCONSTSUB(stash,"VTX_BOX",	newSViv(VTX_BOX));
	newCONSTSUB(stash,"VTX_FLASH",	newSViv(VTX_FLASH));
	newCONSTSUB(stash,"VTX_DOUBLE1",newSViv(VTX_DOUBLE1));
	newCONSTSUB(stash,"VTX_DOUBLE2",newSViv(VTX_DOUBLE2));
	newCONSTSUB(stash,"VTX_INVERT",	newSViv(VTX_INVERT));
	newCONSTSUB(stash,"VTX_DOUBLE",	newSViv(VTX_DOUBLE));
}
        
