/* @(#) $Id: Utmp.xs 1.6 Mon, 27 Mar 2006 02:20:00 +0200 mxp $ */

#ifdef __cplusplus
extern "C" {
#endif
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#ifdef __cplusplus
}
#endif

#include <utmp.h>

/* Handle older Linux versions with UT_UNKNOWN instead of EMPTY */
#ifndef EMPTY
#ifdef  UT_UNKNOWN
#define EMPTY UT_UNKNOWN
#endif
#endif

#ifdef _XOPEN_UNIX
#define HAS_UTMPX
#endif

#ifdef HAS_UTMPX
#include <utmpx.h>

#ifdef __NetBSD__
/* NetBSD uses ut_name instead of ut_user.  This macro is already in
 * utmpx.h, which should normally be included, but just in case we
 * check again. */
#ifndef ut_user
#define ut_user ut_name
#endif
#endif
#endif

#ifndef MIN
#define MIN(a, b) (((a)<(b))?(a):(b))
#endif

static int
not_here(s)
char *s;
{
    croak("%s not implemented on this architecture", s);
    return -1;
}

static int
constant(char *name, int arg)
{
   errno = 0;
   switch (*name)
   {
      case 'B':
	 if (strEQ(name, "BOOT_TIME"))
#ifdef BOOT_TIME
	    return BOOT_TIME;
#else
	 goto not_there;
#endif
	 break;
      case 'D':
	 if (strEQ(name, "DEAD_PROCESS"))
#ifdef DEAD_PROCESS
	    return DEAD_PROCESS;
#else
	 goto not_there;
#endif
	 break;
      case 'E':
	 if (strEQ(name, "EMPTY"))
#ifdef EMPTY
	    return EMPTY;
#else
	 goto not_there;
#endif
	 break;
      case 'H':
	 if (strEQ(name, "HAS_UTMPX"))
#ifdef HAS_UTMPX
	    return 1;
#else
	 return 0;
#endif
	    case 'I':
   if (strEQ(name, "INIT_PROCESS"))
#ifdef INIT_PROCESS
      return INIT_PROCESS;
#else
	 goto not_there;
#endif
	 break;
      case 'L':
	 if (strEQ(name, "LOGIN_PROCESS"))
#ifdef LOGIN_PROCESS
	    return LOGIN_PROCESS;
#else
	 goto not_there;
#endif
	 break;
      case 'N':
	 if (strEQ(name, "NEW_TIME"))
#ifdef NEW_TIME
	    return NEW_TIME;
#else
	 goto not_there;
#endif
	 break;
      case 'O':
	 if (strEQ(name, "OLD_TIME"))
#ifdef OLD_TIME
	    return OLD_TIME;
#else
	 goto not_there;
#endif
	 break;
      case 'R':
	 if (strEQ(name, "RUN_LVL"))
#ifdef RUN_LVL
	    return RUN_LVL;
#else
	 goto not_there;
#endif
	 break;
      case 'U':
	 if (strEQ(name, "USER_PROCESS"))
#ifdef USER_PROCESS
	    return USER_PROCESS;
#else
	 goto not_there;
#endif
	 break;
   }
   errno = EINVAL;
   return 0;

  not_there:
   errno = ENOENT;
   return 0;
}


