/* -*-C-*-
 * $Id: DBlib.xs,v 1.61 2005/03/20 19:50:59 mpeppler Exp $
 *
 * From
 *	@(#)DBlib.xs	1.47	03/26/99
 */	


/* Copyright (c) 1991-2001
   Michael Peppler

   You may copy this under the terms of the GNU General Public License,
   or the Artistic License, copies of which should have accompanied
   your Perl kit. */
 
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

/* Defines needed for perl 5.005 / threading */

#if defined(op)
#undef op
#endif
#if !defined(dTHR)
#define dTHR	extern int errno
#endif

#include "patchlevel.h"		/* This is the perl patchlevel.h */
#if PATCHLEVEL < 5 && SUBVERSION < 5

#define PL_na na
#define PL_sv_undef sv_undef
#define PL_dirty dirty

#endif

#ifdef TDS_DBOPEN_HACK
#define dbopen(a,b) tdsdbopen((a), (b))
#endif


#include <sybfront.h>
#include <sybdb.h>
#include <syberror.h>

#if !defined(_CPROTO_) && ! defined(CS_PUBLIC)
#define CS_PUBLIC
#endif

#if !defined(DBLIBVS)
#define DBLIBVS		400
#endif

/* This is the amount of buffer storage we use in dbnextrow/dbgetdata */
/* The 520 comes from VARBINARY(256)=>512 chars + some extra space */
#define MAX_BUFF_SIZE	520

#if !defined(DBSETLCHARSET)
#define DBSETLCHARSET(a,c)	not_here("DBSETLCHARSET")
#endif
#if !defined(DBSETLNATLANG)
#define DBSETLNATLANG(a,c)	not_here("DBSETLNATLANG")
#endif
#if !defined(DBGETTIME)
#define DBGETTIME()		not_here("DBGETTIME")
#endif
#if !defined(DBSETLPACKET)
#define DBSETLPACKET(l, i)		not_here("DBSETLPACKET")
#endif

#if DBLIBVS < 1000
#define dbsetversion(s)		not_here("dbsetversion")
#define dbsetdefcharset(s)	not_here("dbsetdefcharset")
#define dbsetdeflang(s)		not_here("dbsetdeflang")
#if DBLIBVS < 461
#define new_mnytochar(a, b, c)  not_here("new_mnytochar")
#define new_mny4tochar(a,b,c)   not_here("new_mny4tochar")
#define bcp_getl(a)		not_here("bcp_getl")
#define dbsettime(t)		not_here("dbsettime")
#define dbsetlogintime(t)	not_here("dbsetlogintime")
#define dbmnymaxpos(a,b)	not_here("dbmnymaxpos")
#define dbmnymaxneg(a,b)	not_here("dbmnymaxneg")
#define dbmnyndigit(a,b,c,d)	not_here("dbmnyndigit")
#define dbmnyscale(a,b,c,d)	not_here("dbmnyscale")
#define dbmnyinit(a,b,c,d)	not_here("dbmnyinit")
#define dbmnydown(a,b,c,d)	not_here("dbmonydown")
#define dbmnyinc(a,b) 		not_here("dbmnyinc")
#define dbmnydec(a,b)		not_here("dbmnydec")
#define dbmnyzero(a,b)		not_here("dbmnyzero")
#define dbmnycmp(a,b,c)		not_here("dbmnycmp")
#define dbmnysub(a,b,c,d)	not_here("dbmnysub")
#define dbmnymul(a,b,c,d)	not_here("dbmnymul")
#define dbmnyminus(a,b,c)	not_here("dbmnyminus")
#define dbmnydivide(a,b,c,d)	not_here("dbmnydivide")
#define dbmnyadd(a,b,c,d)	not_here("dbmnyadd")
#define dbmny4zero(a,b)		not_here("dbmny4zero")
#define dbmny4cmp(a,b,c)	not_here("dbmny4cmp")
#define dbmny4sub(a,b,c,d)	not_here("dbmny4sub")
#define dbmny4mul(a,b,c,d)	not_here("dbmny4mul")
#define dbmny4minus(a,b,c)	not_here("dbmny4minus")
#define dbmny4divide(a,b,c,d)	not_here("dbmny4divide")
#define dbmny4add(a,b,c,d)	not_here("dbmny4add")
#if !defined(DBMONEY4)
#define DBMONEY4		DBMONEY
#define SYBMONEY4		SYBMONEY /* don't know if this is necessary */
#endif /* !defined(DBMONEY4) */
#if DBLIBVS < 420
#define dbrecftos(s)		not_here("dbrecftos")
#define dbsafestr(a,b,c,d,e,f)	not_here("dbsafestr")
#define dbversion()		"4.00"
#define dbdatecmp(a, b, c)	not_here("dbdatecmp");
#ifndef DBDOUBLE
#define DBDOUBLE	1
#endif
#ifndef DBSINGLE
#define DBSINGLE	0
#endif
#ifndef DBBOTH
#define DBBOTH	2
typedef struct daterec
{
	DBINT		dateyear;	/* 1900 to the future */
	DBINT		datemonth;	/* 0 - 11 */
	DBINT		datedmonth;	/* 1 - 31 */
	DBINT		datedyear;	/* 1 - 366 */
	DBINT		datedweek;	/* 0 - 6 (Mon. - Sun.) */
	DBINT		datehour;	/* 0 - 23 */
	DBINT		dateminute;	/* 0 - 59 */
	DBINT		datesecond;	/* 0 - 59 */
	DBINT		datemsecond;	/* 0 - 997 */
	DBINT		datetzone;	/* 0 - 127 */
} DBDATEREC;
#endif
#endif /* DBLIBVS < 420 */
#endif /* DBLIBVS < 461 */
#endif /* DBLIBVS < 1000 */

#if !defined(DBMAXNAME)
#define DBMAXNAME          MAXNAME
#endif

typedef enum hash_key_id
{
    HV_compute_id,
    HV_dbstatus,
    HV_nullundef,
    HV_keepnum,
    HV_bin0x,
    HV_use_datetime,
    HV_use_money,
    HV_max_rows,
    HV_pid,
    HV_dbproc
} hash_key_id;

static struct _hash_keys {
    char *key;
    int  id;
} hash_keys[] = {
    { "ComputeID",       HV_compute_id },
    { "DBstatus",        HV_dbstatus },
    { "dbNullIsUndef",   HV_nullundef },
    { "dbKeepNumeric",   HV_keepnum },
    { "dbBin0x",         HV_bin0x },
    { "UseDateTime",     HV_use_datetime },
    { "UseMoney",        HV_use_money },
    { "MaxRows",         HV_max_rows },
    { "__PID__",         HV_pid },
    { "dbproc",          HV_dbproc },
    { "",                -1 }
};

struct RpcInfo
{
    int type;
    union {
	DBINT i;
	DBFLT8 f;
	DBCHAR *c;
    } u;
    int size;
    void *value;
    struct RpcInfo *next;
};

typedef struct bcp_data {
    int numcols;
    BYTE **colPtr;
} BCP_DATA;

struct attribs {
    int ComputeID;
    int DBstatus;
    int dbNullIsUndef;
    int dbKeepNumeric;
    int dbBin0x;
    int UseDateTime;
    int UseMoney;
    int MaxRows;
    int pid;
    HV *other;
};

typedef struct {
    DBPROCESS *dbproc;
    struct RpcInfo *rpcInfo;
    BCP_DATA *bcp_data;

    int numCols;
    
    AV *av;
    HV *hv;

    struct attribs attr;
} ConInfo;




typedef struct {
    DBPROCESS *dbproc;
    DBDATETIME date;
} DateTime;

typedef struct {
    DBPROCESS *dbproc;
    DBMONEY mn;
} Money;

/* Call back stuff has been borrowed from DB_File.xs */
typedef struct
{
    SV *	sub ;
} CallBackInfo ;

static CallBackInfo err_callback 	= { 0 } ;
static CallBackInfo msg_callback 	= { 0 } ;

static int dbexit_called;

/* Debugging/tracing: */
#define TRACE_NONE	(0)
#define TRACE_DESTROY	(1 << 0)
#define TRACE_CREATE	(1 << 1)
#define TRACE_RESULTS	(1 << 2)
#define TRACE_FETCH	(1 << 3)
#define TRACE_CURSOR	(1 << 4)
#define TRACE_PARAMS	(1 << 5)
#define TRACE_OVERLOAD  (1 << 6)
#define TRACE_SQL	(1 << 7)
#define TRACE_ALL	((unsigned int)(~0))
static unsigned int debug_level = TRACE_NONE;

static char DateTimePkg[]="Sybase::DBlib::DateTime";
static char MoneyPkg[]="Sybase::DBlib::Money";

static LOGINREC *syb_login;

static int attr_store _((ConInfo*, char*, int, SV*, int));
static SV* attr_fetch _((ConInfo*, char*, int));
static SV *newdbh _((ConInfo *, char *, SV*));
static ConInfo *get_ConInfoFromMagic _((HV*));
static ConInfo *get_ConInfo _((SV*));
static DBPROCESS *getDBPROC _((SV*));
static char *neatsvpv _((SV*, STRLEN));
static DateTime to_datetime _((char*));
static char *from_datetime _((DateTime*));
static SV *newdate _((DBPROCESS*, DBDATETIME*));
static Money to_money _((char*));
static char *from_money _((Money*));
static double money2float _((Money*));
static SV *newmoney _((DBPROCESS*, DBMONEY*));
static int CS_PUBLIC err_handler _((DBPROCESS*, int, int, int, char*, char*));
static int CS_PUBLIC msg_handler _((DBPROCESS*, DBINT, int, int, char*, char*, char*, int));
static void initialize _((void));
#if DBLIBVS >= 461
static void new_mny4tochar _((DBPROCESS*, DBMONEY4*, DBCHAR*));
static void new_mnytochar _((DBPROCESS*, DBMONEY*, DBCHAR*));
#endif
static int not_here _((char*));
static double constant _((char*, int));


/* A couple of simplified calls for our own use... */

static SV*
attr_fetch(info, key, keylen)
    ConInfo *info;
    char *key;
    int keylen;
{
    int i;
    SV *sv = Nullsv;
    
    for(i = 0; hash_keys[i].id >= 0; ++i)
	if(strlen(hash_keys[i].key) == keylen && strEQ(key, hash_keys[i].key))
	    break;

    if(hash_keys[i].id < 0) {
	SV **svp;
#if defined(DO_TIE)
	if(!hv_exists(info->attr.other, key, keylen)) {
	    warn("'%s' is not a valid Sybase::DBlib attribute", key);
	    return Nullsv;
	}
#endif
	svp = hv_fetch(info->attr.other, key, keylen, 0);
	return svp ? *svp : Nullsv;
    }

    switch(hash_keys[i].id) {
      case HV_compute_id:
	  sv = newSViv(info->attr.ComputeID);
	  break;
      case HV_dbstatus:
	  sv = newSViv(info->attr.DBstatus);
	  break;
      case HV_nullundef:
	  sv = newSViv(info->attr.dbNullIsUndef);
	  break;
      case HV_keepnum:
	  sv = newSViv(info->attr.dbKeepNumeric);
          break;
      case HV_bin0x:
	  sv = newSViv(info->attr.dbBin0x);
	  break;
      case HV_use_datetime:
	  sv = newSViv(info->attr.UseDateTime);
	  break;
      case HV_use_money:
	  sv = newSViv(info->attr.UseMoney);
	  break;
      case HV_max_rows:
	  sv = newSViv(info->attr.MaxRows);
	  break;
      case HV_pid:
	  sv = newSViv(info->attr.pid);
	  break;
      default:
	  return Nullsv;
    }

    return sv_2mortal(sv);
}

static int
attr_store(info, key, keylen, sv, flag)
    ConInfo *info;
    char *key;
    int keylen;
    SV *sv;
    int flag;
{
    int i;
    
    for(i = 0; hash_keys[i].id >= 0; ++i)
	if(strlen(hash_keys[i].key) == keylen && strEQ(key, hash_keys[i].key))
	    break;

    if(hash_keys[i].id < 0) {
#if defined(DO_TIE)
	if(!flag) {
	    if(!hv_exists(info->attr.other, key, keylen)) {
		warn("'%s' is not a valid Sybase::DBlib attribute", key);
		return 0;
	    }
	}
#endif
	hv_store(info->attr.other, key, keylen, newSVsv(sv), 0);
	return 1;
    }

    switch(hash_keys[i].id) {
      case HV_compute_id:
	  info->attr.ComputeID      = SvIV(sv);
	  break;
      case HV_dbstatus:
	  info->attr.DBstatus      = SvIV(sv);
	  break;
      case HV_nullundef:
	  info->attr.dbNullIsUndef = SvTRUE(sv);
	  break;
      case HV_keepnum:
	  info->attr.dbKeepNumeric = SvTRUE(sv);
          break;
      case HV_bin0x:
	  info->attr.dbBin0x       = SvTRUE(sv);
	  break;
      case HV_use_datetime:
	  info->attr.UseDateTime   = SvTRUE(sv);
	  break;
      case HV_use_money:
	  info->attr.UseMoney      = SvTRUE(sv);
	  break;
      case HV_max_rows:
	  info->attr.MaxRows       = SvIV(sv);
	  break;
      case HV_pid:
	  info->attr.pid           = SvIV(sv);
	  break;
      default:
	  return 0;
    }

    return 1;
}

static SV *
newdbh(info, package, attr_ref)
    ConInfo *info;
    char *package;
    SV *attr_ref;
{
    HV *hv, *thv, *stash, *Att;
    SV *rv, *sv, **svp;
    
    info->attr.other = newHV();
    info->av = newAV();
    info->hv = newHV();
    
    thv = (HV*)sv_2mortal((SV*)newHV());

    if((attr_ref != &PL_sv_undef)) {
	if(!SvROK(attr_ref))
	    warn("Attributes parameter is not a reference");
	else
	{
	    char *key;
	    I32 klen;
	    hv = (HV*)SvRV(attr_ref);
	    hv_iterinit(hv);
	    while((sv = hv_iternextsv(hv, &key, &klen)))
		attr_store(info, key, klen, sv, 1);
	}
    }
	    
    if((Att = perl_get_hv("Sybase::DBlib::Att", FALSE)))
    {
	if((svp = hv_fetch(Att, hash_keys[HV_use_datetime].key,
			   strlen(hash_keys[HV_use_datetime].key), 0)))
	    info->attr.UseDateTime = SvTRUE(*svp);
	else
	    info->attr.UseDateTime = 0;
	if((svp = hv_fetch(Att, hash_keys[HV_use_money].key,
			   strlen(hash_keys[HV_use_money].key), 0)))
	    info->attr.UseMoney = SvTRUE(*svp);
	else
	    info->attr.UseMoney = 0;
	if((svp = hv_fetch(Att, hash_keys[HV_max_rows].key,
			   strlen(hash_keys[HV_max_rows].key), 0)))
	    info->attr.MaxRows = SvIV(*svp);
	else
	    info->attr.MaxRows = 0;
	if((svp = hv_fetch(Att, hash_keys[HV_keepnum].key,
			   strlen(hash_keys[HV_keepnum].key), 0)))
	    info->attr.dbKeepNumeric = SvTRUE(*svp);
	else
	    info->attr.dbKeepNumeric = 0;
	if((svp = hv_fetch(Att, hash_keys[HV_nullundef].key,
			   strlen(hash_keys[HV_nullundef].key), 0)))
	    info->attr.dbNullIsUndef = SvTRUE(*svp);
	else
	    info->attr.dbNullIsUndef = 0;
	if((svp = hv_fetch(Att, hash_keys[HV_bin0x].key,
			   strlen(hash_keys[HV_bin0x].key), 0)))
	    info->attr.dbBin0x = SvTRUE(*svp);
	else
	    info->attr.dbBin0x = 0;
    }
    else
    {
	warn("Couldn't find %Att hash");
	info->attr.UseDateTime = 0;
	info->attr.UseMoney = 0;
	info->attr.MaxRows = 0;
	info->attr.dbKeepNumeric = 0;
	info->attr.dbNullIsUndef = 0;
	info->attr.dbBin0x = 0;
    }
    info->attr.DBstatus = 0;
    info->attr.ComputeID = 0;
    info->rpcInfo = NULL;
    info->attr.pid = getpid();
    info->numCols = -1;


    /* FIXME
       This creates a small memory leak, because the tied _attribs hash
       does not get automatically destroyed when the dbhandle goes out of
       scope. */
    sv = newSViv((IV)info);
    sv_magic((SV*)thv, sv, '~', "DBlib", 5);
    SvRMAGICAL_on((SV*)thv);

    rv = newRV((SV*)thv);
    stash = gv_stashpv("Sybase::DBlib::_attribs", TRUE);
    (void)sv_bless(rv, stash);
    hv = (HV*)sv_2mortal((SV*)newHV());

    sv_magic((SV*)hv, sv, '~', "DBlib", 5);
    /* Turn on the 'tie' magic */
    sv_magic((SV*)hv, rv, 'P', Nullch, 0);

    SvRMAGICAL_on((SV*)hv);

    dbsetuserdata(info->dbproc, (BYTE*)hv);

    rv = newRV((SV*)hv);
    stash = gv_stashpv(package, TRUE);
    sv = sv_bless(rv, stash);
    return sv;
}

static ConInfo *
get_ConInfoFromMagic(hv)
    HV *hv;
{
    dTHR;
    ConInfo *info = NULL;
    IV i;
    MAGIC *m;

    m = mg_find((SV*)hv, '~');
    if(!m) {
	if(PL_dirty)		/* Flag only if not in global destruction */
	    return NULL;

	croak("no connection key in hash");
    }

    /* When doing global destruction, the tied _attribs hash gets freed
       before we get here. The statement below causes the program to exit
       under the debugger. */
    if((i = SvIV(m->mg_obj)) != 0)
	info = (void *)i;
    return info;
}

static ConInfo *
get_ConInfo(dbp)
    SV *dbp;
{
    ConInfo *info;
    dTHR;
    
    if(!SvROK(dbp))
	croak("connection parameter is not a reference");
    info = get_ConInfoFromMagic((HV *)SvRV(dbp));

    return info;
}

static DBPROCESS *
getDBPROC(dbp)
    SV *dbp;
{
    ConInfo *conInfo;
    dTHR;

    conInfo = get_ConInfo(dbp);
    if(conInfo)
	return conInfo->dbproc;

    return NULL;
}

/* Borrowed/adapted from DBI.xs */

static char *
neatsvpv(sv, maxlen) /* return a tidy ascii value, for debugging only */
    SV * sv;
    STRLEN maxlen;
{
    STRLEN len;
    SV *nsv = NULL;
    char *v;
    int is_ovl = 0;
    
    if (!sv)
	return "NULL";
    
    /* If this sv is a ref with overload magic, we need to turn it off
       before calling SvPV() so that the package name is returned, not
       the content. */
    if(SvROK(sv) && (is_ovl = SvAMAGIC(sv)))
	SvAMAGIC_off(sv);
    v = (SvOK(sv)) ? SvPV(sv,len) : "undef";
    if(is_ovl)
	SvAMAGIC_on(sv);
    /* undef and numbers get no special treatment */
    if (!SvOK(sv) || SvIOK(sv) || SvNOK(sv))
	return v;
    if (SvROK(sv))
	return v;

	
    /* for strings we limit the length and translate codes */
    nsv = sv_2mortal(newSVpv("'",1));
    if (maxlen == 0)
	maxlen = 64; /* FIXME */
    if (len > maxlen)
    {
	sv_catpvn(nsv, v, maxlen);
	sv_catpv( nsv, "...");
    }
    else
    {
	sv_catpvn(nsv, v, len);
	sv_catpv( nsv, "'");
    }
    v = SvPV(nsv, len);
    while(len-- > 0)
    { /* cleanup string (map control chars to ascii etc) */
	if (!isprint(v[len]) && !isspace(v[len]))
	    v[len] = '.';
    }
    return v;
}

