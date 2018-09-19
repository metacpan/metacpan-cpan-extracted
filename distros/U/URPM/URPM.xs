/* Copyright (c) 2002, 2003, 2004, 2005 MandrakeSoft SA
 * Copyright (c) 2005, 2006, 2007, 2008 Mandriva SA
 * Copyright (c) 2011-2016 Mageia
 *
 * All rights reserved.
 * This program is free software; you can redistribute it and/or
 * modify it under the same terms as Perl itself.
 *
 * 
 */
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "rpmversion.h"

#include <sys/utsname.h>
#include <sys/select.h>
#include <sys/time.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <sys/wait.h>
#include <fcntl.h>
#include <unistd.h>
#include <libintl.h>

// fix compiling (error: conflicting types for ‘fflush’):
#undef Fflush
#undef Mkdir
#undef Stat
#undef Fstat

static inline void *_free(const void * p) {
  if (p != NULL) free((void *)p); 
  return NULL;
}
typedef struct rpmSpec_s * Spec;

#include <rpm/rpmio.h>
#include <rpm/rpmdb.h>
#include <rpm/rpmts.h>
#include <rpm/rpmte.h>
#include <rpm/rpmps.h>
#include <rpm/rpmpgp.h>
#include <rpm/rpmcli.h>
#include <rpm/rpmbuild.h>
#include <rpm/rpmlog.h>

struct s_Package {
  Header h;
  UV filesize;
  unsigned flag;
  char *info;
  char *requires;
  char *recommends;
  char *obsoletes;
  char *conflicts;
  char *provides;
  char *rflags;
  char *summary;
};

struct s_Transaction {
  rpmts ts;
  int count;
};

struct s_TransactionData {
  SV* callback_open;
  SV* callback_close;
  SV* callback_trans;
  SV* callback_uninst;
  SV* callback_inst;
  SV* callback_error;
  SV* callback_elem;
  SV* callback_verify;
  long min_delta;
  SV *data; /* chain with another data user provided */
};

typedef struct s_Transaction* URPM__DB;
typedef struct s_Transaction* URPM__Transaction;
typedef struct s_Package* URPM__Package;

/*
 * URPM__Package->flag is an unsigned int:
 * bit :  significance
 * 0..20: ID
 * 21-23: rate
 * 24:    BASE
 * 25:    SKIP
 * 26:    DISABLE_OBSOLETE
 * 27:    INSTALLED
 * 28:    REQUESTED
 * 29:    REQUIRED
 * 30:    UPGRADE
 * 31:    NO_HEADER_FREE
 * */

#define FLAG_ID_MASK          0x001fffffU
#define FLAG_RATE_MASK        0x00e00000U
#define FLAG_BASE             0x01000000U
#define FLAG_SKIP             0x02000000U
#define FLAG_DISABLE_OBSOLETE 0x04000000U
#define FLAG_INSTALLED        0x08000000U
#define FLAG_REQUESTED        0x10000000U
#define FLAG_REQUIRED         0x20000000U
#define FLAG_UPGRADE          0x40000000U
#define FLAG_NO_HEADER_FREE   0x80000000U

#define FLAG_ID_MAX           0x001ffffe
#define FLAG_ID_INVALID       0x001fffff

#define FLAG_RATE_POS         21
#define FLAG_RATE_MAX         5
#define FLAG_RATE_INVALID     0


#define FILTER_MODE_ALL_FILES     0
#define FILTER_MODE_DOC_FILES     1
#define FILTER_MODE_CONF_FILES    2

#ifdef RPM4_11_0
#ifndef RPM4_12_0
#define RPMTAG_RECOMMENDNAME RPMTAG_SUGGESTSNAME
#define RPMTAG_RECOMMENDFLAGS RPMTAG_SUGGESTSFLAGS
#define RPMTAG_RECOMMENDVERSION RPMTAG_SUGGESTSVERSION
#endif
#endif

static ssize_t write_nocheck(int fd, const void *buf, size_t count) {
  return write(fd, buf, count);
}
static int rpmError_callback_data;

static int rpmError_callback(rpmlogRec rec, __attribute__((unused)) rpmlogCallbackData data) {
  write_nocheck(rpmError_callback_data, rpmlogRecMessage(rec), strlen(rpmlogRecMessage(rec)));
  return RPMLOG_DEFAULT;
}

static inline int _run_cb_while_traversing(SV *callback, Header header, VOL I32 flags) {
     dSP;
     URPM__Package pkg = calloc(1, sizeof(struct s_Package));

     pkg->flag = FLAG_ID_INVALID | FLAG_NO_HEADER_FREE;
     pkg->h = header;

     PUSHMARK(SP);
     mXPUSHs(sv_setref_pv(newSVpvs(""), "URPM::Package", pkg));
     PUTBACK;

     int count = call_sv(callback, G_SCALAR | flags);

     SPAGAIN;
     pkg->h = NULL; /* avoid using it anymore, in case it has been copied inside callback */
     return count;
}

static inline  void _header_free(URPM__Package pkg) {
     if (pkg->h && !(pkg->flag & FLAG_NO_HEADER_FREE))
          pkg->h = headerFree(pkg->h);
}

static int rpm_codeset_is_utf8 = 0;

static SV*
newSVpv_utf8(const char *s, STRLEN len)
{
  SV *sv = newSVpv(s, len);
  SvUTF8_on(sv);
  return sv;
}

static void
get_fullname_parts(URPM__Package pkg, char **name, char **version, char **release, char **arch, char **eos) {
  char *_version = NULL, *_release = NULL, *_arch = NULL, *_eos = NULL;

  if (!pkg->info)
    return;
  if ((_eos = strchr(pkg->info, '@')) != NULL) {
    *_eos = 0; /* mark end of string to enable searching backwards */
    if ((_arch = strrchr(pkg->info, '.')) != NULL) {
      *_arch = 0;
      if ((release != NULL || version != NULL || name != NULL) && (_release = strrchr(pkg->info, '-')) != NULL) {
	*_release = 0;
	if ((version != NULL || name != NULL) && (_version = strrchr(pkg->info, '-')) != NULL) {
	  if (name != NULL) *name = pkg->info;
	  if (version != NULL) *version = _version + 1;
	}
	if (release != NULL) *release = _release + 1;
	*_release = '-';
      }
      if (arch != NULL) *arch = _arch + 1;
      *_arch = '.';
    }
    if (eos != NULL) *eos = _eos;
    *_eos = '@';
  }
}

static char *
get_name(const Header header, rpmTag tag) {
  struct rpmtd_s val;

  headerGet(header, tag, &val, HEADERGET_MINMEM);
  char *name = (char *) rpmtdGetString(&val);
  return name ? name : "";
}

static char*
get_arch(const Header header) {
     return headerIsEntry(header, RPMTAG_SOURCERPM) ? get_name(header, RPMTAG_ARCH) : "src";
}

static UV
get_int(const Header header, rpmTag tag) {
  struct rpmtd_s val;

  headerGet(header, tag, &val, HEADERGET_ALLOC);
  return rpmtdGetNumber(&val);
}

static UV
get_int2(const Header header, rpmTag newtag, rpmTag oldtag) {
  struct rpmtd_s val;

  if (!headerGet(header, newtag, &val, HEADERGET_DEFAULT))
      headerGet(header, oldtag, &val, HEADERGET_DEFAULT);
  return rpmtdGetNumber(&val);
}

static UV
get_filesize(const Header h) {
  return get_int2(h, RPMTAG_LONGSIGSIZE, RPMTAG_SIGSIZE) + 440; /* 440 is the rpm header size (?) empirical, but works */
}

static int
print_list_entry(char *buff, int sz, const char *name, rpmsenseFlags flags, const char *evr) {
  int len = strlen(name);
  char *p = buff;

  if (len >= sz || !strncmp(name, "rpmlib(", 7))
    return -1;
  memcpy(p, name, len); p += len;

  if (flags & (RPMSENSE_PREREQ|RPMSENSE_SCRIPT_PREUN|RPMSENSE_SCRIPT_PRE|RPMSENSE_SCRIPT_POSTUN|RPMSENSE_SCRIPT_POST)) {
    if (p - buff + 3 >= sz)
      return -1;
    memcpy(p, "[*]", 4); p += 3;
  }
  if (evr != NULL) {
    len = strlen(evr);
    if (len > 0) {
      if (p - buff + 6 + len >= sz)
        return -1;
      *p++ = '[';
      if (flags & RPMSENSE_LESS) *p++ = '<';
      if (flags & RPMSENSE_GREATER) *p++ = '>';
      if (flags & RPMSENSE_EQUAL) *p++ = '=';
      if ((flags & (RPMSENSE_LESS|RPMSENSE_EQUAL|RPMSENSE_GREATER)) == RPMSENSE_EQUAL) *p++ = '=';
      *p++ = ' ';
      memcpy(p, evr, len); p+= len;
      *p++ = ']';
    }
  }
  *p = 0; /* make sure to mark null char, Is it really necessary ? */

  return p - buff;
}

static int
ranges_overlap(rpmsenseFlags aflags, char *sa, rpmsenseFlags bflags, char *sb) {
  if (!aflags || !bflags)
    return 1; /* really faster to test it there instead of later */
  else {
    int res;
    char *eosa = strchr(sa, ']');
    char *eosb = strchr(sb, ']');
    rpmds dsa, dsb;

    if (eosa) *eosa = 0;
    if (eosb) *eosb = 0;

    dsa = rpmdsSingle(RPMTAG_REQUIRENAME, "", sa, aflags);
    dsb = rpmdsSingle(RPMTAG_REQUIRENAME, "", sb, bflags);
    res = rpmdsCompare(dsa, dsb);
    rpmdsFree(dsa);
    rpmdsFree(dsb);

    if (eosb) *eosb = ']';
    if (eosa) *eosa = ']';

    return res;
  }
}

typedef int (*callback_list_str)(char *s, int slen, const char *name, const rpmsenseFlags flags, const char *evr, void *param);

static int
callback_list_str_xpush(char *s, int slen, const char *name, rpmsenseFlags flags, const char *evr, __attribute__((unused)) void *param) {
  dSP;
  if (s)
    mXPUSHs(newSVpv(s, slen));
  else {
    char buff[4096];
    int len = print_list_entry(buff, sizeof(buff)-1, name, flags, evr);
    if (len >= 0)
      mXPUSHs(newSVpv(buff, len));
  }
  PUTBACK;
  /* returning zero indicates to continue processing */
  return 0;
}

struct cb_overlap_s {
  rpmsenseFlags flags;
  int direction; /* indicate to compare the above at left or right to the iteration element */
  char *name;
  char *evr;
};

static int
callback_list_str_overlap(char *s, int slen, const char *name, rpmsenseFlags flags, const char *evr, void *param) {
  struct cb_overlap_s *os = (struct cb_overlap_s *)param;
  int result = 0;
  char *eos = NULL;
  char *eon = NULL;
  char eosc = '\0';
  char eonc = '\0';

  /* we need to extract name, flags and evr from a full sense information, store result in local copy */
  if (s) {
    if (slen) {
      eos = s + slen;
      eosc = *eos;
      *eos = 0;
    }
    name = s;
    while (*s && *s != ' ' && *s != '[' && *s != '<' && *s != '>' && *s != '=') ++s;
    if (*s) {
      eon = s;
      while (*s) {
	if (*s == ' ' || *s == '[' || *s == '*' || *s == ']');
	else if (*s == '<') flags |= RPMSENSE_LESS;
	else if (*s == '>') flags |= RPMSENSE_GREATER;
	else if (*s == '=') flags |= RPMSENSE_EQUAL;
	else break;
	++s;
      }
      evr = s;
    } else
      evr = "";
  }

  /* mark end of name */
  if (eon) {
       eonc = *eon;
       *eon = 0;
  }
  /* names should be equal, else it will not overlap */
  if (!strcmp(name, os->name)) {
    /* perform overlap according to direction needed, negative for left */
    if (os->direction < 0)
      result = ranges_overlap(os->flags, os->evr, flags, (char *) evr);
    else
      result = ranges_overlap(flags, (char *) evr, os->flags, os->evr);
  }

  /* fprintf(stderr, "cb_list_str_overlap result=%d, os->direction=%d, os->name=%s, os->evr=%s, name=%s, evr=%s\n",
     result, os->direction, os->name, os->evr, name, evr); */

  /* restore s if needed */
  if (eon) *eon = eonc;
  if (eos) *eos = eosc;

  return result;
}

static int
return_list_str(char *s, const Header header, rpmTag tag_name, rpmTag tag_flags, rpmTag tag_version, callback_list_str f, void *param) {
  int count = 0;

  if (s != NULL) {
    char *ps = strchr(s, '@');
    if (tag_flags && tag_version) {
      while(ps != NULL) {
	++count;
	if (f(s, ps-s, NULL, 0, NULL, param))
          return -count;
	s = ps + 1; ps = strchr(s, '@');
      }
      ++count;
      if (f(s, 0, NULL, 0, NULL, param))
        return -count;
    } else {
      char *eos;
      while(ps != NULL) {
	*ps = 0; eos = strchr(s, '['); if (!eos) eos = strchr(s, ' ');
	++count;
	if (f(s, eos ? eos-s : ps-s, NULL, 0, NULL, param)) {
          *ps = '@';
          return -count;
        }
	*ps = '@'; /* restore in memory modified char */
	s = ps + 1; ps = strchr(s, '@');
      }
      eos = strchr(s, '['); if (!eos) eos = strchr(s, ' ');
      ++count;
      if (f(s, eos ? eos-s : 0, NULL, 0, NULL, param))
         return -count;
    }
  } else if (header) {
    struct rpmtd_s list, flags, list_evr;

    if (headerGet(header, tag_name, &list, HEADERGET_EXT)) {
      memset((void*)&flags, 0, sizeof(flags));
      memset((void*)&list_evr, 0, sizeof(list_evr));
      if (tag_flags) headerGet(header, tag_flags, &flags, HEADERGET_DEFAULT);
      if (tag_version) headerGet(header, tag_version, &list_evr, HEADERGET_DEFAULT);
      while (rpmtdNext(&list) >= 0) {
	++count;
	uint32_t *flag = rpmtdNextUint32(&flags);
	if (f(NULL, 0, rpmtdGetString(&list), flag ? *flag : 0, 
	      rpmtdNextString(&list_evr), param)) {
	  rpmtdFreeData(&list);
	  if (tag_flags) rpmtdFreeData(&flags);
	  if (tag_version) rpmtdFreeData(&list_evr);
	  return -count;
	}
      }
      rpmtdFreeData(&list);
      if (tag_flags) rpmtdFreeData(&flags);
      if (tag_version) rpmtdFreeData(&list_evr);
    }
  }
  return count;
}

static int
xpush_simple_list_str(const Header header, rpmTag tag_name) {
  dSP;
  if (header) {
    struct rpmtd_s list;
    const char *val;
    int size;

    if (!headerGet(header, tag_name, &list, HEADERGET_DEFAULT))
        return 0;
    size = rpmtdCount(&list);

    EXTEND(SP, size);
    while ((val = rpmtdNextString(&list)))
        mPUSHs(newSVpv(val, 0));
    rpmtdFreeData(&list);
    PUTBACK;
    return size;
  } else return 0;
}

