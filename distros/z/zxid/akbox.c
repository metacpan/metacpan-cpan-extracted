/* akbox.c  -  Application Black (K) Box Decoder
 * Copyright (c) 2006,2012 Sampo Kellomaki (sampo@iki.fi), All Rights Reserved.
 * This is confidential unpublished proprietary source code of the author.
 * NO WARRANTY, not even implied warranties. Contains trade secrets.
 * Distribution prohibited unless authorized in writing. See file COPYING.
 * Special grant: akbox.h may be used with zxid open source project under
 * same licensing terms as zxid itself.
 * $Id$
 *
 * Application Black Box provides a lock-less logging facility
 * using a circular memory buffer per thread. These buffers will
 * hold recent history of application and will be part of any core
 * dump that may happen, facilitating interpretation of such core.
 * This is a simple log analysis program for figuring out such cores.
 * There may exist other more full-fledged tools for this task.
 *
 * Bad compile:
 * export PATH=/apps/gcc/3.3.3/bin:/apps/binutils/2.14.90.0.4.1/bin:$PATH
 * gcc -g -O -Wall -fmessage-length=0 -Wno-unused-label -Wno-unknown-pragmas -fno-strict-aliasing -D_REENTRANT -o akbox akbox.c -lpthread -lcrypto -lbfd -liberty
 *
 * Good compile:
 * export PATH=/apps/gcc/3.3.3/bin:/usr/bin:$PATH
 * gcc -g -O -Wall -fmessage-length=0 -Wno-unused-label -Wno-unknown-pragmas -fno-strict-aliasing -D_REENTRANT -o akbox akbox.c akboxlog.c -lpthread -lcrypto -lbfd
 *
 * Unfortunately there are several different versions of bfd.h and presumably
 * the library. They are not compatible. One tell tale sign in _raw_size vs. rawsize.
 *
 * TO DO
 * - use bfd to implement live snooping
 * - use symbolic thread indications in brief mode
 * - compute how much of each buffer was consumed (if not wrapped around)
 *
 * See also: objdump -afph core2
 * See also: ak-lock.pl -w 1000 <ak.out
 */

#include "platform.h"
#include "errmac.h"
#include "akbox.h"

#include <errno.h>
#include <sys/types.h>
#include <string.h>
#include <stdarg.h>
#include <sys/time.h>
#include <stdio.h>
#include <stdlib.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <unistd.h>
#include <limits.h>
#include <time.h>
//#include <sys/ptrace.h>  /* see also /proc/pid , Not needed*/
#include <bfd.h>         /* -lbfd */

#define AKBOX_RELEASE REL " - akbox -"

/* Called by:  add_password, main x18 */
void usage(char* err) {
  fputs(err, stderr);
  fputs(
"Application Blak Box Decoder, Rel " AKBOX_RELEASE "\n"
"Copyright (c) 2006,2012 Sampo Kellomaki (sampo@iki.fi), All Rights Reserved.\n"
"NO WARRANTY. Not even implied warranty of any kind.\n"
"Send well researched bug reports to sampo@zxid.org\n"
"$Id$\n\n"
"Usage: akbox [options] bin.exe core  # analyze a core wrt binary\n"
"       akbox [options] -p pid        # attach to live process and analyze it\n"
"       akbox [options] -f pid        # attach to process, follow continuously\n"
"       akbox [options] -r funcno [n] # resolve function number to name and file\n"
"       akbox [options] -e errno      # Show errno as string\n"
"       akbox [options] -x bin.exe    # extract function names from binary\n"
"       akbox [options] -y core >exe  # extract an executable from core\n"
"       akbox [options] -z p sigma >v.gz  # Extract checksum and version info\n"
"       akbox [options] -t            # Show table of known function numbers.\n"
"       akbox [options] -T            # Show table of known targets.\n"
"  -s nn   Use swimlane view to visualize activity in each thread where\n"
"          each thread column is nn characters wide.\n"
"  -2      Use 2 swimlanes: 1st is main thread and 2nd is all worker threads.\n"
"  -c nn   Use swimlane view to visualize activity of each\n"
"          connection. Each lane is nn characters wide and two sublanes are\n"
"          used for main thread and all other threads. Lane width is nn.\n"
"  -b      Brief. Omit time stamps and other info.\n"
"  -m msec Fuzz factor in millisec for simultaneous events in lane views.\n"
"  -n nn   Only mmap nn first bytes of core (used for analyzing huge cores).\n"
"  -g file Produce GraphViz output (see \n"
"            http://www.research.att.com/sw/tools/graphviz/download.html)\n"
"\n"
"The default view is a simple time ordered listing of all activity with\n"
"one event per line, irrespective of line width.\n"
"You can further analyze the log with ak-lock.pl -w 1000 <ak.out\n"
, stderr);
  exit(1);
}

/* Called by:  ak_gviz, anal_live x3, extract_a_sym x2, extract_exe, extract_syms, open_obj x6 */
void die(char* why) {
  perror(why); exit(2);
}
/* Called by:  extract_a_sym x2, locate_buffers x2, resolve */
void die2(char* why) {
  fprintf(stderr, "%s\n", why);  exit(3);
}
/* Called by:  locate_buffers, main x2 */
void warning(char* why) {
  fprintf(stderr, "%s\n", why);
}

void akbox_gviz(char* file);

pthread_mutexattr_t MUTEXATTR_DECL;
unsigned long max_size = ULONG_MAX;  /* max size of mmap, e.g. core file */
int adhoc = 1;
int leak_free = 0;
int assert_nonfatal = 0;
int lane_width = 80;
int fuzz_usec = 0;
int brief = 0;
char* format = "full";
char* gviz = 0;       /* File where graphviz output should be dumped */
int swimlane = 0;
int siz, n_thr;       /* size of mmap'd core image, number of buffers */
unsigned char* base;  /* base of mmap'd core image */
unsigned char* ebase = 0; /* base of mmap'd executable binary image */
int esiz = 0;

struct ak_master_rec* mr;
struct ak_buf* b[AK_MAX_BUFS];
struct ak_ts* pp[AK_MAX_BUFS];    /* original "point" */
struct ak_ts* p[AK_MAX_BUFS];     /* working point */
struct ak_ts* lim[AK_MAX_BUFS];   /* end of buffer */
struct ak_ts* start[AK_MAX_BUFS]; /* start of buffer */
int seen[AK_MAX_BUFS];  /* Used to determine when HOSTART has happened. */

char* file[65536];   /* Function number to file mapping */
char* func[65536];   /* Function number to function name mapping */
extern const_str sev[];

bfd* ebfd = 0;  /* Binary File Descriptor for the executable binary, if any. */
bfd* cbfd = 0;  /* Binary File Descriptor for the core, if any. */
/* Called by:  anal_live, extract_a_sym x3, extract_syms x3, open_obj x2 */
void die_bfd(char* why) {
  bfd_perror(why);
  exit(4);
}

#define BFD_DEBUG(x)
#define BFD_DEBUG_ON(x) x

/* Called by: */
CU8* zx_memmem(CU8* haystack, int haystacklen, CU8* needle, int needlelen)
{
  CU8* p = haystack;
  CU8* lim = haystack + haystacklen - needlelen + 1;

  while ((p < lim) && (p = memchr(p, needle[0], lim-p))) {
    if (!memcmp(p, needle, needlelen)) return p;
    ++p;
  }
  return 0;
}