static DateTime
to_datetime(str)
    char *str;
{
    DateTime dt;
    
    memset(&dt, 0, sizeof(dt));

    if(!str)
	return dt;
    
    if (dbconvert(NULL, SYBCHAR, (BYTE*)str, -1, SYBDATETIME,
		  (BYTE*)&dt.date, -1) != sizeof(DBDATETIME))
	warn("dbconvert failed (to_datetime(%s))", str);
    
    return dt;
}

static char *
from_datetime(dt)
    DateTime *dt;
{
    static char buff[256];
    
    if (dbconvert(dt->dbproc, SYBDATETIME, (BYTE*)&dt->date, sizeof(DBDATETIME),
		  SYBCHAR, (BYTE *)buff, -1) > 0)
	return buff;
    
    return NULL;
}


static SV *
newdate(dbproc, dt)
    DBPROCESS *dbproc;
    DBDATETIME *dt;
{
    SV *sv;
    DateTime *ptr;
    char *package=DateTimePkg;

    New(902, ptr, 1, DateTime);

    ptr->dbproc = dbproc;
    if(dt)
	ptr->date = *(DBDATETIME *)dt;
    else
    {
	/* According to the Sybase docs I can initialize the
           DBDATETIME entry to be Jan 1 1900 00:00 by setting all the
           fields to 0. */
	memset(&ptr->date, 0, sizeof(DBDATETIME));
    }
    sv = newSV(0);
    sv_setref_pv(sv, package, (void*)ptr);
    
    if(debug_level & TRACE_CREATE)
	warn("Created %s", neatsvpv(sv, 0));
    
    return sv;
}

static Money
to_money(str)
    char *str;
{
    Money m;
    
    memset(&m, 0, sizeof(m));

    if(!str)
	return m;
    
    if (dbconvert(NULL, SYBCHAR, (BYTE*)str, -1, SYBMONEY,
		  (BYTE*)&m.mn, -1) != sizeof(DBMONEY))
	warn("dbconvert failed (to_money(%s))", str);
    
    return m;
}

static char *
from_money(m)
    Money *m;
{
    static char buff[256];
    
    if (dbconvert(m->dbproc, SYBMONEY, (BYTE*)&m->mn, sizeof(DBMONEY),
		  SYBCHAR, (BYTE*)buff, -1) > 0)
	return buff;
    
    return NULL;
}

static double
money2float(m)
    Money *m;
{
    double f;
    
    if (dbconvert(m->dbproc, SYBMONEY, (BYTE*)&m->mn, sizeof(DBMONEY),
		  SYBFLT8, (BYTE*)&f, -1) > 0)
	return f;
    
    return 0.0;
}

static SV *
newmoney(dbproc, mn)
    DBPROCESS *dbproc;
    DBMONEY *mn;
{
    SV *sv;
    Money *ptr;
    char *package=MoneyPkg;

    New(902, ptr, 1, Money);

    ptr->dbproc = dbproc;
    if(mn)
	ptr->mn = *(DBMONEY *)mn;
    else
	memset(&ptr->mn, 0, sizeof(DBMONEY));

    sv = newSV(0);
    sv_setref_pv(sv, package, (void*)ptr);
    
    if(debug_level & TRACE_CREATE)
	warn("Created %s", neatsvpv(sv, 0));
    
    return sv;
}

static int CS_PUBLIC err_handler(db, severity, dberr, oserr, dberrstr, oserrstr)
    DBPROCESS *db;
    int severity;
    int dberr;
    int oserr;
    char *dberrstr;
    char *oserrstr;
{
    dTHR;

    if(err_callback.sub)	/* a perl error handler has been installed */
    {
	dSP;
	SV *rv;
	SV *sv;
	HV *hv;
	int retval, count;

	ENTER;
	SAVETMPS;
	PUSHMARK(sp);
	
	if(db && (hv = (HV*)dbgetuserdata(db)))
	{
	    rv = newRV((SV*)hv);
		
	    XPUSHs(sv_2mortal(rv));
	}
	else
	    XPUSHs(&PL_sv_undef);
	    
	XPUSHs(sv_2mortal (newSViv (severity)));
	XPUSHs(sv_2mortal (newSViv (dberr)));
	XPUSHs(sv_2mortal (newSViv (oserr)));
	if (dberrstr && *dberrstr)
	    XPUSHs(sv_2mortal (newSVpv (dberrstr, 0)));
	else
	    XPUSHs(&PL_sv_undef);
	if (oserrstr && *oserrstr)
	    XPUSHs(sv_2mortal (newSVpv (oserrstr, 0)));
	else
	    XPUSHs(&PL_sv_undef);

	PUTBACK;
	if((count = perl_call_sv(err_callback.sub, G_SCALAR)) != 1)
	    croak("An error handler can't return a LIST.");
	SPAGAIN;
	retval = POPi;
	
	PUTBACK;
	FREETMPS;
	LEAVE;
	
	return retval;
    }
    
    fprintf(stderr,"DB-Library error:\n\t%s\n", dberrstr);
	
    if (oserr != DBNOERR)
	fprintf(stderr,"Operating-system error:\n\t%s\n", oserrstr);
    
    return(INT_CANCEL);
}

static int CS_PUBLIC msg_handler(db, msgno, msgstate, severity, msgtext, srvname, procname, line)
    DBPROCESS *db;
    DBINT msgno;
    int msgstate;
    int severity;
    char *msgtext;
    char *srvname;
    char *procname;
    int line;
{
    dTHR;

    if(msg_callback.sub)	/* a perl error handler has been installed */
    {
	dSP;
	SV * rv;
	SV * sv;
	HV * hv;
	int retval, count;

	ENTER;
	SAVETMPS;
	PUSHMARK(sp);

	if(db && (hv = (HV*)dbgetuserdata(db)))	/* FIXME */
	{
	    rv = newRV((SV*)hv);
	
	    XPUSHs(sv_2mortal(rv));
	}
	else
	    XPUSHs(&PL_sv_undef);

	XPUSHs(sv_2mortal (newSViv (msgno)));
	XPUSHs(sv_2mortal (newSViv (msgstate)));
	XPUSHs(sv_2mortal (newSViv (severity)));
	if (msgtext && *msgtext)
	    XPUSHs(sv_2mortal (newSVpv (msgtext, 0)));
	else
	    XPUSHs(&PL_sv_undef);
	if (srvname && *srvname)
	    XPUSHs(sv_2mortal (newSVpv (srvname, 0)));
	else
	    XPUSHs(&PL_sv_undef);
	if (procname && *procname)
	    XPUSHs(sv_2mortal (newSVpv (procname, 0)));
	else
	    XPUSHs(&PL_sv_undef);
	XPUSHs(sv_2mortal (newSViv (line)));

	PUTBACK;
	if((count = perl_call_sv(msg_callback.sub, G_SCALAR)) != 1)
	    croak("A msg handler cannot return a LIST");
	SPAGAIN;
	retval = POPi;
	
	PUTBACK;
	FREETMPS;
	LEAVE;
	
	return retval;
    }
    
    /* Don't print any message if severity == 0 */
    if(!severity)
	return 0;

    fprintf (stderr,"Msg %ld, Level %d, State %d\n", 
	     msgno, severity, msgstate);
    if ((int)strlen(srvname) > 0)
	fprintf (stderr,"Server '%s', ", srvname);
    if ((int)strlen(procname) > 0)
	fprintf (stderr,"Procedure '%s', ", procname);
    if (line > 0)
	fprintf (stderr,"Line %d", line);
    
    fprintf(stderr,"\n\t%s\n", msgtext);
    
    return(0);
}

static void 
setAppName(ptr)
    LOGINREC *ptr;
{
    SV *sv;
    dTHR;

    if((sv = perl_get_sv("0", FALSE)))
    {
	char scriptname[256];
	char *p;
	strcpy(scriptname, SvPV(sv, PL_na));
	if((p = strrchr(scriptname, '/')))
	    ++p;
	else
	    p = scriptname;
	
	/* The script name must not be longer than DBMAXNAME or DBSETLAPP */
	/* fails */
	if((int)strlen(p) > DBMAXNAME)
	    p[DBMAXNAME] = 0;
	
	DBSETLAPP(ptr, p);
    }
}

static void
initialize()
{
    if(!syb_login)
    {
	SV *sv;
	
	if(dbinit() == FAIL)
	    croak("Can't initialize dblibrary...");
#if DBLIBVS >= 1000 && !defined(MSSQL)
	dbsetversion(DBVERSION_100);
#endif
	dberrhandle(err_handler);
	dbmsghandle(msg_handler);
	syb_login = dblogin();

	setAppName(syb_login);

	/* This is deprecated: use Sybase::DBlib::Version instead */
	if((sv = perl_get_sv("main::SybperlVer", TRUE|GV_ADDMULTI)))
	    sv_setpv(sv, SYBPLVER);

	if((sv = perl_get_sv("Sybase::DBlib::Version", TRUE|GV_ADDMULTI)))
	{
	    char buff[2048];
	    sprintf(buff, "This is sybperl, version %s\n\nSybase::DBlib $Revision: 1.61 $ $Date: 2005/03/20 19:50:59 $ \n\nCopyright (c) 1991-2001 Michael Peppler\n\nDB-Library version: %s\n",
		    SYBPLVER, dbversion());
	    sv_setnv(sv, atof(SYBPLVER));
	    sv_setpv(sv, buff);
	    SvNOK_on(sv);
	}
	if((sv = perl_get_sv("Sybase::DBlib::VERSION", TRUE|GV_ADDMULTI)))
	    sv_setnv(sv, atof(SYBPLVER));
    }
}
    
#if DBLIBVS >= 461

/* This is taken straight from sybperl 1.0xx.
   These routines were contributed by Jeff Wong. */

/* The following routines originate from the OpenClient R4.6.1 reference  */
/* manual, pages 2-165 to 2-168 both inclusive.  It has been subsequently */
/* modified (slightly) to suit local conditions.                          */

#define PRECISION 4

static void new_mny4tochar(dbproc, mny4ptr, buf_ptr)
DBPROCESS *dbproc;
DBMONEY4  *mny4ptr;
DBCHAR    *buf_ptr;
{
   DBMONEY local_mny;
   DBCHAR  value;
   char    temp_buf[40];

   int     bytes_written = 0;
   int     i             = 0;
   DBBOOL  negative      = (DBBOOL)FALSE;
   DBBOOL  zero          = (DBBOOL)FALSE;

   if (dbconvert(dbproc, SYBMONEY4, (BYTE*)mny4ptr, (DBINT)-1,
                 SYBMONEY, (BYTE*)&local_mny, (DBINT)-1) == -1)
   {
      croak("dbconvert() failed in routine new_mny4tochar()");
   }

   if (dbmnyinit(dbproc, &local_mny, 4 - PRECISION, &negative) == FAIL)
   {
      croak("dbmnyinit() failed in routine new_mny4tochar()");
   }

   while (zero == FALSE)
   {
      if (dbmnyndigit(dbproc, &local_mny, &value, &zero) == FAIL)
      {
         croak("dbmnyndigit() failed in routine new_mny4tochar()");
      }

      temp_buf[bytes_written++] = value;

      if (zero == FALSE)
      {
         if (bytes_written == PRECISION)
         {
            temp_buf[bytes_written++] = '.';
         }
      }
   }

   while (bytes_written < PRECISION)
   {
      temp_buf[bytes_written++] = '0';
   }

   if (bytes_written == PRECISION)
   {
      temp_buf[bytes_written++] = '.';
      temp_buf[bytes_written++] = '0';
   }

   if (negative == TRUE)
   {
      buf_ptr[i++] = '-';
   }

   while (bytes_written--)
   {
      buf_ptr[i++] = temp_buf[bytes_written];
   }

   buf_ptr[i] = '\0';

   return;
}

static void new_mnytochar(dbproc, mnyptr, buf_ptr)
DBPROCESS *dbproc;
DBMONEY   *mnyptr;
DBCHAR    *buf_ptr;
{
   DBMONEY local_mny;
   DBCHAR  value;
   char    temp_buf[40];

   int     bytes_written = 0;
   int     i             = 0;
   DBBOOL  negative      = (DBBOOL)FALSE;
   DBBOOL  zero          = (DBBOOL)FALSE;

   if (dbmnycopy(dbproc, mnyptr, &local_mny) == FAIL)
   {
      croak("dbmnycopy() failed in routine new_mnytochar()");
   }

   if (dbmnyinit(dbproc, &local_mny, 4 - PRECISION, &negative) == FAIL)
   {
      croak("dbmnyinit() failed in routine new_mnytochar()");
   }

   while (zero == FALSE)
   {
      if (dbmnyndigit(dbproc, &local_mny, &value, &zero) == FAIL)
      {
         croak("dbmnyndigit() failed in routine new_mnytochar()");
      }

      temp_buf[bytes_written++] = value;

      if (zero == FALSE)
      {
         if (bytes_written == PRECISION)
         {
            temp_buf[bytes_written++] = '.';
         }
      }
   }

   while (bytes_written < PRECISION)
   {
      temp_buf[bytes_written++] = '0';
   }

   if (bytes_written == PRECISION)
   {
      temp_buf[bytes_written++] = '.';
      temp_buf[bytes_written++] = '0';
   }

   if (negative == TRUE)
   {
      buf_ptr[i++] = '-';
   }

   while (bytes_written--)
   {
      buf_ptr[i++] = temp_buf[bytes_written];
   }

   buf_ptr[i] = '\0';

   return;
}

#endif  /* DBLIBVS >= 461 */

static int
not_here(s)
char *s;
{
    croak("Sybase::DBlib::%s not implemented on this architecture", s);
    return -1;
}

static double
constant(name, arg)
char *name;
int arg;
{
    errno = 0;
    switch (*name) {
    case 'A':
	break;
    case 'B':
	if (strEQ(name, "BCPBATCH"))
#ifdef BCPBATCH
	    return BCPBATCH;
#else
	    goto not_there;
#endif
	if (strEQ(name, "BCPERRFILE"))
#ifdef BCPERRFILE
	    return BCPERRFILE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "BCPFIRST"))
#ifdef BCPFIRST
	    return BCPFIRST;
#else
	    goto not_there;
#endif
	if (strEQ(name, "BCPLAST"))
#ifdef BCPLAST
	    return BCPLAST;
#else
	    goto not_there;
#endif
	if (strEQ(name, "BCPMAXERRS"))
#ifdef BCPMAXERRS
	    return BCPMAXERRS;
#else
	    goto not_there;
#endif
	if (strEQ(name, "BCPNAMELEN"))
#ifdef BCPNAMELEN
	    return BCPNAMELEN;
#else
	    goto not_there;
#endif
	break;
    case 'C':
	break;
    case 'D':
	if (strEQ(name, "DBAUTH"))
#ifdef DBAUTH
	    return DBAUTH;
#else
	    goto not_there;
#endif
	if (strEQ(name, "DBARITHABORT"))
#ifdef DBARITHABORT
	    return DBARITHABORT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "DBARITHIGNORE"))
#ifdef DBARITHIGNORE
	    return DBARITHIGNORE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "DBBOTH"))
#ifdef DBBOTH
	    return DBBOTH;
#else
	    goto not_there;
#endif
	if (strEQ(name, "DBBROWSE"))
#if 0
	    /* I think that this option is unusable in sybperl... */
/*#ifdef DBBROWSE
	    return DBBROWSE;
#else*/
#endif
	    goto not_there;
/*#endif*/
	if (strEQ(name, "DBBUFFER"))
#ifdef DBBUFFER
	    return DBBUFFER;
#else
	    goto not_there;
#endif
	if (strEQ(name, "DBBUFSIZE"))
#ifdef DBBUFSIZE
	    return DBBUFSIZE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "DBCHAINXACTS"))
#ifdef DBCHAINXACTS
	    return DBCHAINXACTS;
#else
	    goto not_there;
#endif
	if (strEQ(name, "DBCONFIRM"))
#ifdef DBCONFIRM
	    return DBCONFIRM;
#else
	    goto not_there;
#endif
	if (strEQ(name, "DBDATEFORMAT"))
#ifdef DBDATEFORMAT
	    return DBDATEFORMAT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "DBDATEFIRST"))
#ifdef DBDATEFIRST
	    return DBDATEFIRST;
#else
	    goto not_there;
#endif
	if (strEQ(name, "DBDOUBLE"))
#ifdef DBDOUBLE
	    return DBDOUBLE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "DBERRLVL"))
#ifdef DBERRLVL
	    return DBERRLVL;
#else
	    goto not_there;
#endif
	if (strEQ(name, "DBESTIMATE"))
#ifdef DBESTIMATE
	    return DBESTIMATE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "DBFIPSFLAG"))
#ifdef DBFIPSFLAG
	    return DBFIPSFLAG;
#else
	    goto not_there;
#endif
	if (strEQ(name, "DBIDENTITY"))
#ifdef DBIDENTITY
	    return DBIDENTITY;
#else
	    goto not_there;
#endif
	if (strEQ(name, "DBISOLATION"))
#ifdef DBISOLATION
	    return DBISOLATION;
#else
	    goto not_there;
#endif
	if (strEQ(name, "DBLIBVS"))
#ifdef DBLIBVS
	    return DBLIBVS;
#else
	    goto not_there;
#endif
	if (strEQ(name, "DBMAXNAME"))
#ifdef DBMAXNAME
	    return DBMAXNAME;
#else
	    goto not_there;
#endif
	if (strEQ(name, "DBNATLANG"))
#ifdef DBNATLANG
	    return DBNATLANG;
#else
	    goto not_there;
#endif
	if (strEQ(name, "DBNOAUTOFREE"))
#ifdef DBNOAUTOFREE
	    return DBNOAUTOFREE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "DBNOCOUNT"))
#ifdef DBNOCOUNT
	    return DBNOCOUNT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "DBNOEXEC"))
#ifdef DBNOEXEC
	    return DBNOEXEC;
#else
	    goto not_there;
#endif
	if (strEQ(name, "DBNOIDCOL"))
#ifdef DBNOIDCOL
	    return DBNOIDCOL;
#else
	    goto not_there;
#endif
	if (strEQ(name, "DBNUMOPTIONS"))
#ifdef DBNUMOPTIONS
	    return DBNUMOPTIONS;
#else
	    goto not_there;
#endif
	if (strEQ(name, "DBOFFSET"))
#ifdef DBOFFSET
	    return DBOFFSET;
#else
	    goto not_there;
#endif
	if (strEQ(name, "DBPARSEONLY"))
#ifdef DBPARSEONLY
	    return DBPARSEONLY;
#else
	    goto not_there;
#endif
	if (strEQ(name, "DBROWCOUNT"))
#ifdef DBROWCOUNT
	    return DBROWCOUNT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "DBRPCNORETURN"))
#ifdef DBRPCNORETURN
	    return DBRPCNORETURN;
#else
	    goto not_there;
#endif
	if (strEQ(name, "DBRPCRETURN"))
#ifdef DBRPCRETURN
	    return DBRPCRETURN;
#else
	    goto not_there;
#endif
	if (strEQ(name, "DBRESULT"))
#ifdef DBRESULT
	    return DBRESULT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "DBNOTIFICATION"))
#ifdef DBNOTIFICATION
	    return DBNOTIFICATION;
#else
	    goto not_there;
#endif
	if (strEQ(name, "DBINTERRUPT"))
#ifdef DBINTERURPT
	    return DBINTERRUPT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "DBTIMEOUT"))
#ifdef DBTIMEOUT
	    return DBTIMEOUT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "DBRPCRECOMPILE"))
#ifdef DBRPCRECOMPILE
	    return DBRPCRECOMPILE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "DBSHOWPLAN"))
#ifdef DBSHOWPLAN
	    return DBSHOWPLAN;
#else
	    goto not_there;
#endif
	if (strEQ(name, "DBSINGLE"))
#ifdef DBSINGLE
	    return DBSINGLE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "DBSTAT"))
#ifdef DBSTAT
	    return DBSTAT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "DBSTORPROCID"))