static void
return_list_number(const Header header, rpmTag tag_name) {
  dSP;
  if (header) {
    struct rpmtd_s list;
    if (headerGet(header, tag_name, &list, HEADERGET_DEFAULT)) {
      int count = rpmtdCount(&list);
      int i;
      EXTEND(SP, count);
      for(i = 0; i < count; i++) {
	rpmtdNext(&list);
	mPUSHs(newSViv(rpmtdGetNumber(&list)));
      }
      rpmtdFreeData(&list);
    }
  }
  PUTBACK;
}

static void
return_list_tag_modifier(const Header header, rpmTag tag_name) {
  dSP;
  int i;
  struct rpmtd_s td;
  if (!headerGet(header, tag_name, &td, HEADERGET_DEFAULT))
    return;
  int count = rpmtdCount(&td);
  rpmtdInit(&td);

  for (i = 0; i < count; i++) {
    char buff[15];
    char *s = buff;
    int32_t tag;
    rpmtdNext(&td);
    tag = rpmtdGetNumber(&td);

    if (tag_name == RPMTAG_FILEFLAGS) {
      if (tag & RPMFILE_CONFIG)    *s++ = 'c';
      if (tag & RPMFILE_DOC)       *s++ = 'd';
      if (tag & RPMFILE_GHOST)     *s++ = 'g';
      if (tag & RPMFILE_LICENSE)   *s++ = 'l';
      if (tag & RPMFILE_MISSINGOK) *s++ = 'm';
      if (tag & RPMFILE_NOREPLACE) *s++ = 'n';
      if (tag & RPMFILE_SPECFILE)  *s++ = 'S';
      if (tag & RPMFILE_README)    *s++ = 'R';
      if (tag & RPMFILE_ICON)      *s++ = 'i';
      if (tag & RPMFILE_PUBKEY)    *s++ = 'p';
    } else {
      rpmtdFreeData(&td);
      return;  
    }
    *s = '\0';
    mXPUSHs(newSVpv(buff, strlen(buff)));
  }
  rpmtdFreeData(&td);
  PUTBACK;
}

static void
return_list_tag(const URPM__Package pkg, rpmTag tag_name) {
  dSP;
  if (pkg->h != NULL) {
    struct rpmtd_s td;
    if (headerGet(pkg->h, tag_name, &td, HEADERGET_DEFAULT)) {
      int32_t count = rpmtdCount(&td);
      if (tag_name == RPMTAG_ARCH)
	mXPUSHs(newSVpv(get_arch(pkg->h), 0));
      else
	switch (rpmtdType(&td)) {
	  case RPM_NULL_TYPE:
	    break;
	  case RPM_CHAR_TYPE:
	  case RPM_INT8_TYPE:
	  case RPM_INT16_TYPE:
	  case RPM_INT32_TYPE:
	    {
	      int i;
              EXTEND(SP, count);
	      for (i=0; i < count; i++) {
		rpmtdNext(&td);
		mPUSHs(newSViv(rpmtdGetNumber(&td)));
	      }
	    }
	    break;
	  case RPM_STRING_TYPE:
	    mPUSHs(newSVpv(rpmtdGetString(&td), 0));
	    break;
	  case RPM_BIN_TYPE:
	    break;
	  case RPM_STRING_ARRAY_TYPE:
	    {
	      int i;
              EXTEND(SP, count);
              rpmtdInit(&td);
	      for (i = 0; i < count; i++)
		mPUSHs(newSVpv(rpmtdNextString(&td), 0));
	    }
	    break;
	  case RPM_I18NSTRING_TYPE:
	    break;
	  case RPM_INT64_TYPE:
	    break;
	}
    }
  } else {
    char *name, *version, *release, *arch, *eos, *data = NULL;
    int len;
    switch (tag_name) {
      case RPMTAG_NAME:
	{
	  get_fullname_parts(pkg, &name, &version, &release, &arch, &eos);
	  data = name;
	  len = version-name;
	}
	break;
      case RPMTAG_VERSION:
	{
	  get_fullname_parts(pkg, &name, &version, &release, &arch, &eos);
	  data = version;
	  len = release-version;
	}
	break;
      case RPMTAG_RELEASE:
	{
	  get_fullname_parts(pkg, &name, &version, &release, &arch, &eos);
	  data = release;
	  len = arch-release;
	}
	break;
      case RPMTAG_ARCH:
	{
	  get_fullname_parts(pkg, &name, &version, &release, &arch, &eos);
	  mXPUSHs(newSVpv(arch, eos-arch));
	}
	break;
      case RPMTAG_SUMMARY:
	mXPUSHs(newSVpv(pkg->summary, 0));
	break;
      default:
	croak("unexpected tag %s", rpmTagGetName(tag_name));
	break;
    }
    if (data) {
      if (len < 1) croak("invalid fullname");
      mXPUSHs(newSVpv(data, len - 1));
    }
  }
  PUTBACK;
}


static void
return_files(const Header header, int filter_mode) {
  dSP;
  if (header) {
    char buff[4096];
    char *p; const char *s;
    STRLEN len;
    unsigned int i;

    struct rpmtd_s td_flags, td_fmodes;
    int32_t *flags = NULL;
    if (filter_mode) {
      headerGet(header, RPMTAG_FILEFLAGS, &td_flags, HEADERGET_DEFAULT);
      headerGet(header, RPMTAG_FILEMODES, &td_fmodes, HEADERGET_DEFAULT);
      flags = td_flags.data;
    }

    struct rpmtd_s td_baseNames, td_dirIndexes, td_dirNames, td_list;
    headerGet(header, RPMTAG_BASENAMES, &td_baseNames, HEADERGET_DEFAULT);
    headerGet(header, RPMTAG_DIRINDEXES, &td_dirIndexes, HEADERGET_DEFAULT);
    headerGet(header, RPMTAG_DIRNAMES, &td_dirNames, HEADERGET_DEFAULT);

    char **baseNames = td_baseNames.data;
    char **dirNames = td_dirNames.data;
    int32_t *dirIndexes = td_dirIndexes.data;
    int is_oldfilenames = !baseNames || !dirNames || !dirIndexes;

    if (is_oldfilenames) {
      if (!headerGet(header, RPMTAG_OLDFILENAMES, &td_list, HEADERGET_DEFAULT))
        return;
      rpmtdInit(&td_list);
    }

    rpm_count_t count = is_oldfilenames ? rpmtdCount(&td_list) : rpmtdCount(&td_baseNames);
    for(i = 0; i < count; i++) {
      if (is_oldfilenames) {
	s = rpmtdNextString(&td_list);
	len = strlen(s);
      } else {
	len = strlen(dirNames[dirIndexes[i]]);
	if (len >= sizeof(buff)) continue;
	memcpy(p = buff, dirNames[dirIndexes[i]], len + 1); p += len;
	len = strlen(baseNames[i]);
	if (p - buff + len >= sizeof(buff)) continue;
	memcpy(p, baseNames[i], len + 1); p += len;
	s = buff;
	len = p-buff;
      }

      if (filter_mode) {
	if ((filter_mode & FILTER_MODE_CONF_FILES) && flags && (flags[i] & RPMFILE_CONFIG) == 0) continue;
	if ((filter_mode & FILTER_MODE_DOC_FILES) && flags && (flags[i] & RPMFILE_DOC) == 0) continue;
      }

      mXPUSHs(newSVpv(s, len));
    }

    rpmtdFreeData(&td_baseNames);
    rpmtdFreeData(&td_dirNames);
    if (is_oldfilenames)
      rpmtdFreeData(&td_list);
  }
  PUTBACK;
}

static void
return_problems(rpmps ps, int translate_message, int raw_message) {
  dSP;
  if (ps && rpmpsNumProblems(ps) > 0) {
    rpmpsi iterator = rpmpsInitIterator(ps);
    while (rpmpsNextIterator(iterator) >= 0) {
      rpmProblem p = rpmpsGetProblem(iterator);

      if (translate_message) {
	/* translate error using rpm localization */
	const char *buf = rpmProblemString(p);
	SV *sv = newSVpv(buf, 0);
	if (rpm_codeset_is_utf8) SvUTF8_on(sv);
	mXPUSHs(sv);
	_free(buf);
      }
      if (raw_message) {
	const char *pkgNEVR = rpmProblemGetPkgNEVR(p) ? rpmProblemGetPkgNEVR(p) : "";
	const char *altNEVR = rpmProblemGetAltNEVR(p) ? rpmProblemGetAltNEVR(p) : "";
	const char *s = rpmProblemGetStr(p) ? rpmProblemGetStr(p) : "";
	SV *sv;

	switch (rpmProblemGetType(p)) {
	case RPMPROB_BADARCH:
	  sv = newSVpvf("badarch@%s", pkgNEVR); break;

	case RPMPROB_BADOS:
	  sv = newSVpvf("bados@%s", pkgNEVR); break;

	case RPMPROB_PKG_INSTALLED:
	  sv = newSVpvf("installed@%s", pkgNEVR); break;

	case RPMPROB_BADRELOCATE:
	  sv = newSVpvf("badrelocate@%s@%s", pkgNEVR, s); break;

	case RPMPROB_NEW_FILE_CONFLICT:
	case RPMPROB_FILE_CONFLICT:
	  sv = newSVpvf("conflicts@%s@%s@%s", pkgNEVR, altNEVR, s); break;

	case RPMPROB_OLDPACKAGE:
	  sv = newSVpvf("installed@%s@%s", pkgNEVR, altNEVR); break;

	case RPMPROB_DISKSPACE:
	  sv = newSVpvf("diskspace@%s@%s@%lld", pkgNEVR, s, (long long)rpmProblemGetDiskNeed(p)); break;
	case RPMPROB_DISKNODES:
	  sv = newSVpvf("disknodes@%s@%s@%lld", pkgNEVR, s, (long long)rpmProblemGetDiskNeed(p)); break;
	case RPMPROB_REQUIRES:
	  sv = newSVpvf("requires@%s@%s", pkgNEVR, altNEVR+2); break;

	case RPMPROB_CONFLICT:
	  sv = newSVpvf("conflicts@%s@%s", pkgNEVR, altNEVR+2); break;

	case RPMPROB_OBSOLETES:
	  sv = newSVpvf("obsoletes@%s@%s", pkgNEVR, altNEVR+2); break;

	default:
	  sv = newSVpvf("unknown@%s", pkgNEVR); break;
	}
	mXPUSHs(sv);
      }
    }
    rpmpsFreeIterator(iterator);
  }
  PUTBACK;
}

static char *
pack_list(const Header header, rpmTag tag_name, rpmTag tag_flags, rpmTag tag_version) {
  char buff[65536*2];
  char *p = buff;

  struct rpmtd_s td;
  if (headerGet(header, tag_name, &td, HEADERGET_EXT)) {
    char **list = td.data;
    char **list_evr = NULL;
    rpmTag *flags = NULL;
    unsigned int i;
    
    struct rpmtd_s td_flags, td_list_evr;
    if (tag_flags   && headerGet(header, tag_flags,   &td_flags, HEADERGET_DEFAULT))    flags    = td_flags.data;
    if (tag_version && headerGet(header, tag_version, &td_list_evr, HEADERGET_DEFAULT)) list_evr = td_list_evr.data;
    for(i = 0; i < rpmtdCount(&td); i++) {
      int len = print_list_entry(p, sizeof(buff)-(p-buff)-1, list[i], flags ? flags[i] : 0, list_evr ? list_evr[i] : NULL);
      if (len < 0) continue;
      p += len;
      *p++ = '@';
    }
    if (p > buff) p[-1] = 0;

    free(list);
    free(list_evr);
  }

  return p > buff ? memcpy(malloc(p-buff), buff, p-buff) : NULL;
}

static void
pack_header(const URPM__Package pkg) {
  if (pkg->h) {
    if (pkg->info == NULL) {
      char buff[1024];
      const char *p = buff;
      const char *nvr = headerGetAsString(pkg->h, RPMTAG_NVR);
      const char *arch = get_arch(pkg->h);
      p += 1 + snprintf(buff, sizeof(buff), "%s.%s@%" PRIu64 "@%" PRIu64 "@%s", nvr, arch,
		    get_int(pkg->h, RPMTAG_EPOCH), get_int2(pkg->h, RPMTAG_LONGSIZE, RPMTAG_SIZE),
		    get_name(pkg->h, RPMTAG_GROUP));
      pkg->info = memcpy(malloc(p-buff), buff, p-buff);
    }
    if (pkg->filesize == 0) pkg->filesize = get_filesize(pkg->h);
    if (pkg->requires == NULL)
      pkg->requires = pack_list(pkg->h, RPMTAG_REQUIRENAME, RPMTAG_REQUIREFLAGS, RPMTAG_REQUIREVERSION);
    if (pkg->recommends == NULL)
      pkg->recommends = pack_list(pkg->h, RPMTAG_RECOMMENDNAME, 0, 0);
    if (pkg->obsoletes == NULL)
      pkg->obsoletes = pack_list(pkg->h, RPMTAG_OBSOLETENAME, RPMTAG_OBSOLETEFLAGS, RPMTAG_OBSOLETEVERSION);
    if (pkg->conflicts == NULL)
      pkg->conflicts = pack_list(pkg->h, RPMTAG_CONFLICTNAME, RPMTAG_CONFLICTFLAGS, RPMTAG_CONFLICTVERSION);
    if (pkg->provides == NULL)
      pkg->provides = pack_list(pkg->h, RPMTAG_PROVIDENAME, RPMTAG_PROVIDEFLAGS, RPMTAG_PROVIDEVERSION);
    if (pkg->summary == NULL) {
      char *summary = get_name(pkg->h, RPMTAG_SUMMARY);
      int len = 1 + strlen(summary);

      pkg->summary = memcpy(malloc(len), summary, len);
    }

    _header_free(pkg);
    pkg->h = NULL;
  }
}

static void
update_hash_entry(HV *hash, const char *name, STRLEN len, int force, IV use_sense, const URPM__Package pkg) {
  SV** isv;

  if (!len) len = strlen(name);
  if ((isv = hv_fetch(hash, name, len, force))) {
    /* check if an entry has been found or created, it should so be updated */
    if (!SvROK(*isv) || SvTYPE(SvRV(*isv)) != SVt_PVHV) {
      SV* choice_set = (SV*)newHV();
      if (choice_set) {
	SvREFCNT_dec(*isv); /* drop the old as we are changing it */
	if (!(*isv = newRV_noinc(choice_set))) {
	  SvREFCNT_dec(choice_set);
	  *isv = &PL_sv_undef;
	}
      }
    }
    if (isv && *isv != &PL_sv_undef) {
      char id[8];
      STRLEN id_len = snprintf(id, sizeof(id), "%d", pkg->flag & FLAG_ID_MASK);
      SV **sense = hv_fetch((HV*)SvRV(*isv), id, id_len, 1);
      if (sense && use_sense) sv_setiv(*sense, use_sense);
    }
  }
}

