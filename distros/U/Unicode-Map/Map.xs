/* 
 * $Id: Map.xs,v 1.28 1998/03/23 23:57:46 schwartz Exp $
 *
 * ALPHA version
 *
 * Unicode::Map - C extensions
 *
 * Interface documentation at Map.pm
 *
 * Copyright (C) 1998, 1999, 2000 Martin Schwartz. All rights reserved.
 * This program is free software; you can redistribute it and/or
 * modify it under the same terms as Perl itself.
 *
 * Contact: Martin Schwartz <martin@nacho.de>
 */

#ifdef __cplusplus
extern "C" {
#endif
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#ifdef __cplusplus
}
#endif

/* 
 * It seems that dowarn isn't defined on some systems, PL_dowarn not on 
 * others. Gisle Aas deals with it this way:
 */
#include "patchlevel.h"
#if PATCHLEVEL <= 4 && !defined(PL_dowarn)
   #define PL_dowarn dowarn
#endif

/*
 *
 * "Map.h"
 *
 */

#define M_MAGIC               0xb827 /* magic word */
#define MAP8_BINFILE_MAGIC_HI 0xfffe /* magic word for Gisle's file format */
#define MAP8_BINFILE_MAGIC_LO 0x0001 /* */

#define M_END   0       /* end */
#define M_INF   1       /* infinite subsequent entries (default) */
#define M_BYTE  2       /* 1..255 subsequent entries  */
#define M_VER   4       /* (Internal) file format revision. */
#define M_AKV   6       /* key1, val1, key2, val2, ... (default) */
#define M_AKAV  7       /* key1, key2, ..., val1, val2, ... */
#define M_PKV   8       /* partial key value mappings */
#define M_CKn   10      /* compress keys not */
#define M_CK    11      /* compress keys (default) */
#define M_CVn   13      /* compress values not */
#define M_CV    14      /* compress values (default) */

#define I_NAME  20      /* Info: (wstring) Character Set Name */
#define I_ALIAS 21      /* Info: (wstring) Charset alias (several entries ok) */
#define I_VER   22      /* Info: (wstring) Mapfile revision */
#define I_AUTH  23 	/* Info: (wstring) Mapfile authRess */
#define I_INFO  24      /* Info: (wstring) Some userEss definable string */

#define T_BAD   0	/* Type: unknown */
#define T_MAP8  1	/* Type: Map8 style */
#define T_MAP   2	/* Type: Map style */

#define num1_DEFAULT    M_INF;
#define method1_DEFAULT M_AKV;
#define keys1_DEFAULT   M_CK;
#define values1_DEFAULT M_CV;

/* No function prototypes (as very old C-Compilers don't like them) */

/*
 *
 * "Map.c"
 *
 */

U8  _byte(char** buf) { 
   U8* tmp = (U8*) *buf; *buf+=1; return tmp[0]; 
}
U16 _word(char** buf) {
   U16 tmp; memcpy ((char*) &tmp, *buf, 2); *buf+=2; return ntohs(tmp);
}
U32 _long(char** buf) {
   U32 tmp; memcpy ((char*) &tmp, *buf, 4); *buf+=4; return ntohl(tmp);
}

AV* __system_test (void) {
/*
 * If this test suit gets passed ok, the C methods will probably work.
 */
   char* check = "\x01\x04\xfe\x83\x73\xf8\x04\x59\x19";
   char* buf;
   AV*   list = newAV();
   U32   i, k;

   /*
    * Have the Unn the bytesize I assume?
    */
   if (sizeof(U8)!=1)  { av_push (list, newSVpv("1a", 1)); }
   if (sizeof(U16)!=2) { av_push (list, newSVpv("1b", 1)); }
   if (sizeof(U32)!=4) { av_push (list, newSVpv("1c", 1)); }
   
   /*
    * Does _byte work?
    */
   buf = check;                   
   if (_byte(&buf) != 0x01) { av_push(list, newSVpv("2a", 2)); }
   if (_byte(&buf) != 0x04) { av_push(list, newSVpv("2b", 2)); }
   if (_byte(&buf) != 0xfe) { av_push(list, newSVpv("2c", 2)); }
   if (_byte(&buf) != 0x83) { av_push(list, newSVpv("2d", 2)); }
   
   /*
    * Are _word and _long really reading Network order?
    */
   if (_word(&buf) != 0x73f8)     { av_push(list, newSVpv("3a", 2)); }
   if (_word(&buf) != 0x0459)     { av_push(list, newSVpv("3b", 2)); }
   buf = check + 1;
   if (_byte(&buf) != 0x04)       { av_push(list, newSVpv("4a", 2)); }
   if (_long(&buf) != 0xfe8373f8) { av_push(list, newSVpv("4b", 2)); }
   
   /*
    * Is U32 really not an I32?
    */
   buf = check + 2;
   i = _long(&buf);
   i ++;
   if (i != 0xfe8373f9) { av_push(list, newSVpv("5", 1)); }
   
   k = htonl(0x12345678);
   if (memcmp((char*)&k+(4-1), "\x78", 1)) { 
      av_push(list, newSVpv("6a", 2)); 
   }
   if (memcmp((char*)&k+(4-2), "\x56\x78", 2)) { 
      av_push(list, newSVpv("6b", 2)); 
   }
   if (memcmp((char*)&k+(4-4), "\x12\x34\x56\x78", 4)) { 
      av_push(list, newSVpv("6c", 2)); 
   }

   return (list);
}