#ifdef DBSTORPROCID
	    return DBSTORPROCID;
#else
	    goto not_there;
#endif
	if (strEQ(name, "DBTEXTLIMIT"))
#ifdef DBTEXTLIMIT
	    return DBTEXTLIMIT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "DBTEXTSIZE"))
#ifdef DBTEXTSIZE
	    return DBTEXTSIZE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "DBTXPLEN"))
#ifdef DBTXPLEN
	    return DBTXPLEN;
#else
	    goto not_there;
#endif
	if (strEQ(name, "DBTXTSLEN"))
#ifdef DBTXTSLEN
	    return DBTXTSLEN;
#else
	    goto not_there;
#endif
	if (strEQ(name, "DB_IN"))
#ifdef DB_IN
	    return DB_IN;
#else
#ifdef IN
	    return IN;
	
#endif
	    goto not_there;
#endif
	if (strEQ(name, "DB_OUT"))
#ifdef DB_OUT
	    return DB_OUT;
#else
#ifdef OUT
	    return OUT;
#endif
	    goto not_there;
#endif
	break;
    case 'E':
	if (strEQ(name, "ERREXIT"))
#ifdef ERREXIT
	    return ERREXIT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "EXCEPTION"))
#ifdef EXCEPTION
	    return EXCEPTION;
#else
	    goto not_there;
#endif
	if (strEQ(name, "EXCLIPBOARD"))
#ifdef EXCLIPBOARD
	    return EXCLIPBOARD;
#else
	    goto not_there;
#endif
	if (strEQ(name, "EXCOMM"))
#ifdef EXCOMM
	    return EXCOMM;
#else
	    goto not_there;
#endif
	if (strEQ(name, "EXCONSISTENCY"))
#ifdef EXCONSISTENCY
	    return EXCONSISTENCY;
#else
	    goto not_there;
#endif
	if (strEQ(name, "EXCONVERSION"))
#ifdef EXCONVERSION
	    return EXCONVERSION;
#else
	    goto not_there;
#endif
	if (strEQ(name, "EXDBLIB"))
#ifdef EXDBLIB
	    return EXDBLIB;
#else
	    goto not_there;
#endif
	if (strEQ(name, "EXECDONE"))
#ifdef EXECDONE
	    return EXECDONE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "EXFATAL"))
#ifdef EXFATAL
	    return EXFATAL;
#else
	    goto not_there;
#endif
	if (strEQ(name, "EXFORMS"))
#ifdef EXFORMS
	    return EXFORMS;
#else
	    goto not_there;
#endif
	if (strEQ(name, "EXINFO"))
#ifdef EXINFO
	    return EXINFO;
#else
	    goto not_there;
#endif
	if (strEQ(name, "EXLOOKUP"))
#ifdef EXLOOKUP
	    return EXLOOKUP;
#else
	    goto not_there;
#endif
	if (strEQ(name, "EXNONFATAL"))
#ifdef EXNONFATAL
	    return EXNONFATAL;
#else
	    goto not_there;
#endif
	if (strEQ(name, "EXPROGRAM"))
#ifdef EXPROGRAM
	    return EXPROGRAM;
#else
	    goto not_there;
#endif
	if (strEQ(name, "EXRESOURCE"))
#ifdef EXRESOURCE
	    return EXRESOURCE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "EXSCREENIO"))
#ifdef EXSCREENIO
	    return EXSCREENIO;
#else
	    goto not_there;
#endif
	if (strEQ(name, "EXSERVER"))
#ifdef EXSERVER
	    return EXSERVER;
#else
	    goto not_there;
#endif
	if (strEQ(name, "EXSIGNAL"))
#ifdef EXSIGNAL
	    return EXSIGNAL;
#else
	    goto not_there;
#endif
	if (strEQ(name, "EXTIME"))
#ifdef EXTIME
	    return EXTIME;
#else
	    goto not_there;
#endif
	if (strEQ(name, "EXUSER"))
#ifdef EXUSER
	    return EXUSER;
#else
	    goto not_there;
#endif
	break;
    case 'F':
	if (strEQ(name, "FAIL"))
#ifdef FAIL
	    return FAIL;
#else
	    goto not_there;
#endif
	if (strEQ(name, "FALSE"))
#ifdef FALSE
	    return FALSE;
#else
	    goto not_there;
#endif
	break;
    case 'G':
	break;
    case 'H':
	break;
    case 'I':
	if (strEQ(name, "IN"))
#ifdef DB_IN
	    return DB_IN;
#else
	    return 1;		/* XXX hack! */
#endif
	if (strEQ(name, "INT_CANCEL"))
#ifdef INT_CANCEL
	    return INT_CANCEL;
#else
	    goto not_there;
#endif
	if (strEQ(name, "INT_CONTINUE"))
#ifdef INT_CONTINUE
	    return INT_CONTINUE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "INT_EXIT"))
#ifdef INT_EXIT
	    return INT_EXIT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "INT_TIMEOUT"))
#ifdef INT_TIMEOUT
	    return INT_TIMEOUT;
#else
	    goto not_there;
#endif
	break;
    case 'J':
	break;
    case 'K':
	break;
    case 'L':
	break;
    case 'M':
	if (strEQ(name, "MAXBIND"))
#ifdef MAXBIND
	    return MAXBIND;
#else
	    goto not_there;
#endif
	if (strEQ(name, "MAXNAME"))
#ifdef MAXNAME
	    return MAXNAME;
#else
	    goto not_there;
#endif
	if (strEQ(name, "MAXOPTTEXT"))
#ifdef MAXOPTTEXT
	    return MAXOPTTEXT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "MAXSECLEVEL"))
#ifdef MAXSECLEVEL
	    return MAXSECLEVEL;
#else
	    goto not_there;
#endif
	if (strEQ(name, "MINSECLEVEL"))
#ifdef MINSECLEVEL
	    return MINSECLEVEL;
#else
	    goto not_there;
#endif
	if (strEQ(name, "MORE_ROWS"))
#ifdef MORE_ROWS
	    return MORE_ROWS;
#else
	    goto not_there;
#endif
	break;
    case 'N':
	if (strEQ(name, "NOSUCHOPTION"))
#ifdef NOSUCHOPTION
	    return NOSUCHOPTION;
#else
	    goto not_there;
#endif
	if (strEQ(name, "NO_MORE_PARAMS"))
#ifdef NO_MORE_PARAMS
	    return NO_MORE_PARAMS;
#else
	    goto not_there;
#endif
	if (strEQ(name, "NO_MORE_RESULTS"))
#ifdef NO_MORE_RESULTS
	    return NO_MORE_RESULTS;
#else
	    goto not_there;
#endif
	if (strEQ(name, "NO_MORE_ROWS"))
#ifdef NO_MORE_ROWS
	    return NO_MORE_ROWS;
#else
	    goto not_there;
#endif
	if (strEQ(name, "NULL"))
#ifdef NULL
	    return (double)((int)NULL);	/* The cast is there to make NeXT cc happy */
#else
	    goto not_there;
#endif
	break;
    case 'O':
	if (strEQ(name, "OFF"))
#ifdef OFF
	    return OFF;
#else
	    goto not_there;
#endif
	if (strEQ(name, "OFF_COMPUTE"))
#ifdef OFF_COMPUTE
	    return OFF_COMPUTE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "OFF_EXEC"))
#ifdef OFF_EXEC
	    return OFF_EXEC;
#else
	    goto not_there;
#endif
	if (strEQ(name, "OFF_FROM"))
#ifdef OFF_FROM
	    return OFF_FROM;
#else
	    goto not_there;
#endif
	if (strEQ(name, "OFF_ORDER"))
#ifdef OFF_ORDER
	    return OFF_ORDER;
#else
	    goto not_there;
#endif
	if (strEQ(name, "OFF_PARAM"))
#ifdef OFF_PARAM
	    return OFF_PARAM;
#else
	    goto not_there;
#endif
	if (strEQ(name, "OFF_PROCEDURE"))
#ifdef OFF_PROCEDURE
	    return OFF_PROCEDURE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "OFF_SELECT"))
#ifdef OFF_SELECT
	    return OFF_SELECT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "OFF_STATEMENT"))
#ifdef OFF_STATEMENT
	    return OFF_STATEMENT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "OFF_TABLE"))
#ifdef OFF_TABLE
	    return OFF_TABLE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ON"))
#ifdef ON
	    return ON;
#else
	    goto not_there;
#endif
	break;
    case 'P':
	break;
    case 'Q':
	break;
    case 'R':
	if (strEQ(name, "REG_ROW"))
#ifdef REG_ROW
	    return REG_ROW;
#else
	    goto not_there;
#endif
	break;
    case 'S':
	if (strEQ(name, "STATNULL"))
#ifdef STATNULL
	    return STATNULL;
#else
	    goto not_there;
#endif
	if (strEQ(name, "STDEXIT"))
#ifdef STDEXIT
	    return STDEXIT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SUCCEED"))
#ifdef SUCCEED
	    return SUCCEED;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SYBBINARY"))
#ifdef SYBBINARY
	    return SYBBINARY;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SYBBIT"))
#ifdef SYBBIT
	    return SYBBIT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SYBCHAR"))
#ifdef SYBCHAR
	    return SYBCHAR;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SYBDATETIME"))
#ifdef SYBDATETIME
	    return SYBDATETIME;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SYBDATETIME4"))
#ifdef SYBDATETIME4
	    return SYBDATETIME4;
#else
	    goto not_there;
#endif
	if(strnEQ(name, "SYBE", 4))
	{
	    if (strEQ(name, "SYBEAAMT"))
#ifdef SYBEAAMT
		return SYBEAAMT;
#else
	    goto not_there;
#endif
		if (strEQ(name, "SYBEABMT"))
#ifdef SYBEABMT
		    return SYBEABMT;
#else
		goto not_there;
#endif
		if (strEQ(name, "SYBEABNC"))
#ifdef SYBEABNC
		    return SYBEABNC;
#else
		goto not_there;
#endif
		if (strEQ(name, "SYBEABNP"))
#ifdef SYBEABNP
		    return SYBEABNP;
#else
		goto not_there;
#endif
		if (strEQ(name, "SYBEABNV"))
#ifdef SYBEABNV
		    return SYBEABNV;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SYBEACNV"))
#ifdef SYBEACNV
	    return SYBEACNV;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SYBEADST"))
#ifdef SYBEADST
	    return SYBEADST;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SYBEAICF"))
#ifdef SYBEAICF
	    return SYBEAICF;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SYBEALTT"))
#ifdef SYBEALTT
	    return SYBEALTT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SYBEAOLF"))
#ifdef SYBEAOLF
	    return SYBEAOLF;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SYBEAPCT"))
#ifdef SYBEAPCT
	    return SYBEAPCT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SYBEAPUT"))
#ifdef SYBEAPUT
	    return SYBEAPUT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SYBEARDI"))
#ifdef SYBEARDI
	    return SYBEARDI;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SYBEARDL"))
#ifdef SYBEARDL
	    return SYBEARDL;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SYBEASEC"))
#ifdef SYBEASEC
	    return SYBEASEC;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SYBEASNL"))
#ifdef SYBEASNL
	    return SYBEASNL;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SYBEASTF"))
#ifdef SYBEASTF
	    return SYBEASTF;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SYBEASTL"))
#ifdef SYBEASTL
	    return SYBEASTL;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SYBEASUL"))
#ifdef SYBEASUL
	    return SYBEASUL;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SYBEAUTN"))
#ifdef SYBEAUTN
	    return SYBEAUTN;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SYBEBADPK"))
#ifdef SYBEBADPK
	    return SYBEBADPK;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SYBEBBCI"))
#ifdef SYBEBBCI
	    return SYBEBBCI;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SYBEBCBC"))
#ifdef SYBEBCBC
	    return SYBEBCBC;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SYBEBCFO"))
#ifdef SYBEBCFO
	    return SYBEBCFO;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SYBEBCIS"))
#ifdef SYBEBCIS
	    return SYBEBCIS;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SYBEBCIT"))
#ifdef SYBEBCIT
	    return SYBEBCIT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SYBEBCNL"))
#ifdef SYBEBCNL
	    return SYBEBCNL;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SYBEBCNN"))
#ifdef SYBEBCNN
	    return SYBEBCNN;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SYBEBCNT"))
#ifdef SYBEBCNT
	    return SYBEBCNT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SYBEBCOR"))
#ifdef SYBEBCOR
	    return SYBEBCOR;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SYBEBCPB"))
#ifdef SYBEBCPB
	    return SYBEBCPB;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SYBEBCPI"))
#ifdef SYBEBCPI
	    return SYBEBCPI;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SYBEBCPN"))
#ifdef SYBEBCPN
	    return SYBEBCPN;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SYBEBCRE"))
#ifdef SYBEBCRE
	    return SYBEBCRE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SYBEBCRO"))
#ifdef SYBEBCRO
	    return SYBEBCRO;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SYBEBCSA"))
#ifdef SYBEBCSA
	    return SYBEBCSA;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SYBEBCSI"))
#ifdef SYBEBCSI
	    return SYBEBCSI;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SYBEBCUC"))
#ifdef SYBEBCUC
	    return SYBEBCUC;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SYBEBCUO"))
#ifdef SYBEBCUO
	    return SYBEBCUO;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SYBEBCVH"))
#ifdef SYBEBCVH
	    return SYBEBCVH;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SYBEBCWE"))
#ifdef SYBEBCWE
	    return SYBEBCWE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SYBEBDIO"))
#ifdef SYBEBDIO
	    return SYBEBDIO;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SYBEBEOF"))
#ifdef SYBEBEOF
	    return SYBEBEOF;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SYBEBIHC"))
#ifdef SYBEBIHC
	    return SYBEBIHC;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SYBEBIVI"))
#ifdef SYBEBIVI
	    return SYBEBIVI;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SYBEBNCR"))
#ifdef SYBEBNCR
	    return SYBEBNCR;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SYBEBPKS"))
#ifdef SYBEBPKS
	    return SYBEBPKS;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SYBEBRFF"))
#ifdef SYBEBRFF
	    return SYBEBRFF;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SYBEBTMT"))
#ifdef SYBEBTMT
	    return SYBEBTMT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SYBEBTOK"))
#ifdef SYBEBTOK
	    return SYBEBTOK;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SYBEBTYP"))
#ifdef SYBEBTYP
	    return SYBEBTYP;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SYBEBUCE"))
#ifdef SYBEBUCE
	    return SYBEBUCE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SYBEBUCF"))
#ifdef SYBEBUCF
	    return SYBEBUCF;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SYBEBUDF"))
#ifdef SYBEBUDF
	    return SYBEBUDF;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SYBEBUFF"))
#ifdef SYBEBUFF
	    return SYBEBUFF;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SYBEBUFL"))
#ifdef SYBEBUFL
	    return SYBEBUFL;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SYBEBUOE"))
#ifdef SYBEBUOE
	    return SYBEBUOE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SYBEBUOF"))
#ifdef SYBEBUOF
	    return SYBEBUOF;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SYBEBWEF"))
#ifdef SYBEBWEF
	    return SYBEBWEF;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SYBEBWFF"))
#ifdef SYBEBWFF
	    return SYBEBWFF;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SYBECDNS"))
#ifdef SYBECDNS
	    return SYBECDNS;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SYBECLOS"))
#ifdef SYBECLOS
	    return SYBECLOS;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SYBECLOSEIN"))
#ifdef SYBECLOSEIN
	    return SYBECLOSEIN;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SYBECLPR"))
#ifdef SYBECLPR
	    return SYBECLPR;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SYBECNOR"))
#ifdef SYBECNOR
	    return SYBECNOR;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SYBECNOV"))
#ifdef SYBECNOV
	    return SYBECNOV;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SYBECOFL"))
#ifdef SYBECOFL
	    return SYBECOFL;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SYBECONN"))
#ifdef SYBECONN
	    return SYBECONN;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SYBECRNC"))
#ifdef SYBECRNC
	    return SYBECRNC;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SYBECSYN"))
#ifdef SYBECSYN
	    return SYBECSYN;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SYBECUFL"))
#ifdef SYBECUFL
	    return SYBECUFL;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SYBECWLL"))
#ifdef SYBECWLL
	    return SYBECWLL;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SYBEDBPS"))
#ifdef SYBEDBPS
	    return SYBEDBPS;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SYBEDDNE"))
#ifdef SYBEDDNE
	    return SYBEDDNE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SYBEDIVZ"))
#ifdef SYBEDIVZ
	    return SYBEDIVZ;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SYBEDNTI"))
#ifdef SYBEDNTI
	    return SYBEDNTI;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SYBEDPOR"))
#ifdef SYBEDPOR
	    return SYBEDPOR;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SYBEDVOR"))
#ifdef SYBEDVOR
	    return SYBEDVOR;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SYBEECAN"))
#ifdef SYBEECAN
	    return SYBEECAN;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SYBEECRT"))
#ifdef SYBEECRT
	    return SYBEECRT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SYBEEINI"))
#ifdef SYBEEINI
	    return SYBEEINI;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SYBEEQVA"))
#ifdef SYBEEQVA
	    return SYBEEQVA;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SYBEESSL"))
#ifdef SYBEESSL
	    return SYBEESSL;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SYBEETD"))
#ifdef SYBEETD
	    return SYBEETD;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SYBEEUNR"))
#ifdef SYBEEUNR
	    return SYBEEUNR;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SYBEEVOP"))
#ifdef SYBEEVOP
	    return SYBEEVOP;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SYBEEVST"))
#ifdef SYBEEVST
	    return SYBEEVST;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SYBEFCON"))
#ifdef SYBEFCON
	    return SYBEFCON;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SYBEFGTL"))
#ifdef SYBEFGTL
	    return SYBEFGTL;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SYBEFMODE"))
#ifdef SYBEFMODE
	    return SYBEFMODE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SYBEFSHD"))
#ifdef SYBEFSHD
	    return SYBEFSHD;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SYBEGENOS"))
#ifdef SYBEGENOS
	    return SYBEGENOS;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SYBEICN"))
#ifdef SYBEICN
	    return SYBEICN;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SYBEIDCL"))
#ifdef SYBEIDCL
	    return SYBEIDCL;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SYBEIFCL"))
#ifdef SYBEIFCL
	    return SYBEIFCL;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SYBEIFNB"))
#ifdef SYBEIFNB
	    return SYBEIFNB;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SYBEIICL"))
#ifdef SYBEIICL
	    return SYBEIICL;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SYBEIMCL"))
#ifdef SYBEIMCL
	    return SYBEIMCL;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SYBEINLN"))
#ifdef SYBEINLN
	    return SYBEINLN;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SYBEINTF"))
#ifdef SYBEINTF
	    return SYBEINTF;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SYBEIPV"))
#ifdef SYBEIPV
	    return SYBEIPV;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SYBEISOI"))
#ifdef SYBEISOI
	    return SYBEISOI;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SYBEITIM"))
#ifdef SYBEITIM
	    return SYBEITIM;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SYBEKBCI"))
#ifdef SYBEKBCI
	    return SYBEKBCI;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SYBEKBCO"))
#ifdef SYBEKBCO
	    return SYBEKBCO;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SYBEMEM"))
#ifdef SYBEMEM
	    return SYBEMEM;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SYBEMOV"))
#ifdef SYBEMOV
	    return SYBEMOV;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SYBEMPLL"))
#ifdef SYBEMPLL
	    return SYBEMPLL;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SYBEMVOR"))
#ifdef SYBEMVOR
	    return SYBEMVOR;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SYBENBUF"))
#ifdef SYBENBUF
	    return SYBENBUF;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SYBENBVP"))
#ifdef SYBENBVP
	    return SYBENBVP;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SYBENDC"))
#ifdef SYBENDC
	    return SYBENDC;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SYBENDTP"))
#ifdef SYBENDTP
	    return SYBENDTP;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SYBENEHA"))
#ifdef SYBENEHA
	    return SYBENEHA;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SYBENHAN"))
#ifdef SYBENHAN
	    return SYBENHAN;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SYBENLNL"))
#ifdef SYBENLNL
	    return SYBENLNL;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SYBENMOB"))
#ifdef SYBENMOB
	    return SYBENMOB;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SYBENOEV"))
#ifdef SYBENOEV
	    return SYBENOEV;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SYBENOTI"))
#ifdef SYBENOTI
	    return SYBENOTI;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SYBENPRM"))
#ifdef SYBENPRM
	    return SYBENPRM;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SYBENSIP"))
#ifdef SYBENSIP
	    return SYBENSIP;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SYBENTLL"))
#ifdef SYBENTLL
	    return SYBENTLL;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SYBENTST"))
#ifdef SYBENTST
	    return SYBENTST;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SYBENTTN"))
#ifdef SYBENTTN
	    return SYBENTTN;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SYBENULL"))
#ifdef SYBENULL
	    return SYBENULL;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SYBENULP"))
#ifdef SYBENULP
	    return SYBENULP;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SYBENUM"))
#ifdef SYBENUM
	    return SYBENUM;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SYBENXID"))
#ifdef SYBENXID
	    return SYBENXID;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SYBEOOB"))
#ifdef SYBEOOB
	    return SYBEOOB;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SYBEOPIN"))
#ifdef SYBEOPIN
	    return SYBEOPIN;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SYBEOPNA"))
#ifdef SYBEOPNA
	    return SYBEOPNA;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SYBEOPTNO"))
#ifdef SYBEOPTNO
	    return SYBEOPTNO;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SYBEOREN"))
#ifdef SYBEOREN
	    return SYBEOREN;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SYBEORPF"))
#ifdef SYBEORPF
	    return SYBEORPF;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SYBEOSSL"))
#ifdef SYBEOSSL
	    return SYBEOSSL;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SYBEPAGE"))
#ifdef SYBEPAGE
	    return SYBEPAGE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SYBEPOLL"))
#ifdef SYBEPOLL
	    return SYBEPOLL;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SYBEPRTF"))
#ifdef SYBEPRTF
	    return SYBEPRTF;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SYBEPWD"))
#ifdef SYBEPWD
	    return SYBEPWD;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SYBERDCN"))
#ifdef SYBERDCN
	    return SYBERDCN;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SYBERDNR"))
#ifdef SYBERDNR
	    return SYBERDNR;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SYBEREAD"))
#ifdef SYBEREAD
	    return SYBEREAD;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SYBERFILE"))
#ifdef SYBERFILE
	    return SYBERFILE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SYBERPCS"))
#ifdef SYBERPCS
	    return SYBERPCS;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SYBERPIL"))
#ifdef SYBERPIL
	    return SYBERPIL;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SYBERPNA"))
#ifdef SYBERPNA
	    return SYBERPNA;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SYBERPND"))
#ifdef SYBERPND
	    return SYBERPND;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SYBERPUL"))
#ifdef SYBERPUL
	    return SYBERPUL;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SYBERTCC"))
#ifdef SYBERTCC
	    return SYBERTCC;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SYBERTSC"))
#ifdef SYBERTSC
	    return SYBERTSC;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SYBERTYPE"))
#ifdef SYBERTYPE
	    return SYBERTYPE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SYBERXID"))
#ifdef SYBERXID
	    return SYBERXID;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SYBESEFA"))
#ifdef SYBESEFA
	    return SYBESEFA;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SYBESEOF"))
#ifdef SYBESEOF
	    return SYBESEOF;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SYBESFOV"))
#ifdef SYBESFOV
	    return SYBESFOV;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SYBESLCT"))
#ifdef SYBESLCT
	    return SYBESLCT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SYBESMSG"))
#ifdef SYBESMSG
	    return SYBESMSG;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SYBESOCK"))
#ifdef SYBESOCK
	    return SYBESOCK;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SYBESPID"))
#ifdef SYBESPID
	    return SYBESPID;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SYBESYNC"))
#ifdef SYBESYNC
	    return SYBESYNC;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SYBETEXS"))
#ifdef SYBETEXS
	    return SYBETEXS;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SYBETIME"))
#ifdef SYBETIME
	    return SYBETIME;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SYBETMCF"))
#ifdef SYBETMCF
	    return SYBETMCF;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SYBETMTD"))
#ifdef SYBETMTD
	    return SYBETMTD;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SYBETPAR"))
#ifdef SYBETPAR
	    return SYBETPAR;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SYBETPTN"))
#ifdef SYBETPTN
	    return SYBETPTN;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SYBETRAC"))
#ifdef SYBETRAC
	    return SYBETRAC;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SYBETRAN"))
#ifdef SYBETRAN
	    return SYBETRAN;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SYBETRAS"))
#ifdef SYBETRAS
	    return SYBETRAS;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SYBETRSN"))
#ifdef SYBETRSN
	    return SYBETRSN;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SYBETSIT"))
#ifdef SYBETSIT
	    return SYBETSIT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SYBETTS"))
#ifdef SYBETTS
	    return SYBETTS;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SYBETYPE"))
#ifdef SYBETYPE
	    return SYBETYPE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SYBEUACS"))
#ifdef SYBEUACS
	    return SYBEUACS;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SYBEUAVE"))
#ifdef SYBEUAVE
	    return SYBEUAVE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SYBEUCPT"))
#ifdef SYBEUCPT
	    return SYBEUCPT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SYBEUCRR"))
#ifdef SYBEUCRR
	    return SYBEUCRR;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SYBEUDTY"))
#ifdef SYBEUDTY
	    return SYBEUDTY;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SYBEUFDS"))
#ifdef SYBEUFDS
	    return SYBEUFDS;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SYBEUFDT"))
#ifdef SYBEUFDT
	    return SYBEUFDT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SYBEUHST"))
#ifdef SYBEUHST
	    return SYBEUHST;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SYBEUNAM"))
#ifdef SYBEUNAM
	    return SYBEUNAM;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SYBEUNOP"))
#ifdef SYBEUNOP
	    return SYBEUNOP;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SYBEUNT"))
#ifdef SYBEUNT
	    return SYBEUNT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SYBEURCI"))
#ifdef SYBEURCI
	    return SYBEURCI;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SYBEUREI"))
#ifdef SYBEUREI
	    return SYBEUREI;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SYBEUREM"))
#ifdef SYBEUREM
	    return SYBEUREM;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SYBEURES"))
#ifdef SYBEURES
	    return SYBEURES;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SYBEURMI"))
#ifdef SYBEURMI
	    return SYBEURMI;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SYBEUSCT"))
#ifdef SYBEUSCT
	    return SYBEUSCT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SYBEUTDS"))
#ifdef SYBEUTDS
	    return SYBEUTDS;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SYBEUVBF"))
#ifdef SYBEUVBF
	    return SYBEUVBF;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SYBEUVDT"))
#ifdef SYBEUVDT
	    return SYBEUVDT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SYBEVDPT"))
#ifdef SYBEVDPT
	    return SYBEVDPT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SYBEVMS"))
#ifdef SYBEVMS
	    return SYBEVMS;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SYBEVOIDRET"))
#ifdef SYBEVOIDRET
	    return SYBEVOIDRET;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SYBEWAID"))
#ifdef SYBEWAID
	    return SYBEWAID;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SYBEWRIT"))
#ifdef SYBEWRIT
	    return SYBEWRIT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SYBEXOCI"))
#ifdef SYBEXOCI
	    return SYBEXOCI;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SYBEXTDN"))
#ifdef SYBEXTDN
	    return SYBEXTDN;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SYBEXTN"))
#ifdef SYBEXTN
	    return SYBEXTN;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SYBEXTSN"))
#ifdef SYBEXTSN
	    return SYBEXTSN;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SYBEZTXT"))
#ifdef SYBEZTXT
	    return SYBEZTXT;
#else
	    goto not_there;
#endif
	}
	if (strEQ(name, "SYBFLT8"))