static void
update_provides(const URPM__Package pkg, HV *provides) {
  if (pkg->h) {
    int len;
    struct rpmtd_s td, td_flags;
    unsigned int i;

    /* examine requires for files which need to be marked in provides */
    if (headerGet(pkg->h, RPMTAG_REQUIRENAME, &td, HEADERGET_DEFAULT)) {
      for (i = 0; i < rpmtdCount(&td); ++i) {
	const char *s = rpmtdNextString(&td);
	len = strlen(s);
	if (s[0] == '/') (void)hv_fetch(provides, s, len, 1);
      }
    }

    /* update all provides */
    if (headerGet(pkg->h, RPMTAG_PROVIDENAME, &td, HEADERGET_DEFAULT)) {
      char **list = td.data;
      rpmsenseFlags *flags = NULL;
      if (headerGet(pkg->h, RPMTAG_PROVIDEFLAGS, &td_flags, HEADERGET_DEFAULT))
	flags = td_flags.data;
      for (i = 0; i < rpmtdCount(&td); ++i) {
	len = strlen(list[i]);
	if (!strncmp(list[i], "rpmlib(", 7)) continue;
	update_hash_entry(provides, list[i], len, 1, flags && flags[i] & (RPMSENSE_PREREQ|RPMSENSE_SCRIPT_PREUN|RPMSENSE_SCRIPT_PRE|RPMSENSE_SCRIPT_POSTUN|RPMSENSE_SCRIPT_POST|RPMSENSE_LESS|RPMSENSE_EQUAL|RPMSENSE_GREATER),
			     pkg);
      }
    }
  } else {
    char *ps, *s, *es;

    if ((s = pkg->requires) != NULL && *s != 0) {
      ps = strchr(s, '@');
      /* examine requires for files which need to be marked in provides */
      while(ps != NULL) {
	if (s[0] == '/') {
	  *ps = 0; es = strchr(s, '['); if (!es) es = strchr(s, ' '); *ps = '@';
	  (void)hv_fetch(provides, s, es != NULL ? es-s : ps-s, 1);
	}
	s = ps + 1; ps = strchr(s, '@');
      }
      if (s[0] == '/') {
      es = strchr(s, '['); if (!es) es = strchr(s, ' ');
	(void)hv_fetch(provides, s, es != NULL ? (U32)(es-s) : strlen(s), 1);
      }
    }

    /* update all provides */
    if ((s = pkg->provides) != NULL && *s != 0) {
      ps = strchr(s, '@');
      while(ps != NULL) {
	*ps = 0; es = strchr(s, '['); if (!es) es = strchr(s, ' '); *ps = '@';
	update_hash_entry(provides, s, es != NULL ? es-s : ps-s, 1, es != NULL, pkg);
	s = ps + 1; ps = strchr(s, '@');
      }
      es = strchr(s, '['); if (!es) es = strchr(s, ' ');
      update_hash_entry(provides, s, es != NULL ? es-s : 0, 1, es != NULL, pkg);
    }
  }
}

static void
update_obsoletes(const URPM__Package pkg, HV *obsoletes) {
  if (pkg->h) {
    struct rpmtd_s td;

    /* update all provides */
    if (headerGet(pkg->h, RPMTAG_OBSOLETENAME, &td, HEADERGET_DEFAULT)) {
      unsigned int i;
      for (i = 0; i < rpmtdCount(&td); ++i)
	update_hash_entry(obsoletes, rpmtdNextString(&td), 0, 1, 0, pkg);
    }
  } else {
    char *ps, *s;

    if ((s = pkg->obsoletes) != NULL && *s != 0) {
      char *es;

      ps = strchr(s, '@');
      while(ps != NULL) {
	*ps = 0; es = strchr(s, '['); if (!es) es = strchr(s, ' '); *ps = '@';
	update_hash_entry(obsoletes, s, es != NULL ? es-s : ps-s, 1, 0, pkg);
	s = ps + 1; ps = strchr(s, '@');
      }
      es = strchr(s, '['); if (!es) es = strchr(s, ' ');
      update_hash_entry(obsoletes, s, es != NULL ? es-s : 0, 1, 0, pkg);
    }
  }
}

static void
update_provides_files(const URPM__Package pkg, HV *provides) {
  if (pkg->h) {
    STRLEN len;
    unsigned int i;

    struct rpmtd_s td_baseNames, td_dirIndexes, td_dirNames;
    if (headerGet(pkg->h, RPMTAG_BASENAMES, &td_baseNames, HEADERGET_DEFAULT) &&
	headerGet(pkg->h, RPMTAG_DIRINDEXES, &td_dirIndexes, HEADERGET_DEFAULT) &&
	headerGet(pkg->h, RPMTAG_DIRNAMES, &td_dirNames, HEADERGET_DEFAULT)) {

      char **baseNames = td_baseNames.data;
      char **dirNames = td_dirNames.data;
      int32_t *dirIndexes = td_dirIndexes.data;

      char buff[4096];
      char *p;

      for(i = 0; i < rpmtdCount(&td_baseNames); i++) {
	len = strlen(dirNames[dirIndexes[i]]);
	if (len >= sizeof(buff)) continue;
	memcpy(p = buff, dirNames[dirIndexes[i]], len + 1); p += len;
	len = strlen(baseNames[i]);
	if (p - buff + len >= sizeof(buff)) continue;
	memcpy(p, baseNames[i], len + 1); p += len;

	update_hash_entry(provides, buff, p-buff, 0, 0, pkg);
      }

      rpmtdFreeData(&td_baseNames);
      rpmtdFreeData(&td_dirNames);
    } else {
      struct rpmtd_s td;
      
      if (headerGet(pkg->h, RPMTAG_OLDFILENAMES, &td, HEADERGET_DEFAULT)) {
	for (i = 0; i < rpmtdCount(&td); i++)
	  update_hash_entry(provides, rpmtdNextString(&td), 0, 0, 0, pkg);

	rpmtdFreeData(&td);
      }
    }
  }
}

static FD_t
open_archive(char *filename, int *empty_archive) {
  int fd;
  FD_t rfd = NULL;
  struct {
    char header[4];
    char toc_d_count[4];
    char toc_l_count[4];
    char toc_f_count[4];
    char toc_str_size[4];
    char uncompress[40];
    char trailer[4];
  } buf;

  fd = open(filename, O_RDONLY);
  if (fd >= 0) {
    int pos = lseek(fd, -(int)sizeof(buf), SEEK_END);
    if (read(fd, &buf, sizeof(buf)) != sizeof(buf) || strncmp(buf.header, "cz[0", 4) || strncmp(buf.trailer, "0]cz", 4)) {
      /* this is not an archive, open it without magic, but first rewind at begin of file */
      lseek(fd, 0, SEEK_SET);
      rfd = fdDup(fd);
      close(fd);
      return rfd;
    } else if (pos == 0) {
      *empty_archive = 1;
    } else {
      /* this is an archive, prepare for reading with uncompress defined inside */
      rfd = Fopen(filename, "r.fdio");
      if (strcmp(buf.uncompress, "gzip"))
           rfd = Fdopen(rfd, "r.gzip");
      else if (strcmp(buf.uncompress, "bzip"))
           rfd = Fdopen(rfd, "r.bzip2");
      else if (strcmp(buf.uncompress, "xz") || strcmp(buf.uncompress, "lzma"))
           rfd = Fdopen(rfd, "r.xz");
      else {
           free(rfd);
           rfd = NULL;
      }
    }
  }
  close(fd); // we rely on EBADF in testsuite
  return rfd;
}

static int
call_package_callback(SV *urpm, SV *sv_pkg, SV *callback) {
  if (sv_pkg != NULL && callback != NULL) {
    int count;

    /* now, a callback will be called for sure */
    dSP;
    PUSHMARK(SP);
    EXTEND(SP, 2);
    PUSHs(urpm);
    PUSHs(sv_pkg);
    PUTBACK;
    count = call_sv(callback, G_SCALAR);
    SPAGAIN;
    if (count == 1 && !POPi) {
      /* package should not be added in depslist, so we free it */
      SvREFCNT_dec(sv_pkg);
      sv_pkg = NULL;
    }
    PUTBACK;
  }

  return sv_pkg != NULL;
}

static void
push_in_depslist(struct s_Package *_pkg, SV *urpm, AV *depslist, SV *callback, HV *provides, HV *obsoletes, int packing) {
    SV *sv_pkg = sv_setref_pv(newSVpvs(""), "URPM::Package", _pkg);
    if (call_package_callback(urpm, sv_pkg, callback)) {
      if (provides) {
	update_provides(_pkg, provides);
	update_provides_files(_pkg, provides);
      }
      if (obsoletes) update_obsoletes(_pkg, obsoletes);
      if (packing) pack_header(_pkg);
      av_push(depslist, sv_pkg);
    }
}

static int
parse_line(AV *depslist, HV *provides, HV *obsoletes, URPM__Package pkg, char *buff, SV *urpm, SV *callback) {
  char *tag, *data;

  if (buff[0] == 0)
    return 1;
  else if ((tag = buff)[0] == '@' && (data = strchr(tag+1, '@')) != NULL) {
    *tag++ = *data++ = 0;
    int data_len = 1+strlen(data);
    if (!strcmp(tag, "info")) {
      pkg->info = memcpy(malloc(data_len), data, data_len);
      pkg->flag &= ~FLAG_ID_MASK;
      pkg->flag |= 1 + av_len(depslist);
      URPM__Package _pkg = memcpy(malloc(sizeof(struct s_Package)), pkg, sizeof(struct s_Package));
      push_in_depslist(_pkg, urpm, depslist, callback, provides, obsoletes, 0);
      // reset package, next line will be for another one
      memset(pkg, 0, sizeof(struct s_Package));
    } else if (!strcmp(tag, "filesize"))
      pkg->filesize = atoll(data);
    else {
      char **ptr = NULL;
      if (!strcmp(tag, "requires"))
        ptr = &pkg->requires;
      else if (!strcmp(tag, "suggests") || !strcmp(tag, "recommends"))
        ptr = &pkg->recommends;
      else if (!strcmp(tag, "obsoletes"))
        ptr = &pkg->obsoletes;
      else if (!strcmp(tag, "conflicts"))
        ptr = &pkg->conflicts;
      else if (!strcmp(tag, "provides"))
        ptr = &pkg->provides;
      else if (!strcmp(tag, "summary"))
        ptr = &pkg->summary;

      if (ptr)
        free(*ptr), *ptr = memcpy(malloc(data_len), data, data_len);
    }
    return 1;
  } else {
    fprintf(stderr, "bad line <%s>\n", buff);
    return 0;
  }
}

#if 0
/*
 * this code is unused since August 2007 and hasn't work since MDK8.1 and rpm 4 (2001!!!).
 */
static void pack_rpm_header(Header *h) {
  Header packed = headerNew();

  HeaderIterator hi = headerInitIterator(*h);
  struct rpmtd_s td;
  while (headerNext(hi, &td)) {
      // fprintf(stderr, "adding %s %d\n", tagname(tag), c);
      headerPut(packed, &td, HEADERPUT_DEFAULT);
      rpmtdFreeData(&td);
  }

  headerFreeIterator(hi);
  *h = headerFree(*h);

  *h = packed;
}

static void drop_tags(Header *h) {
  headerDel(*h, RPMTAG_FILEUSERNAME); /* user ownership is correct */
  headerDel(*h, RPMTAG_FILEGROUPNAME); /* group ownership is correct */
  headerDel(*h, RPMTAG_FILEMTIMES); /* correct time without it */
  headerDel(*h, RPMTAG_FILEINODES); /* hardlinks work without it */
  headerDel(*h, RPMTAG_FILEDEVICES); /* it is the same number for every file */
  headerDel(*h, RPMTAG_FILESIZES); /* ? */
  headerDel(*h, RPMTAG_FILERDEVS); /* it seems unused. always empty */
  headerDel(*h, RPMTAG_FILEVERIFYFLAGS); /* only used for -V */
  headerDel(*h, RPMTAG_FILEDIGESTALGOS); /* only used for -V */
  headerDel(*h, RPMTAG_FILEDIGESTS); /* only used for -V */ /* alias: RPMTAG_FILEMD5S */ 
  /* keep RPMTAG_FILEFLAGS for %config (rpmnew) to work */
  /* keep RPMTAG_FILELANGS for %lang (_install_langs) to work */
  /* keep RPMTAG_FILELINKTOS for checking conflicts between symlinks */
  /* keep RPMTAG_FILEMODES otherwise it segfaults with excludepath */

  /* keep RPMTAG_POSTIN RPMTAG_POSTUN RPMTAG_PREIN RPMTAG_PREUN */
  /* keep RPMTAG_TRIGGERSCRIPTS RPMTAG_TRIGGERVERSION RPMTAG_TRIGGERFLAGS RPMTAG_TRIGGERNAME */
  /* small enough, and only in some packages. not needed per se */

  headerDel(*h, RPMTAG_ICON);
  headerDel(*h, RPMTAG_GIF);
  headerDel(*h, RPMTAG_EXCLUSIVE);
  headerDel(*h, RPMTAG_COOKIE);
  headerDel(*h, RPMTAG_VERIFYSCRIPT);

  /* always the same for our packages */
  headerDel(*h, RPMTAG_VENDOR);
  headerDel(*h, RPMTAG_DISTRIBUTION);

  /* keep RPMTAG_SIGSIZE, useful to tell the size of the rpm file (+440) */

  headerDel(*h, RPMTAG_DSAHEADER);
  headerDel(*h, RPMTAG_SHA1HEADER);
  headerDel(*h, RPMTAG_SIGMD5);
  headerDel(*h, RPMTAG_SIGGPG);

  pack_rpm_header(h);
}
#endif

static int
update_header(char *filename, URPM__Package pkg, __attribute__((unused)) int keep_all_tags, int vsflags) {
  int d = open(filename, O_RDONLY);

  if (d >= 0) {
    unsigned char sig[4];

    if (read(d, &sig, sizeof(sig)) == sizeof(sig)) {
      lseek(d, 0, SEEK_SET);
      // Is it RPM lead?
      if (sig[0] == 0xed && sig[1] == 0xab && sig[2] == 0xee && sig[3] == 0xdb) {
	FD_t fd = fdDup(d);
	Header header;
	rpmts ts;
	pkg->filesize = fdSize(fd);

	close(d);
	ts = rpmtsCreate();
	rpmtsSetVSFlags(ts, _RPMVSF_NOSIGNATURES | vsflags);
	if (fd != NULL && rpmReadPackageFile(ts, fd, filename, &header) == 0 && header) {
	  Fclose(fd);

	  _header_free(pkg);
	  pkg->h = header;
	  pkg->flag &= ~FLAG_NO_HEADER_FREE;

	  /*if (!keep_all_tags) drop_tags(&pkg->h);*/
	  (void)rpmtsFree(ts);
	  return 1;
	}
	(void)rpmtsFree(ts);
      } else if (sig[0] == 0x8e && sig[1] == 0xad && sig[2] == 0xe8 && sig[3] == 0x01) {
	// or is it RPM header magic?
	FD_t fd = fdDup(d);

	close(d);
	if (fd != NULL) {
	  _header_free(pkg);
	  pkg->h = headerRead(fd, HEADER_MAGIC_YES);
	  pkg->flag &= ~FLAG_NO_HEADER_FREE;
	  Fclose(fd);
	  return 1;
	}
      } else close(d);
    } else close(d);
  }
  return 0;
}

static int
read_config_files(int force) {
  static int already = 0;
  int rc = 0;

  if (!already || force) {
    rc = rpmReadConfigFiles(NULL, NULL);
    already = (rc == 0); /* set config as load only if it succeed */
  }
  return rc;
}

static rpmVSFlags
ts_nosignature(rpmts ts) {
  return rpmtsSetVSFlags(ts, _RPMVSF_NODIGESTS | _RPMVSF_NOSIGNATURES);
}