SV *utent2perl(struct utmp *entry)
{
   HV *perl_hash;
   HV *exit_hash;
   
   perl_hash = newHV();
   exit_hash = newHV();

   hv_store(perl_hash, "ut_user", 7,
	    newSVpv(entry->ut_user, MIN(8, strlen(entry->ut_user))), 0);
   hv_store(perl_hash, "ut_line", 7,
	    newSVpv(entry->ut_line, MIN(12, strlen(entry->ut_line))), 0);
   hv_store(perl_hash, "ut_time", 7, newSViv(entry->ut_time), 0);

#ifdef HAS_UT_EXTENSIONS
   hv_store(perl_hash, "ut_id",   5,
	    newSVpv(entry->ut_id, MIN(4, strlen(entry->ut_id))), 0);
   hv_store(perl_hash, "ut_pid",  6, newSViv(entry->ut_pid),  0);
   hv_store(perl_hash, "ut_type", 7, newSViv(entry->ut_type), 0);
   hv_store(exit_hash, "e_termination", 13,
	    newSViv(entry->ut_exit.e_termination), 0);
   hv_store(exit_hash, "e_exit", 6,  newSViv(entry->ut_exit.e_exit), 0);
   hv_store(perl_hash, "ut_exit", 7, newRV_noinc((SV *) exit_hash), 0);
#endif

#ifdef HAS_UT_HOST
   hv_store(perl_hash, "ut_host", 7,
	    newSVpv(entry->ut_host, MIN(16, strlen(entry->ut_host))), 0);
#endif

#ifdef HAS_UT_ADDR
   if (entry->ut_addr)
      hv_store(perl_hash, "ut_addr", 7,
	       newSVpv((char *) &entry->ut_addr, 4), 0);
   else
      hv_store(perl_hash, "ut_addr", 7, newSVpv("", 0), 0);
#endif

   return newRV_noinc((SV *) perl_hash);
}

#ifdef HAS_UTMPX
SV *utxent2perl(struct utmpx *entry)
{
   HV *perl_hash;
   HV *exit_hash;
   HV *time_hash;

   perl_hash = newHV();
   exit_hash = newHV();
   time_hash = newHV();

   /* The <utmpx.h> header shall define the utmpx structure that shall
    * include at least the following members:
    *
    * char            ut_user[]  User login name.
    * char            ut_id[]    Unspecified initialization process identifier.
    * char            ut_line[]  Device name.
    * pid_t           ut_pid     Process ID.
    * short           ut_type    Type of entry.
    * struct timeval  ut_tv      Time entry was made.
    */

   hv_store(perl_hash, "ut_user", 7,
	    newSVpv(entry->ut_user, MIN(sizeof(entry->ut_user),
					strlen(entry->ut_user))), 0);
   hv_store(perl_hash, "ut_id",   5,
	    newSVpv(entry->ut_id, MIN(sizeof(entry->ut_id),
				      strlen(entry->ut_id))), 0);
   hv_store(perl_hash, "ut_line", 7,
	    newSVpv(entry->ut_line, MIN(sizeof(entry->ut_line),
					strlen(entry->ut_line))), 0);
   hv_store(perl_hash, "ut_pid",  6, newSViv(entry->ut_pid), 0);
   hv_store(perl_hash, "ut_type", 7, newSViv(entry->ut_type), 0);
   hv_store(time_hash, "tv_sec",  6, newSViv(entry->ut_tv.tv_sec), 0);
   hv_store(time_hash, "tv_usec", 7, newSViv(entry->ut_tv.tv_usec), 0);
   hv_store(perl_hash, "ut_tv",   5, newRV_noinc((SV *) time_hash), 0);

   /* This is a "synthetic" field for compatibility with utmp */
   hv_store(perl_hash, "ut_time", 7, newSViv(entry->ut_tv.tv_sec), 0);

   /* Implementation-dependent extra fields */

#ifdef HAS_X_UT_EXIT
#ifdef __hpux
   hv_store(exit_hash, "e_exit", 6,  newSViv(entry->ut_exit.__e_exit), 0);
   hv_store(exit_hash, "e_termination", 13,
	    newSViv(entry->ut_exit.__e_termination), 0);
#else
   hv_store(exit_hash, "e_exit", 6,  newSViv(entry->ut_exit.e_exit), 0);
   hv_store(exit_hash, "e_termination", 13,
	    newSViv(entry->ut_exit.e_termination), 0);
#endif

   hv_store(perl_hash, "ut_exit", 7, newRV_noinc((SV *) exit_hash), 0);
#endif

#ifdef HAS_X_UT_HOST
#ifdef HAS_X_UT_SYSLEN
   hv_store(perl_hash, "ut_host", 7, newSVpv(entry->ut_host,
					     entry->ut_syslen + 1), 0);
#else
   hv_store(perl_hash, "ut_host", 7,
	    newSVpv(entry->ut_host, MIN(sizeof(entry->ut_host),
					strlen(entry->ut_host))), 0);
#endif
#endif

#ifdef HAS_X_UT_ADDR
   if (entry->ut_addr)
      hv_store(perl_hash, "ut_addr", 7,
	       newSVpv((char *) &entry->ut_addr, 4), 0);
   else
      hv_store(perl_hash, "ut_addr", 7, newSVpv("", 0), 0);
#endif

   return newRV_noinc((SV *) perl_hash);
}
#endif