int
__limit_ol (SV* string, SV* o, SV* l, char** ro, U32* rl, U16 cs) {
/*
 * Checks, if offset and length are valid. If offset is negative, it is
 * treated like a negative offset in perl.
 *
 * When successful, sets ro (real offset) and rl (real length).
 */
   STRLEN  slen;
   char*   address;
   I32     offset;
   U32     length;

   *ro = 0;
   *rl = 0;

   if (!SvOK(string)) {
      if (PL_dowarn) { warn ("String undefined!"); }
      return (0);
   }

   address = SvPV (string, slen);
   offset  = SvOK(o) ? SvIV(o) : 0;
   length  = SvOK(l) ? SvIV(l) : slen;

   if (offset < 0) {
      offset += slen;
   }

   if (offset < 0) {
      offset = 0;
      length = slen;
      if (PL_dowarn) { warn ("Bad negative string offset!"); }
   }

   if (offset > slen) {
      offset = slen;
      length = 0;
      if (PL_dowarn) { warn ("String offset to big!"); }
   }

   if (offset + length > slen) {
      length = slen - offset;
      if (PL_dowarn) { warn ("Bad string length!"); }
   }

   if (length % cs != 0) {
      if (length>cs) {
         length -= (length % cs);
      } else {
         length = 0;
      }
      if (PL_dowarn) { warn("Bad string size!"); }
   }

   *ro = address + offset;
   *rl = length;

   return (1);
}

int
__get_mode (char** buf, U8* num, U8* method, U8* keys, U8* values) {
   U8 type, size;

   type = _byte(buf);
   size = _byte(buf); *buf += size;

   switch (type) {
      case M_INF:
      case M_BYTE:
         *num = type; break;
      case M_AKV:
      case M_AKAV:
      case M_PKV:
         *method = type; break;
      case M_CKn:
      case M_CK:
         *keys = type; break;
      case M_CVn:
      case M_CV:
         *values = type; break;
   }
   return (type);
}

/*
 *  void = __read_binary_mapping (bufS, oS, UR, CR)
 *
 *  Table of mode combinations:
 *  
 *  Mode      | n1  n2  | INF  BYTE  |  CK  CKn  |  CV  CVn
 *  ---------------------------------------------------------
 *  AKV       |         |            |           |
 *  AKAV      |         |            |           |
 *  PKV   ok  | ==1 ==1 |      ok    |  ok       |  ok
 */