/* we don't use the header arg, but we do use $urpm passed in data by Trans_run() -> rpmtsSetNotifyCallback() */
static void *rpmRunTransactions_callback(__attribute__((unused)) const void *h,
					 const rpmCallbackType what, 
					 const rpm_loff_t amount, 
					 const rpm_loff_t total,
					 fnpyKey pkgKey,
					 rpmCallbackData data) {
  static struct timeval tprev;
  static struct timeval tcurr;
  static FD_t fd = NULL;
  long delta;
  int i;
  struct s_TransactionData *td = data;
  SV *callback = NULL;
  char *callback_type = NULL;
  char *callback_subtype = NULL;

  if (!td)
    return NULL;

  switch (what) {
    case RPMCALLBACK_INST_OPEN_FILE:
      callback = td->callback_open;
      callback_type = "open";
      break;
    case RPMCALLBACK_INST_CLOSE_FILE:
      callback = td->callback_close;
      callback_type = "close";
      break;
    case RPMCALLBACK_TRANS_START:
    case RPMCALLBACK_TRANS_PROGRESS:
    case RPMCALLBACK_TRANS_STOP:
      callback = td->callback_trans;
      callback_type = "trans";
      break;
    case RPMCALLBACK_UNINST_START:
    case RPMCALLBACK_UNINST_PROGRESS:
    case RPMCALLBACK_UNINST_STOP:
      callback = td->callback_uninst;
      callback_type = "uninst";
      break;
#ifdef RPM4_14_2
    case RPMCALLBACK_VERIFY_START:
    case RPMCALLBACK_VERIFY_PROGRESS:
    case RPMCALLBACK_VERIFY_STOP:
      callback = td->callback_verify;
      callback_type = "verify";
      break;
#endif
    case RPMCALLBACK_INST_START:
    case RPMCALLBACK_INST_PROGRESS:
    case RPMCALLBACK_INST_STOP:
      callback = td->callback_inst;
      callback_type = "inst";
      break;
    case RPMCALLBACK_SCRIPT_START:
    case RPMCALLBACK_SCRIPT_STOP:
      callback = td->callback_inst;
      callback_type = "script";
      break;
    case RPMCALLBACK_CPIO_ERROR:
    case RPMCALLBACK_SCRIPT_ERROR:
    case RPMCALLBACK_UNPACK_ERROR:
      callback = td->callback_error;
      callback_type = "error";
      break;
#ifdef RPM4_13_0
    case RPMCALLBACK_ELEM_PROGRESS:
      callback = td->callback_elem;
      callback_type = "elem";
      break;
#endif
    default:
      break;
  }

  if (callback != NULL) {
    switch (what) {
      case RPMCALLBACK_INST_START:
      case RPMCALLBACK_TRANS_START:
      case RPMCALLBACK_UNINST_START:
#ifdef RPM4_14_2
      case RPMCALLBACK_VERIFY_START:
#endif
	callback_subtype = "start";
	gettimeofday(&tprev, NULL);
	break;
      case RPMCALLBACK_INST_PROGRESS:
      case RPMCALLBACK_TRANS_PROGRESS:
      case RPMCALLBACK_UNINST_PROGRESS:
#ifdef RPM4_14_2
      case RPMCALLBACK_VERIFY_PROGRESS:
#endif
	callback_subtype = "progress";
	gettimeofday(&tcurr, NULL);
	delta = 1000000 * (tcurr.tv_sec - tprev.tv_sec) + (tcurr.tv_usec - tprev.tv_usec);
	if (delta < td->min_delta && amount < total - 1)
	  callback = NULL; /* avoid calling too often a given callback */
	else
	  tprev = tcurr;
	break;
      case RPMCALLBACK_INST_STOP:
      case RPMCALLBACK_TRANS_STOP:
      case RPMCALLBACK_UNINST_STOP:
#ifdef RPM4_14_2
      case RPMCALLBACK_VERIFY_STOP:
#endif
	callback_subtype = "stop";
	break;
      case RPMCALLBACK_CPIO_ERROR:
	callback_subtype = "cpio";
	break;
#ifdef RPM4_13_0
      case RPMCALLBACK_ELEM_PROGRESS:
	callback_subtype = "progress";
	break;
#endif
      case RPMCALLBACK_SCRIPT_ERROR:
	callback_subtype = "script";
	break;
      case RPMCALLBACK_UNPACK_ERROR:
	callback_subtype = "unpack";
	break;
      default:
	break;
    }

    if (callback != NULL) {
      /* now, a callback will be called for sure */
      dSP;
      ENTER;
      SAVETMPS;
      PUSHMARK(SP);
      EXTEND(SP, callback_subtype == NULL ? 3 : 6);
      PUSHs(td->data);
      mPUSHs(newSVpv(callback_type, 0));
      PUSHs(pkgKey != NULL ? sv_2mortal(newSViv((long)pkgKey - 1)) : &PL_sv_undef);
      if (callback_subtype != NULL) {
	mPUSHs(newSVpv(callback_subtype, 0));
	mPUSHs(newSViv(amount));
	mPUSHs(newSViv(total));
      }
      PUTBACK;
      i = call_sv(callback, callback == td->callback_open ? G_SCALAR : G_DISCARD);
      SPAGAIN;
      if (callback == td->callback_open) {
	if (i != 1) croak("callback_open should return a file handle");
	i = POPi;
	fd = fdDup(i);
	if (fd) {
	  fd = fdLink(fd);
	  Fcntl(fd, F_SETFD, (void *)1); /* necessary to avoid forked/execed process to lock removable media */
	}
	PUTBACK;
      } else if (callback == td->callback_close) {
	if (fd) {
	  Fclose(fd);
	  fd = NULL;
	}
      }
      FREETMPS;
      LEAVE;
    }
  }
  return callback == td->callback_open ? fd : NULL;
}

static rpmDbiTag
rpmtag_from_string(char *tag)
{
    if (!strcmp(tag, "name"))
      return RPMDBI_NAME;
    else if (!strcmp(tag, "whatprovides"))
      return RPMDBI_PROVIDENAME;
    else if (!strcmp(tag, "whatrequires"))
      return RPMDBI_REQUIRENAME;
    else if (!strcmp(tag, "whatconflicts"))
      return RPMDBI_CONFLICTNAME;
    else if (!strcmp(tag, "group"))
      return RPMDBI_GROUP;
    else if (!strcmp(tag, "triggeredby"))
      return RPMDBI_TRIGGERNAME;
    else if (!strcmp(tag, "path"))
      return RPMDBI_BASENAMES;
    else if (!strcmp(tag, "nvra"))
      return RPMDBI_LABEL;
    else croak("unknown tag [%s]", tag);
}

static unsigned mask_from_string(char *name) {
  unsigned mask;
  if (!strcmp(name, "skip")) mask = FLAG_SKIP;
  else if (!strcmp(name, "disable_obsolete")) mask = FLAG_DISABLE_OBSOLETE;
  else if (!strcmp(name, "installed")) mask = FLAG_INSTALLED;
  else if (!strcmp(name, "requested")) mask = FLAG_REQUESTED;
  else if (!strcmp(name, "required")) mask = FLAG_REQUIRED;
  else if (!strcmp(name, "upgrade")) mask = FLAG_UPGRADE;
  else croak("unknown flag: %s", name);
  return mask;
}

static int compare_evrs(int lepoch, char*lversion, char*lrelease, int repoch, char*rversion, char*rrelease) {
    int compare;
    compare = lepoch - repoch;
    if (!compare) {
      compare = rpmvercmp(lversion, rversion);
      if (!compare && rrelease)
	compare = rpmvercmp(lrelease, rrelease);
    }
    return compare;
}

static int get_e_v_r(URPM__Package pkg, int *epoch, char **version, char **release, char **arch) {
    if (pkg->info) {
      char *s, *eos;

      if ((s = strchr(pkg->info, '@')) != NULL) {
	if ((eos = strchr(s+1, '@')) != NULL)
          *eos = 0; /* mark end of string to enable searching backwards */
	*epoch = atoi(s+1);
	if (eos != NULL) *eos = '@';
      } else
	*epoch = 0;
      get_fullname_parts(pkg, NULL, version, release, arch, &eos);
      /* temporarily mark end of each substring */
      (*release)[-1] = 0;
      (*arch)[-1] = 0;
      return 1;
    } else if (pkg->h) {
      *epoch = get_int(pkg->h, RPMTAG_EPOCH);
      *version = get_name(pkg->h, RPMTAG_VERSION);
      *release = get_name(pkg->h, RPMTAG_RELEASE);
      *arch = get_arch(pkg->h);
      return 1;
    }
    return 0;
}


MODULE = URPM            PACKAGE = URPM::Package       PREFIX = Pkg_

void
Pkg_DESTROY(pkg)
  URPM::Package pkg
  CODE:
  free(pkg->info);
  free(pkg->requires);
  free(pkg->recommends);
  free(pkg->obsoletes);
  free(pkg->conflicts);
  free(pkg->provides);
  free(pkg->rflags);
  free(pkg->summary);
  _header_free(pkg);
  free(pkg);

void
Pkg_name(pkg)
  URPM::Package pkg
    ALIAS:
     version  = 1
     release  = 2
     arch     = 3
  PPCODE:
  if (pkg->info) {
    char *name, *version, *release, *arch, *eos;
    char *res;
    STRLEN end;

    get_fullname_parts(pkg, &name, &version, &release, &arch, &eos);
    switch (ix) {
    case 1:  res = version; end = release - version; break;
    case 2:  res = release; end = arch-release;      break;
    case 3:  res = arch;    end = eos-arch+1;        break;
    default: res = name;    end = version - name;
    }
    if (end < 1) croak("invalid fullname");
    mXPUSHs(newSVpv(res, end-1));
  } else if (pkg->h) {
    char *str;
    switch (ix) {
    case 1:  str = get_name(pkg->h, RPMTAG_VERSION); break;
    case 2:  str = get_name(pkg->h, RPMTAG_RELEASE); break;
    case 3:  str = get_arch(pkg->h); break;
    default: str = get_name(pkg->h, RPMTAG_NAME);
    }
    mXPUSHs(newSVpv(str, 0));
  }

void
Pkg_EVR(pkg)
  URPM::Package pkg
  PPCODE:
    if (pkg->info) {
      char *s, *eos;
      char *version, *arch;
      int epoch;

      if ((s = strchr(pkg->info, '@')) != NULL) {
	if ((eos = strchr(s+1, '@')) != NULL)
          *eos = 0; /* mark end of string to enable searching backwards */
	epoch = atoi(s+1);
	if (eos != NULL) *eos = '@';
      } else
	epoch = 0;
      get_fullname_parts(pkg, NULL, &version, NULL, &arch, &eos);
      if (epoch == 0)
         mXPUSHs(newSVpv(version, arch-version-1));
      else {
         char *res;
         arch--;
         *arch = '\0';
         asprintf(&res, "%d:%s", epoch, version);
         mXPUSHs(newSVpv(res, 0));
         *arch = '.'; /* restore info string modified */
      }
    } else if (pkg->h) {
         char *s = headerGetAsString(pkg->h, RPMTAG_EVR);
         mXPUSHs(newSVpv(s, 0));
         free(s);
    }

int
Pkg_is_arch_compat__XS(pkg)
  URPM::Package pkg
  INIT:
  CODE:
  read_config_files(0);
  if (pkg->info) {
    char *arch;
    char *eos;

    get_fullname_parts(pkg, NULL, NULL, NULL, &arch, &eos);
    *eos = 0;
    RETVAL = rpmMachineScore(RPM_MACHTABLE_INSTARCH, arch);
    *eos = '@';
  } else if (pkg->h && headerIsEntry(pkg->h, RPMTAG_SOURCERPM)) {
    char *arch = get_name(pkg->h, RPMTAG_ARCH);
    RETVAL = rpmMachineScore(RPM_MACHTABLE_INSTARCH, arch);
  } else {
    RETVAL = 0;
  }
  OUTPUT:
  RETVAL

void
Pkg_summary(pkg)
  URPM::Package pkg
  PPCODE:
  if (pkg->summary) {
    mXPUSHs(newSVpv_utf8(pkg->summary, 0));
  } else if (pkg->h) {
    mXPUSHs(newSVpv_utf8(get_name(pkg->h, RPMTAG_SUMMARY), 0));
  }

void
Pkg_description(pkg)
  URPM::Package pkg
    ALIAS:
     packager  = 1
  PPCODE:
  if (pkg->h) {
       rpmTag tag = ix == 0 ? RPMTAG_DESCRIPTION : RPMTAG_PACKAGER;
       mXPUSHs(newSVpv_utf8(get_name(pkg->h, tag), 0));
  }

void
Pkg_sourcerpm(pkg)
  URPM::Package pkg
    ALIAS:
     buildhost = 1
     url       = 2
     license   = 3
     distribution = 4
     vendor    = 5
     os        = 6
     payload_format = 7
  PPCODE:
  if (pkg->h) {
       rpmTag tag;
       switch (ix) {
       case 1:  tag = RPMTAG_BUILDHOST;     break;
       case 2:  tag = RPMTAG_URL;           break;
       case 3:  tag = RPMTAG_LICENSE;       break;
       case 4:  tag = RPMTAG_DISTRIBUTION;  break;
       case 5:  tag = RPMTAG_VENDOR;        break;
       case 6:  tag = RPMTAG_OS;            break;
       case 7:  tag = RPMTAG_PAYLOADFORMAT; break;
       default: tag = RPMTAG_SOURCERPM;     break;
       }
       mXPUSHs(newSVpv(get_name(pkg->h, tag), 0));
  }

int
Pkg_buildtime(pkg)
  URPM::Package pkg
  ALIAS:
       installtid = 1
  CODE:
  if (pkg->h)
    RETVAL = get_int(pkg->h, ix == 1 ? RPMTAG_INSTALLTID : RPMTAG_BUILDTIME);
  else
    RETVAL = 0;
  OUTPUT:
  RETVAL


void
Pkg_fullname(pkg)
  URPM::Package pkg
  PREINIT:
  I32 gimme = GIMME_V;
  PPCODE:
  if (pkg->info) {
    if (gimme == G_SCALAR) {
      char *eos;
      if ((eos = strchr(pkg->info, '@')) != NULL) {
	mXPUSHs(newSVpv(pkg->info, eos-pkg->info));
      }
    } else if (gimme == G_ARRAY) {
      char *name, *version, *release, *arch, *eos;
      get_fullname_parts(pkg, &name, &version, &release, &arch, &eos);
      if (version - name < 1 || release - version < 1 || arch - release < 1)
	  croak("invalid fullname");
      EXTEND(SP, 4);
      mPUSHs(newSVpv(name, version-name-1));
      mPUSHs(newSVpv(version, release-version-1));
      mPUSHs(newSVpv(release, arch-release-1));
      mPUSHs(newSVpv(arch, eos-arch));
    }
  } else if (pkg->h) {
    char *arch = get_arch(pkg->h);

    if (gimme == G_SCALAR) {
      char *s = headerGetAsString(pkg->h, RPMTAG_NVR);
      mXPUSHs(newSVpvf("%s.%s", s, arch));
      free(s);
    } else if (gimme == G_ARRAY) {
      EXTEND(SP, 4);
      mPUSHs(newSVpv(get_name(pkg->h, RPMTAG_NAME), 0));
      mPUSHs(newSVpv(get_name(pkg->h, RPMTAG_VERSION), 0));
      mPUSHs(newSVpv(get_name(pkg->h, RPMTAG_RELEASE), 0));
      mPUSHs(newSVpv(arch, 0));
    }
  }