#ifdef SYBFLT8
	    return SYBFLT8;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SYBIMAGE"))
#ifdef SYBIMAGE
	    return SYBIMAGE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SYBINT1"))
#ifdef SYBINT1
	    return SYBINT1;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SYBINT2"))
#ifdef SYBINT2
	    return SYBINT2;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SYBINT4"))
#ifdef SYBINT4
	    return SYBINT4;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SYBMONEY"))
#ifdef SYBMONEY
	    return SYBMONEY;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SYBMONEY4"))
#ifdef SYBMONEY4
	    return SYBMONEY4;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SYBREAL"))
#ifdef SYBREAL
	    return SYBREAL;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SYBTEXT"))
#ifdef SYBTEXT
	    return SYBTEXT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SYBVARBINARY"))
#ifdef SYBVARBINARY
	    return SYBVARBINARY;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SYBVARCHAR"))
#ifdef SYBVARCHAR
	    return SYBVARCHAR;
#else
	    goto not_there;
#endif
	
	break;
    case 'T':
	if (strEQ(name, "TRACE_NONE"))
	    return TRACE_NONE;
	if (strEQ(name, "TRACE_DESTROY"))
	    return TRACE_DESTROY;
	if (strEQ(name, "TRACE_CREATE"))
	    return TRACE_CREATE;
	if (strEQ(name, "TRACE_RESULTS"))
	    return TRACE_RESULTS;
	if (strEQ(name, "TRACE_FETCH"))
	    return TRACE_FETCH;
	if (strEQ(name, "TRACE_CURSOR"))
	    return TRACE_CURSOR;
	if (strEQ(name, "TRACE_PARAMS"))
	    return TRACE_PARAMS;
	if (strEQ(name, "TRACE_OVERLOAD"))
	    return TRACE_OVERLOAD;
	if (strEQ(name, "TRACE_SQL"))
	    return TRACE_SQL;
	if (strEQ(name, "TRACE_ALL"))
	    return TRACE_ALL;
	if (strEQ(name, "TRUE"))
	    return TRUE;
	break;
    case 'U':
	break;
    case 'V':
	break;
    case 'W':
	break;
    case 'X':
	break;
    case 'Y':
	break;
    case 'Z':
	break;
    case '_':
	break;
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}


MODULE = Sybase::DBlib		PACKAGE = Sybase::DBlib

BOOT:
initialize();


double
constant(name,arg)
	char *		name
	int		arg

void
dblogin(package="Sybase::DBlib",user=NULL,pwd=NULL,server=NULL,appname=NULL,attr=&PL_sv_undef)
	char *	package
	char *	user
	char *	pwd
	char *	server
	char *	appname
	SV *	attr
ALIAS:
     new    = 1
  CODE:
{
    DBPROCESS *dbproc;
    SV *sv;
#if defined(NCR_BUG)
/* ugly hack to fix a bug with DBSETLUSER() on NCR & OC 10.x */
    char *ptr = (char*)syb_login->ltds_loginrec+31;
    memset(ptr,0,30);
#endif

    if(user && *user) 
	DBSETLUSER(syb_login, user);
    else
	DBSETLUSER(syb_login, NULL);
	
    if(pwd && *pwd)
	DBSETLPWD(syb_login, pwd);
    else
	DBSETLPWD(syb_login, NULL);
    
    if(server && !*server)
	server = NULL;
    if(appname && *appname)
	DBSETLAPP(syb_login, appname);
    if(!(dbproc = dbopen(syb_login, server)))
    {
	ST(0) = sv_newmortal();
    }
    else
    {
	ConInfo *info;

	Newz(902, info, 1, ConInfo);
	info->dbproc = dbproc;
	sv = newdbh(info, package, attr);
	if(debug_level & TRACE_CREATE)
	    warn("Created %s", neatsvpv(sv, 0));
	ST(0) = sv_2mortal(sv);
    }
}

void
dbopen(package="Sybase::DBlib",server=NULL,appname=NULL,attr=&PL_sv_undef)
	char *	package
	char *	server
	char *	appname
	SV *	attr
  CODE:
{
    DBPROCESS *dbproc;
    SV *sv;
    
    if(server && !*server)
	server = NULL;
    if(appname && *appname)
	DBSETLAPP(syb_login, appname);
    
    if(!(dbproc = dbopen(syb_login, server)))
    {
	ST(0) = sv_newmortal();
    }
    else
    {
	ConInfo *info;
	
	Newz(902, info, 1, ConInfo);
	info->dbproc = dbproc;
	sv = newdbh(info, package, attr);
	if(debug_level & TRACE_CREATE)
	    warn("Created %s", neatsvpv(sv, 0));
	ST(0) = sv_2mortal(sv);
    }
}

void
DESTROY(dbp)
	SV *	dbp
CODE:
{
    ConInfo *info = get_ConInfo(dbp);

    if(PL_dirty && !info)
    {
	if(debug_level & TRACE_DESTROY)
	    warn("Skipping Destroying %s (dirty)", neatsvpv(dbp, 0));
	XSRETURN_EMPTY;
    }

    if(debug_level & TRACE_DESTROY)
	warn("Destroying %s", neatsvpv(dbp, 0));
    
    if(!info)			/* it's already been closed! */
    {
	if(debug_level & TRACE_DESTROY)
	    warn("ConInfo pointer is NULL for %s", neatsvpv(dbp, 0));
	XSRETURN_EMPTY;
    }

    if(info->attr.pid != getpid()) {
	if(debug_level & TRACE_DESTROY)
	    warn("Skipping Destroying %s (pid %d != getpid %d)", neatsvpv(dbp, 0), info->attr.pid, getpid());
	XSRETURN_EMPTY;
    }
 
    if(info->bcp_data)
    {
	Safefree(info->bcp_data->colPtr);
	Safefree(info->bcp_data);
    }

    if(info->dbproc && !dbexit_called)
	dbclose(info->dbproc);

    hv_undef(info->hv);
    hv_undef(info->attr.other);
    av_undef(info->av);
    Safefree(info);
}

void
debug(level)
	int	level
  CODE:
{
    debug_level = level;
}

void
force_dbclose(dbp)
	SV *	dbp
CODE:
{
  ConInfo *info = get_ConInfo(dbp);

  dbclose(info->dbproc);
  info->dbproc = NULL;
}


int
dbuse(dbp,db)
	SV *	dbp
	char *	db
CODE:
{
    DBPROCESS *dbproc = getDBPROC(dbp);

    RETVAL = dbuse(dbproc, db);
}
 OUTPUT:
RETVAL


int
dbcmd(dbp,cmd)
	SV *	dbp
	char *	cmd
CODE:
{
    DBPROCESS *dbproc = getDBPROC(dbp);

    RETVAL = dbcmd(dbproc, cmd);

    if(debug_level & TRACE_SQL)
	warn("%s->dbcmd('%s') == %d",
	     neatsvpv(dbp, 0), cmd, RETVAL);
}
 OUTPUT:
RETVAL

int
dbsqlexec(dbp)
	SV *	dbp
CODE:
{
    DBPROCESS *dbproc = getDBPROC(dbp);

    RETVAL = dbsqlexec(dbproc);

    if(debug_level & TRACE_RESULTS)
	warn("%s->dbsqlexec == %d",
	     neatsvpv(dbp, 0), RETVAL);
}
 OUTPUT:
RETVAL

int
dbsqlok(dbp)
	SV *	dbp
CODE:
{
    DBPROCESS *dbproc = getDBPROC(dbp);

    RETVAL = dbsqlok(dbproc);

    if(debug_level & TRACE_RESULTS)
	warn("%s->dbsqlok == %d",
	     neatsvpv(dbp, 0), RETVAL);
}
 OUTPUT:
RETVAL

int
dbsqlsend(dbp)
	SV *	dbp
CODE:
{
    DBPROCESS *dbproc = getDBPROC(dbp);

    RETVAL = dbsqlsend(dbproc);

    if(debug_level & TRACE_RESULTS)
	warn("%s->dbsqlsend == %d",
	     neatsvpv(dbp, 0), RETVAL);
}
 OUTPUT:
RETVAL

int
dbresults(dbp)
	SV *	dbp
CODE:
{
    ConInfo *info = get_ConInfo(dbp);
    DBPROCESS *dbproc = info->dbproc;

    RETVAL = dbresults(dbproc);

    hv_clear(info->hv);

    if(debug_level & TRACE_RESULTS)
	warn("%s->dbresults == %d",
	     neatsvpv(dbp, 0), RETVAL);
}
 OUTPUT:
RETVAL

int
dbcancel(dbp)
	SV *	dbp
CODE:
{
    DBPROCESS *dbproc = getDBPROC(dbp);

    RETVAL = dbcancel(dbproc);
}
 OUTPUT:
RETVAL


int
dbcanquery(dbp)
	SV *	dbp
CODE:
{
    DBPROCESS *dbproc = getDBPROC(dbp);

    RETVAL = dbcanquery(dbproc);
}
 OUTPUT:
RETVAL


void
dbpoll(dbp, milliseconds)
	SV *	dbp
	int	milliseconds
PPCODE:
{
    DBPROCESS *dbproc = NULL;
    int reason;
    RETCODE ret;
    SV *sv;
    HV *hv = NULL;
    SV *rv;

    if(SvROK(dbp)) {
	dbproc = getDBPROC(dbp);
    }

    ret = dbpoll(dbproc, milliseconds, &dbproc, &reason);
    if(ret == SUCCEED) {
	switch(reason) {
	case DBRESULT:
	case DBNOTIFICATION:
	    if(dbproc && !DBDEAD(dbproc) && (hv = (HV*)dbgetuserdata(dbproc))) 
	    {
		rv = newRV((SV*)hv);
		XPUSHs(sv_2mortal(rv));
	    } 
	default:
	    if(!hv)
		XPUSHs(&PL_sv_undef);
	    XPUSHs(sv_2mortal(newSViv(reason)));
	    break;
	}
    }
}



void
dbfreebuf(dbp)
	SV *	dbp
CODE:
{
    DBPROCESS *dbproc = getDBPROC(dbp);

    dbfreebuf(dbproc);
}

int
dbsetopt(dbp, option, c_val=NULL, i_val=-1)
	SV *	dbp
	int	option
	char *	c_val
	int	i_val
  CODE:
{
    DBPROCESS *dbproc = NULL;

    if(dbp != &PL_sv_undef)
	dbproc = getDBPROC(dbp);

    RETVAL = dbsetopt(dbproc, option, c_val, i_val);
}
 OUTPUT:
RETVAL

int
dbclropt(dbp, option, c_val=NULL)
	SV *	dbp
	int	option
	char *	c_val
  CODE:
{
    DBPROCESS *dbproc = NULL;

    if(dbp != &PL_sv_undef)
	dbproc = getDBPROC(dbp);

    RETVAL = dbclropt(dbproc, option, c_val);
}
 OUTPUT:
RETVAL

int
dbisopt(dbp, option, c_val=NULL)
	SV *	dbp
	int	option
	char *	c_val
  CODE:
{
    DBPROCESS *dbproc = getDBPROC(dbp);

    RETVAL = dbisopt(dbproc, option, c_val);
}
 OUTPUT:
RETVAL

int
DBCURROW(dbp)
	SV *	dbp
CODE:
{
    DBPROCESS *dbproc = getDBPROC(dbp);

    RETVAL = DBCURROW(dbproc);
}
 OUTPUT:
RETVAL

int
DBCURCMD(dbp)
	SV *	dbp
CODE:
{
    DBPROCESS *dbproc = getDBPROC(dbp);

    RETVAL = DBCURCMD(dbproc);
}
 OUTPUT:
RETVAL

int
DBMORECMDS(dbp)
	SV *	dbp
CODE:
{
    DBPROCESS *dbproc = getDBPROC(dbp);

    RETVAL = DBMORECMDS(dbproc);
}
 OUTPUT:
RETVAL

int
DBCMDROW(dbp)
	SV *	dbp
CODE:
{
    DBPROCESS *dbproc = getDBPROC(dbp);

    RETVAL = DBCMDROW(dbproc);
}
 OUTPUT:
RETVAL

int
DBROWS(dbp)
	SV *	dbp
CODE:
{
    DBPROCESS *dbproc = getDBPROC(dbp);

    RETVAL = DBROWS(dbproc);
}
 OUTPUT:
RETVAL