void perl2utent(HV *entry, struct utmp *utent)
{
   HE    *hashentry;
   char  *key;
   SV    *val;
   I32    len;
   STRLEN strlen;

   hv_iterinit(entry);
   
   while ((hashentry = hv_iternext(entry)))
   {
      key = hv_iterkey(hashentry, &len);
      val = hv_iterval(entry, hashentry);

      if (strEQ(key, "ut_user"))
      {
	 char* c_val;
	    
	 c_val = SvPV(val, strlen);
	 strncpy(utent->ut_user, c_val, sizeof(utent->ut_user));
      }
      else if (strEQ(key, "ut_line"))
      {
	 char* c_val;

	 c_val = SvPV(val, strlen);
	 strncpy(utent->ut_line, c_val, sizeof(utent->ut_line));
      }
      else if (strEQ(key, "ut_time"))
      {
	 utent->ut_time = (time_t) SvIV(val);
      }

#ifdef HAS_UT_EXTENSIONS
      else if (strEQ(key, "ut_id"))
      {
	 char* c_val;

	 c_val = SvPV(val, strlen);
	 strncpy(utent->ut_id, c_val, sizeof(utent->ut_id));
      }
      else if (strEQ(key, "ut_pid"))
      {
	 utent->ut_pid = (pid_t) SvIV(val);
      }
      else if (strEQ(key, "ut_type"))
      {
	 utent->ut_type = (short) SvIV(val);
      }
      else if (strEQ(key, "ut_exit"))
      {
	 HE   *he;
	 char *localkey;
	 SV   *localval;

	 hv_iterinit((HV *) SvRV(val));
	 while ((he = hv_iternext((HV *) SvRV(val))))
	 {
	    localkey = hv_iterkey(he, &len);
	    localval = hv_iterval((HV *) SvRV(val), he);

	    if (strEQ(key, "e_termination"))
	    {
	       utent->ut_exit.e_termination = (short) SvIV(localval);
	    }
	    else if (strEQ(key, "e_exit"))
	    {
	       utent->ut_exit.e_exit = (short) SvIV(localval);
	    }
	 }
      }
#endif

#ifdef HAS_UT_HOST
      else if (strEQ(key, "ut_host"))
      {
	 char *c_val;
	    
	 c_val = SvPV(val, strlen);
	 strncpy(utent->ut_host, c_val, sizeof(utent->ut_host));
      }
#endif

#ifdef HAS_UT_ADDR
      else if (strEQ(key, "ut_addr"))
      {
	 memcpy(&utent->ut_addr, SvPV(val, strlen),
		MIN(sizeof(utent->ut_addr), strlen));
      }
#endif
   }
}