int
Pkg_epoch(pkg)
  URPM::Package pkg
  CODE:
  if (pkg->info) {
    char *s, *eos;

    if ((s = strchr(pkg->info, '@')) != NULL) {
      if ((eos = strchr(s+1, '@')) != NULL)
         *eos = 0; /* mark end of string to enable searching backwards */
      RETVAL = atoi(s+1);
      if (eos != NULL) *eos = '@';
    } else
      RETVAL = 0;
  } else if (pkg->h) {
    RETVAL = get_int(pkg->h, RPMTAG_EPOCH);
  } else RETVAL = 0;
  OUTPUT:
  RETVAL

int
Pkg_compare_pkg(lpkg, rpkg)
  URPM::Package lpkg
  URPM::Package rpkg
  PREINIT:
  int compare = 0;
  int lepoch, repoch;
  char *lversion, *lrelease, *larch;
  char *rversion, *rrelease, *rarch;
  CODE:
  if (lpkg == rpkg) RETVAL = 0;
  else {
    if (!get_e_v_r(lpkg, &lepoch, &lversion, &lrelease, &larch))
      croak("undefined package");

    if (!get_e_v_r(rpkg, &repoch, &rversion, &rrelease, &rarch)) {
      /* restore info string modified */
      if (lpkg->info) {
	lrelease[-1] = '-';
	larch[-1] = '.';
      }
      croak("undefined package");
    }
    compare = compare_evrs(lepoch, lversion, lrelease, repoch, rversion, rrelease);
    // equal? compare arches too
    if (!compare) {
	  int lscore, rscore;
	  char *eolarch = strchr(larch, '@');
	  char *eorarch = strchr(rarch, '@');

	  read_config_files(0);
	  if (eolarch) *eolarch = 0; lscore = rpmMachineScore(RPM_MACHTABLE_INSTARCH, larch);
	  if (eorarch) *eorarch = 0; rscore = rpmMachineScore(RPM_MACHTABLE_INSTARCH, rarch);
	  if (lscore == 0) {
	    if (rscore == 0)
              /* Nanar: TODO check this 
               * hu ?? what is the goal of strcmp, some of arch are equivalent */
	      compare = strcmp(larch, rarch);
	    else
	      compare = -1;
	  } else {
	    if (rscore == 0)
	      compare = 1;
	    else
	      compare = rscore - lscore; /* score are lower for better */
	  }
	  if (eolarch) *eolarch = '@';
	  if (eorarch) *eorarch = '@';
    }
    /* restore info string modified */
    if (lpkg->info) {
      lrelease[-1] = '-';
      larch[-1] = '.';
    }
    if (rpkg->info) {
      rrelease[-1] = '-';
      rarch[-1] = '.';
    }
    RETVAL = compare;
  }
  OUTPUT:
  RETVAL

int
Pkg_compare(pkg, evr)
  URPM::Package pkg
  char *evr
  PREINIT:
  int _epoch, repoch = 0;
  char *_version, *_release, *_eos;
  CODE:
  if (!get_e_v_r(pkg, &_epoch, &_version, &_release, &_eos))
      croak("undefined package");

  char *epoch = NULL, *version, *release;
  if (!strncmp(evr, "URPM::Package=", 14))
      croak("compare() must not be called with a package reference as argument; use compare_pkg() instead");

  /* extract epoch and version from evr */
  version = evr;
  while (*version && isdigit(*version)) version++;
  if (*version == ':') {
    epoch = evr;
    *version++ = 0;
    if (!*epoch) epoch = "0";
    version[-1] = ':'; /* restore in memory modification */
  } else {
    /* there is no epoch defined, so assume epoch = 0 */
    version = evr;
  }
  if ((release = strrchr(version, '-')) != NULL)
     *release++ = 0;
  repoch = epoch && *epoch ? atoi(epoch) : 0;

  RETVAL = compare_evrs(_epoch, _version, _release, repoch, version, release);
  /* restore info string modified */
  if (pkg->info) {
    _release[-1] = '-';
    _eos[-1] = '.';
  }
  if (release)
    release[-1] = '-'; /* restore in memory modification */
  OUTPUT:
  RETVAL

UV
Pkg_size(pkg)
  URPM::Package pkg
  CODE:
  if (pkg->info) {
    char *s, *eos;

    if ((s = strchr(pkg->info, '@')) != NULL && (s = strchr(s+1, '@')) != NULL) {
      if ((eos = strchr(s+1, '@')) != NULL)
        *eos = 0; /* mark end of string to enable searching backwards */
      RETVAL = atoll(s+1);
      if (eos != NULL) *eos = '@';
    } else
      RETVAL = 0;
  } else if (pkg->h)
    RETVAL = get_int2(pkg->h, RPMTAG_LONGSIZE, RPMTAG_SIZE);
  else
    RETVAL = 0;
  OUTPUT:
  RETVAL

void
Pkg_set_filesize(pkg, filesize)
  URPM::Package pkg
  UV filesize;
  PPCODE:
  pkg->filesize = filesize;

UV
Pkg_filesize(pkg)
  URPM::Package pkg
  CODE:
  if (pkg->filesize)
    RETVAL = pkg->filesize;
  else if (pkg->h)
    RETVAL = get_filesize(pkg->h);
  else RETVAL = 0;
  OUTPUT:
  RETVAL

void
Pkg_group(pkg)
  URPM::Package pkg
  PPCODE:
  if (pkg->info) {
    char *s;

    if ((s = strchr(pkg->info, '@')) != NULL && (s = strchr(s+1, '@')) != NULL && (s = strchr(s+1, '@')) != NULL) {
      char *eos = strchr(s+1, '@');
      mXPUSHs(newSVpv_utf8(s+1, eos != NULL ? eos-s-1 : 0));
    }
  } else if (pkg->h)
    mXPUSHs(newSVpv_utf8(get_name(pkg->h, RPMTAG_GROUP), 0));

void
Pkg_filename(pkg)
  URPM::Package pkg
  PPCODE:
  if (pkg->info) {
    char *eon;

    if ((eon = strchr(pkg->info, '@')) != NULL && strlen(eon) >= 3) {
	char savbuf[4];
	memcpy(savbuf, eon, 4); /* there should be at least epoch and size described so (@0@0 minimum) */
	memcpy(eon, ".rpm", 4);
	mXPUSHs(newSVpv(pkg->info, eon-pkg->info+4));
	memcpy(eon, savbuf, 4);
    }
  } else if (pkg->h) {
    char *nvr = headerGetAsString(pkg->h, RPMTAG_NVR);
    char *arch = get_arch(pkg->h);

    mXPUSHs(newSVpvf("%s.%s.rpm", nvr, arch));
  }

void
Pkg_id(pkg)
  URPM::Package pkg
  PPCODE:
  int id = pkg->flag & FLAG_ID_MASK;
  if (id <= FLAG_ID_MAX)
    mXPUSHs(newSViv(id));

void
Pkg_set_id(pkg, id=-1)
  URPM::Package pkg
  int id
  PPCODE:
  int old_id = pkg->flag & FLAG_ID_MASK;
  if (old_id <= FLAG_ID_MAX)
    mXPUSHs(newSViv(old_id));
  pkg->flag &= ~FLAG_ID_MASK;
  pkg->flag |= id >= 0 && id <= FLAG_ID_MAX ? id : FLAG_ID_INVALID;

void
Pkg_obsoletes(pkg)
  URPM::Package pkg
  ALIAS:
      conflicts = 1
      provides  = 2
      requires  = 3
      recommends= 4
  PPCODE:
  PUTBACK;
  rpmTag tag, flags, tag_version;
  char *s;
  switch (ix) {
  case 1:  tag = RPMTAG_CONFLICTNAME; s = pkg->conflicts; flags = RPMTAG_CONFLICTFLAGS; tag_version = RPMTAG_CONFLICTVERSION; break;
  case 2:  tag = RPMTAG_PROVIDENAME;  s = pkg->provides;  flags = RPMTAG_PROVIDEFLAGS;  tag_version = RPMTAG_PROVIDEVERSION;  break;
  case 3:  tag = RPMTAG_REQUIRENAME;  s = pkg->requires;  flags = RPMTAG_REQUIREFLAGS;  tag_version = RPMTAG_REQUIREVERSION;  break;
  case 4:  tag = RPMTAG_RECOMMENDNAME;s = pkg->recommends;flags = RPMTAG_RECOMMENDFLAGS;tag_version = RPMTAG_RECOMMENDVERSION;break;
  default: tag = RPMTAG_OBSOLETENAME; s = pkg->obsoletes; flags = RPMTAG_OBSOLETEFLAGS; tag_version = RPMTAG_OBSOLETEVERSION; break;
  }
  return_list_str(s, pkg->h, tag, flags, tag_version, callback_list_str_xpush, NULL);
  SPAGAIN;

void
Pkg_obsoletes_nosense(pkg)
  URPM::Package pkg
  ALIAS:
      conflicts_nosense = 1
      provides_nosense  = 2
      requires_nosense  = 3
      recommends_nosense= 4
      suggests          = 4
  PPCODE:
  PUTBACK;
  rpmTag tag;
  char *s;
  switch (ix) {
  case 1:  tag = RPMTAG_CONFLICTNAME; s = pkg->conflicts; break;
  case 2:  tag = RPMTAG_PROVIDENAME;  s = pkg->provides;  break;
  case 3:  tag = RPMTAG_REQUIRENAME;  s = pkg->requires;  break;
  case 4:  tag = RPMTAG_RECOMMENDNAME;s = pkg->recommends; break;
  default: tag = RPMTAG_OBSOLETENAME; s = pkg->obsoletes; break;
  }
  return_list_str(s, pkg->h, tag, 0, 0, callback_list_str_xpush, NULL);
  SPAGAIN;

int
Pkg_obsoletes_overlap(pkg, s)
  URPM::Package pkg
  char *s
  ALIAS:
     provides_overlap = 1
  PREINIT:
  struct cb_overlap_s os;
  char *eon = NULL;
  char eonc = '\0';
  rpmTag tag_name;
  rpmTag tag_flags, tag_version;
  CODE:
  switch (ix) {
  case 1:
       tag_name = RPMTAG_PROVIDENAME;
       tag_flags = RPMTAG_PROVIDEFLAGS;
       tag_version = RPMTAG_PROVIDEVERSION;
       break;
  default:
       tag_name = RPMTAG_OBSOLETENAME;
       tag_flags = RPMTAG_OBSOLETEFLAGS;
       tag_version = RPMTAG_OBSOLETEVERSION;
       break;
  }
  os.name = s;
  os.flags = 0;
  while (*s && *s != ' ' && *s != '[' && *s != '<' && *s != '>' && *s != '=') ++s;
  if (*s) {
    eon = s;
    while (*s) {
      if (*s == ' ' || *s == '[' || *s == '*' || *s == ']');
      else if (*s == '<') os.flags |= RPMSENSE_LESS;
      else if (*s == '>') os.flags |= RPMSENSE_GREATER;
      else if (*s == '=') os.flags |= RPMSENSE_EQUAL;
      else break;
      ++s;
    }
    os.evr = s;
  } else
    os.evr = "";
  os.direction = ix == 0 ? -1 : 1;
  /* mark end of name */
  if (eon) {
    eonc = *eon;
    *eon = 0;
  }
  /* return_list_str returns a negative value is the callback has returned non-zero */
  RETVAL = return_list_str(ix == 0 ? pkg->obsoletes : pkg->provides, pkg->h, tag_name, tag_flags, tag_version,
			   callback_list_str_overlap, &os) < 0;
  /* restore end of name */
  if (eon) *eon = eonc;
  OUTPUT:
  RETVAL

void
Pkg_buildarchs(pkg)
  URPM::Package pkg
  ALIAS:
    excludearchs   = 1
    exclusivearchs = 2
    dirnames       = 3
    filelinktos    = 4
    files_md5sum   = 5
    files_owner    = 6
    files_group    = 7
    changelog_name = 8
    changelog_text = 9
  PPCODE:
  PUTBACK;
       rpmTag tag;
       switch (ix) {
       case 1: tag = RPMTAG_EXCLUDEARCH; break;
       case 2: tag = RPMTAG_EXCLUSIVEARCH; break;
       case 3: tag = RPMTAG_DIRNAMES; break;
       case 4: tag = RPMTAG_FILELINKTOS; break;
       case 5: tag = RPMTAG_FILEMD5S; break;
       case 6: tag = RPMTAG_FILEUSERNAME; break;
       case 7: tag = RPMTAG_FILEGROUPNAME; break;
       case 8: tag = RPMTAG_CHANGELOGNAME; break;
       case 9: tag = RPMTAG_CHANGELOGTEXT; break;
       default: tag = RPMTAG_BUILDARCHS; break;
       }
       xpush_simple_list_str(pkg->h, tag);
  SPAGAIN;

void
Pkg_files(pkg)
  URPM::Package pkg
  ALIAS:
    conf_files     = FILTER_MODE_CONF_FILES
    doc_files      = FILTER_MODE_DOC_FILES
  PPCODE:
  PUTBACK;
  return_files(pkg->h, ix);
  SPAGAIN;

void
Pkg_files_mtime(pkg)
  URPM::Package pkg
  ALIAS:
    files_size     = 1
    files_uid      = 2
    files_gid      = 3
    files_mode     = 4
    files_flags    = 5
    changelog_time = 6
  PPCODE:
  PUTBACK;
       rpmTag tag;
       switch (ix) {
       case 1: tag = RPMTAG_FILESIZES; break;
       case 2: tag = RPMTAG_FILEUIDS; break;
       case 3: tag = RPMTAG_FILEGIDS; break;
       case 4: tag = RPMTAG_FILEMODES; break;
       case 5: tag = RPMTAG_FILEFLAGS; break;
       case 6: tag = RPMTAG_CHANGELOGTIME; break;
       default: tag = RPMTAG_FILEMTIMES; break;
       }
       return_list_number(pkg->h, tag);
  SPAGAIN;

void
Pkg_queryformat(pkg, fmt)
  URPM::Package pkg
  char *fmt
  PREINIT:
  char *s;
  PPCODE:
  if (pkg->h) {
    s = headerFormat(pkg->h, fmt, NULL);
      if (s)
        mXPUSHs(newSVpv_utf8(s, 0));
  }
  
void
Pkg_get_tag(pkg, tagname)
  URPM::Package pkg
  int tagname;
  ALIAS:
    get_tag_modifiers = 1
  PPCODE:
  PUTBACK;
  if (ix == 0)
    return_list_tag(pkg, tagname);
  else
    return_list_tag_modifier(pkg->h, tagname);
  SPAGAIN;

  
void
Pkg_pack_header(pkg)
  URPM::Package pkg
  CODE:
  pack_header(pkg);

int
Pkg_update_header(pkg, filename, ...)
  URPM::Package pkg
  char *filename
  PREINIT:
  int packing = 0;
  int keep_all_tags = 0;
  CODE:
  if (items > 3) {
    int i;
    for (i = 2; i < items-1; i+=2) {
      STRLEN len;
      char *s = SvPV(ST(i), len);

      if (len == 7 && !memcmp(s, "packing", 7))
	packing = SvTRUE(ST(i + 1));
      else if (len == 13 && !memcmp(s, "keep_all_tags", 13))
	keep_all_tags = SvTRUE(ST(i+1));
    }
  }
  RETVAL = update_header(filename, pkg, !packing && keep_all_tags, RPMVSF_DEFAULT);
  if (RETVAL && packing) pack_header(pkg);
  OUTPUT:
  RETVAL