int
DBCOUNT(dbp)
	SV *	dbp
CODE:
{
    DBPROCESS *dbproc = getDBPROC(dbp);

    RETVAL = DBCOUNT(dbproc);
}
 OUTPUT:
RETVAL

int
DBIORDESC(dbp)
	SV *	dbp
CODE:
{
    DBPROCESS *dbproc = getDBPROC(dbp);

    RETVAL = DBIORDESC(dbproc);
}
 OUTPUT:
RETVAL

int
DBIOWDESC(dbp)
	SV *	dbp
CODE:
{
    DBPROCESS *dbproc = getDBPROC(dbp);

    RETVAL = DBIOWDESC(dbproc);
}
 OUTPUT:
RETVAL


int
dbhasretstat(dbp)
	SV *	dbp
CODE:
{
    DBPROCESS *dbproc = getDBPROC(dbp);

    RETVAL = dbhasretstat(dbproc);
}
 OUTPUT:
RETVAL

int
dbretstatus(dbp)
	SV *	dbp
CODE:
{
    DBPROCESS *dbproc = getDBPROC(dbp);

    RETVAL = dbretstatus(dbproc);
}
 OUTPUT:
RETVAL

int
dbnumcols(dbp)
	SV *	dbp
CODE:
{
    DBPROCESS *dbproc = getDBPROC(dbp);

    RETVAL = dbnumcols(dbproc);
}
 OUTPUT:
RETVAL

int
dbcoltype(dbp, colid)
	SV *	dbp
	int	colid
CODE:
{
    DBPROCESS *dbproc = getDBPROC(dbp);

    RETVAL = dbcoltype(dbproc, colid);
}
 OUTPUT:
RETVAL

int
dbcollen(dbp, colid)
	SV *	dbp
	int	colid
CODE:
{
    DBPROCESS *dbproc = getDBPROC(dbp);

    RETVAL = dbcollen(dbproc, colid);
}
 OUTPUT:
RETVAL

char *
dbcolname(dbp, colid)
	SV *	dbp
	int	colid
CODE:
{
    DBPROCESS *dbproc = getDBPROC(dbp);

    RETVAL = dbcolname(dbproc, colid);
}
 OUTPUT:
RETVAL

void
dbnextrow(dbp,doAssoc=0,wantref=0)
	SV *	dbp
	int	doAssoc
	int	wantref
PPCODE:
{
    int retval, ComputeId = 0;
    char buff[MAX_BUFF_SIZE];
    BYTE *data;
    int col, type, numcols = 0;
    int len;
    DBDATETIME dt;
    char *colname;
    char cname[64];
    int is_null;
#if DBLIBVS >= 461
    DBMONEY tv_money;
#else
    DBFLT8 tmp;
#endif
    int dbKeepNumeric = 0;
    int dbBin0x = 0;
    int dbNullIsUndef = 0;
    int useDateTime = 0;
    int useMoney = 0;
    ConInfo *info = get_ConInfo(dbp);
    DBPROCESS *dbproc = info->dbproc;
    SV *sv;
#if defined(UNDEF_BUG)
    int n_null = doAssoc;
#endif

    
    dbNullIsUndef = info->attr.dbNullIsUndef;
    dbKeepNumeric = info->attr.dbKeepNumeric;
    dbBin0x       = info->attr.dbBin0x;
    useDateTime   = info->attr.UseDateTime;
    useMoney      = info->attr.UseMoney;
    
    retval = dbnextrow(dbproc);
    if(debug_level & TRACE_FETCH)
	warn("%s->dbnextrow(%s) == %d (dbNullIsUndef=%d,dbKeepNumeric=%d,useDateTime=%d,useMoney=%d)",
	     neatsvpv(dbp, 0), doAssoc ? "TRUE" : "FALSE", retval,
	     dbNullIsUndef, dbKeepNumeric, useDateTime, useMoney);
    if(retval == REG_ROW)
    {
	numcols = dbnumcols(dbproc);
    }
    else if(retval > 0)
    {
 	ComputeId = retval;
	numcols = dbnumalts(dbproc, retval);
    }
    if(numcols && numcols != info->numCols) {
	int i = numcols;
	info->numCols = i;
	av_clear(info->av);
	hv_clear(info->hv);
	while(i--)
	    av_store(info->av, i, newSV(0));
    }
	
    info->attr.ComputeID = ComputeId;
    info->attr.DBstatus  = retval;

    for(col = 1, buff[0] = 0; col <= numcols; ++col)
    {
	sv = AvARRAY(info->av)[col-1];
	is_null = 0;
	colname = NULL;
	if(!ComputeId)
	{
	    type = dbcoltype(dbproc, col);
	    len = dbdatlen(dbproc,col);
	    data = (BYTE *)dbdata(dbproc, col);
	    colname = dbcolname(dbproc, col);
	    if(!colname || !colname[0])
	    {
		sprintf(cname, "Col %d", col);
		colname = cname;
	    }
	}
	else
	{
	    int colid = dbaltcolid(dbproc, ComputeId, col);
	    type = dbalttype(dbproc, ComputeId, col);
	    len = dbadlen(dbproc, ComputeId, col);
	    data = (BYTE *)dbadata(dbproc, ComputeId, col);
	    if(colid > 0)
		colname = dbcolname(dbproc, colid);
	    if(!colname || !colname[0])
	    {
		sprintf(cname, "Col %d", col);
		colname = cname;
	    }
	}
	if(doAssoc && !wantref)
	{
	    SV *namesv = newSVpv(colname, 0);
	    if(debug_level & TRACE_FETCH)
		warn("%s->dbnextrow pushes %s on the stack (doAssoc == TRUE)",
		     neatsvpv(dbp, 0), neatsvpv(namesv, 0));
	    XPUSHs(sv_2mortal(namesv));
	}
	if(!data && !len)
	{
	    ++is_null;
	    if(dbNullIsUndef)
		(void)SvOK_off(sv);
	    else
		sv_setpvn(sv, "NULL", 4);
	    if(debug_level & TRACE_FETCH)
		warn("%s->dbnextrow pushes %s on the stack",
		     neatsvpv(dbp, 0), neatsvpv(sv, 0));
	    if(!wantref) {
		XPUSHs(sv);
		/* the rest of this iteration is irrelevant */
		continue;
	    }
	}
	else
	{
	    switch(type)
	    {
	      case SYBCHAR:
	      case SYBTEXT:
	      case SYBIMAGE:
		sv_setpvn(sv,( char*)data, len);
		break;
	      case SYBINT1:
	      case SYBBIT: /* a bit is at least a byte long... */
		if(dbKeepNumeric)
		    sv_setiv(sv, (IV)*(DBTINYINT*)data);
		else
		{
		    sprintf(buff,"%u",*(DBTINYINT *)data);
		    sv_setpv(sv, buff);
		}
		break;
	      case SYBINT2:
		if(dbKeepNumeric)
		    sv_setiv(sv, (IV)*(DBSMALLINT*)data);
		else
		{
		    sprintf(buff,"%d",*(DBSMALLINT *)data);
		    sv_setpv(sv, buff);
		}
		break;
	      case SYBINT4:
		if(dbKeepNumeric)
		    sv_setiv(sv, (IV)*(DBINT*)data);
		else
		{
		    sprintf(buff,"%d",*(DBINT *)data);
		    sv_setpv(sv, buff);
		}
		break;
	      case SYBFLT8:
		if(dbKeepNumeric)
		    sv_setnv(sv, *(DBFLT8*)data);
		else
		{
		    sprintf(buff,"%.6f",*(DBFLT8 *)data);
		    sv_setpv(sv, buff);
		}
		break;
#if   DBLIBVS >= 461
	      case SYBMONEY:
		dbconvert(dbproc, SYBMONEY, (BYTE *)data, len,
			  SYBMONEY, (BYTE*)&tv_money, -1);
		if(useMoney)
		    sv_setsv(sv, sv_2mortal(newmoney(dbproc, &tv_money)));
		else
		{
		    new_mnytochar(dbproc, &tv_money, buff);
		    sv_setpv(sv, buff);
		}
		break;
#else
	      case SYBMONEY:
		dbconvert(dbproc, SYBMONEY, data, len,
			  SYBFLT8, (BYTE*)&tmp, -1);
		if(dbKeepNumeric)
		    sv_setnv(sv, tmp);
		else
		{
		    sprintf(buff,"%.6f",tmp);
		    sv_setpv(sv, buff);
		}
		break;
#endif
	      case SYBDATETIME:
		if(useDateTime)
		{
		    dt = *(DBDATETIME*)data;
		    sv_setsv(sv, sv_2mortal(newdate(dbproc, &dt)));
		}
		else
		{
		    dbconvert(dbproc, SYBDATETIME, (BYTE *)data, len,
			      SYBCHAR, (BYTE *)buff, -1);
		    sv_setpv(sv, buff);
		}
		break;
	      case SYBBINARY:
		if(dbBin0x)
		{
		    strcpy(buff, "0x");
		    dbconvert(dbproc, type, (BYTE *)data, len,
			      SYBCHAR, (BYTE *)&buff[2], -1);
		}
		else
		    dbconvert(dbproc, type, (BYTE *)data, len,
			      SYBCHAR, (BYTE *)buff, -1);
		sv_setpv(sv, buff);
		break;
#if DBLIBVS >= 420
	      case SYBREAL:
		if(dbKeepNumeric)
		    sv_setnv(sv, *(DBREAL*)data);
		else
		{
		    sprintf(buff, "%.6f", (double)*(DBREAL *)data);
		    sv_setpv(sv, buff);
		}
		break;
	      case SYBDATETIME4:
		if(useDateTime)
		{
		    dbconvert(dbproc, SYBDATETIME4, (BYTE *)data, len,
			      SYBDATETIME, (BYTE *)&dt, -1);
		    sv_setsv(sv, sv_2mortal(newdate(dbproc, &dt)));
		}
		else
		{
		    dbconvert(dbproc, SYBDATETIME4, (BYTE *)data, len,
			      SYBCHAR, (BYTE *)buff, -1);
		    sv_setpv(sv, buff);
		}
		break;
#if DBLIBVS >= 461
	      case SYBMONEY4:
		dbconvert(dbproc, SYBMONEY4, (BYTE *)data, len,
			  SYBMONEY, (BYTE*)&tv_money, -1);
		if(useMoney)
		    sv_setsv(sv, sv_2mortal(newmoney(dbproc, &tv_money)));
		else
		{
		    new_mnytochar(dbproc, &tv_money, buff);
		    sv_setpv(sv, buff);
		}
		break;
#endif
#endif
	      default:
		/* 
		 * WARNING!
		 * 
		 * We convert unknown data types to SYBCHAR 
		 * without checking to see if the resulting 
		 * string will fit in the 'buff' variable. 
		 * This isn't very pretty...
		 */
		dbconvert(dbproc, type, (BYTE *)data, len,
			  SYBCHAR, (BYTE *)buff, -1); /* FIXME */
		sv_setpv(sv, buff);
		break;
	    }
	}
#if defined(UNDEF_BUG)
	++n_null;
#endif
	if(debug_level & TRACE_FETCH)
	    warn("%s->dbnextrow pushes %s on the stack",
		 neatsvpv(dbp, 0), neatsvpv(sv, 0));
	if(!wantref)
	    XPUSHs(sv_mortalcopy(sv));
	else if(doAssoc)
	    hv_store(info->hv, colname, strlen(colname),
		     newSVsv(sv), 0);
	
    }
    if(wantref && numcols > 0) {
	if(doAssoc) {
	    XPUSHs(sv_2mortal((SV*)newRV((SV*)info->hv)));
	} else {
	    XPUSHs(sv_2mortal((SV*)newRV((SV*)info->av)));
	}
    }
#if defined(UNDEF_BUG)
    if(!n_null && numcols > 0)
	XPUSHs(sv_2mortal(newSVpv("__ALL NULL__", 0)));
#endif
}

int
dbretlen(dbp, retnum)
	SV *	dbp
	int	retnum
CODE:
{
    DBPROCESS *dbproc = getDBPROC(dbp);

    RETVAL = dbretlen(dbproc, retnum);
}
 OUTPUT:
RETVAL

int
dbrettype(dbp, retnum)
	SV *	dbp
	int	retnum
CODE:
{
    DBPROCESS *dbproc = getDBPROC(dbp);

    RETVAL = dbrettype(dbproc, retnum);
}
 OUTPUT:
RETVAL

char *
dbretname(dbp, retnum)
	SV *	dbp
	int	retnum
CODE:
{
    DBPROCESS *dbproc = getDBPROC(dbp);

    RETVAL = dbretname(dbproc, retnum);
}
 OUTPUT:
RETVAL


void
dbretdata(dbp,doAssoc=0)
	SV *	dbp
	int	doAssoc
PPCODE:
{
    char buff[MAX_BUFF_SIZE];
    BYTE *data;
    int col, type, numcols;
    int len;
    DBDATETIME dt;
    char *colname;
    char cname[64];
    int is_null;
#if DBLIBVS >= 461
    DBMONEY tv_money;
#else
    DBFLT8 tmp;
#endif
    int dbKeepNumeric = 0;
    int dbBin0x = 0;
    int dbNullIsUndef = 0;
    int useDateTime = 0;
    int useMoney = 0;
    ConInfo *info = get_ConInfo(dbp);
    DBPROCESS *dbproc = info->dbproc;
    SV *sv;
#if defined(UNDEF_BUG)
    int n_null = doAssoc;
#endif

    
    dbNullIsUndef = info->attr.dbNullIsUndef;
    dbKeepNumeric = info->attr.dbKeepNumeric;
    dbBin0x       = info->attr.dbBin0x;
    useDateTime   = info->attr.UseDateTime;
    useMoney      = info->attr.UseMoney;
    
    numcols = dbnumrets(dbproc);
    if(debug_level & TRACE_FETCH)
	warn("%s->dbretdata(%s) == %d (dbNullIsUndef=%d,dbKeepNumeric=%d,useDateTime=%d,useMoney=%d)",
	     neatsvpv(dbp, 0), doAssoc ? "TRUE" : "FALSE", numcols,
	     dbNullIsUndef, dbKeepNumeric, useDateTime, useMoney);
    for(col = 1, buff[0] = 0; col <= numcols; ++col)
    {
	is_null = 0;
	colname = NULL;
	type = dbrettype(dbproc, col);
	len = dbretlen(dbproc,col);
	data = (BYTE *)dbretdata(dbproc,col);
	colname = dbretname(dbproc, col);
	if(!colname || !colname[0])
	{
	    sprintf(cname, "Par %d", col);
	    colname = cname;
	}
	if(doAssoc)
	{
	    sv = newSVpv(colname, 0);
	    if(debug_level & TRACE_FETCH)
		warn("%s->dbretdata pushes %s on the stack (doAssoc == TRUE)",
		     neatsvpv(dbp, 0), neatsvpv(sv, 0));
	    XPUSHs(sv_2mortal(sv));
	}
	if(!data && !len)
	{
	    if(dbNullIsUndef)
		sv = &PL_sv_undef;
	    else
		sv = newSVpv("NULL", 0);
	    if(debug_level & TRACE_FETCH)
		warn("%s->dbretdata pushes %s on the stack",
		     neatsvpv(dbp, 0), neatsvpv(sv, 0));
	    XPUSHs(sv);

	    /* Nothing else needs doing when the data is NULL */
	    continue;
	}
	else
	{
	    switch(type)
	    {
	      case SYBCHAR:
	      case SYBTEXT:
	      case SYBIMAGE:
		sv = newSVpv((char*)data, len);
		break;
	      case SYBINT1:
	      case SYBBIT: /* a bit is at least a byte long... */
		if(dbKeepNumeric)
		    sv = newSViv((IV)*(DBTINYINT*)data);
		else
		{
		    sprintf(buff,"%u",*(DBTINYINT *)data);
		    sv = newSVpv(buff, 0);
		}
		break;
	      case SYBINT2:
		if(dbKeepNumeric)
		    sv = newSViv((IV)*(DBSMALLINT*)data);
		else
		{
		    sprintf(buff,"%d",*(DBSMALLINT *)data);
		    sv = newSVpv(buff, 0);
		}
		break;
	      case SYBINT4:
		if(dbKeepNumeric)
		    sv = newSViv((IV)*(DBINT*)data);
		else
		{
		    sprintf(buff,"%d",*(DBINT *)data);
		    sv = newSVpv(buff, 0);
		}
		break;
	      case SYBFLT8:
		if(dbKeepNumeric)
		    sv = newSVnv(*(DBFLT8*)data);
		else
		{
		    sprintf(buff,"%.6f",*(DBFLT8 *)data);
		    sv = newSVpv(buff, 0);
		}
		break;
#if   DBLIBVS >= 461
	      case SYBMONEY:
		dbconvert(dbproc, SYBMONEY, data, len,
			  SYBMONEY, (BYTE*)&tv_money, -1);
		if(useMoney)
		    sv = newmoney(dbproc, &tv_money);
		else
		{
		    new_mnytochar(dbproc, &tv_money, buff);
		    sv = newSVpv(buff, 0);
		}
		break;
#else
	      case SYBMONEY:
		dbconvert(dbproc, SYBMONEY, data, len,
			  SYBFLT8, (BYTE*)&tmp, -1);
		if(dbKeepNumeric)
		    sv = newSVnv(tmp);
		else
		{
		    sprintf(buff,"%.6f",tmp);
		    sv = newSVpv(buff, 0);
		}
		break;
#endif
	      case SYBDATETIME:
		if(useDateTime)
		{
		    dt = *(DBDATETIME*)data;
		    sv = newdate(dbproc, &dt);
		}
		else
		{
		    dbconvert(dbproc, SYBDATETIME, data, len,
			      SYBCHAR, (BYTE *)buff, -1);
		    sv = newSVpv(buff, 0);
		}
		break;
	      case SYBBINARY:
		if(dbBin0x)
		{
		    strcpy(buff, "0x");
		    dbconvert(dbproc, type, data, len,
			      SYBCHAR, (BYTE *)&buff[2], -1);
		}
		else
		    dbconvert(dbproc, type, data, len,
			      SYBCHAR, (BYTE *)buff, -1);
		sv = newSVpv(buff, 0);
		break;
#if DBLIBVS >= 420
	      case SYBREAL:
		if(dbKeepNumeric)
		    sv = newSVnv(*(DBREAL*)data);
		else
		{
		    sprintf(buff, "%.6f", (double)*(DBREAL *)data);
		    sv = newSVpv(buff, 0);
		}
		break;
	      case SYBDATETIME4:
		if(useDateTime)
		{
		    dbconvert(dbproc, SYBDATETIME4, (BYTE *)data, len,
			      SYBDATETIME, (BYTE *)&dt, -1);
		    sv = newdate(dbproc, &dt);
		}
		else
		{
		    dbconvert(dbproc, SYBDATETIME4, (BYTE *)data, len,
			      SYBCHAR, (BYTE *)buff, -1);
		    sv = newSVpv(buff, 0);
		}
		break;
#if DBLIBVS >= 461
	      case SYBMONEY4:
		dbconvert(dbproc, SYBMONEY4, (BYTE *)data, len,
			  SYBMONEY, (BYTE*)&tv_money, -1);
		if(useMoney)
		    sv = newmoney(dbproc, &tv_money);
		else
		{
		    new_mnytochar(dbproc, &tv_money, buff);
		    sv = newSVpv(buff, 0);
		}
		break;
#endif
#endif

	      default:
		/* 
		 * WARNING!
		 * 
		 * We convert unknown data types to SYBCHAR 
		 * without checking to see if the resulting 
		 * string will fit in the 'buff' variable. 
		 * This isn't very pretty...
		 */
		dbconvert(dbproc, type, (BYTE *)data, len,
			  SYBCHAR, (BYTE *)buff, -1);
		sv = newSVpv(buff, 0);
		break;
	    }
	}
#if defined(UNDEF_BUG)
	++n_null;
#endif
	if(debug_level & TRACE_FETCH)
	    warn("%s->dbnextrow pushes %s on the stack",
		 neatsvpv(dbp, 0), neatsvpv(sv, 0));
	XPUSHs(sv_2mortal(sv));
    }
#if defined(UNDEF_BUG)
    if(!n_null)
	XPUSHs(sv_2mortal(newSVpv("__ALL NULL__", 0)));
#endif
}