/* Look up an address in BFD aware way from core or executable sections. */
/* Called by:  amap x2 */
static char* map_in_bfd(bfd* abfd, char* x)
{
  bfd_size_type siz;
  char* cont;
  char* vma;
  char* vma_lim;
  asection* s;
  for (s = abfd->sections; s; s = s->next) {
    vma = (char*)bfd_get_section_vma(abfd, s);
    siz = bfd_section_size(abfd, s);
    vma_lim = (char*)( bfd_get_section_vma(abfd, s) + siz );
    if (x >= vma && x < vma_lim) {
      BFD_DEBUG(fprintf(stderr, "addr %p [%p..%p] in %s section %s\n", x, (char*)s->vma, (char*)s->vma + s->rawsize, what, bfd_get_section_name(abfd, s)));
      if (!(s->flags & SEC_HAS_CONTENTS))
	continue;
      cont = x - (int)s->vma + (int)s->contents;
      BFD_DEBUG(fprintf(stderr, "map_in_bfd(%s, %p) returns %p (s->contents=%p, s->vma=%p s->filepos=%d)\n", what, x, cont, s->contents, (char*)s->vma, (int)s->filepos));
      return cont;
    }
  }
  return 0;
}

/* Called by:  extract_exe, locate_buffers x7, print_trace */
static char* amap(char* x)
{
  char* y;
  if (!x) return "(null)";
  /* *** do endianness check and adjust as needed */
  y = map_in_bfd(cbfd, x);
  if (y) {
    if (y >= (char*)base + siz)
      return "(core-truncated)";
    return y;
  }
  if (ebase) {
    y = map_in_bfd(ebfd, x);
    if (y) {
      if (y >= (char*)ebase + esiz)
	return "(exec-truncated)";
      return y;
    }
  }
  fprintf(stderr, "addr %p not found in any section\n", x);
  return "(not-found)";
}

#define LK_FMT "%s"
#define lkmap(lk) amap(lk)

#if 0

/* Called by:  print_io x4 */
static char* proto_map(int proto, char* proto_buf)
{
  switch (proto) {
  case  SG_PROTO_LDAP:            return "LDAP";
  case  SG_PROTO_LDAPS:           return "LDAPS";
  case  SG_PROTO_HTTP:            return "HTTP";
  case  SG_PROTO_HTTP11:          return "HTTP11";
  case  SG_PROTO_HTTPS:           return "HTTPS";
  case  SG_PROTO_HTTP11S:         return "HTTP11S";
  case  SG_PROTO_MM1:             return "MM1";
  case  SG_PROTO_SNMP:            return "SNMP";
  case  SG_PROTO_RADIUS:          return "RADIUS";
  case  SG_PROTO_SIP_TCP:         return "SIP_TCP";
  case  SG_PROTO_SIPS:            return "SIPS";
  case  SG_PROTO_SIP_UDP:         return "SIP_UDP";
  case  SG_PROTO_UHAP_UDP:        return "UHAP_UDP";
  case  SG_PROTO_UHAP:            return "UHAP";
  case  SG_PROTO_UHAPS:           return "UHAPS";
  case  SG_PROTO_RAWTCP_STREAM:   return "RAWTCPSTREAM";
  case  SG_PROTO_RAWTCP_STREAMS:  return "RAWTCPSTREAMS";
  case  SG_PROTO_RAWTCP:          return "RAWTCP";
  case  SG_PROTO_RAWSSL:          return "RAWSSL";
  case  SG_PROTO_LINETCP:         return "LINETCP";
  case  SG_PROTO_LINESSL:         return "LINESSL";
  case  SG_PROTO_RAWUDP:          return "RAWUDP";
  default:
    sprintf(proto_buf, "proto%d", proto);
    return proto_buf;
  }
}

/* Called by:  print_io x6 */
static char* flags_map(unsigned char flags, char* flags_buf){
  if (flags & IO_CLOSED)     flags_buf[0] = 'C'; else flags_buf[0] = '-';
  if (flags & IO_HTTP_EOF)   flags_buf[1] = 'H'; else flags_buf[1] = '-';
  if (flags & IO_ENQUEUED)   flags_buf[2] = 'Q'; else flags_buf[2] = '-';
  if (flags & IO_INUSE)      flags_buf[3] = 'U'; else flags_buf[3] = '-';
  if (flags & IO_CLOSING)    flags_buf[4] = 'I'; else flags_buf[4] = '-';
  if (flags & IO_MISSING)    flags_buf[5] = 'M'; else flags_buf[5] = '-';
  if (flags & IO_MISSPOLL)   flags_buf[6] = 'S'; else flags_buf[6] = '-';
  flags_buf[7] = '\0';
  return flags_buf;
}

/* Called by:  print_line */
static void print_io(int i, char* raz)
{
  char proto_buf[16];
  char flags_buf[8];
  struct ak_io* io = ((struct ak_io*)(p[i]));
  switch (io->role) {
  case IO_ROLE_FE:           /* 0 */
    printf("%s(%x.%p)\t%s_FE (%s) req_head(%p) req_tail(%p) (%.28s) [" LK_FMT "]\n", raz,
	   io->fd, io->io, proto_map(io->proto, proto_buf), flags_map(io->flags, flags_buf), io->req_head, io->req_tail,
	   io->msg, lkmap(p[i]->h.logkey));
    break;
  case IO_ROLE_BE:           /* 1 */
    printf("%s(%x.%p)\t%s_BE (%s) (%.28s) [" LK_FMT "]\n", raz,
	   io->fd, io->io, proto_map(io->proto, proto_buf), flags_map(io->flags, flags_buf), io->msg, lkmap(p[i]->h.logkey));
    break;
  case IO_ROLE_LISTENER:     /* 2 */
    printf("%s(%x.%p)\t%s_LISTENER (%s) (%.28s) [" LK_FMT "]\n", raz,
	   io->fd, io->io, proto_map(io->proto, proto_buf), flags_map(io->flags, flags_buf), io->msg, lkmap(p[i]->h.logkey));
    break;
  case IO_ROLE_UDP_LISTENER: /* 3 */
    printf("%s(%x.%p)\t%s_UDP_LISTENER (%s) (%.28s) [" LK_FMT "]\n", raz,
	   io->fd, io->io, proto_map(io->proto, proto_buf), flags_map(io->flags, flags_buf), io->msg, lkmap(p[i]->h.logkey));
    break;
  case IO_ROLE_HOPELESS:     /* 5 */
    printf("%s(%x.%p)\tHOPELESS_BE (%s) (%.28s) [" LK_FMT "]\n", raz,
	   io->fd, io->io, flags_map(io->flags, flags_buf), io->msg, lkmap(p[i]->h.logkey));
    break;
  case IO_ROLE_SUPERVISOR:     /* 4 */
  default:
    printf("%s(%x.%p)\trole=%d proto=%d (%s) req_head(%p) req_tail(%p) (%.28s) [" LK_FMT "]\n", raz,
	   io->fd, io->io, io->role, io->proto, flags_map(io->flags, flags_buf), io->req_head, io->req_tail,
	   io->msg, lkmap(p[i]->h.logkey));
  }
}

/* Called by:  print_line */
static void print_mem(int i, char* raz)
{
  struct ak_mem* r = ((struct ak_mem*)(p[i]));
  printf("%s(%p)\tlen=%d pool=%p p_b=%d (%.32s) [" LK_FMT "]\n", raz,
	 r->mem, r->len, r->pool, r->pool_blocks, r->msg, lkmap(p[i]->h.logkey));
}

/* Called by:  decode_pdu_flags x4 */
static char* map_inthr(int x) {
  switch (x & 0x7) {
  case 0: return "0";  /* not in thread */
  case 1: return "T";  /* inthread any prio */
  case 2: return "I";  /* inthread */
  case 3: return "A";  /* aborted */
  case 4: return "W";  /* in write */
  case 5: return "R";  /* run (actively running) */
  case 6: return "S";  /* suspended */
  case 7: return "E";  /* enqueued */
  default: return "?";
  }
}