void
Pkg_free_header(pkg)
  URPM::Package pkg
  CODE:
  _header_free(pkg);
  pkg->h = NULL;

void
Pkg_build_info(pkg, fileno, provides_files=NULL, recommends=0)
  URPM::Package pkg
  int fileno
  char *provides_files
  int recommends
  CODE:
  if (pkg->info) {
    char buff[65536*2];
    UV size;

    /* info line should be the last to be written */
    if (pkg->provides && *pkg->provides) {
      size = snprintf(buff, sizeof(buff), "@provides@%s\n", pkg->provides);
      if (size < sizeof(buff)) {
	if (provides_files && *provides_files) {
	  --size;
	  size += snprintf(buff+size, sizeof(buff)-size, "@%s\n", provides_files);
	}
	write_nocheck(fileno, buff, size);
      }
    }
    if (pkg->conflicts && *pkg->conflicts) {
      size = snprintf(buff, sizeof(buff), "@conflicts@%s\n", pkg->conflicts);
      if (size < sizeof(buff)) write_nocheck(fileno, buff, size);
    }
    if (pkg->obsoletes && *pkg->obsoletes) {
      size = snprintf(buff, sizeof(buff), "@obsoletes@%s\n", pkg->obsoletes);
      if (size < sizeof(buff)) write_nocheck(fileno, buff, size);
    }
    if (pkg->requires && *pkg->requires) {
      size = snprintf(buff, sizeof(buff), "@requires@%s\n", pkg->requires);
      if (size < sizeof(buff)) write_nocheck(fileno, buff, size);
    }
    if (pkg->recommends && *pkg->recommends) {
      size = snprintf(buff, sizeof(buff), recommends ? "@recommends@%s\n" : "@suggests@%s\n", pkg->recommends);
      if (size < sizeof(buff)) write_nocheck(fileno, buff, size);
    }
    if (pkg->summary && *pkg->summary) {
      size = snprintf(buff, sizeof(buff), "@summary@%s\n", pkg->summary);
      if (size < sizeof(buff)) write_nocheck(fileno, buff, size);
    }
    if (pkg->filesize) {
      size = snprintf(buff, sizeof(buff), "@filesize@%" PRIu64 "\n", pkg->filesize);
      if (size < sizeof(buff)) write_nocheck(fileno, buff, size);
    }
    size = snprintf(buff, sizeof(buff), "@info@%s\n", pkg->info);
    write_nocheck(fileno, buff, size);
  } else croak("no info available for package %s",
	  pkg->h ? get_name(pkg->h, RPMTAG_NAME) : "-");

void
Pkg_build_header(pkg, fileno)
  URPM::Package pkg
  int fileno
  CODE:
  if (pkg->h) {
    FD_t fd;

    if ((fd = fdDup(fileno)) != NULL) {
      headerWrite(fd, pkg->h, HEADER_MAGIC_YES);
      Fclose(fd);
    } else croak("unable to get rpmio handle on fileno %d", fileno);
  } else croak("no header available for package");

int
Pkg_flag(pkg, name)
  URPM::Package pkg
  char *name
  PREINIT:
  unsigned mask;
  CODE:
  mask = mask_from_string(name);
  RETVAL = pkg->flag & mask;
  OUTPUT:
  RETVAL

int
Pkg_set_flag(pkg, name, value=1)
  URPM::Package pkg
  char *name
  int value
  PREINIT:
  unsigned mask;
  CODE:
  mask = mask_from_string(name);
  RETVAL = pkg->flag & mask;
  if (value) pkg->flag |= mask;
  else       pkg->flag &= ~mask;
  OUTPUT:
  RETVAL

int
Pkg_set_flag_skip(pkg, value=1)
  URPM::Package pkg
  int value
  ALIAS:
    set_flag_base = 1
    set_flag_disable_obsolete = 2
    set_flag_installed = 3
    set_flag_requested = 4
    set_flag_required = 5
    set_flag_upgrade = 6
  CODE:
  unsigned flag;
  switch (ix) {
  case 1: flag = FLAG_BASE; break;
  case 2: flag = FLAG_DISABLE_OBSOLETE; break;
  case 3: flag = FLAG_INSTALLED; break;
  case 4: flag = FLAG_REQUESTED; break;
  case 5: flag = FLAG_REQUIRED; break;
  case 6: flag = FLAG_UPGRADE; break;
  default: flag = FLAG_SKIP; break;
  }
  RETVAL = pkg->flag & flag;
  if (value) pkg->flag |= flag;
  else       pkg->flag &= ~flag;
  OUTPUT:
  RETVAL


int
Pkg_flag_required(pkg)
  URPM::Package pkg
  ALIAS:
    flag_upgrade = 1
    flag_disable_obsolete = 2
    flag_requested = 3
    flag_installed = 4
    flag_base = 5
    flag_skip = 6
  CODE:
  unsigned flag;
  switch (ix) {
  case 1: flag = FLAG_UPGRADE; break;
  case 2: flag = FLAG_DISABLE_OBSOLETE; break;
  case 3: flag = FLAG_REQUESTED; break;
  case 4: flag = FLAG_INSTALLED; break;
  case 5: flag = FLAG_BASE; break;
  case 6: flag = FLAG_SKIP; break;
  default: flag = FLAG_REQUIRED; break;
  }
  RETVAL = pkg->flag & flag;
  OUTPUT:
  RETVAL

int
Pkg_flag_selected(pkg)
  URPM::Package pkg
  CODE:
  RETVAL = pkg->flag & FLAG_UPGRADE ? pkg->flag & (FLAG_BASE | FLAG_REQUIRED) : 0;
  OUTPUT:
  RETVAL

int
Pkg_flag_available(pkg)
  URPM::Package pkg
  CODE:
  RETVAL = (pkg->flag & FLAG_INSTALLED && !(pkg->flag & FLAG_UPGRADE)) ||
           (pkg->flag & FLAG_UPGRADE ? pkg->flag & (FLAG_BASE | FLAG_REQUIRED) : 0);
  OUTPUT:
  RETVAL

int
Pkg_rate(pkg)
  URPM::Package pkg
  CODE:
  RETVAL = (pkg->flag & FLAG_RATE_MASK) >> FLAG_RATE_POS;
  OUTPUT:
  RETVAL

int
Pkg_set_rate(pkg, rate)
  URPM::Package pkg
  int rate
  CODE:
  RETVAL = (pkg->flag & FLAG_RATE_MASK) >> FLAG_RATE_POS;
  pkg->flag &= ~FLAG_RATE_MASK;
  pkg->flag |= (rate >= 0 && rate <= FLAG_RATE_MAX ? rate : FLAG_RATE_INVALID) << FLAG_RATE_POS;
  OUTPUT:
  RETVAL

void
Pkg_rflags(pkg)
  URPM::Package pkg
  PREINIT:
  I32 gimme = GIMME_V;
  PPCODE:
  if (gimme == G_ARRAY && pkg->rflags != NULL) {
    char *s = pkg->rflags;
    char *eos;
    while ((eos = strchr(s, '\t')) != NULL) {
      mXPUSHs(newSVpv(s, eos-s));
      s = eos + 1;
    }
    mXPUSHs(newSVpv(s, 0));
  }

void
Pkg_set_rflags(pkg, ...)
  URPM::Package pkg
  PREINIT:
  I32 gimme = GIMME_V;
  char *new_rflags;
  STRLEN total_len;
  int i;
  PPCODE:
  total_len = 0;
  for (i = 1; i < items; ++i)
    total_len += SvCUR(ST(i)) + 1;

  new_rflags = malloc(total_len);
  total_len = 0;
  for (i = 1; i < items; ++i) {
    STRLEN len;
    char *s = SvPV(ST(i), len);
    memcpy(new_rflags + total_len, s, len);
    new_rflags[total_len + len] = '\t';
    total_len += len + 1;
  }
  new_rflags[total_len - 1] = 0; /* but mark end-of-string correctly */

  if (gimme == G_ARRAY && pkg->rflags != NULL) {
    char *s = pkg->rflags;
    char *eos;
    while ((eos = strchr(s, '\t')) != NULL) {
      mXPUSHs(newSVpv(s, eos-s));
      s = eos + 1;
    }
    mXPUSHs(newSVpv(s, 0));
  }

  free(pkg->rflags);
  pkg->rflags = new_rflags;


MODULE = URPM            PACKAGE = URPM::DB            PREFIX = Db_

URPM::DB
Db_open(prefix=NULL, write_perm=0)
  char *prefix
  int write_perm
  PREINIT:
  URPM__DB db;
  CODE:
  read_config_files(0);
  db = malloc(sizeof(struct s_Transaction));
  db->count = 1;
  db->ts = rpmtsCreate();
  rpmtsSetRootDir(db->ts, prefix && prefix[0] ? prefix : NULL);
  if (rpmtsOpenDB(db->ts, write_perm ? O_RDWR | O_CREAT : O_RDONLY) == 0) {
    RETVAL = db;
  } else {
    RETVAL = NULL;
    (void)rpmtsFree(db->ts);
    free(db);
  }
  OUTPUT:
  RETVAL

int
Db_rebuild(prefix=NULL)
  char *prefix
  PREINIT:
  rpmts ts;
  CODE:
  read_config_files(0);
  ts = rpmtsCreate();
  rpmtsSetRootDir(ts, prefix);
  RETVAL = rpmtsRebuildDB(ts) == 0;
  (void)rpmtsFree(ts);
  OUTPUT:
  RETVAL

int
Db_verify(prefix=NULL)
  char *prefix
  PREINIT:
  rpmts ts;
  CODE:
  ts = rpmtsCreate();
  rpmtsSetRootDir(ts, prefix);
  RETVAL = rpmtsVerifyDB(ts) == 0;
  rpmtsFree(ts);
  OUTPUT:
  RETVAL

void
Db_DESTROY(db)
  URPM::DB db
  CODE:
  (void)rpmtsFree(db->ts);
  if (!--db->count) free(db);

int
Db_traverse(db,callback)
  URPM::DB db
  SV *callback
  PREINIT:
  Header header;
  rpmdbMatchIterator mi;
  rpmVSFlags ovsflags;
  int count = 0;
  CODE:
  db->ts = rpmtsLink(db->ts);
  ovsflags = ts_nosignature(db->ts);
  mi = rpmtsInitIterator(db->ts, RPMDBI_PACKAGES, NULL, 0);
  while ((header = rpmdbNextIterator(mi))) {
    if (SvROK(callback))
         _run_cb_while_traversing(callback, header, G_DISCARD);
    ++count;
  }
  rpmdbFreeIterator(mi);
  rpmtsSetVSFlags(db->ts, ovsflags);
  (void)rpmtsFree(db->ts);
  RETVAL = count;
  OUTPUT:
  RETVAL

int
Db_traverse_tag(db,tag,names,callback)
  URPM::DB db
  char *tag
  SV *names
  SV *callback
  PREINIT:
  Header header;
  rpmdbMatchIterator mi;
  int count = 0;
  rpmVSFlags ovsflags;
  CODE:
  if (SvROK(names) && SvTYPE(SvRV(names)) == SVt_PVAV) {
    AV* names_av = (AV*)SvRV(names);
    int len = av_len(names_av);
    int i;
    rpmDbiTag rpmtag = rpmtag_from_string(tag);

    for (i = 0; i <= len; ++i) {
      STRLEN str_len;
      SV **isv = av_fetch(names_av, i, 0);
      char *name = SvPV(*isv, str_len);
      db->ts = rpmtsLink(db->ts);
      ovsflags = ts_nosignature(db->ts);
      mi = rpmtsInitIterator(db->ts, rpmtag, name, str_len);
      while ((header = rpmdbNextIterator(mi))) {
	if (SvROK(callback))
	  _run_cb_while_traversing(callback, header, G_DISCARD);
	++count;
      }
      (void)rpmdbFreeIterator(mi);
      rpmtsSetVSFlags(db->ts, ovsflags);
      (void)rpmtsFree(db->ts);
    } 
  } else croak("bad arguments list");
  RETVAL = count;
  OUTPUT:
  RETVAL

int
Db_traverse_tag_find(db,tag,name,callback)
  URPM::DB db
  char *tag
  char *name
  SV *callback
  PREINIT:
  Header header;
  rpmdbMatchIterator mi;
  CODE:
  rpmDbiTag rpmtag = rpmtag_from_string(tag);
  int found = 0;
  rpmVSFlags ovsflags;
  db->ts = rpmtsLink(db->ts);
  ovsflags = ts_nosignature(db->ts);
  mi = rpmtsInitIterator(db->ts, rpmtag, name, 0);
  while ((header = rpmdbNextIterator(mi))) {
      dSP;
      int count = _run_cb_while_traversing(callback, header, 0);

      SPAGAIN;
      if (count == 1) {
	SV* ret = POPs;
	found = SvTRUE(ret);
	PUTBACK;
      }
      if (found) {
	break;
      }
  }
  rpmtsSetVSFlags(db->ts, ovsflags);
  (void)rpmdbFreeIterator(mi);
  (void)rpmtsFree(db->ts);
  RETVAL = found;
  OUTPUT:
  RETVAL

URPM::Transaction
Db_create_transaction(db)
  URPM::DB db
  CODE:
  /* this is *REALLY* dangerous to create a new transaction while another is open,
     so use the db transaction instead. */
  db->ts = rpmtsLink(db->ts);
  ++db->count;
  RETVAL = db;
  OUTPUT:
  RETVAL


MODULE = URPM            PACKAGE = URPM::Transaction   PREFIX = Trans_

void
Trans_DESTROY(trans)
  URPM::Transaction trans
  CODE:
  (void)rpmtsFree(trans->ts);
  if (!--trans->count) free(trans);

void
Trans_set_script_fd(trans, fdno)
  URPM::Transaction trans
  int fdno
  CODE:
  rpmtsSetScriptFd(trans->ts, fdDup(fdno));

int
Trans_add(trans, pkg, ...)
  URPM::Transaction trans
  URPM::Package pkg
  CODE:
  if ((pkg->flag & FLAG_ID_MASK) <= FLAG_ID_MAX && pkg->h != NULL) {
    int update = 0;
    rpmRelocation *relocations = NULL;
    if (items > 3) {
      int i;
      for (i = 2; i < items-1; i+=2) {
	STRLEN len;
	char *s = SvPV(ST(i), len);

	if (len == 6 && !memcmp(s, "update", 6))
	  update = SvIV(ST(i+1));
	else if (len == 11 && !memcmp(s, "excludepath", 11)) {
	  if (SvROK(ST(i+1)) && SvTYPE(SvRV(ST(i+1))) == SVt_PVAV) {
	    AV *excludepath = (AV*)SvRV(ST(i+1));
	    I32 j = 1 + av_len(excludepath);
	    if (relocations) free(relocations);
	    relocations = calloc(j + 1, sizeof(rpmRelocation));
	    while (--j >= 0) {
	      SV **e = av_fetch(excludepath, j, 0);
	      if (e != NULL && *e != NULL)
		relocations[j].oldPath = SvPV_nolen(*e);
	    }
	  }
	}
      }
    }
    RETVAL = rpmtsAddInstallElement(trans->ts, pkg->h, (fnpyKey)(1+(long)(pkg->flag & FLAG_ID_MASK)), update, relocations) == 0;
    /* free allocated memory, check rpm is copying it just above, at least in 4.0.4 */
    free(relocations);
  } else RETVAL = 0;
  OUTPUT:
  RETVAL