void
dbstrcpy(dbp)
	SV *	dbp
CODE:
{
    DBPROCESS *dbproc = getDBPROC(dbp);
    int retval, len;
    char *buff;
    

    ST(0) = sv_newmortal();
    if(dbproc && (len = dbstrlen(dbproc)))
    {
	New(902, buff, len+1, char);
	retval = dbstrcpy(dbproc, 0, -1, buff);
	sv_setpv(ST(0), buff);
	Safefree(buff);
    }
    else
	ST(0) = &PL_sv_undef;
}

void
dbsafestr(dbp, instr, quote_char=NULL)
	SV *	dbp
	char *	instr
	char *	quote_char
CODE:
{
    DBPROCESS *dbproc = getDBPROC(dbp);
    int retval, len, quote;
    char *buff;

    ST(0) = sv_newmortal();
    
    if(!quote_char)
	quote = DBBOTH;
    else if(*quote_char == '"')
	quote = DBDOUBLE;
    else if(*quote_char == '\'')
	quote = DBSINGLE;
    else
    {
	warn("Sybase::DBlib::dbsafestr invalid quote character used.");
	quote = -1;
    }
    if(quote >= 0 && dbproc && (len = strlen(instr)))
    {
	/* twice as much space needed worst case */
	New (902, buff, len * 2 + 1, char);
	retval = dbsafestr(dbproc, instr, -1, buff, -1, quote);
	sv_setpv(ST(0), buff);
	Safefree(buff);
    }
    else
	ST(0) = &PL_sv_undef;
}

char *
dbprtype(dbp, colid)
	SV *	dbp
	int	colid
CODE:
{
    DBPROCESS *dbproc = getDBPROC(dbp);

    RETVAL = dbprtype(dbcoltype(dbproc, colid));
}
 OUTPUT:
RETVAL



int
dbwritetext(dbp, colname, dbp2, colnum, text, log=0)
	SV *	dbp
	char *	colname
	SV *	dbp2
	int	colnum
	SV *	text
	int	log
  CODE:
{
    DBPROCESS *dbproc = getDBPROC(dbp);
    DBPROCESS *dbproc2 = getDBPROC(dbp2);
    char *ptr;
    STRLEN len;

    ptr = SvPV(text, len);

    RETVAL = dbwritetext(dbproc, colname, dbtxptr(dbproc2, colnum),
			 DBTXPLEN, dbtxtimestamp(dbproc2, colnum), (DBBOOL)log,
			 len, (BYTE *)ptr);
}
 OUTPUT:
RETVAL

int
dbpreptext(dbp, colname, dbp2, colnum, size, log=0)
	SV *	dbp
	char *	colname
	SV *	dbp2
	int	colnum
	int	size
	int	log
  CODE:
{
    DBPROCESS *dbproc = getDBPROC(dbp);
    DBPROCESS *dbproc2 = getDBPROC(dbp2);

    RETVAL = dbwritetext(dbproc, colname, dbtxptr(dbproc2, colnum),
			 DBTXPLEN, dbtxtimestamp(dbproc2, colnum), (DBBOOL)log,
			 size, NULL);
}
 OUTPUT:
RETVAL

int
dbreadtext(dbp, buf, size)
	SV *	dbp
	char *	buf
	int	size
CODE:
{
    DBPROCESS *dbproc = getDBPROC(dbp);
 
    Newz(902, buf, size, char);

    RETVAL = dbreadtext(dbproc, buf, size);
}
OUTPUT:
RETVAL
buf if(RETVAL > 0) sv_setpvn(ST(1), buf, RETVAL);
CLEANUP:
Safefree(buf);

int
dbmoretext(dbp, size, buf)
	SV *	dbp
	int	size
	char*	buf
CODE:
{
    DBPROCESS *dbproc = getDBPROC(dbp);

    RETVAL = dbmoretext(dbproc, size, buf);
}
OUTPUT:
RETVAL



void
dberrhandle(err_handle)
	SV *	err_handle
  CODE:
{
    char *name;
    SV *ret = NULL;

    if(err_callback.sub)
	ret = newSVsv(err_callback.sub);
    if(!SvOK(err_handle))
	err_callback.sub = NULL;
    else
    {
	if(!SvROK(err_handle))
	{
	    name = SvPV(err_handle, PL_na);
	    if((err_handle = (SV*) perl_get_cv(name, FALSE)))
		if(err_callback.sub == (SV*) NULL)
		    err_callback.sub = newSVsv(newRV(err_handle));
		else
		    sv_setsv(err_callback.sub, newRV(err_handle));
	}
	else
	{
	    if(err_callback.sub == (SV*) NULL)
		err_callback.sub = newSVsv(err_handle);
	    else
		sv_setsv(err_callback.sub, err_handle);
	}
    }
    if(ret)
	ST(0) = sv_2mortal(ret);
    else
	ST(0) = sv_newmortal();
}

void
dbmsghandle(msg_handle)
	SV *	msg_handle
  CODE:
{
    char *name;
    SV *ret = NULL;

    if(msg_callback.sub)
	ret = newSVsv(msg_callback.sub);
    if(!SvOK(msg_handle))
	msg_callback.sub = NULL;
    else
    {
	if(!SvROK(msg_handle))
	{
	    name = SvPV(msg_handle, PL_na);
	    if((msg_handle = (SV*) perl_get_cv(name, FALSE)))
		if(msg_callback.sub == (SV*)NULL)
		    msg_callback.sub = newSVsv(newRV(msg_handle));
		else
		    sv_setsv(msg_callback.sub, newRV(msg_handle));
	}
	else
	{
	    if(msg_callback.sub == (SV*) NULL)
		msg_callback.sub = newSVsv(msg_handle);
	    else
		sv_setsv(msg_callback.sub, msg_handle);
	}
    }
    if(ret)
	ST(0) = sv_2mortal(ret);
    else
	ST(0) = sv_newmortal();
}


void
dbsetifile(filename)
	char *	filename
  CODE:
{
    if(filename && !*filename)
	filename = NULL;
    dbsetifile(filename);
}

void
dbrecftos(fname)
	char *	fname


char *
dbversion()


int
dbsetdefcharset(char_set)
	char *	char_set

int
dbsetdeflang(language)
	char *	language

int
dbsetmaxprocs(maxprocs)
	int	maxprocs

int
dbgetmaxprocs()


void
DBSETLCHARSET(char_set)
	char *	char_set
  CODE:
{
    DBSETLCHARSET(syb_login, char_set);
}

int
DBSETLENCRYPT(value)
	int value
  CODE:
{
    RETVAL = DBSETLENCRYPT(syb_login, value);
}
OUTPUT:
RETVAL

void
DBSETLNATLANG(language)
	char *	language
  CODE:
{
    DBSETLNATLANG(syb_login, language);
}

void
DBSETLPACKET(packet_size)
	int	packet_size
  CODE:
{
    DBSETLPACKET(syb_login, packet_size);
}

void
DBSETLHOST(host)
	char *	host
  CODE:
{
    DBSETLHOST(syb_login, host);
}


int
dbgetpacket(dbp)
	SV *	dbp
  CODE:
{
    DBPROCESS *dbproc = getDBPROC(dbp);

    RETVAL = dbgetpacket(dbproc);
}
 OUTPUT:
RETVAL


int
DBGETTIME()

int
dbsettime(seconds)
	int	seconds

int
dbsetlogintime(seconds)
	int	seconds

void
dbexit()
CODE:
{
    ++dbexit_called;
    dbexit();
}

void
BCP_SETL(state)
	int	state
  CODE:
{
    BCP_SETL(syb_login, state);
}

int
bcp_getl()
  CODE:
{
    RETVAL = bcp_getl(syb_login);
}
 OUTPUT:
RETVAL

int
bcp_init(dbp,tblname,hfile,errfile,dir)
	SV *	dbp
	char *	tblname
	char *	hfile
	char *	errfile
	int	dir
  CODE:
{
    DBPROCESS *dbproc = getDBPROC(dbp);

    if(hfile && !*hfile)
	hfile = NULL;
    RETVAL = bcp_init(dbproc, tblname, hfile, errfile, dir);
}
 OUTPUT:
RETVAL

int
bcp_meminit(dbp,numcols)
	SV *	dbp
	int	numcols
  CODE:
{
    ConInfo *info = get_ConInfo(dbp);
    DBPROCESS *dbproc = info->dbproc;
    int j;
    BYTE dummy;
    
    /* make sure we free the pointer in the case where bcp_meminit()
       is called several times... */
    if(info->bcp_data) {
	Safefree(info->bcp_data->colPtr);
    } else {
	New (902, info->bcp_data, 1, BCP_DATA);
    }
    New (902, info->bcp_data->colPtr, numcols, BYTE*);
    info->bcp_data->numcols = numcols;
    
    for(j = 1; j <= numcols; ++j)
	bcp_bind(dbproc, &dummy, 0, 1, (BYTE *)NULL, 0, SYBCHAR, j);

    RETVAL = j;
}
 OUTPUT:
RETVAL

int
bcp_sendrow(dbp, ...)
	SV *	dbp
  CODE:
{
    ConInfo *info = get_ConInfo(dbp);
    SV *sv;
    DBPROCESS *dbproc = info->dbproc;
    BCP_DATA *bcp_data = info->bcp_data;
    int j;
    STRLEN slen;

    if(!bcp_data)
	croak("You must call bcp_meminit before calling bcp_sendrow (Sybase::DBlib).");
    
    if(items - 2  > bcp_data->numcols)
	croak("More columns passed to bcp_sendrow than were allocated with bcp_meminit");
    
    for(j = 1; j < items; ++j)
    {
	sv = ST(j);
	if(SvROK(sv))		/* the array has been passed as a reference */
	{
	    AV *av = (AV*)SvRV(sv);
	    I32 len = av_len(av);
	    int i;
	    SV **svp;

	    if(len > bcp_data->numcols)
		croak("More columns passed to bcp_sendrow than were allocated with bcp_meminit");
	    for(i = len; i >= 0; --i)
	    {
		svp = av_fetch(av, i, 0);
		bcp_data->colPtr[i] = (BYTE*)SvPV(*svp, slen);
		if(*svp == &PL_sv_undef)
		    bcp_collen(dbproc, 0, i+1);
		else
		    bcp_collen(dbproc, slen, i+1);
		bcp_colptr(dbproc, (BYTE*)bcp_data->colPtr[i], i+1);
	    }
	    break;
	}
	bcp_data->colPtr[j-1] = (BYTE*)SvPV(sv, slen);
	if(sv == &PL_sv_undef)	/* it's a null data value */
	    bcp_collen(dbproc, 0, j);
	else
	    bcp_collen(dbproc, slen, j);
	bcp_colptr(dbproc, (BYTE*)bcp_data->colPtr[j-1], j);
    }
    RETVAL = bcp_sendrow(dbproc);
}
 OUTPUT:
RETVAL

int
bcp_batch(dbp)
	SV *	dbp
  CODE:
{
    DBPROCESS *dbproc = getDBPROC(dbp);
    
    RETVAL = bcp_batch(dbproc);
}
 OUTPUT:
RETVAL

int
bcp_done(dbp)
	SV *	dbp
CODE:
{
    ConInfo *info = get_ConInfo(dbp);
    DBPROCESS *dbproc = info->dbproc;
    
    RETVAL = bcp_done(dbproc);
    if(info->bcp_data) /* avoid a potential memory leak */
    {
	Safefree(info->bcp_data->colPtr);
	Safefree(info->bcp_data);
	info->bcp_data = NULL;
    }
}
OUTPUT:
RETVAL

int
bcp_control(dbp,field,value)
	SV *	dbp
	int	field
	int	value
  CODE:
{
    DBPROCESS *dbproc = getDBPROC(dbp);

    RETVAL = bcp_control(dbproc, field, value);
}
 OUTPUT:
RETVAL

int
bcp_columns(dbp,colcount)
	SV *	dbp
	int	colcount
  CODE:
{
    DBPROCESS *dbproc = getDBPROC(dbp);

    RETVAL = bcp_columns(dbproc, colcount);
}
 OUTPUT:
RETVAL

int
bcp_colfmt(dbp, host_col, host_type, host_prefixlen, host_collen, host_term, host_termlen, table_col, precision=-1, scale=-1)
	SV *	dbp
	int	host_col
	int	host_type
	int	host_prefixlen
	int	host_collen
	char *	host_term
	int	host_termlen
	int	table_col
	int	precision
	int	scale
  CODE:
{
    DBPROCESS *dbproc = getDBPROC(dbp);
#if DBLIBVS >= 1000 
    DBTYPEINFO typeinfo;
#endif
    
    if(host_term && !*host_term)
	host_term = NULL;
#if DBLIBVS >= 1000
    if(precision != -1 && scale != -1)
    {
	typeinfo.precision = precision;
	typeinfo.scale = scale;
	RETVAL = bcp_colfmt_ps(dbproc, host_col, host_type, host_prefixlen,
			host_collen, (BYTE *)host_term, host_termlen,
			table_col, &typeinfo);
    }
    else
#endif
    RETVAL = bcp_colfmt(dbproc, host_col, host_type, host_prefixlen,
			host_collen, (BYTE *)host_term, host_termlen,
			table_col);
}
 OUTPUT:
RETVAL

int
bcp_collen(dbp, varlen, table_column)
	SV *	dbp
	int	varlen
	int	table_column
  CODE:
{
    DBPROCESS *dbproc = getDBPROC(dbp);

    RETVAL = bcp_collen(dbproc, varlen, table_column);
}
 OUTPUT:
RETVAL

void
bcp_exec(dbp)
	SV *	dbp
  PPCODE:
{
    DBPROCESS *dbproc = getDBPROC(dbp);
    DBINT rows;
    int j;

    j = bcp_exec(dbproc, &rows);

    XPUSHs(sv_2mortal(newSVnv(j)));
    XPUSHs(sv_2mortal(newSViv(rows)));
}

int
bcp_readfmt(dbp, filename)
	SV *	dbp
	char *	filename
  CODE:
{
    DBPROCESS *dbproc = getDBPROC(dbp);

    RETVAL = bcp_readfmt(dbproc, filename);
}
 OUTPUT:
RETVAL

int
bcp_writefmt(dbp, filename)
	SV *	dbp
	char *	filename
  CODE:
{
    DBPROCESS *dbproc = getDBPROC(dbp);

    RETVAL = bcp_writefmt(dbproc, filename);
}
 OUTPUT:
RETVAL

void
dbmny4add(dbp, m1, m2)
	SV *	dbp
	char *	m1
	char *	m2
  PPCODE:
{
    DBPROCESS *dbproc = getDBPROC(dbp);
    DBMONEY4 mm1, mm2, mresult;
    DBCHAR mnybuf[40];
    int retval;

    if (dbconvert(dbproc, SYBCHAR,
		  (BYTE *)m1, (DBINT)-1,
		  SYBMONEY4, (BYTE*)&mm1, (DBINT)-1) == -1)
	croak("Invalid dbconvert() for DBMONEY $m1 parameter");
    
    if (dbconvert(dbproc, SYBCHAR,
		  (BYTE *)m2, (DBINT)-1,
		  SYBMONEY4, (BYTE*)&mm2, (DBINT)-1) == -1)
	croak("Invalid dbconvert() for DBMONEY $m2 parameter");

    retval = dbmny4add(dbproc, &mm1, &mm2, &mresult);

    new_mny4tochar(dbproc, &mresult, mnybuf);

    XPUSHs(sv_2mortal(newSViv(retval)));
    XPUSHs(sv_2mortal(newSVpv(mnybuf, 0)));
}

void
dbmny4divide(dbp, m1, m2)
	SV *	dbp
	char *	m1
	char *	m2
  PPCODE:
{
    DBPROCESS *dbproc = getDBPROC(dbp);
    DBMONEY4 mm1, mm2, mresult;
    DBCHAR mnybuf[40];
    int retval;

    if (dbconvert(dbproc, SYBCHAR,
		  (BYTE *)m1, (DBINT)-1,
		  SYBMONEY4, (BYTE*)&mm1, (DBINT)-1) == -1)
	croak("Invalid dbconvert() for DBMONEY $m1 parameter");
    
    if (dbconvert(dbproc, SYBCHAR,
		  (BYTE *)m2, (DBINT)-1,
		  SYBMONEY4, (BYTE*)&mm2, (DBINT)-1) == -1)
	croak("Invalid dbconvert() for DBMONEY $m2 parameter");

    retval = dbmny4divide(dbproc, &mm1, &mm2, &mresult);

    new_mny4tochar(dbproc, &mresult, mnybuf);

    XPUSHs(sv_2mortal(newSViv(retval)));
    XPUSHs(sv_2mortal(newSVpv(mnybuf, 0)));
}

void
dbmny4minus(dbp, m1)
	SV *	dbp
	char *	m1
  PPCODE:
{
    DBPROCESS *dbproc = getDBPROC(dbp);
    DBMONEY4 mm1, mresult;
    DBCHAR mnybuf[40];
    int retval;

    if (dbconvert(dbproc, SYBCHAR,
		  (BYTE *)m1, (DBINT)-1,
		  SYBMONEY4, (BYTE*)&mm1, (DBINT)-1) == -1)
	croak("Invalid dbconvert() for DBMONEY $m1 parameter");
    

    retval = dbmny4minus(dbproc, &mm1, &mresult);

    new_mny4tochar(dbproc, &mresult, mnybuf);

    XPUSHs(sv_2mortal(newSViv(retval)));
    XPUSHs(sv_2mortal(newSVpv(mnybuf, 0)));
}

void
dbmny4mul(dbp, m1, m2)
	SV *	dbp
	char *	m1
	char *	m2
  PPCODE:
{
    DBPROCESS *dbproc = getDBPROC(dbp);
    DBMONEY4 mm1, mm2, mresult;
    DBCHAR mnybuf[40];
    int retval;

    if (dbconvert(dbproc, SYBCHAR,
		  (BYTE *)m1, (DBINT)-1,
		  SYBMONEY4, (BYTE*)&mm1, (DBINT)-1) == -1)
	croak("Invalid dbconvert() for DBMONEY $m1 parameter");
    
    if (dbconvert(dbproc, SYBCHAR,
		  (BYTE *)m2, (DBINT)-1,
		  SYBMONEY4, (BYTE*)&mm2, (DBINT)-1) == -1)
	croak("Invalid dbconvert() for DBMONEY $m2 parameter");

    retval = dbmny4mul(dbproc, &mm1, &mm2, &mresult);

    new_mny4tochar(dbproc, &mresult, mnybuf);

    XPUSHs(sv_2mortal(newSViv(retval)));
    XPUSHs(sv_2mortal(newSVpv(mnybuf, 0)));
}

void
dbmny4sub(dbp, m1, m2)
	SV *	dbp
	char *	m1
	char *	m2
  PPCODE:
{
    DBPROCESS *dbproc = getDBPROC(dbp);
    DBMONEY4 mm1, mm2, mresult;
    DBCHAR mnybuf[40];
    int retval;

    if (dbconvert(dbproc, SYBCHAR,
		  (BYTE *)m1, (DBINT)-1,
		  SYBMONEY4, (BYTE*)&mm1, (DBINT)-1) == -1)
	croak("Invalid dbconvert() for DBMONEY $m1 parameter");
    
    if (dbconvert(dbproc, SYBCHAR,
		  (BYTE *)m2, (DBINT)-1,
		  SYBMONEY4, (BYTE*)&mm2, (DBINT)-1) == -1)
	croak("Invalid dbconvert() for DBMONEY $m2 parameter");

    retval = dbmny4sub(dbproc, &mm1, &mm2, &mresult);

    new_mny4tochar(dbproc, &mresult, mnybuf);

    XPUSHs(sv_2mortal(newSViv(retval)));
    XPUSHs(sv_2mortal(newSVpv(mnybuf, 0)));
}