int
__read_binary_mapping (SV* bufS, SV* oS, SV* UR, SV* CR) {
   char* buf;
   U32 o;
   HV* U; SV* uR; HV* u;
   HV* C; SV* cR; HV* c;
   
   int   buflen;
   char* bufmax;
   U8    cs1, cs1b, cs2, cs2b;
   U32   n1, n2;
   U16   check;
   U16   type=T_BAD;
   U8    num1, method1, keys1, values1;
   I16   kn, vn;
   U32   kbegin, vbegin;
   SV*   Ustr;
   SV*   Cstr;
   SV**  tmp_spp;
   
   buf =        SvPVX (bufS);
   o   =        SvIV (oS);
   U   = (HV *) SvRV (UR);
   C   = (HV *) SvRV (CR);

   buflen = SvCUR(bufS); if (buflen < 2) { 
      /*
       * Too short file. (No place for magic)
       */
      if ( PL_dowarn ) { warn ( "Bad map file: too short!" ); }
      return (0); 
   }
   bufmax = buf + buflen;
   buf += o;
   check = _word(&buf);

   if (check == M_MAGIC) {
      type = T_MAP;
   } else if (
      ( check == MAP8_BINFILE_MAGIC_HI ) &&
      ( _word(&buf) == MAP8_BINFILE_MAGIC_LO )
   ) {
      type = T_MAP8;
   }

   if (type == T_BAD) {
      if ( PL_dowarn ) { warn ( "Unknown map file format!" ); }
      return (0);
   }

   num1    = num1_DEFAULT;
   method1 = method1_DEFAULT;
   keys1   = keys1_DEFAULT;
   values1 = values1_DEFAULT;

   while (buf<bufmax) {
      U8 num2, method2, keys2, values2;
      num2=num1; method2=method1; keys2=keys1; values2=values1;

      if (type == T_MAP) {
         cs1 = _byte (&buf);
         if (!cs1) {
            if (__get_mode(&buf, &num1, &method1, &keys1, &values1) == M_END) {
               break;
            }
            continue;
         } else {
            n1  = _byte (&buf);
            cs2 = _byte (&buf);
            n2  = _byte (&buf);
         }
         cs1b = (cs1+7)/8;
         cs2b = (cs2+7)/8;
      } else if (type == T_MAP8) {
         cs1b=1; n1=1; cs2b=2; n2=1;
      }

      Ustr = newSVpvf ("%d,%d,%d,%d", cs1b, n1, cs2b, n2);
      Cstr = newSVpvf ("%d,%d,%d,%d", cs2b, n2, cs1b, n1);

      /*
       * Get, create hash for submapping of %U
       */
      if (!hv_exists_ent(U, Ustr, 0)) {
         hv_store_ent(U, Ustr, newRV_inc((SV*) newHV()), 0);
      }
      tmp_spp = hv_fetch(U, SvPVX(Ustr), SvCUR(Ustr), 0);
      if (!tmp_spp) {
         if ( PL_dowarn ) { warn ( "Can't retrieve U submapping!" ); }
         return (0);
      } else {
         uR = (SV *) *tmp_spp;
         u  = (HV *) SvRV (uR);
      }

      /*
       * Get, create hash for submapping of %C
       */
      if (!hv_exists_ent(C, Cstr, 0)) {
         hv_store_ent(C, Cstr, newRV_inc((SV*) newHV()), 0);
      }
      tmp_spp = hv_fetch(C, SvPVX(Cstr), SvCUR(Cstr), 0);
      if (!tmp_spp) {
         if ( PL_dowarn ) { warn ( "Can't retrieve C submapping!" ); }
         return (0);
      } else {
         cR = (SV *) *tmp_spp;
         c  = (HV *) SvRV (cR);
      }

      if (type == T_MAP8) {
      /*
       * Map8 mode
       */
         /*
          * => All (key, value) pairs
          */
         SV* tmpk; SV* tmpv;
         while (buf<bufmax) {
            if (buf[0] != '\0') {
               if ( PL_dowarn ) { warn ( "Bad map file!" ); }
               return (0);
            }
            tmpk = newSVpv(buf+1, 1); buf += 2;
            tmpv = newSVpv(buf  , 2); buf += 2;
            if (buf > bufmax) { break; }

            hv_store_ent(u, tmpk, tmpv, 0);
            hv_store_ent(c, tmpv, tmpk, 0);
         }
      } else if (method1==M_AKV) {
      /*
       * Map mode
       */
         U32 ksize = n1*cs1b; SV* tmpk;
         U32 vsize = n2*cs2b; SV* tmpv;
         if ( num1==M_INF ) {
            /*
             * All (key, value) pairs
             */
            while (buf<bufmax) {
               if ( buf+ksize+vsize>bufmax ) {
                  buf += ( ksize+vsize );
                  break;
               }
               tmpk = newSVpv(buf, ksize); buf += ksize;
               tmpv = newSVpv(buf, vsize); buf += vsize;
               hv_store_ent(c, tmpv, tmpk, 0);
               hv_store_ent(u, tmpk, tmpv, 0);
            }
         } else if ( num1==M_BYTE ) {
            while ( buf<bufmax ) {
               if (!(kn=_byte(&buf))) { 
                  if (__get_mode(&buf,&num2,&method2,&keys2,&values2)==M_END) {
                     break;
                  }
               }
               while ( kn>0 ) {
                  if ( buf+ksize+vsize>bufmax ) {
                     buf += ( ksize+vsize );
                     break;
                  }
                  tmpk = newSVpv(buf, ksize); buf += ksize;
                  tmpv = newSVpv(buf, vsize); buf += vsize;
                  hv_store_ent(c, tmpv, tmpk, 0);
                  hv_store_ent(u, tmpk, tmpv, 0);
                  kn--;
               }
            }
         }
      } else if (method1==M_AKAV) {
         /*
          * First all keys, then all values
          */
         if ( PL_dowarn ) { warn ( "M_AKAV not supported!" ); }
         return (0);
      } else if (method1==M_PKV) {
         /*
          * Partial 
          */
         if (num1==M_INF) { 
            /* no infinite mode */
            if ( PL_dowarn ) { warn ( "M_INF not supported for M_PKV!" ); }
            return (0); 
         } 
         while(buf<bufmax) {
            U8 num3, method3, keys3, values3;
            num3=num2; method3=method2; keys3=keys2; values3=values2;
            if (!(kn = _byte(&buf))) { 
               if (__get_mode(&buf,&num2,&method2,&keys2,&values2)==M_END) {
                  break;
               }
               continue;
            }
            switch (cs1b) {
               case 1: kbegin = _byte(&buf); break;
               case 2: kbegin = _word(&buf); break;
               case 4: kbegin = _long(&buf); break;
               default:
                  if ( PL_dowarn ) { warn ( "Unknown element size!" ); }
                  return (0);
            }
            while (kn>0) {
               if (values3==M_CV) {
                  /*
                   * Partial, keys compressed, values compressed
                   */
                  SV* tmpk; U32 k;
                  SV* tmpv; U32 v;
                  U32 max;
                  vn = _byte(&buf);
                  if (!vn) { 
                     if(__get_mode(&buf,&num3,&method3,&keys3,&values3)==M_END){
                        break;
                     }
                     continue;
                  }
                  if ((n1 != 1) || (n2 != 1)) {
                     /*
                      * n (n>1) characters cannot be mapped to one integer
                      */
                     if ( PL_dowarn ) { warn("Bad map file: count mismatch!"); }
                     return (0);
                  }
                  switch (cs2b) {
                     case 1: vbegin = _byte(&buf); break;
                     case 2: vbegin = _word(&buf); break;
                     case 4: vbegin = _long(&buf); break;
                     default: 
                        if ( PL_dowarn ) { warn ( "Unknown element size!" ); }
                        return (0);
                  }

                  max = kbegin + vn;
                  for (; kbegin<max; kbegin++, vbegin++) {
               
                     k = htonl(kbegin);
                     tmpk = newSVpv((char *) &k + (4-cs1b), cs1b);
               
                     v = htonl(vbegin);
                     tmpv = newSVpv((char *) &v + (4-cs2b), cs2b);

                     hv_store_ent(c, tmpv, tmpk, 0);
                     hv_store_ent(u, tmpk, tmpv, 0);
                  }
                  kn-=vn;

               } else if (values3==M_CVn) {
                  /*
                   * Partial, keys compressed, values not compressed
                   */
                  U32 v;
                  U32 vsize = n2*cs2b;
                  SV* tmpk;
                  SV* tmpv;
                  if (n1 != 1) {
                     if ( PL_dowarn ) { warn ( "Bad map file: mismatch 2!" ); }
                     return (0);
                  }
                  while (kn--) {
                     v = htonl(kbegin);
                     tmpk = newSVpv((char *) &v + (4-cs1b), cs1b);
                     tmpv = newSVpv(buf, vsize); buf += vsize;

                     hv_store_ent(u, tmpk, tmpv, 0);
                     hv_store_ent(c, tmpv, tmpk, 0);

                     kbegin++;
                  }
               } else {
               /*
                * Unknown value compression.
                */
                  if ( PL_dowarn ) { warn ( "Unknown compression!" ); }
                  return (0);
               }
            }
         }
      } else {
         /*
          * unknown method
          */
         if ( PL_dowarn ) { warn ( "Unknown method!" ); }
         return (0);
      }
   }

   return (1);
}