int
Trans_remove(trans, name)
  URPM::Transaction trans
  char *name
  PREINIT:
  Header h;
  rpmdbMatchIterator mi;
  int count = 0;
  CODE:
  mi = rpmtsInitIterator(trans->ts, RPMDBI_LABEL, name, 0);
  while ((h = rpmdbNextIterator(mi))) {
    unsigned int recOffset = rpmdbGetIteratorOffset(mi);
    if (recOffset != 0) {
      rpmtsAddEraseElement(trans->ts, h, recOffset);
      ++count;
    }
  }
  rpmdbFreeIterator(mi);
  RETVAL=count;
  OUTPUT:
  RETVAL

int
Trans_traverse(trans, callback)
  URPM::Transaction trans
  SV *callback
  PREINIT:
  rpmdbMatchIterator mi;
  Header h;
  int c = 0;
  CODE:
  mi = rpmtsInitIterator(trans->ts, RPMDBI_PACKAGES, NULL, 0);
  while ((h = rpmdbNextIterator(mi))) {
    if (SvROK(callback))
      _run_cb_while_traversing(callback, h, G_DISCARD);
    ++c;
  }
  rpmdbFreeIterator(mi);
  RETVAL = c;
  OUTPUT:
  RETVAL

void
Trans_check(trans, ...)
  URPM::Transaction trans
  PREINIT:
  I32 gimme = GIMME_V;
  int translate_message = 0;
  int i;
  PPCODE:
  for (i = 1; i < items-1; i+=2) {
    STRLEN len;
    char *s = SvPV(ST(i), len);

    if (len == 17 && !memcmp(s, "translate_message", 17))
      translate_message = SvIV(ST(i+1));
  }
  rpmtsCheck(trans->ts);
    rpmps ps = rpmtsProblems(trans->ts);
    if (rpmpsNumProblems(ps) > 0) {
      if (gimme == G_SCALAR)
	mXPUSHs(newSViv(0));
      else if (gimme == G_ARRAY) {
	/* now translation is handled by rpmlib, but only for version 4.2 and above */
	PUTBACK;
	return_problems(ps, 1, 0);
	SPAGAIN;
      }
    } else if (gimme == G_SCALAR)
      mXPUSHs(newSViv(1));
    
    rpmpsFree(ps);

void
Trans_order(trans, ...)
  URPM::Transaction trans
  PREINIT:
  rpmtransFlags transFlags = RPMTRANS_FLAG_NONE;
  I32 gimme = GIMME_V;
  int i;
  PPCODE:
  for (i = 1; i < items-1; i+=2) {
    STRLEN len;
    char *s = SvPV(ST(i), len);

    if (len == 8 && !memcmp(s, "deploops", 8)) {
      if (SvIV(ST(i+1))) transFlags |= RPMTRANS_FLAG_DEPLOOPS;
    }
  }
  rpmtsSetFlags(trans->ts, transFlags);
  if (rpmtsOrder(trans->ts) == 0) {
    if (gimme == G_SCALAR)
      mXPUSHs(newSViv(1));
  } else {
    if (gimme == G_SCALAR)
      mXPUSHs(newSViv(0));
    else if (gimme == G_ARRAY)
      mXPUSHs(newSVpvs("error while ordering dependencies"));
  }

int
Trans_NElements(trans)
  URPM::Transaction trans
  CODE:
  RETVAL = rpmtsNElements(trans->ts);
  OUTPUT:
  RETVAL

char *
Trans_Element_name(trans, index)
  URPM::Transaction trans
  int index
  ALIAS:
       Element_version  = 1
       Element_release  = 2
       Element_fullname = 3
  CODE:
  rpmte te = rpmtsElement(trans->ts, index);
  if (te) {
       switch (ix) {
       case 1:  RETVAL = (char *) rpmteV(te); break;
       case 2:  RETVAL = (char *) rpmteR(te); break;
       case 3:  RETVAL = (char *) rpmteNEVRA(te); break;
       default: RETVAL = (char *) rpmteN(te); break;
       }
  } else {
       RETVAL = NULL;
  }
  OUTPUT:
  RETVAL

void
Trans_run(trans, data, ...)
  URPM::Transaction trans
  SV *data
  PREINIT:
  struct s_TransactionData td = { NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 100000, data };
  rpmtransFlags transFlags = RPMTRANS_FLAG_NONE;
  int probFilter = 0;
  int translate_message = 0, raw_message = 0;
  int i;
  PPCODE:
  for (i = 2 ; i < items - 1 ; i += 2) {
    STRLEN len;
    char *s = SvPV(ST(i), len);

    if (len == 4 && !memcmp(s, "test", 4)) {
      if (SvIV(ST(i+1))) transFlags |= RPMTRANS_FLAG_TEST;
    } else if (len == 11 && !memcmp(s, "excludedocs", 11)) {
      if (SvIV(ST(i+1))) transFlags |= RPMTRANS_FLAG_NODOCS;
    } else if (len == 5) {
      if (!memcmp(s, "force", 5)) {
	if (SvIV(ST(i+1))) probFilter |= (RPMPROB_FILTER_REPLACEPKG |
					  RPMPROB_FILTER_REPLACEOLDFILES |
					  RPMPROB_FILTER_REPLACENEWFILES |
					  RPMPROB_FILTER_OLDPACKAGE);
      } else if (!memcmp(s, "delta", 5))
	td.min_delta = SvIV(ST(i+1));
    } else if (len == 6 && !memcmp(s, "nosize", 6)) {
      if (SvIV(ST(i+1))) probFilter |= (RPMPROB_FILTER_DISKSPACE|RPMPROB_FILTER_DISKNODES);
    } else if (len == 9 && !memcmp(s, "noscripts", 9)) {
      if (SvIV(ST(i+1))) transFlags |= (RPMTRANS_FLAG_NOSCRIPTS |
				        RPMTRANS_FLAG_NOPRE |
				        RPMTRANS_FLAG_NOPREUN |
				        RPMTRANS_FLAG_NOPOST |
				        RPMTRANS_FLAG_NOPOSTUN );
    } else if (len == 10 && !memcmp(s, "oldpackage", 10)) {
      if (SvIV(ST(i+1))) probFilter |= RPMPROB_FILTER_OLDPACKAGE;
    } else if (len == 11 && !memcmp(s, "replacepkgs", 11)) {
      if (SvIV(ST(i+1))) probFilter |= RPMPROB_FILTER_REPLACEPKG;
    } else if (len == 11 && !memcmp(s, "raw_message", 11)) {
      raw_message = 1;
    } else if (len == 12 && !memcmp(s, "replacefiles", 12)) {
      if (SvIV(ST(i+1))) probFilter |= RPMPROB_FILTER_REPLACEOLDFILES | RPMPROB_FILTER_REPLACENEWFILES;
    } else if (len == 6 && !memcmp(s, "justdb", 6)) {
      if (SvIV(ST(i+1))) transFlags |= RPMTRANS_FLAG_JUSTDB;
    } else if (len == 10 && !memcmp(s, "ignorearch", 10)) {
      if (SvIV(ST(i+1))) probFilter |= RPMPROB_FILTER_IGNOREARCH;
    } else if (len == 17 && !memcmp(s, "translate_message", 17))
      translate_message = 1;
    else if (len >= 9 && !memcmp(s, "callback_", 9)) {
      if (len == 9+4 && !memcmp(s+9, "open", 4)) {
	if (SvROK(ST(i+1))) td.callback_open = ST(i+1);
      } else if (len == 9+5 && !memcmp(s+9, "close", 5)) {
	if (SvROK(ST(i+1))) td.callback_close = ST(i+1);
      } else if (len == 9+4 && !memcmp(s+9, "elem", 4)) {
	if (SvROK(ST(i+1))) td.callback_elem = ST(i+1);
      } else if (len == 9+5 && !memcmp(s+9, "trans", 5)) {
	if (SvROK(ST(i+1))) td.callback_trans = ST(i+1);
      } else if (len == 9+6 && !memcmp(s+9, "uninst", 6)) {
	if (SvROK(ST(i+1))) td.callback_uninst = ST(i+1);
      } else if (len == 9+6 && !memcmp(s+9, "verify", 6)) {
	if (SvROK(ST(i+1))) td.callback_verify = ST(i+1);
      } else if (len == 9+4 && !memcmp(s+9, "inst", 4)) {
	if (SvROK(ST(i+1))) td.callback_inst = ST(i+1);
      } else if (len == 9+5 && !memcmp(s+9, "error", 5)) {
	if (SvROK(ST(i+1))) td.callback_error = ST(i+1);
      }
    }
  }
  rpmtsSetFlags(trans->ts, transFlags);
  trans->ts = rpmtsLink(trans->ts);
  rpmtsSetNotifyCallback(trans->ts, rpmRunTransactions_callback, &td);
  if (rpmtsRun(trans->ts, NULL, probFilter) > 0) {
    rpmps ps = rpmtsProblems(trans->ts);
    PUTBACK;
    return_problems(ps, translate_message, raw_message || !translate_message);
    SPAGAIN;
    rpmpsFree(ps);
  }
  rpmtsEmpty(trans->ts);
  (void)rpmtsFree(trans->ts);

MODULE = URPM            PACKAGE = URPM                PREFIX = Urpm_

BOOT:
(void) read_config_files(0);

void
Urpm_bind_rpm_textdomain_codeset()
  CODE:
  rpm_codeset_is_utf8 = 1;
  bind_textdomain_codeset("rpm", "UTF-8");

int
Urpm_read_config_files()
  CODE:
  RETVAL = (read_config_files(1) == 0); /* force re-read of configuration files */
  OUTPUT:
  RETVAL

int
rpmvercmp(one, two)
    char *one
    char *two        
       
int
Urpm_ranges_overlap(a, b)
  char *a
  char *b
  PREINIT:
  char *sa = a, *sb = b;
  int aflags = 0, bflags = 0;
  CODE:
  while (*sa && *sa != ' ' && *sa != '[' && *sa != '<' && *sa != '>' && *sa != '=' && *sa == *sb) {
    ++sa;
    ++sb;
  }
  if ((*sa && *sa != ' ' && *sa != '[' && *sa != '<' && *sa != '>' && *sa != '=') ||
      (*sb && *sb != ' ' && *sb != '[' && *sb != '<' && *sb != '>' && *sb != '=')) {
    /* the strings are sure to be different */
    RETVAL = 0;
  } else {
    while (*sa) {
      if (*sa == ' ' || *sa == '[' || *sa == '*' || *sa == ']');
      else if (*sa == '<') aflags |= RPMSENSE_LESS;
      else if (*sa == '>') aflags |= RPMSENSE_GREATER;
      else if (*sa == '=') aflags |= RPMSENSE_EQUAL;
      else break;
      ++sa;
    }
    while (*sb) {
      if (*sb == ' ' || *sb == '[' || *sb == '*' || *sb == ']');
      else if (*sb == '<') bflags |= RPMSENSE_LESS;
      else if (*sb == '>') bflags |= RPMSENSE_GREATER;
      else if (*sb == '=') bflags |= RPMSENSE_EQUAL;
      else break;
      ++sb;
    }
    RETVAL = ranges_overlap(aflags, sa, bflags, sb);
  }
  OUTPUT:
  RETVAL

void
Urpm_parse_synthesis__XS(urpm, filename, ...)
  SV *urpm
  char *filename
  PPCODE:
  if (SvROK(urpm) && SvTYPE(SvRV(urpm)) == SVt_PVHV) {
    SV **fdepslist = hv_fetch((HV*)SvRV(urpm), "depslist", 8, 0);
    AV *depslist = fdepslist && SvROK(*fdepslist) && SvTYPE(SvRV(*fdepslist)) == SVt_PVAV ? (AV*)SvRV(*fdepslist) : NULL;
    SV **fprovides = hv_fetch((HV*)SvRV(urpm), "provides", 8, 0);
    HV *provides = fprovides && SvROK(*fprovides) && SvTYPE(SvRV(*fprovides)) == SVt_PVHV ? (HV*)SvRV(*fprovides) : NULL;
    SV **fobsoletes = hv_fetch((HV*)SvRV(urpm), "obsoletes", 9, 0);
    HV *obsoletes = fobsoletes && SvROK(*fobsoletes) && SvTYPE(SvRV(*fobsoletes)) == SVt_PVHV ? (HV*)SvRV(*fobsoletes) : NULL;

    if (depslist != NULL) {
      char buff[65536*2];
      char *p, *eol, *t;
      int buff_len;
      struct s_Package pkg;
      FD_t f = NULL;
      int start_id = 1 + av_len(depslist);
      SV *callback = NULL;
      rpmCompressedMagic compressed = COMPRESSED_OTHER;

      if (items > 2) {
	int i;
	for (i = 2; i < items-1; i+=2) {
	  STRLEN len;
	  char *s = SvPV(ST(i), len);

	  if (len == 8 && !memcmp(s, "callback", 8) && SvROK(ST(i+1)))
	    callback = ST(i+1);
	}
      }

      PUTBACK;
      int rc = rpmFileIsCompressed(filename, &compressed);

      switch (compressed) {
      case COMPRESSED_BZIP2: t = "r.bzip2"; break;
      case COMPRESSED_LZMA:
      case COMPRESSED_XZ:
        t = "r.xz"; break;
      case COMPRESSED_OTHER:
      default:
        t = "r.gzip"; break;
      }
      f = Fopen(filename, "r.fdio");

      if (!rc && (f = Fdopen(f, t)) != NULL && !Ferror(f)) {
	// initialize first package
	memset(&pkg, 0, sizeof(struct s_Package));
	buff[sizeof(buff)-1] = 0;
	p = buff;
	int ok = 1;
	while ((buff_len = Fread(p, sizeof(buff)-1-(p-buff), 1, f)) >= 0 &&
	       (buff_len += p-buff)) {
	  buff[buff_len] = 0;
	  p = buff;
	  if ((eol = strchr(p, '\n')) != NULL) {
	    do {
	      *eol++ = 0;
	      if (!parse_line(depslist, provides, obsoletes, &pkg, p, urpm, callback)) {
                ok = 0;
                break;
              }
	      p = eol;
	    } while ((eol = strchr(p, '\n')) != NULL);
	  } else {
	    /* a line larger than sizeof(buff) has been encountered, bad file problably */
	    fprintf(stderr, "invalid line <%s>\n", p);
	    ok = 0;
	    break;
	  }
	    /* move the remaining non-complete-line at beginning */
	    memmove(buff, p, buff_len-(p-buff));
	    /* point to the end of the non-complete-line */
	    p = &buff[buff_len-(p-buff)];
	}
        // EOF:
        if (ok && buff_len > 0
            && !parse_line(depslist, provides, obsoletes, &pkg, p, urpm, callback))
             ok = 0;
	if (Fclose(f) != 0) ok = 0;
	SPAGAIN;
	if (ok) {
	  mXPUSHs(newSViv(start_id));
	  mXPUSHs(newSViv(av_len(depslist)));
	}
      } else {
	  SV **nofatal = hv_fetch((HV*)SvRV(urpm), "nofatal", 7, 0);
	  if (!errno) errno = EINVAL; /* zlib error */
	  if (!nofatal || !SvIV(*nofatal))
	      croak(errno == ENOENT
		      ? "unable to read synthesis file %s"
		      : "unable to uncompress synthesis file %s", filename);
      }
    } else croak("first argument should contain a depslist ARRAY reference");
  } else croak("first argument should be a reference to a HASH");