#ifdef HAS_UTMPX
void perl2utxent(HV *entry, struct utmpx *utent)
{
   HE    *hashentry;
   char  *key;
   SV    *val;
   I32    len;
   STRLEN strlen;

   /* Initialize the entry */

   strncpy(utent->ut_user, "", sizeof(utent->ut_user));
   strncpy(utent->ut_id,   "", sizeof(utent->ut_id));
   strncpy(utent->ut_line, "", sizeof(utent->ut_line));
   utent->ut_pid = 0;
   utent->ut_type = EMPTY;
   utent->ut_tv.tv_sec = time(NULL);
   utent->ut_tv.tv_usec = 0;

#ifdef HAS_X_UT_EXIT
#ifdef __hpux
   utent->ut_exit.__e_exit = 0;
   utent->ut_exit.__e_termination = 0;
#else
   utent->ut_exit.e_exit = 0;
   utent->ut_exit.e_termination = 0;
#endif
#endif

#ifdef HAS_X_UT_ADDR
   utent->ut_addr = 0;
#endif

#ifdef HAS_X_UT_HOST
   strncpy(utent->ut_host, "", sizeof(utent->ut_host));
#ifdef HAS_X_UT_SYSLEN
   utent->ut_syslen = 0;
#endif
#endif

   hv_iterinit(entry);
   
   while ((hashentry = hv_iternext(entry)))
   {
      key = hv_iterkey(hashentry, &len);
      val = hv_iterval(entry, hashentry);

      if (strEQ(key, "ut_user"))
      {
	 char* c_val;
	    
	 c_val = SvPV(val, strlen);
	 strncpy(utent->ut_name, c_val, sizeof(utent->ut_name));
      }
      else if (strEQ(key, "ut_id"))
      {
	 char* c_val;

	 c_val = SvPV(val, strlen);
	 strncpy(utent->ut_id, c_val, sizeof(utent->ut_id));
      }
      else if (strEQ(key, "ut_line"))
      {
	 char* c_val;

	 c_val = SvPV(val, strlen);
	 strncpy(utent->ut_line, c_val, sizeof(utent->ut_line));
      }
      else if (strEQ(key, "ut_pid"))
      {
	 if (SvOK(val))
	    utent->ut_pid = (pid_t) SvIV(val);
	 else
	    utent->ut_pid = (pid_t) NULL;
      }
      else if (strEQ(key, "ut_type"))
      {
	 if (SvOK(val))
	    utent->ut_type = (short) SvIV(val);
	 else
	    utent->ut_type = (short) NULL;
      }
      else if (strEQ(key, "ut_tv"))
      {
	 SV **sec;
	 SV **usec;
	 HV *tv_hash;

	 if (SvROK(val))
	 {
	    if (SvTYPE(SvRV(val)) == SVt_PVHV)
	    {
	       tv_hash = (HV *)SvRV(val);

	       if (hv_exists(tv_hash, "tv_sec", 6))
	       {
		  sec  = hv_fetch(tv_hash, "tv_sec", 6, FALSE);
		  if (SvOK(*sec))
		     utent->ut_tv.tv_sec  = (time_t) SvIV(*sec);
	       }

	       if (hv_exists(tv_hash, "tv_usec", 7))
	       {
		  usec = hv_fetch(tv_hash, "tv_usec", 7, FALSE);
		  if (SvOK(*usec))
		     utent->ut_tv.tv_usec = (long) SvIV(*usec);
	       }
	    }
	 }
      }

      else if (strEQ(key, "ut_time"))
      {
	 utent->ut_tv.tv_sec = (time_t) SvIV(val);
	 utent->ut_tv.tv_usec = (long) 0;
      }

#ifdef HAS_X_UT_EXIT
      else if (strEQ(key, "ut_exit"))
      {
	 SV **exit;
	 SV **term;
	 HV *exit_hash;

	 if (SvROK(val))
	 {
	    if (SvTYPE(SvRV(val)) == SVt_PVHV)
	    {
	       exit_hash = (HV *)SvRV(val);

	       if (hv_exists(exit_hash, "e_exit", 6))
	       {
		  exit  = hv_fetch(exit_hash, "e_exit", 6, FALSE);
		  if (SvOK(*exit))
#ifdef __hpux
		     utent->ut_exit.__e_exit = (short) SvIV(*exit);
#else
		     utent->ut_exit.e_exit = (short) SvIV(*exit);
#endif
	       }

	       if (hv_exists(exit_hash, "e_termination", 13))
	       {
		  term = hv_fetch(exit_hash, "e_termination", 13, FALSE);
		  if (SvOK(*term))
#ifdef __hpux
		     utent->ut_exit.__e_termination = (long) SvIV(*term);
#else
		     utent->ut_exit.e_termination = (long) SvIV(*term);
#endif
	       }
	    }
	 }
      }
#endif

#ifdef HAS_X_UT_HOST
      if (strEQ(key, "ut_host"))
      {
	 char* c_val;

	 c_val = SvPV(val, strlen);
	 strncpy(utent->ut_host, c_val, sizeof(utent->ut_host));
      }
#endif
   }
}
#endif