/*
 *
 * "Map.xs"
 *
 */

MODULE = Unicode::Map	PACKAGE = Unicode::Map

PROTOTYPES: DISABLE

#
# $text = $Map -> reverse_unicode($text)
#
SV*
_reverse_unicode(Map, text)
        SV*  Map
        SV*  text

        PREINIT:
        int i; 
        char c;
        STRLEN len; 
        char* src; 
        char* dest;

        PPCODE:
	src = SvPV (text, len);
	if (PL_dowarn && (len % 2) != 0) {
    	   warn("Bad string size!"); len--;
	}
        /* Code below adapted from GAAS's Unicode::String */
        if ( GIMME_V == G_VOID ) {
           if ( SvREADONLY(text) ) {
              die ( "reverse_unicode: string is readonly!" );
           }
           dest = src;
        } else {
           SV* dest_sv = sv_2mortal ( newSV(len+1) );
           SvCUR_set ( dest_sv, len );
           *SvEND ( dest_sv ) = 0;
           SvPOK_on ( dest_sv );
           PUSHs ( dest_sv );
           dest = SvPVX ( dest_sv );
        }
        for ( ; len>=2; len-=2 ) {
            char tmp = *src++;
            *dest++ = *src++;
            *dest++ = tmp;
        }

#
# $mapped_str = $Map -> _map_hash($string, \%mapping, $bytesize, offset, length)
#
# bytesize, offset, length in terms of bytes.
#
# bytesize gives the size of one character for this mapping.
#
SV*
_map_hash(Map, string, mappingR, bytesize, o, l)
        SV*  Map
        SV*  string
        SV*  mappingR
        SV*  bytesize
        SV*  o
        SV*  l

        PREINIT:
        char* offset; U32 length; U16 bs;
        char* smax;
        HV*   mapping;
        SV**  tmp;

        CODE:
        bs = SvIV(bytesize);
        __limit_ol (string, o, l, &offset, &length, bs);
        smax = offset + length;

        RETVAL = newSV((length/bs+1)*2);
        mapping = (HV *) SvRV(mappingR);

        for (; offset<smax; offset+=bs) {
           if (tmp = hv_fetch(mapping, offset, bs, 0)) {
              if ( SvOK(RETVAL) ) {
                 sv_catsv(RETVAL, *tmp); 
              } else {
                 sv_setsv(RETVAL, *tmp);
              }
           } else {
              /* No mapping character found! */
           }
        }

        OUTPUT:
	   RETVAL