void
dbmny4zero(dbp)
	SV *	dbp
  PPCODE:
{
    DBPROCESS *dbproc = getDBPROC(dbp);
    DBMONEY4 mresult;
    DBCHAR mnybuf[40];
    int retval;

    retval = dbmny4zero(dbproc, &mresult);

    new_mny4tochar(dbproc, &mresult, mnybuf);

    XPUSHs(sv_2mortal(newSViv(retval)));
    XPUSHs(sv_2mortal(newSVpv(mnybuf, 0)));
}

int
dbmny4cmp(dbp, m1, m2)
	SV *	dbp
	char *	m1
	char *	m2
  CODE:
{
    DBPROCESS *dbproc = getDBPROC(dbp);
    DBMONEY4 mm1, mm2;

    if (dbconvert(dbproc, SYBCHAR,
		  (BYTE *)m1, (DBINT)-1,
		  SYBMONEY4, (BYTE*)&mm1, (DBINT)-1) == -1)
	croak("Invalid dbconvert() for DBMONEY $m1 parameter");
    
    if (dbconvert(dbproc, SYBCHAR,
		  (BYTE *)m2, (DBINT)-1,
		  SYBMONEY4, (BYTE*)&mm2, (DBINT)-1) == -1)
	croak("Invalid dbconvert() for DBMONEY $m2 parameter");

    RETVAL = dbmny4cmp(dbproc, &mm1, &mm2);
}
 OUTPUT:
RETVAL


void
dbmnyadd(dbp, m1, m2)
	SV *	dbp
	char *	m1
	char *	m2
  PPCODE:
{
    DBPROCESS *dbproc = getDBPROC(dbp);
    DBMONEY mm1, mm2, mresult;
    DBCHAR mnybuf[40];
    int retval;

    if (dbconvert(dbproc, SYBCHAR,
		  (BYTE *)m1, (DBINT)-1,
		  SYBMONEY, (BYTE*)&mm1, (DBINT)-1) == -1)
	croak("Invalid dbconvert() for DBMONEY $m1 parameter");
    
    if (dbconvert(dbproc, SYBCHAR,
		  (BYTE *)m2, (DBINT)-1,
		  SYBMONEY, (BYTE*)&mm2, (DBINT)-1) == -1)
	croak("Invalid dbconvert() for DBMONEY $m2 parameter");

    retval = dbmnyadd(dbproc, &mm1, &mm2, &mresult);

    new_mnytochar(dbproc, &mresult, mnybuf);

    XPUSHs(sv_2mortal(newSViv(retval)));
    XPUSHs(sv_2mortal(newSVpv(mnybuf, 0)));
}

void
dbmnydivide(dbp, m1, m2)
	SV *	dbp
	char *	m1
	char *	m2
  PPCODE:
{
    DBPROCESS *dbproc = getDBPROC(dbp);
    DBMONEY mm1, mm2, mresult;
    DBCHAR mnybuf[40];
    int retval;

    if (dbconvert(dbproc, SYBCHAR,
		  (BYTE *)m1, (DBINT)-1,
		  SYBMONEY, (BYTE*)&mm1, (DBINT)-1) == -1)
	croak("Invalid dbconvert() for DBMONEY $m1 parameter");
    
    if (dbconvert(dbproc, SYBCHAR,
		  (BYTE *)m2, (DBINT)-1,
		  SYBMONEY, (BYTE*)&mm2, (DBINT)-1) == -1)
	croak("Invalid dbconvert() for DBMONEY $m2 parameter");

    retval = dbmnydivide(dbproc, &mm1, &mm2, &mresult);

    new_mnytochar(dbproc, &mresult, mnybuf);

    XPUSHs(sv_2mortal(newSViv(retval)));
    XPUSHs(sv_2mortal(newSVpv(mnybuf, 0)));
}

void
dbmnyminus(dbp, m1)
	SV *	dbp
	char *	m1
  PPCODE:
{
    DBPROCESS *dbproc = getDBPROC(dbp);
    DBMONEY mm1, mresult;
    DBCHAR mnybuf[40];
    int retval;

    if (dbconvert(dbproc, SYBCHAR,
		  (BYTE *)m1, (DBINT)-1,
		  SYBMONEY, (BYTE*)&mm1, (DBINT)-1) == -1)
	croak("Invalid dbconvert() for DBMONEY $m1 parameter");
    
    retval = dbmnyminus(dbproc, &mm1, &mresult);

    new_mnytochar(dbproc, &mresult, mnybuf);

    XPUSHs(sv_2mortal(newSViv(retval)));
    XPUSHs(sv_2mortal(newSVpv(mnybuf, 0)));
}

void
dbmnymul(dbp, m1, m2)
	SV *	dbp
	char *	m1
	char *	m2
  PPCODE:
{
    DBPROCESS *dbproc = getDBPROC(dbp);
    DBMONEY mm1, mm2, mresult;
    DBCHAR mnybuf[40];
    int retval;

    if (dbconvert(dbproc, SYBCHAR,
		  (BYTE *)m1, (DBINT)-1,
		  SYBMONEY, (BYTE*)&mm1, (DBINT)-1) == -1)
	croak("Invalid dbconvert() for DBMONEY $m1 parameter");
    
    if (dbconvert(dbproc, SYBCHAR,
		  (BYTE *)m2, (DBINT)-1,
		  SYBMONEY, (BYTE*)&mm2, (DBINT)-1) == -1)
	croak("Invalid dbconvert() for DBMONEY $m2 parameter");

    retval = dbmnymul(dbproc, &mm1, &mm2, &mresult);

    new_mnytochar(dbproc, &mresult, mnybuf);

    XPUSHs(sv_2mortal(newSViv(retval)));
    XPUSHs(sv_2mortal(newSVpv(mnybuf, 0)));
}

void
dbmnysub(dbp, m1, m2)
	SV *	dbp
	char *	m1
	char *	m2
  PPCODE:
{
    DBPROCESS *dbproc = getDBPROC(dbp);
    DBMONEY mm1, mm2, mresult;
    DBCHAR mnybuf[40];
    int retval;

    if (dbconvert(dbproc, SYBCHAR,
		  (BYTE *)m1, (DBINT)-1,
		  SYBMONEY, (BYTE*)&mm1, (DBINT)-1) == -1)
	croak("Invalid dbconvert() for DBMONEY $m1 parameter");
    
    if (dbconvert(dbproc, SYBCHAR,
		  (BYTE *)m2, (DBINT)-1,
		  SYBMONEY, (BYTE*)&mm2, (DBINT)-1) == -1)
	croak("Invalid dbconvert() for DBMONEY $m2 parameter");

    retval = dbmnysub(dbproc, &mm1, &mm2, &mresult);

    new_mnytochar(dbproc, &mresult, mnybuf);

    XPUSHs(sv_2mortal(newSViv(retval)));
    XPUSHs(sv_2mortal(newSVpv(mnybuf, 0)));
}

void
dbmnydec(dbp, m1)
	SV *	dbp
	char *	m1
  PPCODE:
{
    DBPROCESS *dbproc = getDBPROC(dbp);
    DBMONEY mresult;
    DBCHAR mnybuf[40];
    int retval;

    if (dbconvert(dbproc, SYBCHAR,
		  (BYTE *)m1, (DBINT)-1,
		  SYBMONEY, (BYTE*)&mresult, (DBINT)-1) == -1)
	croak("Invalid dbconvert() for DBMONEY $m1 parameter");
    
    retval = dbmnydec(dbproc, &mresult);

    new_mnytochar(dbproc, &mresult, mnybuf);

    XPUSHs(sv_2mortal(newSViv(retval)));
    XPUSHs(sv_2mortal(newSVpv(mnybuf, 0)));
}

void
dbmnyinc(dbp, m1)
	SV *	dbp
	char *	m1
  PPCODE:
{
    DBPROCESS *dbproc = getDBPROC(dbp);
    DBMONEY mresult;
    DBCHAR mnybuf[40];
    int retval;

    if (dbconvert(dbproc, SYBCHAR,
		  (BYTE *)m1, (DBINT)-1,
		  SYBMONEY, (BYTE*)&mresult, (DBINT)-1) == -1)
	croak("Invalid dbconvert() for DBMONEY $m1 parameter");
    
    retval = dbmnyinc(dbproc, &mresult);

    new_mnytochar(dbproc, &mresult, mnybuf);

    XPUSHs(sv_2mortal(newSViv(retval)));
    XPUSHs(sv_2mortal(newSVpv(mnybuf, 0)));
}

void
dbmnydown(dbp, m1, i1)
	SV *	dbp
	char *	m1
	int	i1
  PPCODE:
{
    DBPROCESS *dbproc = getDBPROC(dbp);
    DBMONEY mresult;
    DBCHAR mnybuf[40];
    int retval, iresult = 0;

    if (dbconvert(dbproc, SYBCHAR,
		  (BYTE *)m1, (DBINT)-1,
		  SYBMONEY, (BYTE*)&mresult, (DBINT)-1) == -1)
	croak("Invalid dbconvert() for DBMONEY $m1 parameter");
    
    retval = dbmnydown(dbproc, &mresult, i1, &iresult);

    new_mnytochar(dbproc, &mresult, mnybuf);

    XPUSHs(sv_2mortal(newSViv(retval)));
    XPUSHs(sv_2mortal(newSVpv(mnybuf, 0)));
    XPUSHs(sv_2mortal(newSViv(iresult)));
}

void
dbmnyinit(dbp, m1, i1)
	SV *	dbp
	char *	m1
	int	i1
  PPCODE:
{
    DBPROCESS *dbproc = getDBPROC(dbp);
    DBMONEY mresult;
    DBCHAR mnybuf[40];
    DBBOOL bresult = (DBBOOL)FALSE;
    int retval;

    if (dbconvert(dbproc, SYBCHAR,
		  (BYTE *)m1, (DBINT)-1,
		  SYBMONEY, (BYTE*)&mresult, (DBINT)-1) == -1)
	croak("Invalid dbconvert() for DBMONEY $m1 parameter");
    
    retval = dbmnyinit(dbproc, &mresult, i1, &bresult);

    new_mnytochar(dbproc, &mresult, mnybuf);

    XPUSHs(sv_2mortal(newSViv(retval)));
    XPUSHs(sv_2mortal(newSVpv(mnybuf, 0)));
    XPUSHs(sv_2mortal(newSViv((int)bresult)));
}

void
dbmnyscale(dbp, m1, i1, i2)
	SV *	dbp
	char *	m1
	int	i1
	int	i2
  PPCODE:
{
    DBPROCESS *dbproc = getDBPROC(dbp);
    DBMONEY mresult;
    DBCHAR mnybuf[40];
    int retval;

    if (dbconvert(dbproc, SYBCHAR,
		  (BYTE *)m1, (DBINT)-1,
		  SYBMONEY, (BYTE*)&mresult, (DBINT)-1) == -1)
	croak("Invalid dbconvert() for DBMONEY $m1 parameter");
    
    retval = dbmnyscale(dbproc, &mresult, i1, i2);

    new_mnytochar(dbproc, &mresult, mnybuf);

    XPUSHs(sv_2mortal(newSViv(retval)));
    XPUSHs(sv_2mortal(newSVpv(mnybuf, 0)));
}

void
dbmnyzero(dbp)
	SV *	dbp
  PPCODE:
{
    DBPROCESS *dbproc = getDBPROC(dbp);
    DBMONEY mresult;
    DBCHAR mnybuf[40];
    int retval;

    retval = dbmnyzero(dbproc, &mresult);

    new_mnytochar(dbproc, &mresult, mnybuf);

    XPUSHs(sv_2mortal(newSViv(retval)));
    XPUSHs(sv_2mortal(newSVpv(mnybuf, 0)));
}


void
dbmnymaxneg(dbp)
	SV *	dbp
  PPCODE:
{
    DBPROCESS *dbproc = getDBPROC(dbp);
    DBMONEY mresult;
    DBCHAR mnybuf[40];
    int retval;

    retval = dbmnymaxneg(dbproc, &mresult);

    new_mnytochar(dbproc, &mresult, mnybuf);

    XPUSHs(sv_2mortal(newSViv(retval)));
    XPUSHs(sv_2mortal(newSVpv(mnybuf, 0)));
}

void
dbmnymaxpos(dbp)
	SV *	dbp
  PPCODE:
{
    DBPROCESS *dbproc = getDBPROC(dbp);
    DBMONEY mresult;
    DBCHAR mnybuf[40];
    int retval;

    retval = dbmnymaxpos(dbproc, &mresult);

    new_mnytochar(dbproc, &mresult, mnybuf);

    XPUSHs(sv_2mortal(newSViv(retval)));
    XPUSHs(sv_2mortal(newSVpv(mnybuf, 0)));
}

void
dbmnyndigit(dbp, m1)
	SV *	dbp
	char *	m1
  PPCODE:
{
    DBPROCESS *dbproc = getDBPROC(dbp);
    DBMONEY mresult;
    DBBOOL  bresult = (DBBOOL)FALSE;
    DBCHAR mnybuf[40], dgtbuf[10];
    int retval;

    if (dbconvert(dbproc, SYBCHAR,
		  (BYTE *)m1, (DBINT)-1,
		  SYBMONEY, (BYTE*)&mresult, (DBINT)-1) == -1)
	croak("Invalid dbconvert() for DBMONEY $m1 parameter");
    
    retval = dbmnyndigit(dbproc, &mresult, dgtbuf, &bresult);

    new_mnytochar(dbproc, &mresult, mnybuf);

    XPUSHs(sv_2mortal(newSViv(retval)));
    XPUSHs(sv_2mortal(newSVpv(mnybuf, 0)));
    XPUSHs(sv_2mortal(newSVpv(dgtbuf, 0)));
    XPUSHs(sv_2mortal(newSViv((int)bresult)));
}


int
dbmnycmp(dbp, m1, m2)
	SV *	dbp
	char *	m1
	char *	m2
  CODE:
{
    DBPROCESS *dbproc = getDBPROC(dbp);
    DBMONEY mm1, mm2;

    if (dbconvert(dbproc, SYBCHAR,
		  (BYTE *)m1, (DBINT)-1,
		  SYBMONEY, (BYTE*)&mm1, (DBINT)-1) == -1)
	croak("Invalid dbconvert() for DBMONEY $m1 parameter");
    
    if (dbconvert(dbproc, SYBCHAR,
		  (BYTE *)m2, (DBINT)-1,
		  SYBMONEY, (BYTE*)&mm2, (DBINT)-1) == -1)
	croak("Invalid dbconvert() for DBMONEY $m2 parameter");
    RETVAL = dbmnycmp(dbproc, &mm1, &mm2);
}
 OUTPUT:
RETVAL

void
dbcomputeinfo(dbp, computeID, column)
	SV *	dbp
	int 	computeID
	int	column
  PPCODE:
{
    DBPROCESS *dbproc = getDBPROC(dbp);
    int retval;

    retval = dbaltcolid(dbproc, computeID, column);
    XPUSHs(sv_2mortal(newSVpv("colid", 0)));
    XPUSHs(sv_2mortal(newSViv(retval)));

    retval = dbaltlen(dbproc, computeID, column);
    XPUSHs(sv_2mortal(newSVpv("len", 0)));
    XPUSHs(sv_2mortal(newSViv(retval)));

    retval = dbaltop(dbproc, computeID, column);
    XPUSHs(sv_2mortal(newSVpv("op", 0)));
    XPUSHs(sv_2mortal(newSViv(retval)));

    retval = dbalttype(dbproc, computeID, column);
    XPUSHs(sv_2mortal(newSVpv("type", 0)));
    XPUSHs(sv_2mortal(newSViv(retval)));

    retval = dbaltutype(dbproc, computeID, column);
    XPUSHs(sv_2mortal(newSVpv("utype", 0)));
    XPUSHs(sv_2mortal(newSViv(retval)));
}

void
dbbylist(dbp, compute_id)
	SV *	dbp
	int	compute_id
CODE:
{
    int i;
    SV *rv;
    AV *av = newAV();
    DBPROCESS *dbproc = getDBPROC(dbp);
    int size;

    BYTE *bylist = dbbylist(dbproc, compute_id, &size);
    if(bylist == NULL) {
	ST(0) = &PL_sv_undef;
    } else {
	for(i = 0; i < size; ++i) {
	    av_push(av, newSViv((int)bylist[i]));
	}
	rv = newRV(sv_2mortal((SV*)av));
	ST(0) = rv;
    }
}


int
DBDEAD(dbp)
      SV *    dbp
  CODE:
{
    DBPROCESS *dbproc = getDBPROC(dbp);

    RETVAL = (DBBOOL)DBDEAD(dbproc);
}
  OUTPUT:
RETVAL

int
dbspid(dbp)
	SV *	dbp
CODE:
{
    DBPROCESS *dbproc = getDBPROC(dbp);

    RETVAL = dbspid(dbproc);
}
  OUTPUT:
RETVAL

void
open_commit(package="Sybase::DBlib",user=NULL,pwd=NULL,server=NULL,appname=NULL,attr=&PL_sv_undef)
	char *	package
	char *	user
	char *	pwd
	char *	server
	char *	appname
	SV *	attr
  CODE:
{
    DBPROCESS *dbproc;
    SV *sv;
    
    if(user && *user)
	DBSETLUSER(syb_login, user);
    if(pwd && *pwd)
	DBSETLPWD(syb_login, pwd);
    if(server && !*server)
	server = NULL;
    if(appname && *appname)
	DBSETLAPP(syb_login, appname);
    if(!(dbproc = open_commit(syb_login, server)))
    {
	ST(0) = sv_newmortal();
    }
    else
    {
	ConInfo *info;

	Newz(902, info, 1, ConInfo);
	info->dbproc = dbproc;
	sv = newdbh(info, package, attr);
	if(debug_level & TRACE_CREATE)
	    warn("Created %s", neatsvpv(sv, 0));
    
	ST(0) = sv_2mortal(sv);
    }
}

int
start_xact(dbp, app_name, xact_name, site_count)
	SV *	dbp
	char *	app_name
	char *	xact_name
	int	site_count
  CODE:
{
    DBPROCESS *dbproc = getDBPROC(dbp);

    RETVAL = start_xact(dbproc, app_name, xact_name, site_count);
}
  OUTPUT:
RETVAL

int
stat_xact(dbp, id)
	SV *	dbp
	int	id
  CODE:
{
    DBPROCESS *dbproc = getDBPROC(dbp);

    RETVAL = stat_xact(dbproc, id);
}
  OUTPUT:
RETVAL

int
scan_xact(dbp, id)
	SV *	dbp
	int	id
  CODE:
{
    DBPROCESS *dbproc = getDBPROC(dbp);

    RETVAL = scan_xact(dbproc, id);
}
  OUTPUT:
RETVAL

int
commit_xact(dbp, id)
	SV *	dbp
	int	id
  CODE:
{
    DBPROCESS *dbproc = getDBPROC(dbp);

    RETVAL = commit_xact(dbproc, id);
}
  OUTPUT:
RETVAL

void
close_commit(dbp)
	SV *	dbp
  CODE:
{
    DBPROCESS *dbproc = getDBPROC(dbp);

    close_commit(dbproc);
}


int
abort_xact(dbp, id)
	SV *	dbp
	int	id
  CODE:
{
    DBPROCESS *dbproc = getDBPROC(dbp);

    RETVAL = abort_xact(dbproc, id);
}
  OUTPUT:
RETVAL

void
build_xact_string(xact_name, service_name, commid)
	char *	xact_name
	char *	service_name
	int	commid
  PPCODE:
{
    char *buf;

    New (902, buf, 15 + strlen(xact_name) + strlen(service_name), char);

    build_xact_string(xact_name, service_name, commid, buf);

    XPUSHs(sv_2mortal(newSVpv(buf, 0)));

    Safefree(buf);
}