/* Called by:  print_pdu x4, print_pdu2 x4, print_pdu_arg x4, print_pdu_lite, print_run */
static char* decode_pdu_flags(char* buf, int flags)
{
#define FL(bit,name) (flags & bit ? name : "-")
  switch (flags & 0x30) {
  case 0x00: sprintf(buf, "REQ(%s,%s,%s,%s)", FL(0x08,"all_seen"), FL(0x80,"D"),
		     FL(0x40,"synth_done"), map_inthr(flags)); break;
  case 0x10: sprintf(buf, "RESP(%s,%s,%s,%s)", FL(0x08,"all_seen"), FL(0x80,"D"),
		     FL(0x40,"synth_done"), map_inthr(flags)); break;
  case 0x20: sprintf(buf, "SUBREQ(%s,%s,%s,%s)", FL(0x08,"all_seen"), FL(0x80,"D"),
		     FL(0x40,"synth_done"), map_inthr(flags)); break;
  case 0x30: sprintf(buf, "SUBRESP(%s,%s,%s,%s)", FL(0x08,"all_seen"), FL(0x80,"D"),
		     FL(0x40,"synth_done"), map_inthr(flags)); break;
  }
  return buf;
}

/* Called by:  print_line */
static void print_run(int i, char* raz)
{
  char buf[128];
  struct ak_run* r = ((struct ak_run*)(p[i]));
  if (r->run) {
     if (r->ph.pdu)	  
        printf("%s(%x:%p)\t%s\tmid=%d run=%p (%.32s) [" LK_FMT "]\n", raz,
	      r->ph.pdu_op, r->ph.pdu, decode_pdu_flags(buf, r->ph.pdu_flags),
	      r->ph.pdu_mid, r->run, r->msg, lkmap(p[i]->h.logkey));
     else 
        printf("%s nopdu run=%p (%.32s) [" LK_FMT "]\n", raz,
	      r->run, r->msg, lkmap(p[i]->h.logkey));
  }
  else
     printf("%s norun (%.32s) [" LK_FMT "]\n", raz,
	    r->msg, lkmap(p[i]->h.logkey));
}

/* Called by:  print_line */
static void print_pdu_lite(int i, char* raz)
{
  char buf[128];
  struct ak_pdu_lite* pdu = ((struct ak_pdu_lite*)(p[i]));
  printf("%s(%x:%p)\t%s\tmid=%d (%.36s) [" LK_FMT "]\n", raz,
	 pdu->ph.pdu_op, pdu->ph.pdu, decode_pdu_flags(buf, pdu->ph.pdu_flags),
	 pdu->ph.pdu_mid, pdu->msg, lkmap(p[i]->h.logkey));
}

/* Called by:  print_line */
static void print_pdu(int i, char* raz)
{
  char buf[128];
  struct ak_pdu* pdu = ((struct ak_pdu*)(p[i]));
  if (pdu->pduparent) {
    if (pdu->pdureq) {
      printf("%s(%x:%p)\t%s\tmid=%d fe(%p) req(%p) parent(%p) nx(%p) pr(%p) wnx(%p) deps=%d (%.4s) [" LK_FMT "]\n", raz,
	     pdu->ph.pdu_op, pdu->ph.pdu, decode_pdu_flags(buf, pdu->ph.pdu_flags),
	     pdu->ph.pdu_mid, pdu->pdufe, pdu->pdureq, pdu->pduparent, pdu->pdunext,
	     pdu->pduprev, pdu->writenext, pdu->pdu_deps, 
	     pdu->msg, lkmap(p[i]->h.logkey));

    } else {
      printf("%s(%x:%p)\t%s\tmid=%d fe(%p) parent(%p) nx(%p) pr(%p) wnx(%p) deps=%d (%.4s) [" LK_FMT "]\n", raz,
	     pdu->ph.pdu_op, pdu->ph.pdu, decode_pdu_flags(buf, pdu->ph.pdu_flags),
	     pdu->ph.pdu_mid, pdu->pdufe, pdu->pduparent, pdu->pdunext,
	     pdu->pduprev, pdu->writenext, pdu->pdu_deps, 
	     pdu->msg, lkmap(p[i]->h.logkey));
    }
  } else {
    if (pdu->pdureq) {
      printf("%s(%x:%p)\t%s\tmid=%d fe(%p) req(%p) nx(%p) pr(%p) wnx(%p) deps=%d (%.4s) [" LK_FMT "]\n", raz,
	     pdu->ph.pdu_op, pdu->ph.pdu, decode_pdu_flags(buf, pdu->ph.pdu_flags),
	     pdu->ph.pdu_mid, pdu->pdufe, pdu->pdureq, pdu->pdunext,
	     pdu->pduprev, pdu->writenext, pdu->pdu_deps, 
	     pdu->msg, lkmap(p[i]->h.logkey));
    } else {
      printf("%s(%x:%p)\t%s\tmid=%d fe(%p) nx(%p) pr(%p) wnx(%p) deps=%d (%.4s) [" LK_FMT "]\n", raz,
	     pdu->ph.pdu_op, pdu->ph.pdu, decode_pdu_flags(buf, pdu->ph.pdu_flags),
	     pdu->ph.pdu_mid, pdu->pdufe, pdu->pdunext,
	     pdu->pduprev, pdu->writenext, pdu->pdu_deps, 
	     pdu->msg, lkmap(p[i]->h.logkey));
    }
  }
}

/* Called by:  print_line */
static void print_pdu_arg(int i, char* raz)
{
  char buf[128];
  struct ak_pdu_arg* pdu = ((struct ak_pdu_arg*)(p[i]));
  if (pdu->pduparent) {
    if (pdu->pdureq) {
      printf("%s(%x:%p)\t%s\tmid=%d fe(%p) req(%p) parent(%p) nx(%p) pr(%p) wnx(%p) deps=%d (0x%x) [" LK_FMT "]\n", raz,
	     pdu->ph.pdu_op, pdu->ph.pdu, decode_pdu_flags(buf, pdu->ph.pdu_flags),
	     pdu->ph.pdu_mid, pdu->pdufe, pdu->pdureq, pdu->pduparent, pdu->pdunext,
	     pdu->pduprev, pdu->writenext, pdu->pdu_deps,
	     pdu->arg, lkmap(p[i]->h.logkey));
    } else {
      printf("%s(%x:%p)\t%s\tmid=%d fe(%p) parent(%p) nx(%p) pr(%p) wnx(%p) deps=%d (0x%x) [" LK_FMT "]\n", raz,
	     pdu->ph.pdu_op, pdu->ph.pdu, decode_pdu_flags(buf, pdu->ph.pdu_flags),
	     pdu->ph.pdu_mid, pdu->pdufe, pdu->pduparent, pdu->pdunext,
	     pdu->pduprev, pdu->writenext, pdu->pdu_deps, 
	     pdu->arg, lkmap(p[i]->h.logkey));
    }
  } else {
    if (pdu->pdureq) {
      printf("%s(%x:%p)\t%s\tmid=%d fe(%p) req(%p) nx(%p) pr(%p) wnx(%p) deps=%d (0x%x) [" LK_FMT "]\n", raz,
	     pdu->ph.pdu_op, pdu->ph.pdu, decode_pdu_flags(buf, pdu->ph.pdu_flags),
	     pdu->ph.pdu_mid, pdu->pdufe, pdu->pdureq, pdu->pdunext,
	     pdu->pduprev, pdu->writenext, pdu->pdu_deps, 
	     pdu->arg, lkmap(p[i]->h.logkey));
    } else {
      printf("%s(%x:%p)\t%s\tmid=%d fe(%p) nx(%p) pr(%p) wnx(%p) deps=%d (0x%x) [" LK_FMT "]\n", raz,
	     pdu->ph.pdu_op, pdu->ph.pdu, decode_pdu_flags(buf, pdu->ph.pdu_flags),
	     pdu->ph.pdu_mid, pdu->pdufe, pdu->pdunext,
	     pdu->pduprev, pdu->writenext, pdu->pdu_deps, 
	     pdu->arg, lkmap(p[i]->h.logkey));
    }
  }
}