MODULE = User::Utmp		PACKAGE = User::Utmp		

PROTOTYPES: ENABLE

double
constant(name,arg)
   char * name
   int    arg

char *
UTMP_FILE()
   CODE:
# if defined (UTMP_FILE)
     RETVAL = UTMP_FILE;
# elif defined (_UTMP_FILE)
     RETVAL = _UTMP_FILE;
# elif defined (_PATH_UTMP)
     RETVAL = _PATH_UTMP;
# else
     croak("Your vendor has not defined the User::Utmp macro UTMP_FILE");
# endif

   OUTPUT:
     RETVAL

char *
WTMP_FILE()
   CODE:
# if defined (WTMP_FILE)
     RETVAL = WTMP_FILE;
# elif defined (_WTMP_FILE)
     RETVAL = _WTMP_FILE;
# elif defined (_PATH_WTMP)
     RETVAL = _PATH_WTMP;
# else
     croak("Your vendor has not defined the User::Utmp macro WTMP_FILE");
# endif

   OUTPUT:
     RETVAL

#ifdef HAS_UTMPX
char *
UTMPX_FILE()
   CODE:
# if defined (UTMPX_FILE)
     RETVAL = UTMPX_FILE;
# elif defined (_UTMPX_FILE)
     RETVAL = _UTMPX_FILE;
# elif defined (_PATH_UTMPX)
     RETVAL = _PATH_UTMPX;
# else
     croak("Your vendor has not defined the User::Utmp macro UTMPX_FILE");
# endif

   OUTPUT:
     RETVAL

char *
WTMPX_FILE()
   CODE:
# if defined (WTMPX_FILE)
     RETVAL = WTMPX_FILE;
# elif defined (_WTMPX_FILE)
     RETVAL = _WTMPX_FILE;
# elif defined (_PATH_WTMPX)
     RETVAL = _PATH_WTMPX;
# else
     croak("Your vendor has not defined the User::Utmp macro WTMPX_FILE");
# endif

   OUTPUT:
     RETVAL

#endif

void
setutent()
   CODE:
      setutent();

void
endutent()
   CODE:
      endutent();

#ifdef HAS_GETUTID

SV*
getutid(type, id = NULL)
   short type
   char *id
   PREINIT:
      struct utmp query;
      struct utmp *entry;
   CODE:
      query.ut_type = type;
      if (id != NULL)
      {
	 strncpy(query.ut_id, id, sizeof(entry->ut_id));
      }
      entry = getutid(&query);

      if (entry == NULL)
      {
	 RETVAL = &PL_sv_undef;
      }
      else
	 RETVAL = utent2perl(entry);
   OUTPUT:
      RETVAL

#endif

#ifdef HAS_GETUTLINE
SV*
getutline(line)
   char *line
   PREINIT:
      struct utmp query;
      struct utmp *entry;
   CODE:
      strncpy(query.ut_line, line, sizeof(entry->ut_line));
      entry = getutline(&query);

      if (entry == NULL)
	 RETVAL = &PL_sv_undef;
      else
	 RETVAL = utent2perl(entry);
   OUTPUT:
      RETVAL

#endif