#
# $mapped_str = $Map -> _map_hashlist($string, [@{\%mapping}], [@{$bytesize}])
#
# bytesize gives the size of one character for this mapping.
#
SV*
_map_hashlist(Map, string, mappingRLR, bytesizeLR, o, l)
        SV*  Map
        SV*  string
        SV*  mappingRLR
        SV*  bytesizeLR
        SV*  o
        SV*  l

        PREINIT:
        int j, max;
        AV* mappingRL; HV* mapping;
        AV* bytesizeL; int bytesize;
        SV** tmp;
        char* offset; U32 length; char* smax; 

        CODE:
        __limit_ol (string, o, l, &offset, &length, 1);
        smax = offset + length;

        RETVAL = newSV((length+1)*2);

	mappingRL = (AV *) SvRV(mappingRLR);
        bytesizeL = (AV *) SvRV(bytesizeLR);
        max = av_len(mappingRL);
        if (max != av_len(bytesizeL)) {
	   warn("$#mappingRL != $#bytesizeL!");
	} else {
           max++;
           for (; offset<smax; ) {
              for (j=0; j<=max; j++) {
                 if (j==max) {
                    /* No mapping character found! 
                     * How many bytes does this unknown character consume?
                     * Sigh, assume 2.
                     */
                    offset += 2;
                 } else {
  	            if (tmp = av_fetch(mappingRL, j, 0)) {
                       mapping = (HV *) SvRV((SV*) *tmp);
                       if (tmp = av_fetch(bytesizeL, j, 0)) {
                          bytesize = SvIV(*tmp);
                          if (tmp = hv_fetch(mapping, offset, bytesize, 0)) {
                             if ( SvOK(RETVAL) ) {
                                sv_catsv(RETVAL, *tmp); 
                             } else {
                                sv_setsv(RETVAL, *tmp);
                             }
                             offset+=bytesize;
                             break;
                          }
                       }
                    }
                 }
              }
           }
        }

        OUTPUT:
	   RETVAL


#
# status = $S->_read_binary_mapping($buf, $o, \%U, \%C);
#
SV*
_read_binary_mapping (MapS, bufS, oS, UR, CR)
	SV* MapS
	SV* bufS
	SV* oS
	SV* UR
	SV* CR

	CODE:
	RETVAL = newSViv(__read_binary_mapping(bufS, oS, UR, CR));

	OUTPUT:
	   RETVAL


#
# 0 || errornum = $S->_test ()
#
AV*
_system_test (void)
	CODE:
	RETVAL = __system_test();
	OUTPUT:
	RETVAL