/* Called by:  print_line */
static void print_pdu2(int i, char* raz)
{
  char buf[128];
  struct ak_pdu* pdu = ((struct ak_pdu*)(p[i]));
  if (pdu->pduparent) {
    if (pdu->pdureq) {
      printf("%s(%x:%p)\t%s\tmid=%d fe(%p) req(%p) parent(%p) nx(%p) pr(%p) wnx(%p) deps=%d (%.4s) [%p]\n", raz,
	     pdu->ph.pdu_op, pdu->ph.pdu, decode_pdu_flags(buf, pdu->ph.pdu_flags),
	     pdu->ph.pdu_mid, pdu->pdufe, pdu->pdureq, pdu->pduparent, pdu->pdunext,
	     pdu->pduprev, pdu->writenext, pdu->pdu_deps, 
	     pdu->msg, p[i]->h.logkey);  /* msg is func called, logkey is really nargs */
    } else {
      printf("%s(%x:%p)\t%s\tmid=%d fe(%p) parent(%p) nx(%p) pr(%p) wnx(%p) deps=%d (%.4s) [%p]\n", raz,
	     pdu->ph.pdu_op, pdu->ph.pdu, decode_pdu_flags(buf, pdu->ph.pdu_flags),
	     pdu->ph.pdu_mid, pdu->pdufe, pdu->pduparent, pdu->pdunext,
	     pdu->pduprev, pdu->writenext, pdu->pdu_deps, 
	     pdu->msg, p[i]->h.logkey);  /* msg is func called, logkey is really nargs */
    }
  } else {
    if (pdu->pdureq) {
      printf("%s(%x:%p)\t%s\tmid=%d fe(%p) req(%p) nx(%p) pr(%p) wnx(%p) deps=%d (%.4s) [%p]\n", raz,
	     pdu->ph.pdu_op, pdu->ph.pdu, decode_pdu_flags(buf, pdu->ph.pdu_flags),
	     pdu->ph.pdu_mid, pdu->pdufe, pdu->pdureq, pdu->pdunext,
	     pdu->pduprev, pdu->writenext, pdu->pdu_deps,
	     pdu->msg, p[i]->h.logkey);  /* msg is func called, logkey is really nargs */
    } else {
      printf("%s(%x:%p)\t%s\tmid=%d fe(%p) nx(%p) pr(%p) wnx(%p) deps=%d (%.4s) [%p]\n", raz,
	     pdu->ph.pdu_op, pdu->ph.pdu, decode_pdu_flags(buf, pdu->ph.pdu_flags),
	     pdu->ph.pdu_mid, pdu->pdufe, pdu->pdunext,
	     pdu->pduprev, pdu->writenext, pdu->pdu_deps, 
	     pdu->msg, p[i]->h.logkey);  /* msg is func called, logkey is really nargs */
    }
  }
}
#endif


/* Called by:  print_line */
static void print_report(int i, char* raz)
{
  struct ak_report* r = ((struct ak_report*)(p[i]));
  printf("%s " LK_FMT "\tblock_size=%d, blks from pool: %d/%d; from malloc: %d/%d %d bytes (%.16s)\n", raz, lkmap(p[i]->h.logkey), r->block_size, r->blocks_out, r->n_blocks, r->malloc_cnt_bal, r->malloc_cnt, r->malloc_vol_bal, r->msg);
}

/* Called by:  print_line */
static void print_ini(int i, char* raz)
{
  struct ak_ini* inc = ((struct ak_ini*)(p[i]));
  printf("%s  F:%s  S:%d Bytes  M:%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x [%s]\n", raz, inc->msg, inc->size, inc->md5val[0], inc->md5val[1], inc->md5val[2], inc->md5val[3], inc->md5val[4], inc->md5val[5], inc->md5val[6], inc->md5val[7], inc->md5val[8], inc->md5val[9], inc->md5val[10], inc->md5val[11], inc->md5val[12], inc->md5val[13], inc->md5val[14], inc->md5val[15], lkmap(p[i]->h.logkey));
}

/* Called by:  print_line x2 */
static void print_ts(int i, char* raz)
{
  printf(raz, p[i]->msg, lkmap(p[i]->h.logkey));
}

/* Called by:  print_line */
static void print_tsa(int i, char* raz)
{
  struct ak_tsa* r = ((struct ak_tsa*)(p[i]));
  printf(raz, r->msg, r->arg, lkmap(p[i]->h.logkey));
}

/* Called by:  print_line x6 */
static void print_trace(int i, char* raz)
{
  struct _binid* cur_func;
  struct ak_disasm* di = ((struct ak_disasm*)(p[i]));
  cur_func = (struct _binid*)amap((char*)di->cur_func);
  printf("%s(%s)\n", raz, lkmap((char *)cur_func->key));
}

#ifdef SUNOS

struct split_ll{
  union{
    struct{
      unsigned long high;
      unsigned long low;
    };
    unsigned long long full;
  };
};

/* Called by:  get_low */
int am_big_endian()
{
  long one= 1;
  return !(*((char *)(&one)));
}

/* Called by:  get_nano, get_secs */
unsigned long get_low (unsigned long long num){
  struct split_ll ll;
  ll.full = num;
  if (am_big_endian())
    return ll.low; 
  else
    return ll.high; 
}

/* Called by:  print_line x2 */
int get_secs (ak_time act_tick){
  unsigned long a;
  a = get_low ((act_tick - mr->first_tick)/1000000000.0);
  return (int)(a);
}

/* Called by:  print_line x2 */
unsigned long get_nano (ak_time act_tick){
  ak_time rest;
  rest = ((act_tick - mr->first_tick)%1000000000);
  return get_low(rest);
}
#endif

#ifdef MINGW
/* Called by:  print_line x2 */
int get_secs (ak_time act_tick){
  return (int)((act_tick.QuadPart - mr->first_tick.QuadPart)/mr->ticksPerSecond.QuadPart);
}

/* Called by:  print_line x2 */
unsigned long get_nano (ak_time act_tick){
  ak_time rest;
  double ticksPerNano;
  ticksPerNano = (mr->ticksPerSecond.QuadPart/1000000000.0); 
  rest.QuadPart = ((act_tick.QuadPart - mr->first_tick.QuadPart)%mr->ticksPerSecond.QuadPart);
  rest.QuadPart = (rest.QuadPart/ticksPerNano);
  return (unsigned long)rest.LowPart;
}
#endif

/* You need to teach this function about every possible message type. When (if) swimlanes
 * are implemented, this function probably needs to be aware of them. */