void
Urpm_parse_hdlist__XS(urpm, filename, ...)
  SV *urpm
  char *filename
  PPCODE:
  if (SvROK(urpm) && SvTYPE(SvRV(urpm)) == SVt_PVHV) {
    SV **fdepslist = hv_fetch((HV*)SvRV(urpm), "depslist", 8, 0);
    AV *depslist = fdepslist && SvROK(*fdepslist) && SvTYPE(SvRV(*fdepslist)) == SVt_PVAV ? (AV*)SvRV(*fdepslist) : NULL;
    SV **fprovides = hv_fetch((HV*)SvRV(urpm), "provides", 8, 0);
    HV *provides = fprovides && SvROK(*fprovides) && SvTYPE(SvRV(*fprovides)) == SVt_PVHV ? (HV*)SvRV(*fprovides) : NULL;
    SV **fobsoletes = hv_fetch((HV*)SvRV(urpm), "obsoletes", 9, 0);
    HV *obsoletes = fobsoletes && SvROK(*fobsoletes) && SvTYPE(SvRV(*fobsoletes)) == SVt_PVHV ? (HV*)SvRV(*fobsoletes) : NULL;

    if (depslist != NULL) {
      int empty_archive = 0;
      FD_t fd;

      fd = open_archive(filename, &empty_archive);

      if (empty_archive) {
	  mXPUSHs(newSViv(1 + av_len(depslist)));
	  mXPUSHs(newSViv(av_len(depslist)));
      } else if (fd != NULL && !Ferror(fd)) {
	Header header;
	int start_id = 1 + av_len(depslist);
	int packing = 0;
	SV *callback = NULL;

	if (items > 3) {
	  int i;
	  for (i = 2; i < items-1; i+=2) {
	    STRLEN len;
	    char *s = SvPV(ST(i), len);

	    if (len == 7 && !memcmp(s, "packing", 7))
	      packing = SvTRUE(ST(i+1));
	    else if (len == 8 && !memcmp(s, "callback", 8) && SvROK(ST(i+1)))
	      callback = ST(i+1);
	  }
	}

	PUTBACK;
	do {
	  header = headerRead(fd, HEADER_MAGIC_YES);
	  if (header != NULL) {
	    struct s_Package *_pkg;
	    _pkg = calloc(1, sizeof(struct s_Package));
	    _pkg->flag = 1 + av_len(depslist);
	    _pkg->h = header;
	    push_in_depslist(_pkg, urpm, depslist, callback, provides, obsoletes, packing);
	  }
	} while (header != NULL);

	int ok = Fclose(fd) == 0;

	if (!empty_archive)
	  ok = av_len(depslist) >= start_id;
	SPAGAIN;
	if (ok) {
	  mXPUSHs(newSViv(start_id));
	  mXPUSHs(newSViv(av_len(depslist)));
	}
      } else {
	  SV **nofatal = hv_fetch((HV*)SvRV(urpm), "nofatal", 7, 0);
	  if (!nofatal || !SvIV(*nofatal))
	      croak("cannot open hdlist file %s", filename);
      }
    } else croak("first argument should contain a depslist ARRAY reference");
  } else croak("first argument should be a reference to a HASH");


#ifndef RPM4_14_0
#define RPMVSF_NOPAYLOAD RPMVSF_NOSHA1
#define RPMVSF_NOSHA256HEADER RPMVSF_NOMD5HEADER
#endif
void
Urpm_parse_rpm(urpm, filename, ...)
  SV *urpm
  char *filename
  PPCODE:
  if (SvROK(urpm) && SvTYPE(SvRV(urpm)) == SVt_PVHV) {
    SV **fdepslist = hv_fetch((HV*)SvRV(urpm), "depslist", 8, 0);
    AV *depslist = fdepslist && SvROK(*fdepslist) && SvTYPE(SvRV(*fdepslist)) == SVt_PVAV ? (AV*)SvRV(*fdepslist) : NULL;
    SV **fprovides = hv_fetch((HV*)SvRV(urpm), "provides", 8, 0);
    HV *provides = fprovides && SvROK(*fprovides) && SvTYPE(SvRV(*fprovides)) == SVt_PVHV ? (HV*)SvRV(*fprovides) : NULL;
    SV **fobsoletes = hv_fetch((HV*)SvRV(urpm), "obsoletes", 8, 0);
    HV *obsoletes = fobsoletes && SvROK(*fobsoletes) && SvTYPE(SvRV(*fobsoletes)) == SVt_PVHV ? (HV*)SvRV(*fobsoletes) : NULL;

    if (depslist != NULL) {
      struct s_Package *_pkg;
      int packing = 0;
      int keep_all_tags = 0;
      SV *callback = NULL;
      rpmVSFlags vsflags = RPMVSF_DEFAULT;

      if (items > 3) {
	int i;
	for (i = 2; i < items-1; i+=2) {
	  STRLEN len;
	  char *s = SvPV(ST(i), len);

	  if (len == 7 && !memcmp(s, "packing", 7))
	    packing = SvTRUE(ST(i + 1));
	  else if (len == 13 && !memcmp(s, "keep_all_tags", 13))
	    keep_all_tags = SvTRUE(ST(i+1));
	  else if (len == 8 && !memcmp(s, "callback", 8) && SvROK(ST(i+1)))
	    callback = ST(i+1);
	  else if (SvIV(ST(i+1))) {
             if (len == 5) {
                if (!memcmp(s, "nopgp", 5))
                  vsflags |= (RPMVSF_NOPAYLOAD | RPMVSF_NOSHA1HEADER);
                else if (!memcmp(s, "nogpg", 5))
                  vsflags |= (RPMVSF_NOPAYLOAD | RPMVSF_NOSHA1HEADER);
                else if (!memcmp(s, "nomd5", 5))
                  vsflags |= (RPMVSF_NOMD5 | RPMVSF_NOSHA256HEADER);
                else if (!memcmp(s, "norsa", 5))
                  vsflags |= (RPMVSF_NORSA | RPMVSF_NORSAHEADER);
                else if (!memcmp(s, "nodsa", 5))
                  vsflags |= (RPMVSF_NODSA | RPMVSF_NODSAHEADER);
             } else if (len == 9) {
                if (!memcmp(s, "nodigests", 9))
                  vsflags |= _RPMVSF_NODIGESTS;
                else if (!memcmp(s, "nopayload", 9))
                  vsflags |= _RPMVSF_NOPAYLOAD;
             }
          } 
	}
      }
      PUTBACK;
      _pkg = calloc(1, sizeof(struct s_Package));
      _pkg->flag = 1 + av_len(depslist);

      if (update_header(filename, _pkg, keep_all_tags, vsflags)) {
	push_in_depslist(_pkg, urpm, depslist, callback, provides, obsoletes, packing);
	SPAGAIN;
	/* only one element read */
	mXPUSHs(newSViv(av_len(depslist)));
	mXPUSHs(newSViv(av_len(depslist)));
      } else free(_pkg);
    } else croak("first argument should contain a depslist ARRAY reference");
  } else croak("first argument should be a reference to a HASH");

int
Urpm_verify_rpm(filename, ...)
  char *filename
  PREINIT:
  FD_t fd;
  int i, oldlogmask;
  rpmVSFlags vsflags;
  CODE:
  /* Don't display error messages */
  oldlogmask = rpmlogSetMask(RPMLOG_UPTO(RPMLOG_PRI(4)));
  vsflags = RPMVSF_DEFAULT;
  for (i = 1 ; i < items - 1 ; i += 2) {
    STRLEN len;
    char *s = SvPV(ST(i), len);
    if (SvIV(ST(i+1))) {
      if (len == 9 && !strncmp(s, "nodigests", 9))
        vsflags |= _RPMVSF_NODIGESTS;
      else if (len == 12 && !strncmp(s, "nosignatures", 12))
        vsflags |= _RPMVSF_NOSIGNATURES;
    }
  }
  fd = Fopen(filename, "r");
  if (fd == NULL)
    RETVAL = 0;
  else {
    Header h;
    read_config_files(0);
    rpmts ts = rpmtsCreate();
    rpmtsSetRootDir(ts, "/");
    rpmtsOpenDB(ts, O_RDONLY);
    rpmtsSetVSFlags(ts, vsflags);
    RETVAL = (rpmReadPackageFile(ts, fd, filename, &h) == RPMRC_OK);
    Fclose(fd);
    if (h)
      h = headerFree(h);
    (void)rpmtsFree(ts);
  }
  rpmlogSetMask(oldlogmask);

  OUTPUT:
  RETVAL


char *
Urpm_get_gpg_fingerprint(filename)
    char * filename
    PREINIT:
    uint8_t fingerprint[sizeof(pgpKeyID_t)];
    char fingerprint_str[sizeof(pgpKeyID_t) * 2 + 1];
    const uint8_t *pkt = NULL;
    size_t pktlen = 0;
    int rc;

    CODE:
    memset (fingerprint, 0, sizeof (fingerprint));
    if ((rc = pgpReadPkts(filename, (uint8_t ** ) &pkt, &pktlen)) <= 0)
	pktlen = 0;
    else if (rc != PGPARMOR_PUBKEY)
	pktlen = 0;
    else {
	unsigned int i;
#ifdef RPM4_14_0
        pgpPubkeyKeyID (pkt, pktlen, fingerprint);
#else
	pgpPubkeyFingerprint (pkt, pktlen, fingerprint);
#endif
   	for (i = 0; i < sizeof (pgpKeyID_t); i++)
	    sprintf(&fingerprint_str[i*2], "%02x", fingerprint[i]);
    }
    _free(pkt);
    RETVAL = fingerprint_str;
    OUTPUT:
    RETVAL


char *
Urpm_verify_signature(filename, prefix=NULL)
  char *filename
  char *prefix
  PREINIT:
  rpmts ts = NULL;
  char result[1024];
  rpmRC rc;
  FD_t fd;
  Header h;
  CODE:
  fd = Fopen(filename, "r");
  if (fd == NULL)
    RETVAL = "NOT OK (could not read file)";
  else {
    read_config_files(0);
    ts = rpmtsCreate();
    rpmtsSetRootDir(ts, prefix);
    rpmtsOpenDB(ts, O_RDONLY);
    rpmtsSetVSFlags(ts, RPMVSF_DEFAULT);
    rc = rpmReadPackageFile(ts, fd, filename, &h);
    Fclose(fd);
    *result = '\0';
    switch(rc) {
      case RPMRC_OK:
	if (h) {
	  char *fmtsig = headerFormat(
	      h,
	      "%|DSAHEADER?{%{DSAHEADER:pgpsig}}:{%|RSAHEADER?{%{RSAHEADER:pgpsig}}:"
	      "{%|SIGGPG?{%{SIGGPG:pgpsig}}:{%|SIGPGP?{%{SIGPGP:pgpsig}}:{(none)}|}|}|}|",
	      NULL);
	  snprintf(result, sizeof(result), "OK (%s)", fmtsig);
	  free(fmtsig);
	} else snprintf(result, sizeof(result), "NOT OK (bad rpm): %s", rpmlogMessage());
	break;
      case RPMRC_NOTFOUND:
	snprintf(result, sizeof(result), "NOT OK (signature not found): %s", rpmlogMessage());
	break;
      case RPMRC_FAIL:
	snprintf(result, sizeof(result), "NOT OK (fail): %s", rpmlogMessage());
	break;
      case RPMRC_NOTTRUSTED:
	snprintf(result, sizeof(result), "NOT OK (key not trusted): %s", rpmlogMessage());
	break;
      case RPMRC_NOKEY:
	snprintf(result, sizeof(result), "NOT OK (no key): %s", rpmlogMessage());
	break;
    }
    RETVAL = result;
    if (h) headerFree(h);
    (void)rpmtsFree(ts);
  }

  OUTPUT:
  RETVAL

    
int
Urpm_import_pubkey_file(db, filename)
    URPM::DB db
    char * filename
    PREINIT:
    const uint8_t *pkt = NULL;
    size_t pktlen = 0;
    int rc;
    CODE:
    rpmts ts = rpmtsLink(db->ts);
    rpmtsClean(ts);
    
    if ((rc = pgpReadPkts(filename, (uint8_t ** ) &pkt, &pktlen)) <= 0)
        RETVAL = 0;
    else if (rc != PGPARMOR_PUBKEY)
        RETVAL = 0;
    else if (rpmtsImportPubkey(ts, pkt, pktlen) != RPMRC_OK)
        RETVAL = 0;
    else
        RETVAL = 1;
    _free(pkt);
    (void)rpmtsFree(ts);
    OUTPUT:
    RETVAL

int
Urpm_archscore(param)
  const char * param
  ALIAS:
         osscore = 1
  PREINIT:
  CODE:
  read_config_files(0);
  RETVAL=rpmMachineScore(ix == 0 ? RPM_MACHTABLE_INSTARCH : RPM_MACHTABLE_INSTOS, param);
  OUTPUT:
  RETVAL


void
Urpm_stream2header(fp)
    FILE *fp
  PREINIT:
    FD_t fd;
    URPM__Package pkg;
  PPCODE:
    if ((fd = fdDup(fileno(fp)))) {
        pkg = (URPM__Package)calloc(1, sizeof(struct s_Package));
        pkg->h = headerRead(fd, HEADER_MAGIC_YES);
        if (pkg->h)
            XPUSHs(sv_setref_pv(sv_newmortal(), "URPM::Package", (void*)pkg));
        else free(pkg);
        Fclose(fd);
    }

void
Urpm_spec2srcheader(specfile)
  char *specfile
  PREINIT:
    URPM__Package pkg;
    Spec spec = NULL;
    Header header = NULL;
  PPCODE:
/* ensure the config is in memory with all macro */
  read_config_files(0);
/* Do not verify architecture */
/* Do not verify whether sources exist */
  spec = rpmSpecParse(specfile, RPMSPEC_ANYARCH|RPMSPEC_FORCE, NULL);
  if (spec) {
    header = rpmSpecSourceHeader(spec);
    pkg = (URPM__Package)calloc(1, sizeof(struct s_Package));
    pkg->h = headerLink(header);
    XPUSHs(sv_setref_pv(sv_newmortal(), "URPM::Package", (void*)pkg));
    rpmSpecFree(spec);
  } else {
    XPUSHs(&PL_sv_undef);
    /* apparently rpmlib sets errno to this when given a bad spec. */
    if (errno == EBADF)
      errno = 0;
  }

void
expand(name)
    char * name
    PPCODE:
    const char * value = rpmExpand(name, NULL);
    mXPUSHs(newSVpv(value, 0));

void
add_macro_noexpand(macro)
    char * macro
    CODE:
    rpmDefineMacro(NULL, macro, RMIL_DEFAULT);

void
del_macro(name)
    char * name
    CODE:
    delMacro(NULL, name);

void
loadmacrosfile(filename)
    char * filename
    PPCODE:
    rpmInitMacros(NULL, filename);

void
resetmacros()
    PPCODE:
    rpmFreeMacros(NULL);

void
setVerbosity(level)
    int level
    PPCODE:
    rpmSetVerbosity(level);

const char *
rpmErrorString()
  CODE:
  RETVAL = rpmlogMessage();
  OUTPUT:
  RETVAL 

void
rpmErrorWriteTo(fd)
  int fd
  CODE:
  rpmError_callback_data = fd;
  rpmlogSetCallback(rpmError_callback, NULL);

  /* vim:set ts=8 sts=2 sw=2: */