SV*
getutent()
   PREINIT:
      struct utmp *entry;
   CODE:
      entry = getutent();

      if (entry == NULL)
      {
	 RETVAL = &PL_sv_undef;
      }
      else
	 RETVAL = utent2perl(entry);
   OUTPUT:
      RETVAL

void
getut()
   PREINIT:
      struct utmp *entry;
   PPCODE:
      setutent();
      while ((entry = getutent()))
      {
	 XPUSHs(sv_2mortal(utent2perl(entry)));
      }
      endutent();

#ifdef HAS_PUTUTLINE
SV*
pututline(perl_hash)
   SV *perl_hash
   PREINIT:
      struct utmp entry;
      struct utmp *ret;
   CODE:
      perl2utent((HV *) SvRV(perl_hash), &entry);
#ifdef __hpux
      ret = _pututline(&entry);
#else
      ret = pututline(&entry);
#endif
      if (ret == NULL)
	 RETVAL = &PL_sv_undef;
      else
	 RETVAL = utent2perl(ret);
   OUTPUT:
      RETVAL

#endif

int
utmpname(utmp_file)
   char *utmp_file
   CODE:
#ifdef HAS_UTMPNAME
     RETVAL = utmpname(utmp_file);
#else
     RETVAL = not_here("utmpname");
#endif
   OUTPUT:
     RETVAL


#ifdef HAS_UTMPX
void
setutxent()
   CODE:
      setutxent();

void
endutxent()
   CODE:
      endutxent();

SV*
getutxid(type, id = NULL)
   short type
   char *id
   PREINIT:
      struct utmpx query;
      struct utmpx *entry;
   CODE:
      query.ut_type = type;
      if (id != NULL)
      {
	 strncpy(query.ut_id, id, sizeof(entry->ut_id));
      }
      entry = getutxid(&query);

      if (entry == NULL)
      {
	 RETVAL = &PL_sv_undef;
      }
      else
	 RETVAL = utxent2perl(entry);
   OUTPUT:
      RETVAL

SV*
getutxline(line)
   char *line
   PREINIT:
      struct utmpx query;
      struct utmpx *entry;
   CODE:
      strncpy(query.ut_line, line, sizeof(entry->ut_line));
      entry = getutxline(&query);

      if (entry == NULL)
      {
	 RETVAL = &PL_sv_undef;
      }
      else
	 RETVAL = utxent2perl(entry);
   OUTPUT:
      RETVAL

SV*
getutxent()
   PREINIT:
      struct utmpx *entry;
   CODE:
      entry = getutxent();

      if (entry == NULL)
      {
	 RETVAL = &PL_sv_undef;
      }
      else
	 RETVAL = utxent2perl(entry);
   OUTPUT:
      RETVAL

void
getutx()
   PREINIT:
      struct utmpx *entry;
   PPCODE:
      setutxent();
      while ((entry = getutxent()))
      {
	 XPUSHs(sv_2mortal(utxent2perl(entry)));
      }
      endutxent();

SV*
pututxline(perl_hash)
   SV *perl_hash
   PREINIT:
      struct utmpx entry;
      struct utmpx *ret;
   CODE:
      perl2utxent((HV *) SvRV(perl_hash), &entry);
      ret = pututxline(&entry);
      if (ret == NULL)
	 RETVAL = &PL_sv_undef;
      else
	 RETVAL = utxent2perl(ret);
   OUTPUT:
      RETVAL

#ifdef HAS_UTMPXNAME
int
utmpxname(utmp_file)
   char *utmp_file
   PREINIT:
     size_t len;
   CODE:
#ifdef __hpux
     len = strlen(utmp_file);

     if (utmp_file[len - 1] == 'x')
     {
	char *fname;
	Newz(0, fname, len, char);
	(void) strncpy(fname, utmp_file, len - 1);
	RETVAL = utmpname(fname);
	Safefree(fname);
     }
     else
	RETVAL = utmpname(utmp_file);
#else
     RETVAL = utmpxname(utmp_file);
#endif

   OUTPUT:
     RETVAL

#endif

#endif