/* Called by:  print_buffers x3 */
static void print_line(int i)
{
  int seve;
  struct tm t;

#ifdef MINGW
    unsigned int secs = mr->first_sec + get_secs(p[i]->h.tv);
    GMTIME(secs, t);
    printf("%c%-2d %04d%02d%02d %02d%02d%02d.%09lu %15s:%-4d %20s():\t",
	   b[i]->comment[0], i-1, t.tm_year+1900, t.tm_mon+1, t.tm_mday,
           t.tm_hour, t.tm_min, t.tm_sec, get_nano (p[i]->h.tv),
	   file[p[i]->h.func], p[i]->h.line, func[p[i]->h.func]);
#endif
#ifdef SUNOS 
    unsigned int secs = mr->first_sec + get_secs(p[i]->h.tv);
    GMTIME(secs, t);
    printf("%c%-2d %04d%02d%02d %02d%02d%02d.%09lu %15s:%-4d %20s():\t",
	   b[i]->comment[0], i-1, t.tm_year+1900, t.tm_mon+1, t.tm_mday,
           t.tm_hour, t.tm_min, t.tm_sec, get_nano (p[i]->h.tv),
	   file[p[i]->h.func], p[i]->h.line, func[p[i]->h.func]);
#endif
#if (!defined(SUNOS)&&!defined(MINGW))
  if (brief) {
    printf("%c%-2d %03ld.%06ld %10.10s:%-3d ", b[i]->comment[0], i-1,
	   p[i]->h.tv.tv_sec % 1000, p[i]->h.tv.tv_usec,
	   func[p[i]->h.func], p[i]->h.line);
  } else {
    GMTIME(p[i]->h.tv.tv_sec, t);
    printf("%c%-2d %04d%02d%02d %02d%02d%02d.%06ld %15s:%-4d %20s():\t",
	   b[i]->comment[0], i-1, t.tm_year+1900, t.tm_mon+1, t.tm_mday,
	   t.tm_hour, t.tm_min, t.tm_sec, p[i]->h.tv.tv_usec,
	   file[p[i]->h.func], p[i]->h.line, func[p[i]->h.func]);
  }
#endif

  switch (p[i]->raz) {

#define AK_RAZ_INI(sym,code,desc)  case AK_ ## sym ## _RAZ: print_ini(i, #sym ); break;
#define AK_RAZ_TS(sym,code,desc)   case AK_ ## sym ## _RAZ: print_ts(i, #sym " (%s) [" LK_FMT "]\n"); break;
#define AK_RAZ_TS2(sym,code,desc)  case AK_ ## sym ## _RAZ: print_ts(i, #sym " (%s) [%p]\n"); break;
#define AK_RAZ_TSA(sym,code,desc)  case AK_ ## sym ## _RAZ: print_tsa(i, #sym " (%s) arg=%p [" LK_FMT "]\n"); break;
#define AK_RAZ_MEM(sym,code,desc)  case AK_ ## sym ## _RAZ: print_mem(i, #sym); break;
#define AK_RAZ_RUN(sym,code,desc)  case AK_ ## sym ## _RAZ: print_run(i, #sym); break;
#define AK_RAZ_PDU(sym,code,desc)  case AK_ ## sym ## _RAZ: print_pdu(i, #sym); break;
#define AK_RAZ_PDU2(sym,code,desc) case AK_ ## sym ## _RAZ: print_pdu2(i, #sym); break;
#define AK_RAZ_LITE(sym,code,desc) case AK_ ## sym ## _RAZ: print_pdu_lite(i, #sym); break;
#define AK_RAZ_ARG(sym,code,desc)  case AK_ ## sym ## _RAZ: print_pdu_arg(i, #sym); break;
#define AK_RAZ_IO(sym,code,desc)   case AK_ ## sym ## _RAZ: print_io(i, #sym); break;
#define AK_RAZ_REPORT(sym,code,desc) case AK_ ## sym ## _RAZ: print_report(i, #sym); break;
#define AK_RAZ_SPEC(sym,code,desc)

#include "aktab.h"

  case AK_ERR_RAZ:
    seve = ((struct ak_err*)p[i])->severity;
    printf("ERR %s %s %d (%s) [" LK_FMT "]\n",
	   map_error(((struct ak_err*)p[i])->error_code),
	   (seve>=0) && (seve < 8) ? sev[seve] : "***UNKWN_SEV",
	   ((struct ak_err*)p[i])->action,
	   ((struct ak_err*)p[i])->msg, lkmap(p[i]->h.logkey)); break;
  case AK_ASSERT_RAZ:      /* ASSERT or CHK macro, logkey is condition */
    printf("ASSERT(" LK_FMT ") [%s]\n", lkmap(p[i]->h.logkey), p[i]->msg); break;
  case AK_ASSERTOP_RAZ:    /* ASSERTOP macro, logkey is value a, msg is condition */
    printf("ASSERTOP(" LK_FMT ") [%s]\n", lkmap(p[i]->h.logkey), p[i]->msg); break;
  case AK_FAIL_RAZ:        /* FAIL macro logkey: val (e.g. failed magic), msg: why */
    printf("FAIL(%s) [%p]\n", p[i]->msg, p[i]->h.logkey); break;
  case AK_FAILS_RAZ:       /* FAIL_PDU macro logkey: str (e.g. function name), msg: why */
    printf("FAIL(%s) [" LK_FMT "]\n", p[i]->msg, lkmap(p[i]->h.logkey)); break;
  case AK_TRACE_VMENTRY_RAZ:  print_trace(i, "VMENTRY"); break;
  case AK_TRACE_CALL_RAZ:     print_trace(i, "CALL"); break;
  case AK_TRACE_RET_RAZ:      print_trace(i, "RET"); break;
  case AK_TRACE_NATCALL_RAZ:  print_trace(i, "NATCALL"); break;
  case AK_TRACE_NATRET_RAZ:   print_trace(i, "NATRET"); break;
  case AK_TRACE_RAZ:          print_trace(i, "TRACE"); break;

  default:
    printf("unknown_reason %x [" LK_FMT "]\n", p[i]->raz, lkmap(p[i]->h.logkey));
  }
  ++(p[i]); /* Advance to next line */
  /*printf("adv. to next p=%p pp=%p lim=%p\n", p[i], pp[i], lim[i]);*/
}

#ifdef MINGW
/* Called by:  anal_core, anal_live */
static void print_buffers()
{
  unsigned long long old_tv;
  int oldest,i,j, wrapped_seen = 0;
  printf("COLDSTART\n");
  while (1) {
    /* Find oldest (that has not run around buffer yet) */
    oldest = -1;  /* none */
    old_tv = ULLONG_MAX;
    for (i = 0; i <= n_thr; ++i) /* Number of threads + 1 static */
      if ((p[i] != pp[i]) &&     /* must not have wrapped around back to the point */
	  (p[i]->h.tv.QuadPart < old_tv)) {
	oldest = i;
	old_tv = p[i]->h.tv.QuadPart;
      }
    if (oldest == -1) break;  /* nothing more to print */

    i = oldest;
    while ((p[i] != pp[i]) &&     /* must not have wrapped around back to the point */
	  (p[i]->h.tv.QuadPart <= old_tv)) {
      if (!seen[i]) {
	seen[i] = 1;
	for (j = 0; j < n_thr; ++j)
	  if (!seen[j])
	    break;
	if (!wrapped_seen && b[i]->wrap_around) {
	  printf("FIRSTWRAP\n");
	  wrapped_seen = 1;
	}
	if (j == n_thr)
	  printf("ALLSEEN\n");
      }
      print_line(i);
      if (p[i] >= lim[i])
	p[i] = start[i];
    }
  }
}
#endif
#ifdef SUNOS
/* Called by:  anal_core, anal_live */
static void print_buffers()
{
  unsigned long long old_tv;
  int oldest,i,j, wrapped_seen = 0;
  printf("COLDSTART\n");
  while (1) {
    /* Find oldest (that has not run around buffer yet) */
    oldest = -1;  /* none */
    old_tv = ULLONG_MAX;
    for (i = 0; i <= n_thr; ++i) /* Number of threads + 1 static */
      if ((p[i] != pp[i]) &&     /* must not have wrapped around back to the point */
          (p[i]->h.tv < old_tv)) {
        oldest = i;
        old_tv = p[i]->h.tv;
      }
    if (oldest == -1) break;  /* nothing more to print */

    i = oldest;
    while ((p[i] != pp[i]) &&     /* must not have wrapped around back to the point */
          (p[i]->h.tv <= old_tv)) {
      if (!seen[i]) {
        seen[i] = 1;
        for (j = 0; j < n_thr; ++j)
          if (!seen[j])
            break;
        if (!wrapped_seen && b[i]->wrap_around) {
          printf("FIRSTWRAP\n");
          wrapped_seen = 1;
        }
        if (j == n_thr)
          printf("ALLSEEN\n");
      }
      print_line(i);
      if (p[i] >= lim[i])
        p[i] = start[i];
    }
  }
}
#endif
#if (!defined(SUNOS)&&!defined(MINGW))
/* Called by:  anal_core, anal_live */
static void print_buffers()
{
  /*unsigned long long end_slice_usec;*/
  struct timeval old_tv;
  int oldest,i,j, wrapped_seen = 0;

  printf("COLDSTART\n");

  while (1) {
    /* Find oldest (that has not run around buffer yet) */
    oldest = -1;  /* none */
    old_tv.tv_sec  = LONG_MAX;
    old_tv.tv_usec = LONG_MAX;
    for (i = 0; i <= n_thr; ++i) /* Number of threads + 1 static */
      if ((p[i] != pp[i]) &&     /* must not have wrapped around back to the point */
	  ((p[i]->h.tv.tv_sec < old_tv.tv_sec)
	   || ((p[i]->h.tv.tv_sec == old_tv.tv_sec)
	       && (p[i]->h.tv.tv_usec < old_tv.tv_usec)))) {
	oldest = i;
	old_tv = p[i]->h.tv;
      }
    if (oldest == -1) break;  /* nothing more to print */

    /* Print as many lines from selected buffer as fuzz_usec permits. Note: handing 64
     * bit ints on 32 bit arcitecture proves to be tricky and gdb, for example, apparently
     * gets it wrong, thus we do the comparisons by parts here. */
    /*end_slice_usec = old_tv.tv_sec * 1000000L + old_tv.tv_usec + fuzz_usec;*/
    old_tv.tv_usec += fuzz_usec;
    if (old_tv.tv_usec > 1000000) {
      old_tv.tv_sec  += old_tv.tv_usec / 1000000;
      old_tv.tv_usec += old_tv.tv_usec % 1000000;
    }
    i = oldest;
    while ((p[i] != pp[i])
	   /*&& ((p[i]->h.tv.tv_sec * 1000000L + p[i]->h.tv.tv_usec) <= end_slice_usec)*/
	   && ((p[i]->h.tv.tv_sec < old_tv.tv_sec)
	       || ((p[i]->h.tv.tv_sec == old_tv.tv_sec)
		   && (p[i]->h.tv.tv_usec <= old_tv.tv_usec)))
	   )
    {
      if (!seen[i]) {
	seen[i] = 1;
	for (j = 0; j < n_thr; ++j)
	  if (!seen[j])
	    break;
	if (!wrapped_seen && b[i]->wrap_around) {
	  printf("FIRSTWRAP\n");
	  wrapped_seen = 1;
	}
	if (j == n_thr)
	  printf("ALLSEEN\n");
      }
      print_line(i);
      if (p[i] >= lim[i])
	p[i] = start[i];
    }
  }
}
#endif