int
remove_xact(dbp, id, site_count)
        SV *    dbp
        int     id
        int     site_count
  CODE:
{
    DBPROCESS *dbproc = getDBPROC(dbp);

    RETVAL = remove_xact(dbproc, id, site_count);
}
  OUTPUT:
RETVAL

int
dbrpcinit(dbp, rpcname, opt)
	SV *	dbp
	char *	rpcname
	int	opt
  CODE:
{
    DBPROCESS *dbproc = getDBPROC(dbp);

    RETVAL = dbrpcinit(dbproc, rpcname, opt);
}
  OUTPUT:
RETVAL

int
dbrpcparam(dbp, parname, status, type, maxlen, datalen, value)
	SV *	dbp
	char *	parname
	int	status
	int	type
	int	maxlen
	int	datalen
	char *	value
  CODE:
{
#if !defined(max)
#define max(a, b)	((a) > (b) ? (a) : (b))
#endif
    ConInfo *info = get_ConInfo(dbp);
    DBPROCESS *dbproc = info->dbproc;
    HV *hv;
    SV **svp, *sv;
    struct RpcInfo *head = info->rpcInfo, *ptr = NULL;
    char buff[256];

    /* FIXME
       The 'value' parameter should be an SV*, so that we can pass DateTime
       or Money values directly, without converting them
       to char* first. */
    
    New(902, ptr, 1, struct RpcInfo);
    switch(type)
    {
      case SYBBIT:
      case SYBINT1:
      case SYBINT2:
      case SYBINT4:
	ptr->type = SYBINT4;
	ptr->u.i = atoi(value);
	ptr->value = &ptr->u.i;
	break;
      case SYBFLT8:
      case SYBMONEY:
#if DBLIBVS >= 420
      case SYBREAL:
#if DBLIBVS >= 461
      case SYBMONEY4:
#if DBLIBVS >= 1000
      case SYBNUMERIC:		/* dunno if this is the right place */
      case SYBDECIMAL:
#endif
#endif
#endif
	ptr->type = SYBFLT8;
	ptr->u.f = atof(value);
	ptr->value = &ptr->u.f;
	break;
      case SYBCHAR:
      case SYBVARCHAR:
      case SYBDATETIME:
      case SYBTEXT:
#if DBLIBVS >= 420
      case SYBDATETIME4:
#endif
	ptr->type = SYBCHAR;
	ptr->size = max(maxlen, datalen);
	New(902, ptr->u.c, ptr->size+1, char);
	strcpy(ptr->u.c, value);
	ptr->value = ptr->u.c;
	break;
      default:
	sprintf(buff, "Invalid type value (%d) for dbrpcparam()", type);
	croak(buff);
    }
    ptr->next = head;
    head = ptr;
    info->rpcInfo = head;
    
    RETVAL = dbrpcparam(dbproc, parname, status, ptr->type, maxlen, datalen, ptr->value);
}
  OUTPUT:
RETVAL

int
dbrpcsend(dbp, no_ok=0)
	SV *	dbp
	int	no_ok
  CODE:
{
    ConInfo *info = get_ConInfo(dbp);
    DBPROCESS *dbproc = info->dbproc;
    HV *hv;
    SV **svp, *sv;
    struct RpcInfo *ptr = info->rpcInfo, *next = NULL;
    
    RETVAL = dbrpcsend(dbproc);

    /* Call dbsqlok() if caller doesn't say not to */
    if(!no_ok && RETVAL != FAIL)
	RETVAL = dbsqlok(dbproc);
    /* clean-up the rpcParam list
       according to the DBlib docs, it should be safe to this here. */
    if(ptr)
    {
	for(; ptr; ptr = next)
	{
	    next = ptr->next;
	    if(ptr->type == SYBCHAR)
		Safefree(ptr->u.c);
	    Safefree(ptr);
	}
	info->rpcInfo = NULL;
    }
}
  OUTPUT:
RETVAL

int
dbreginit(dbp, proc_name)
	SV *	dbp
	char *	proc_name
CODE:
{
    ConInfo *info = get_ConInfo(dbp);
    DBPROCESS *dbproc = info->dbproc;

				/* XXX pass DBNULLTERM? */

    RETVAL = dbreginit(dbproc, proc_name, strlen(proc_name));
}
OUTPUT:
RETVAL

int
dbreglist(dbp)
	SV *	dbp
CODE:
{
    ConInfo *info = get_ConInfo(dbp);
    DBPROCESS *dbproc = info->dbproc;

    RETVAL = dbreglist(dbproc);
}
OUTPUT:
RETVAL


int
dbregparam(dbp, parname, type, datalen, value)
        SV *    dbp
        char *  parname
        int     type
        int     datalen
        char *  value
  CODE:
{
#if !defined(max)
#define max(a, b)       ((a) > (b) ? (a) : (b))
#endif
    ConInfo *info = get_ConInfo(dbp);
    DBPROCESS *dbproc = info->dbproc;
    HV *hv;
    SV **svp, *sv;
    struct RpcInfo *head = info->rpcInfo, *ptr = NULL;
    char buff[256];

    /* FIXME
       The 'value' parameter should be an SV*, so that we can pass DateTime
       or Money values directly, without converting them
       to char* first. */

    New(902, ptr, 1, struct RpcInfo);
    switch(type)
    {
      case SYBBIT:
      case SYBINT1:
      case SYBINT2:
      case SYBINT4:
        ptr->type = SYBINT4;
        ptr->u.i = atoi(value);
        ptr->value = &ptr->u.i;
        break;
      case SYBFLT8:
      case SYBMONEY:
#if DBLIBVS >= 420
      case SYBREAL:
#if DBLIBVS >= 461
      case SYBMONEY4:
#if DBLIBVS >= 1000
      case SYBNUMERIC:          /* dunno if this is the right place */
      case SYBDECIMAL:
#endif
#endif
#endif
        ptr->type = SYBFLT8;
        ptr->u.f = atof(value);
        ptr->value = &ptr->u.f;
        break;
      case SYBCHAR:
      case SYBVARCHAR:
      case SYBDATETIME:
      case SYBTEXT:
#if DBLIBVS >= 420
      case SYBDATETIME4:
#endif
        ptr->type = SYBCHAR;
        ptr->size = datalen;
        New(902, ptr->u.c, ptr->size+1, char);
        strcpy(ptr->u.c, value);
        ptr->value = ptr->u.c;
        break;
      default:
        sprintf(buff, "Invalid type value (%d) for dbregparam()", type);
        croak(buff);
    }
    ptr->next = head;
    head = ptr;
    info->rpcInfo = head;

    RETVAL = dbregparam(dbproc, parname, ptr->type, datalen, ptr->value);
}
  OUTPUT:
RETVAL


int
dbregexec(dbp, opt = 0)
        SV *    dbp
        int     opt
  CODE:
{
    ConInfo *info = get_ConInfo(dbp);
    DBPROCESS *dbproc = info->dbproc;
    struct RpcInfo *ptr = info->rpcInfo, *next = NULL;

    RETVAL = dbregexec(dbproc, opt);

    /* clean-up the rpcParam list
       according to the DBlib docs, it should be safe to this here. */
    if(ptr)
    {
        for(; ptr; ptr = next)
        {
            next = ptr->next;
            if(ptr->type == SYBCHAR)
                Safefree(ptr->u.c);
            Safefree(ptr);
        }
        info->rpcInfo = NULL;
    }
}
  OUTPUT:
RETVAL



int
dbrpwset(srvname, pwd)
	char *	srvname
	char *	pwd
  CODE:
{
    if(!srvname || strlen(srvname) == 0)
	srvname = NULL;
    RETVAL = dbrpwset(syb_login, srvname, pwd, strlen(pwd));
}
  OUTPUT:
RETVAL

void
dbrpwclr()
  CODE:
{
    dbrpwclr(syb_login);
}


void
newdate(dbp, dt=NULL)
	SV *	dbp
	char *	dt
  CODE:
{
    DBPROCESS *dbproc = getDBPROC(dbp);
    DateTime d;

    d = to_datetime(dt);
    ST(0) = sv_2mortal(newdate(dbproc, &d.date));
}

void
newmoney(dbp, m=NULL)
	SV *	dbp
	char *	m
  CODE:
{
    DBPROCESS *dbproc = getDBPROC(dbp);
    Money mn;

    mn = to_money(m);
    ST(0) = sv_2mortal(newmoney(dbproc, &mn.mn));
}

MODULE = Sybase::DBlib		PACKAGE = Sybase::DBlib::DateTime


void
DESTROY(valp)
	SV *	valp
  CODE:
{
    DateTime *ptr;
    if (sv_isa(valp, DateTimePkg)) {
	IV tmp = SvIV((SV*)SvRV(valp));
	ptr = (DateTime *) tmp;
    }
    else
	croak("valp is not of type %s", DateTimePkg);

    if(debug_level & TRACE_DESTROY)
	warn("Destroying %s", neatsvpv(valp, 0));

    Safefree(ptr);
}

char *
str(valp)
	SV *	valp
  CODE:
{
    DateTime *ptr;
    if (sv_isa(valp, DateTimePkg)) {
	IV tmp = SvIV((SV*)SvRV(valp));
	ptr = (DateTime *) tmp;
    }
    else
	croak("valp is not of type %s", DateTimePkg);
    
    RETVAL = from_datetime(ptr);

    if(debug_level & TRACE_OVERLOAD)
	warn("%s->str == %s", neatsvpv(valp,0), RETVAL);
}
 OUTPUT:
RETVAL

void
crack(valp)
	SV *	valp
  PPCODE:
{
    DBDATEREC rec;
    DateTime *ptr;
    if (sv_isa(valp, DateTimePkg)) {
	IV tmp = SvIV((SV*)SvRV(valp));
	ptr = (DateTime *) tmp;
    }
    else
	croak("valp is not of type %s", DateTimePkg);
    if(dbdatecrack(ptr->dbproc, &rec, &ptr->date) == SUCCEED)
    {
	XPUSHs(sv_2mortal(newSViv(rec.dateyear)));
	XPUSHs(sv_2mortal(newSViv(rec.datemonth)));
	XPUSHs(sv_2mortal(newSViv(rec.datedmonth)));
	XPUSHs(sv_2mortal(newSViv(rec.datedyear)));
	XPUSHs(sv_2mortal(newSViv(rec.datedweek)));
	XPUSHs(sv_2mortal(newSViv(rec.datehour)));
	XPUSHs(sv_2mortal(newSViv(rec.dateminute)));
	XPUSHs(sv_2mortal(newSViv(rec.datesecond)));
	XPUSHs(sv_2mortal(newSViv(rec.datemsecond)));
	XPUSHs(sv_2mortal(newSViv(rec.datetzone)));
    }
}

int
cmp(valp, valp2, ord = &PL_sv_undef)
	SV *	valp
	SV *	valp2
	SV *	ord
  CODE:
{
    SV *sv;
    DateTime *d1, *d2, *tmp, dt;
    DBPROCESS *dbproc;
    if (sv_isa(valp, DateTimePkg)) {
	IV tmp = SvIV((SV*)SvRV(valp));
	d1 = (DateTime*) tmp;
    }
    else
	croak("valp is not of type %s", DateTimePkg);

    dbproc = d1->dbproc;	/* The first parameter is guaranteed to have
				   it's dbproc field set. */
    
    if(!SvROK(valp2))
    {
	dt = to_datetime(SvPV(valp2, PL_na));
	d2 = &dt;
    }
    else
    {
	sv = (SV *)SvRV(valp2);
	d2 = (DateTime *)SvIV(sv);
    }
    if(ord != &PL_sv_undef && SvTRUE(ord))
    {
	tmp = d1;
	d1 = d2;
	d2 = tmp;
    }

    RETVAL = dbdatecmp(dbproc, &d1->date, &d2->date);
    if(debug_level & TRACE_OVERLOAD)
	warn("%s->cmp(%s, %s) == %d", neatsvpv(valp,0),
	     neatsvpv(valp2, 0), SvTRUE(ord) ? "TRUE" : "FALSE", RETVAL);
}
 OUTPUT:
RETVAL

void
calc(valp, days, msecs = 0)
	SV *	valp
	int	days
	int	msecs
  CODE:
{
    DateTime *ptr;
    DBDATETIME tmp;
    if (sv_isa(valp, DateTimePkg)) {
	IV tmp = SvIV((SV*)SvRV(valp));
	ptr = (DateTime *) tmp;
    }
    else
	croak("valp is not of type %s", DateTimePkg);
    tmp = ptr->date;			/* make a copy: we don't want to change the original! */
    tmp.dtdays += days;
    tmp.dttime += msecs * 0.33333333;
    ST(0) = sv_2mortal(newdate(ptr->dbproc, &tmp));
}


void
diff(valp, valp2, ord = &PL_sv_undef)
	SV *	valp
	SV *	valp2
	SV *	ord
  PPCODE:
{
    SV *sv;
    DateTime *d1, *d2, *tmp, dt;
    int days, msecs;
    if (sv_isa(valp, DateTimePkg)) {
	IV tmp = SvIV((SV*)SvRV(valp));
	d1 = (DateTime *) tmp;
    }
    else
	croak("valp is not of type %s", DateTimePkg);
    
    if(!SvROK(valp2))
    {
	dt = to_datetime(SvPV(valp2, PL_na));
	d2 = &dt;
    }
    else
    {
	sv = (SV *)SvRV(valp2);
	d2 = (DateTime *)SvIV(sv);
    }
    if(ord != &PL_sv_undef && SvTRUE(ord))
    {
	tmp = d1;
	d1 = d2;
	d2 = tmp;
    }

    days = d2->date.dtdays - d1->date.dtdays;
    msecs = d2->date.dttime - d1->date.dttime;
    XPUSHs(sv_2mortal(newSViv(days)));
    XPUSHs(sv_2mortal(newSViv(msecs)));
}


MODULE = Sybase::DBlib		PACKAGE = Sybase::DBlib::Money

void
DESTROY(valp)
	SV *	valp
  CODE:
{
    Money *ptr;
    if (sv_isa(valp, MoneyPkg)) {
	IV tmp = SvIV((SV*)SvRV(valp));
	ptr = (Money *) tmp;
    }
    else
	croak("valp is not of type %s", MoneyPkg);

    if(debug_level & TRACE_DESTROY)
	warn("Destroying %s", neatsvpv(valp, 0));

    Safefree(ptr);
}

char *
str(valp)
	SV *	valp
  CODE:
{
    Money *ptr;
    if (sv_isa(valp, MoneyPkg)) {
	IV tmp = SvIV((SV*)SvRV(valp));
	ptr = (Money *) tmp;
    }
    else
	croak("valp is not of type %s", MoneyPkg);
    
    RETVAL = from_money(ptr);

    if(debug_level & TRACE_OVERLOAD)
	warn("%s->str == %s", neatsvpv(valp,0), RETVAL);
}
 OUTPUT:
RETVAL

double
num(valp)
	SV *	valp
  CODE:
{
    Money *ptr;
    if (sv_isa(valp, MoneyPkg)) {
	IV tmp = SvIV((SV*)SvRV(valp));
	ptr = (Money *) tmp;
    }
    else
	croak("valp is not of type %s", MoneyPkg);
    
    RETVAL = money2float(ptr);

    if(debug_level & TRACE_OVERLOAD)
	warn("%s->num == %f", neatsvpv(valp,0), RETVAL);
}
 OUTPUT:
RETVAL

void
set(valp, str)
	SV *	valp
	char *	str
  CODE:
{
    Money *ptr, tmp;
    if (sv_isa(valp, MoneyPkg)) {
	IV tmp = SvIV((SV*)SvRV(valp));
	ptr = (Money *) tmp;
    }
    else
	croak("valp is not of type %s", MoneyPkg);

    tmp = to_money(str);
    ptr->mn = tmp.mn;
}

int
cmp(valp, valp2, ord = &PL_sv_undef)
	SV *	valp
	SV *	valp2
	SV *	ord
  CODE:
{
    SV *sv;
    Money *m1, *m2, *tmp, mn;
    DBPROCESS *dbproc;
    if (sv_isa(valp, MoneyPkg)) {
	IV tmp = SvIV((SV*)SvRV(valp));
	m1 = (Money*) tmp;
    }
    else
	croak("valp is not of type %s", MoneyPkg);

    dbproc = m1->dbproc;	/* The first parameter is guaranteed to have
				   it's dbproc field set. */
    
    if(!SvROK(valp2))
    {
	char buff[64];

	sprintf(buff, "%f", SvNV(valp2));
	mn = to_money(buff);
	m2 = &mn;
    }
    else
    {
	sv = (SV *)SvRV(valp2);
	m2 = (Money *)SvIV(sv);
    }
    if(ord != &PL_sv_undef && SvTRUE(ord))
    {
	tmp = m1;
	m1 = m2;
	m2 = tmp;
    }

    RETVAL = dbmnycmp(dbproc, &m1->mn, &m2->mn);
    if(debug_level & TRACE_OVERLOAD)
	warn("%s->cmp(%s, %s) == %d", neatsvpv(valp,0),
	     neatsvpv(valp2, 0), SvTRUE(ord) ? "TRUE" : "FALSE", RETVAL);
}
 OUTPUT:
RETVAL

void
calc(valp1, valp2, op, ord = &PL_sv_undef)
	SV *	valp1
	SV *	valp2
	char	op
	SV *	ord
  CODE:
{
    Money *m1, *m2, *tmp, mn;
    DBMONEY result;
    DBPROCESS *dbproc;
    int ret;
    
    if (sv_isa(valp1, MoneyPkg)) {
	IV tmp = SvIV((SV*)SvRV(valp1));
	m1 = (Money *) tmp;
    }
    else
	croak("valp1 is not of type %s", MoneyPkg);
    dbproc = m1->dbproc;
    
    if(!SvROK(valp2) ||	!sv_isa(valp2, MoneyPkg))
    {
	char buff[64];

	sprintf(buff, "%f", SvNV(valp2));
	mn = to_money(buff);
	m2 = &mn;
    }
    else
    {
	IV tmp = SvIV((SV*)SvRV(valp2));
	m2 = (Money *) tmp;
    }
    if(ord != &PL_sv_undef && SvTRUE(ord))
    {
	tmp = m1;
	m1 = m2;
	m2 = tmp;
    }

    switch(op)
    {
      case '+': ret = dbmnyadd(dbproc, &m1->mn, &m2->mn, &result); break;
      case '-': ret = dbmnysub(dbproc, &m1->mn, &m2->mn, &result); break;
      case '*': ret = dbmnymul(dbproc, &m1->mn, &m2->mn, &result); break;
      case '/': ret = dbmnydivide(dbproc, &m1->mn, &m2->mn, &result); break;
      default:
	croak("Invalid operator %c to Sybase::DBlib::Money::calc", op);
    }
    if(ret != SUCCEED)
	warn("dbmoney calc() failed");

    if(debug_level & TRACE_OVERLOAD) {
	mn.dbproc = dbproc;
	mn.mn = result;
	warn("%s->calc(%s, %c, %s) == %s", neatsvpv(valp1, 0),
	     neatsvpv(valp2, 0), op, SvTRUE(ord) ? "TRUE" : "FALSE",
	     from_money(&mn));
    }

    ST(0) = sv_2mortal(newmoney(dbproc, &result));
}



    
MODULE = Sybase::DBlib		PACKAGE = Sybase::DBlib::_attribs

void
FETCH(sv, keysv)
	SV *	sv
	SV *	keysv
CODE:
{
    ConInfo *info = get_ConInfoFromMagic((HV*)SvRV(sv));
    SV *valuesv = attr_fetch(info, SvPV(keysv, PL_na), sv_len(keysv));
    ST(0) = valuesv;
}

void
STORE(sv, keysv, valuesv)
	SV *	sv
	SV *	keysv
	SV *	valuesv
CODE:
{
    ConInfo *info = get_ConInfoFromMagic((HV*)SvRV(sv));

    attr_store(info, SvPV(keysv, PL_na), sv_len(keysv), valuesv, 0);
}