/* Called by:  anal_core, anal_live, extract_exe */
static void locate_buffers(FILE* file)
{
  int i;
  char* lkmark;
  char stamp[16];
  
  /* Find master block */
  
  mr = (struct ak_master_rec*)base;
  while (mr) {
    mr = (struct ak_master_rec*)zx_memmem((U8*)mr, siz - ((unsigned char*)mr - base),
					    (U8*)AK_MASTER_STAMP, sizeof(AK_MASTER_STAMP));
    if (!mr) die2("AK master magic stamp (" AK_MASTER_STAMP ") not found in core.");
    if (mr->endian_mark == AK_ENDIAN_MARK) break;
    ++mr;
  }

  if (ebase) {
    lkmark = (char*)zx_memmem(ebase, esiz, (U8*)AK_LOGKEY_MARK, sizeof(AK_LOGKEY_MARK));
    /* It seems that windows exe does not have the lkmark, but dll has, take a look at this */
#if !defined(MINGW)
    if (!lkmark) die2("AK log key mark (" AK_LOGKEY_MARK ") not found in executable.");
#endif  
  }
  if (n_thr > AK_MAX_BUFS) warning("n_threads exceeds limit");

  fprintf(file, "Summary\n");
  fprintf(file, "  bin date:    %s %s\n",   mr->date, mr->time);
  fprintf(file, "  n_threads:   %d\n",   n_thr);

#if !defined(INTERIXOS)
#if !defined(MINGW)
  fprintf(file, "  Proc Number: %d\n",   mr->ProcNum);
  fprintf(file, "  Host Id:     %x\n",   (unsigned int)mr->HostId);
  fprintf(file, "  Sys Name:    %s\n",   mr->sysname);
  fprintf(file, "  Node Name:   %s\n",   mr->nodename);
  fprintf(file, "  OS Release:  %s\n",   mr->os_release);
  fprintf(file, "  OS Version:  %s\n",   mr->os_version);
  fprintf(file, "  Machine:     %s\n",   mr->machine);
#else /** MINGW **/
  fprintf(file, "  Proc Number:      %d\n",   mr->ProcNum);
  fprintf(file, "  Sys Name:         %s\n",   mr->sysname);
  fprintf(file, "  OS Version:       %s\n",   mr->os_version);
#endif
#endif
  fprintf(file, "  core command line: %s\n", bfd_core_file_failing_command(cbfd));
  if (ebase) {
    fprintf(file, "  core signal      : %d\n", bfd_core_file_failing_signal(cbfd));
    if (!core_file_matches_executable_p(cbfd, ebfd)) {
      fprintf(stderr, "WARNING: core does not match executable. logkey information may be unreliable.\n");
      fprintf(file, "WARNING: core does not match executable. logkey information may be unreliable.\n");
    }
    fprintf(file, "  bin arch         : %s\n", bfd_printable_name(ebfd));
  }
  fprintf(file, "  core arch        : %s\n", bfd_printable_name(cbfd));
  fprintf(file, "  exe realpath     : %s\n", mr->realpath);

  fprintf(file, "END_PREAMBLE\n");

/** This ASSERT causes some problems in AIX **/
#if !defined(AIXOS)
  ASSERTOP(((char*)(mr)),==,amap((char*)(mr->self)),mr);
#endif
  n_thr = mr->n_threads;
  fprintf(file, "Master record found\n");
  fprintf(file, "  endian_mark: 0x%x\n", mr->endian_mark);
  fprintf(file, "  mr address:  %p\n",   mr);

#if !defined(INTERIXOS)
  fprintf(file, "Machine info\n");

#if !defined(MINGW)
#ifdef AIXOS
  fprintf(file, "  Proc Arch:   %d\n",  mr->ProcArch);
  fprintf(file, "  Proc Imp:    %d\n",  mr->ProcImp);
  fprintf(file, "  Proc Ver:    %d\n",  mr->ProcVer);
  fprintf(file, "  Width(bits): %d\n",  mr->Width);
  fprintf(file, "  Max Memory:  %ld\n", mr->MaxMem);
#else
  fprintf(file, "  Model Name:  %s\n",   mr->ModelName); /* Not completed for AIX*/
#endif
# if defined(LINUX) /** For the moment only works for LINUX **/
  fprintf(file, "  Max Memory:  %ld\n",  mr->MaxMem);
  fprintf(file, "  Max Swap:    %ld\n",  mr->MaxSwap);
  fprintf(file, "  Mem Unit:    %ld\n",  mr->MemUnit);
# endif
#else /** MINGW **/
  fprintf(file, "  Proc Arch:       %d\n",  mr->ProcArch);
  fprintf(file, "  Proc Type:       %d\n",  mr->ProcType);
  fprintf(file, "  Proc Level:      %d\n",  mr->ProcLevel);
  fprintf(file, "  Proc Revision:   %d\n",  mr->ProcRev);
#endif
#endif

  fprintf(file, "Stat info\n");
  fprintf(file, "  exe size         : %d\n", (int)mr->binary_st.st_size);
  fprintf(file, "  exe mode         : %o\n", (unsigned int)mr->binary_st.st_mode);
  fprintf(file, "  exe uid          : %d\n", (int)mr->binary_st.st_uid);
  fprintf(file, "  exe gid          : %d\n", (int)mr->binary_st.st_gid);
  fprintf(file, "  exe nlink        : %d\n", (int)mr->binary_st.st_nlink);
  fprintf(file, "  exe access time  : %d\n", (int)mr->binary_st.st_atime);
  fprintf(file, "  exe modify time  : %d\n", (int)mr->binary_st.st_mtime);
  fprintf(file, "  exe status time  : %d\n", (int)mr->binary_st.st_ctime);
  fprintf(file, "  exe dev          : %d\n", (int)mr->binary_st.st_dev);
  fprintf(file, "  exe inode        : %d\n", (int)mr->binary_st.st_ino);

  /* Locate other blocks */

  fprintf(file, "BUFSPEC\n");
 
  /* First static buffer */
  b[0] = (struct ak_buf*)amap((char*)(mr->st_buf));
  sprintf(stamp, AK_ST_BUFFER_STAMP);
  if (strcmp(stamp, b[0]->stamp))
    fprintf(stderr, "WARNING: st_buf has bad stamp (%s) mapped=%p\n", b[0]->stamp, b[0]);
  pp[0] = (struct ak_ts*)amap((char*)(b[0]->p));
  lim[0] = (struct ak_ts*)amap((char*)(b[0]->lim));
  start[0] = b[0]->start;
  p[0] = b[0]->wrap_around ? pp[0]+1 : start[0];
  if (p[0] >= lim[0])
    p[0] = start[0];
  fprintf(file, "Static Buffer comment(%s) tid=%d wrap_around=%d start=%p lim=%p pp=%p p=%p\n",
     b[0]->comment, b[0]->tid, b[0]->wrap_around, start[0], lim[0], pp[0], p[0]);
 
  for (i = 1; i <= n_thr; ++i) {
    b[i] = (struct ak_buf*)amap((char*)(mr->bufs[i-1]));
    sprintf(stamp, AK_BUFFER_STAMP, i);
    if (strcmp(stamp, b[i]->stamp))
      fprintf(stderr, "WARNING: buf[%d] has bad stamp (%s) mapped=%p\n", i, b[i]->stamp, b[i]);
    pp[i] = (struct ak_ts*)amap((char*)(b[i]->p));
    lim[i] = (struct ak_ts*)amap((char*)(b[i]->lim));
    start[i] = b[i]->start;
    p[i] = b[i]->wrap_around ? pp[i]+1 : start[i];
    if (p[i] >= lim[i])
      p[i] = start[i];
    fprintf(file, "Buffer %c%-2d comment(%s) tid=%d wrap_around=%d start=%p lim=%p pp=%p p=%p mem_pool=%p\n",
	    b[i]->comment[0], i-1, b[i]->comment, b[i]->tid,
	    b[i]->wrap_around, start[i], lim[i], pp[i], p[i], (void *)b[i]->mem_pool);
  }
}

/* ----------------------------------------------------------------- */

/* Called by:  anal_core x2, extract_a_sym, extract_exe */
static char* open_obj(char* filename, int* size, bfd** abfd, bfd_format format) {
  asection* s;
  char* base_ptr;
  fdtype fd;
  struct stat st;
  fd = openfile_ro(filename);
  if (fd == BADFD) die(filename);
#ifdef MINGW
  DWORD filesize;
  // change this to GetFileSizeEx()
  if ((filesize = GetFileSize(fd, 0)) == INVALID_FILE_SIZE) die("GetFileSize() failed....");
  st.st_size = filesize;
#else  
  if (fstat(fd, &st) == -1) die("stat(2)");
#endif
  if ((unsigned int)st.st_size > max_size) {
    fprintf(stderr, "mmap of %s truncated to %lu bytes due to -n flag or max_size limit (the size would have been %lu bytes).\n", filename, max_size, (long unsigned int)st.st_size);
    *size = max_size;
  } else
    *size = st.st_size;
#ifdef MINGW
  HANDLE fM;
  if ((fM = CreateFileMapping(fd, 0, PAGE_READONLY, 0, 0, 0)) == 0) {
    errno = GetLastError();
    die("mmap");
  }
  if ((base_ptr = MapViewOfFile(fM, FILE_MAP_READ, 0, 0, *size)) == 0) {
    errno = GetLastError();
    die("mmap");
  }
#else    
  base_ptr = mmap(0, *size, PROT_READ, MAP_SHARED|MAP_NORESERVE, fd, 0);
  if (!base_ptr || base_ptr == MAP_FAILED) die("mmap");
#endif
#ifdef MINGW
  *abfd = bfd_openr(filename, "pei-i386");
#else  
  *abfd = bfd_openr(filename, "default");
#endif
  if (!*abfd) die_bfd("bfd_fdopenr");
  if (!bfd_check_format(*abfd, format))
    die_bfd("Not a recognized BFD file format.");
  
  for (s = (*abfd)->sections; s; s = s->next) {
    if (!(s->flags & SEC_HAS_CONTENTS))   /* often crashes here with s == 0xfe9, fix is to compile as in comment in the beginning. This is some mixed library or library versioning issue. --Sampo */
      continue;
    s->contents = (U8*)(base_ptr + s->filepos);
    s->flags |= SEC_IN_MEMORY;
  }
  return base_ptr;
}

/* Called by:  main */
static void anal_core(char* bin, char* core)
{
  printf("PREAMBLE %s " AK_RELEASE "\n"
	 "Subject to change without notice.\n\n"
	 "Looking at core file %s generated by %s\n", format, core, bin);
  base  = (U8*)open_obj(core, &siz, &cbfd, bfd_core);
  ebase = (U8*)open_obj(bin, &esiz, &ebfd, bfd_object);
  locate_buffers(stdout);
  print_buffers();
  /*if (gviz) ak_gviz(gviz); */
}

/* Called by:  main x2 */
static void anal_live(int pid)
{
  fdtype fd;
  struct stat st;
  char path[1024];
  sprintf(path, "/proc/%d/as", pid);
  printf("ak - DirectoryScript Application Flight Recorder analysis " AK_RELEASE "\n"
	 "Looking at live core image of pid %d at %s\n", pid, path);

  /* *** use ptrace() to attach to inferior first, otherwise its memory can not be opened. */

  /* Open the core. Not being able to open this is fatal. */
  
  fd=openfile_ro(path);
  if (fd == BADFD) {
    sprintf(path, "/proc/%d/mem", pid);
    printf("first image does not exist (%d), trying again at %s\n", errno, path);
    fd=openfile_ro(path);
  }
  if (fd == BADFD) die("Can not read memory image");
  if (fstat(fd, &st) == -1) die("stat(2) failed on core file");
  siz = st.st_size;
  base = (U8*)mmap(0, siz, PROT_READ, MAP_SHARED|MAP_NORESERVE, fd, 0);
  if (!base || base == MAP_FAILED) die("mmapping core file failed");
  cbfd = bfd_openr(path, 0);
  if (!cbfd) die_bfd("bfd_fdopenr");

  locate_buffers(stdout);
  print_buffers();
  /*  if (gviz) ak_gviz(gviz);*/
}

/* Called by:  main x2, show_tab */
static void resolve(int funcno)
{
  if (funcno < 0 || funcno > 65535) die2("Function number must been in range 0..65535");
  printf("funcno 0x%x (%d) file: %s\tfunction: %s\n", funcno, funcno, file[funcno], func[funcno]);
}

/* Called by:  main */
static void show_tab()
{
  int x;
  for (x=0; x < 65536; ++x) {
    if (!memcmp(func[x], "unknown_func", sizeof("unknown_func")-1))
      continue;
    resolve(x);
  }
}

/* Called by:  main */
static void extract_syms(char* bin)
{
  int n;
  asymbol** symtab;
  asymbol** s;
  ebfd = bfd_openr(bin, 0);
  if (!ebfd) die_bfd("bfd_fdopenr");
  if (!bfd_check_format (ebfd, bfd_object))
    die_bfd("Executable is not in a recognized BFD file format.");
  n = bfd_get_symtab_upper_bound(ebfd);
  if (n <= 0) die_bfd("bfd_get_symtab_upper_bound");
  symtab = (asymbol**)malloc(n);
  if (!symtab) die("malloc");
  bfd_canonicalize_symtab(ebfd, symtab);
  for (s = symtab; *s; ++s)
    printf("%s %s: base=%p value=%p\n", bfd_get_section_name(ebfd, bfd_get_section(*s)),
	   bfd_asymbol_name(*s), (char*)bfd_asymbol_base(*s), (char*)bfd_asymbol_value(*s));
}

/* Called by:  main */
static void extract_a_sym(char* bin, char* sym)
{
  char* sym_data;
  char* sym_end;
  
  fprintf(stderr, "ak - DirectoryScript Application Flight Recorder(tm) " AK_RELEASE "\n"
	  "Extracting symbol %s from binary exectuable file %s\n", sym, bin);
  
  ebase = (U8*)open_obj(bin, &esiz, &ebfd, bfd_object);

#if 0
  int n;
  asymbol** symtab;
  asymbol** s;

  ebfd = bfd_openr(bin, 0);
  if (!ebfd) die_bfd("bfd_fdopenr");
  if (!bfd_check_format (ebfd, bfd_object))
    die_bfd("Executable is not in a recognized BFD file format.");
  n = bfd_get_symtab_upper_bound(ebfd);
  if (n <= 0) die_bfd("bfd_get_symtab_upper_bound");
  symtab = (asymbol**)malloc(n);
  if (!symtab) die("malloc");
  bfd_canonicalize_symtab(ebfd, symtab);
  for (s = symtab; *s; ++s) {
    if (!strcmp(bfd_asymbol_name(*s), sym)) {
      fprintf(stderr, "Found! %s %s: base=%p value=%p\n",
	      bfd_get_section_name(ebfd, bfd_get_section(*s)),
	      bfd_asymbol_name(*s), (char*)bfd_asymbol_base(*s), (char*)bfd_asymbol_value(*s));
      bfd_print_symbol (ebfd, stderr, *s, bfd_print_symbol_all);
      sym_data = s->section ? s->value + s->section->vma : s->value;
      fwrite(sym_data, 1, , stdout);
      exit(0);
    }
  }
#else
  sym_data = (char*)zx_memmem(ebase, esiz, (U8*)"sigmAsigmA", sizeof("sigmAsigmA")-1);
  if (!sym_data) die2("version data magic stamp not found in executable.");
  sym_data += sizeof("sigmAsigmA")-1;
  sym_end = (char*)zx_memmem(sym_data, esiz - (sym_data - (char*)ebase),
		      "SigmaSigmaSigma", sizeof("SigmaSigmaSigma")-1);
  if (!sym_end) die2("version data end stamp not found in executable.");
  fprintf(stderr, "Found! at %p, length %d\n", sym_data, sym_end - sym_data);
  fwrite(sym_data, 1, sym_end - sym_data, stdout);
  exit(0);
#endif
  die("Symbol not found.\n");
}

/* Called by:  main */
static void extract_exe(char* core)
{
  fprintf(stderr, "ak - DirectoryScript Application Flight Recorder(tm) " AK_RELEASE "\n"
	  "Extracting binary from core file %s\n", core);
  base  = (U8*)open_obj(core, &siz, &cbfd, bfd_core);
  locate_buffers(stderr);
  if (!mr->binary) die("No binary found in core.\n");
  fwrite(amap(mr->binary), 1, mr->binary_st.st_size, stdout);
}

/* Called by:  main */
static void init_func(int x, char* funcname, char* filename)
{
  char* c;
  if (func[x]) {
    c = malloc(strlen(funcname)+strlen(func[x])+2);
    strcpy(c, func[x]);
    strcat(c, "|");
    strcat(c, funcname);
    func[x] = c;
  } else {
    func[x] = funcname;
    file[x] = filename;
  }
}

/* Called by: */
int main(int argc, char** argv)
{
  char** cc;
  char* q;
  int x;
  /* Populate table with known functions and their files. function.list was produced by
   * call-anal.pl which eats callgraph.files (see top Makefile callgraph target). */
#define AK_FUNC_DEF(f,fil)  init_func(AK_FUNCNO(f), f, fil);
#include "../function.list"
  for (x=0; x < 65536; ++x) {
    if (func[x]) continue;
    q = malloc(20);
    sprintf(q, "unknown_func_%x", x);
    func[x] = q;
    q = malloc(20);
    sprintf(q, "unknown_file_%x", x);
    file[x] = q;
  }

  bfd_init();

  while (argc>1) {
    ++argv; --argc;
    if (argv[0][0] != '-') {
      if (argc < 1) usage("must supply both executable binary and the core\n");
      anal_core(argv[0], argv[1]);
      exit(0);
    }
    switch (argv[0][1]) {
    case 'p': if (argc < 2) usage("missing pid arg\n"); anal_live(atoi(argv[1])); exit(0);
    case 'f': if (argc < 2) usage("missing pid arg\n"); anal_live(atoi(argv[1])); exit(0);
    case 'r': if (argc < 2) usage("missing funcno arg\n");
              if (strchr(argv[1], ':')) {   /* file:line format */
		char buf[64];
		buf[0] = '0';
		buf[1] = 'x';
		strncpy(buf+2, argv[1], sizeof(buf));
		q = strchr(buf+2, ':');
		*q = 0;
		sscanf(buf, "%i", &x);
		resolve(x);
		*q = 'x';
		q[-1] = '0';
		sscanf(q-1, "%i", &x);
		printf("0x%x == %d\n", x, x);
		exit(0);
              }
              sscanf(argv[1], "%i", &x);
	      resolve(x);
	      if (argc >= 2) {
		sscanf(argv[2], "%i", &x);
		printf("0x%x == %d\n", x, x);
	      }
	      exit(0);
    case 'e': if (argc < 2) usage("missing errno arg\n");
              ++argv; --argc;
	      sscanf(argv[0], "%i", &x);
	      printf("0x%x == %d ==> %s\n", x, x, STRERROR(x));
	      exit(0);
    case 'x': if (argc < 2) usage("missing executable arg\n");
              extract_syms(argv[1]); exit(0);
    case 'z': if (argc < 3) usage("missing executable or symbol arg\n");
              extract_a_sym(argv[1], argv[2]); exit(0);
    case 'y': if (argc < 2) usage("missing core arg\n");
              extract_exe(argv[1]); exit(0);
    case 't': show_tab(); exit(0);
    case 'n': if (argc < 2) usage("missing max core size nn arg\n");
              ++argv; --argc; sscanf(argv[0], "%li", &max_size); break;
    case 's': if (argc < 2) usage("missing lane width nn arg\n");
              ++argv; --argc; swimlane = 1; lane_width = atoi(argv[0]); break;
    case '2': swimlane = 2;   warning("not implemented yet"); break;
    case 'c': if (argc < 2) usage("missing lane width nn arg\n");
              ++argv; --argc; swimlane = 3; lane_width = atoi(argv[0]);
	      warning("not implemented yet"); break;
    case 'b': ++brief; format="brief"; break;
    case 'g': if (argc < 2) usage("missing gviz file name arg\n");
              ++argv; --argc; gviz = argv[0]; break;
    case 'm': if (argc < 2) usage("missing fuzz in millisec arg\n");
              ++argv; --argc; fuzz_usec = 1000 * atoi(argv[0]); break;
    case 'T': for (cc = (char**)bfd_target_list(); *cc; ++cc)
                printf("%s\n", *cc);
               exit(0);
    default: usage("unknown option\n");
    }
  }
  return 0;
}

/* EOF - ak.c */
