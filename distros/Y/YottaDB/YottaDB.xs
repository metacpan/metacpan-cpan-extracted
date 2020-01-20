// #define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include "libyottadb.h"
#include "libydberrors.h"

#ifndef NO_CHILD_INIT
#include <pthread.h>
#endif

#if 0
#define MYDEBUG(s,r) do { fprintf(stderr, "%s: rc=%d\n", (s), (r)); fflush (stderr); } while (0)
#else
#define MYDEBUG(s,r)
#endif

static const char *zstatus(void)
{
        static char buf[8192];
        ydb_buffer_t ret;
        ydb_buffer_t zst;
        int rc;

        zst.len_alloc = 8;
        zst.len_used = 8;
        zst.buf_addr = "$ZSTATUS";

        ret.len_alloc = 8191;
        ret.len_used = 0;
        ret.buf_addr = buf;
        rc = ydb_get_s(&zst, 0, 0, &ret);
        if(rc) {
                return "unable to fetch $ZSTATUS";
        }
        buf[ret.len_used] = 0;
        return buf;
}

#define YDB_CROAK(x) do { if (x) croak ("YottaDB-Error: %d %s", (x), zstatus()); } while (0)


static int my_transaction (void *addr)
{
        dSP;
        SV *func = addr;
        int cnt;
        int ret;
        SV *errtmp;

        ENTER;
        SAVETMPS;
        PUSHMARK(SP);
        PUTBACK;
        cnt = call_sv (func, G_SCALAR|G_NOARGS|G_EVAL);
        SPAGAIN;
        errtmp = ERRSV;
        if(cnt != 1)
            croak ("This should never happen(tm)");
        ret = POPi;
        PUTBACK;
        FREETMPS;
        LEAVE;
        if(SvTRUE(errtmp)) {
                // it died in some way. we rollback.
                // sv_dump(tmp);
                ret = YDB_TP_ROLLBACK;
        }
        MYDEBUG("my_transaction", ret);
        return ret;
}

#ifndef NO_CHILD_INIT

static int filedes[2];

static void paf_prepare (void)
{
	int rc;
	rc = pipe (filedes);
	if (rc < 0) {
		croak ("paf_prepare: pipe error: %m\n");
	}
}

static void paf_parent (void)
{
        char buf[1];
        int rc;
        close (filedes[1]);
        rc = read (filedes[0], buf, 1);
        close (filedes[0]);
        if (rc != 1) {
            croak ("paf_parent: read returned %d\n", rc);
        }
}

static void paf_child (void)
{
        char buf[1];
        int rc;

        buf[0] = 0;
        close (filedes[0]);
        ydb_child_init (0);
        rc = write (filedes[1], buf, 1);
        close (filedes[1]);
        if (rc != 1) {
            croak ("paf_child: write returned %d\n", rc);
        }
}

#endif

MODULE = YottaDB                PACKAGE = YottaDB

PROTOTYPES: DISABLE

BOOT:
{
#ifndef NO_CHILD_INIT
  int rc;
  rc = pthread_atfork (paf_prepare, paf_parent, paf_child);
  if (rc) {
      croak ("pthread_atfork failure, rc=%d", rc);
  }
#endif
}

void
fixup_for_putenv_crash ()
CODE:
        /* this may require -Accflags=-DPERL_USE_SAFE_PUTENV
         * on perl's Configure...
         */
        putenv ("ydb_callin_start");
        putenv ("GTM_CALLIN_START");
OUTPUT:

IV
y_tp_rollback ()
ALIAS:
        y_tp_restart = 1
        y_lock_timeout = 2
        y_ok = 3
PREINIT:
        int rc = 0;
CODE:
        switch(ix) {
                case 0:
                        rc = YDB_TP_ROLLBACK;
                        break;
                case 1:
                        rc = YDB_TP_RESTART;
                        break;
                case 2:
                        rc = YDB_LOCK_TIMEOUT;
                        break;
                case 3:
                        rc = YDB_OK;
                        break;
        }
        RETVAL = rc;
OUTPUT:
        RETVAL


IV
y_data (name, ...)
        SV *name
PREINIT:
        ydb_buffer_t yname;
        ydb_buffer_t subs[YDB_MAX_SUBS];
        STRLEN len;
        char *ptr;
        int rc, i;
CODE:
        if (items - 1 > YDB_MAX_SUBS) {
            croak ("y_data: too many subscripts");
        }
        yname.buf_addr = SvPV (name, len);
        yname.len_alloc = yname.len_used = len;

        for (i = 0; i < items - 1; i++) {
                ptr = SvPV (ST(i+1), len);
                subs[i].len_used = subs[i].len_alloc = len;
                subs[i].buf_addr = ptr;
        }

        rc = ydb_data_s (&yname, items - 1, subs, &i);
        YDB_CROAK(rc);
        RETVAL = i;
OUTPUT:
        RETVAL

void
y_kill_excl (...)
PREINIT:
        ydb_buffer_t varnames[YDB_MAX_NAMES];
        int i;
        char *ptr;
        STRLEN len;
        int rc;
CODE:
        if (items > YDB_MAX_NAMES) {
                croak ("y_kill_excl: too many variables");
        }
        for (i = 0; i < items; i++) {
                ptr = SvPV (ST(i), len);
                varnames[i].len_used = varnames[i].len_alloc = len;
                varnames[i].buf_addr = ptr;
        }
        rc = ydb_delete_excl_s (items, varnames);
        YDB_CROAK(rc);
OUTPUT:

void
y_killall ()
PREINIT:
        int rc;
CODE:
        rc = ydb_delete_excl_s (0, 0);
        YDB_CROAK(rc);
OUTPUT:

SV *
y_get (name, ...)
        SV *name
ALIAS:
        y_get_croak = 1
PREINIT:
        ydb_buffer_t yname;
        ydb_buffer_t ret;
        ydb_buffer_t subs[YDB_MAX_SUBS];
        STRLEN len;
        char *ptr;
        int rc, i;
CODE:
        if (items - 1 > YDB_MAX_SUBS) {
                croak ("y_get: too many subscripts.");
        }
        yname.buf_addr = SvPV (name, len);
        yname.len_alloc = yname.len_used = len;

        for (i = 0; i < items - 1; i++) {
                ptr = SvPV (ST(i+1), len);
                subs[i].len_used = subs[i].len_alloc = len;
                subs[i].buf_addr = ptr;
        }

        ret.len_alloc = YDB_MAX_STR;
        ret.len_used = 0;
        ret.buf_addr = malloc (YDB_MAX_STR);

        rc = ydb_get_s (&yname, items - 1, subs, &ret);
        if (ix == 0 && (rc == YDB_ERR_LVUNDEF || rc == YDB_ERR_GVUNDEF)) {
                free (ret.buf_addr);
                XSRETURN_UNDEF;
        }
        YDB_CROAK(rc);

        RETVAL = newSVpvn (ret.buf_addr, ret.len_used);
        free (ret.buf_addr);
OUTPUT:
        RETVAL

void
y_set (name, ...)
        SV *name
PREINIT:
        ydb_buffer_t yname;
        ydb_buffer_t subs[YDB_MAX_SUBS + 1];
        STRLEN len;
        char *ptr;
        int rc, i;
CODE:
        if (items < 2) {
                croak ("y_set: need at least two arguments.");
        }
        if (items - 2 > YDB_MAX_SUBS) {
                croak ("y_set: too many subscripts.");
        }
        yname.buf_addr = SvPV (name, len);
        yname.len_alloc = yname.len_used = len;

        for (i = 0; i < items - 1; i++) {
                ptr = SvPV (ST(i+1), len);
                subs[i].len_used = subs[i].len_alloc = len;
                subs[i].buf_addr = ptr;
        }

        rc = ydb_set_s (&yname, items - 2, subs, &subs[items - 2]);
        MYDEBUG("ydb_set_s", rc);
        YDB_CROAK(rc);
OUTPUT:

void
y_kill_tree (name, ...)
        SV *name
ALIAS:
        y_kill_node = 1
PREINIT:
        ydb_buffer_t yname;
        ydb_buffer_t subs[YDB_MAX_SUBS];
        STRLEN len;
        char *ptr;
        int rc, i;
CODE:
        if (items - 1 > YDB_MAX_SUBS) {
                croak ("y_kill: too many subscripts.");
        }
        yname.buf_addr = SvPV (name, len);
        yname.len_alloc = yname.len_used = len;

        for (i = 0; i < items - 1; i++) {
                ptr = SvPV (ST(i+1), len);
                subs[i].len_used = subs[i].len_alloc = len;
                subs[i].buf_addr = ptr;
        }
        rc = ydb_delete_s (&yname, items - 1, subs, (ix == 0) ? YDB_DEL_TREE : YDB_DEL_NODE);
        MYDEBUG("ydb_delete_s", rc);
        YDB_CROAK(rc);
OUTPUT:


SV *
y_next (name, ...)
        SV *name
ALIAS:
        y_previous = 1
PREINIT:
        ydb_buffer_t yname;
        ydb_buffer_t ret;
        ydb_buffer_t subs[YDB_MAX_SUBS];
        STRLEN len;
        char *ptr;
        int rc, i;
CODE:
        if (items - 1 > YDB_MAX_SUBS) {
                croak ("y_next: too many subscripts.");
        }
        yname.buf_addr = SvPV (name, len);
        yname.len_alloc = yname.len_used = len;

        for (i = 0; i < items - 1; i++) {
                ptr = SvPV (ST(i+1), len);
                subs[i].len_used = subs[i].len_alloc = len;
                subs[i].buf_addr = ptr;
        }

        ret.len_alloc = YDB_MAX_STR;
        ret.len_used = 0;
        ret.buf_addr = malloc (YDB_MAX_STR);

        rc = ((ix == 0) ? ydb_subscript_next_s : ydb_subscript_previous_s) (&yname, items - 1, subs, &ret);
        if (rc == YDB_ERR_NODEEND) {
                free (ret.buf_addr);
                XSRETURN_UNDEF;
        } else {
                if (rc) {
                        free (ret.buf_addr);
                        YDB_CROAK(rc);
                }
                RETVAL = newSVpvn (ret.buf_addr, ret.len_used);
        }
        free (ret.buf_addr);
OUTPUT:
        RETVAL

void
y_node_next (name, ...)
        SV *name
ALIAS:
        y_node_previous = 1
PREINIT:
        ydb_buffer_t yname;
        ydb_buffer_t ret[YDB_MAX_SUBS];
        ydb_buffer_t subs[YDB_MAX_SUBS];
        STRLEN len;
        char *ptr;
        int rc, i;
        int retlen = YDB_MAX_SUBS;
        char *alloc;
PPCODE:
        if (items - 1 > YDB_MAX_SUBS) {
                croak ("y_node_next: too many subscripts.");
        }
        yname.buf_addr = SvPV (name, len);
        yname.len_alloc = yname.len_used = len;

        for (i = 0; i < items - 1; i++) {
                ptr = SvPV (ST(i+1), len);
                subs[i].len_used = subs[i].len_alloc = len;
                subs[i].buf_addr = ptr;
        }
        alloc = malloc (1024 * YDB_MAX_SUBS);
        for (i = 0; i < YDB_MAX_SUBS; i++) {
                ret[i].len_used = 0;
                ret[i].len_alloc = 1024;
                ret[i].buf_addr = &alloc[1024 * i];
        }

        rc = ((ix == 0) ? ydb_node_next_s : ydb_node_previous_s) (&yname, items - 1, subs, &retlen, ret);
        if (rc) {
                free (alloc);
                if (rc != YDB_ERR_NODEEND)
                        YDB_CROAK(rc);
        }
        if (rc == YDB_ERR_NODEEND) {
                XSRETURN_EMPTY;
        }
        EXTEND (SP, retlen);
        for (i = 0; i < retlen; i++) {
                PUSHs (sv_2mortal (newSVpvn (ret[i].buf_addr, ret[i].len_used)));
        }
       
        free (alloc);

SV *
y_incr (name, ...)
        SV *name
PREINIT:
        ydb_buffer_t yname;
        ydb_buffer_t ret;
        ydb_buffer_t subs[YDB_MAX_SUBS + 1];
        STRLEN len;
        char *ptr;
        int rc, i;
CODE:
        if (items < 2) {
                croak ("y_incr: need at least two arguments.");
        }
        if (items - 2 > YDB_MAX_SUBS) {
                croak ("y_incr: too many subscripts.");
        }
        yname.buf_addr = SvPV (name, len);
        yname.len_alloc = yname.len_used = len;

        for (i = 0; i < items - 1; i++) {
                ptr = SvPV (ST(i+1), len);
                subs[i].len_used = subs[i].len_alloc = len;
                subs[i].buf_addr = ptr;
        }

        ret.len_alloc = 128;
        ret.len_used = 0;
        ret.buf_addr = malloc (128);

        rc = ydb_incr_s (&yname, items - 2, subs, &subs[items-2], &ret);
        if (rc) {
                free (ret.buf_addr);
                YDB_CROAK(rc);
        }

        RETVAL = newSVpvn (ret.buf_addr, ret.len_used);
        free (ret.buf_addr);
OUTPUT:
        RETVAL

SV *
y_zwr2str (buf)
        SV *buf
ALIAS:
        y_str2zwr = 1
PREINIT:
        ydb_buffer_t in, out;
        char *ptr;
        STRLEN len;
        int rc;
CODE:
        ptr = SvPV (buf, len);
        in.buf_addr = ptr;
        in.len_used = in.len_alloc = len;

        out.len_alloc = YDB_MAX_STR;
        out.len_used = 0;
        out.buf_addr = malloc (YDB_MAX_STR);

        rc  = ((ix == 0) ? ydb_zwr2str_s : ydb_str2zwr_s) (&in, &out);
        if (rc) {
                free (out.buf_addr);
                YDB_CROAK(rc);
        }
        RETVAL = newSVpvn (out.buf_addr, out.len_used);
        free (out.buf_addr);
OUTPUT:
        RETVAL

IV
y_lock(timeout, ...)
    NV timeout
PREINIT:
        int rc;
        int i,j;
        STRLEN len, l;
        SV *sv;
        AV *av;
        ydb_buffer_t varnames[YDB_MAX_NAMES];
        int subs_used[YDB_MAX_NAMES];
        ydb_buffer_t subsarray[YDB_MAX_NAMES][YDB_MAX_SUBS];
        long long to;
CODE:
        if (items > YDB_MAX_NAMES + 1)
                croak ("y_lock: too many variables");
        for (i = 0; i < items - 1; i++) {
            sv = ST(i+1);
            if (!SvROK(sv) || (SvTYPE(SvRV(sv)) != SVt_PVAV)) {
                croak ("y_lock: expected array reference (arg %d)", i+2);
            }
            av = (AV*) SvRV(sv);
            len = av_len(av)+1;
            SV ** const ary = AvARRAY (av);
            if (!len) {
                croak ("y_lock: empty array (arg %d)", i+2);
            }
            if (len > YDB_MAX_SUBS+1)
                croak ("y_lock: too many names");

            varnames[i].buf_addr = SvPV(ary[0], l);
            varnames[i].len_alloc = varnames[i].len_used = l;
            subs_used[i] = len - 1;

            for (j = 1; j < len; j++) {
                subsarray[i][j-1].buf_addr = SvPV(ary[j],l);
                subsarray[i][j-1].len_alloc = subsarray[i][j-1].len_used = l;
            }

        }
        timeout *= 1000.0 * 1000.0 * 1000.0;
        to = (long long) timeout;
        switch (items -1) {
                case 0: rc = ydb_lock_s(to, 0); break;
#include "gen-switch.h"
        }
        if (rc == YDB_LOCK_TIMEOUT) {
                RETVAL = 0;
        } else if (rc == YDB_OK) {
                RETVAL = 1;
        } else {
                YDB_CROAK(rc);
        }
OUTPUT:
        RETVAL

IV
y_lock_incr(timeout, name, ...)
    NV timeout
    SV *name
PREINIT:
        ydb_buffer_t yname;
        ydb_buffer_t subs[YDB_MAX_SUBS];
        STRLEN len;
        char *ptr;
        int rc, i;
        long long to;
CODE:
        if (items - 2 > YDB_MAX_SUBS) {
                croak ("y_lock_incr: too many subscripts.");
        }
        yname.buf_addr = SvPV (name, len);
        yname.len_alloc = yname.len_used = len;

        for (i = 0; i < items - 2; i++) {
                ptr = SvPV (ST(i+2), len);
                subs[i].len_used = subs[i].len_alloc = len;
                subs[i].buf_addr = ptr;
        }
        timeout *= 1000.0 * 1000.0 * 1000.0;
        to = (long long) timeout;
        rc = ydb_lock_incr_s (to, &yname, items - 2, subs);
        if (rc == YDB_LOCK_TIMEOUT) {
                RETVAL = 0;
        } else if (rc == YDB_OK) {
                RETVAL = 1;
        } else {
                YDB_CROAK(rc);
        }
OUTPUT:
        RETVAL

void
y_lock_decr(name, ...)
    SV *name
PREINIT:
        ydb_buffer_t yname;
        ydb_buffer_t subs[YDB_MAX_SUBS];
        STRLEN len;
        char *ptr;
        int rc, i;
CODE:
        if (items - 1 > YDB_MAX_SUBS) {
                croak ("y_lock_decr: too many subscripts.");
        }
        yname.buf_addr = SvPV (name, len);
        yname.len_alloc = yname.len_used = len;

        for (i = 0; i < items - 1; i++) {
                ptr = SvPV (ST(i+1), len);
                subs[i].len_used = subs[i].len_alloc = len;
                subs[i].buf_addr = ptr;
        }
        rc = ydb_lock_decr_s (&yname, items - 1, subs);
        YDB_CROAK(rc);
OUTPUT:


IV
y_trans (func, transid, ...)
        SV *func
        char *transid
        PROTOTYPE: &$;@
PREINIT:
        int rc;
        int i;
        STRLEN len;
        char *ptr;
        ydb_buffer_t vars[YDB_MAX_NAMES];
CODE:
        if (items - 2 > YDB_MAX_NAMES)
                croak ("y_trans: too many variables");
        if (!SvROK(func) || (SvTYPE (SvRV (func))!= SVt_PVCV))
                croak ("y_trans: not a code-reference");

        for (i = 0; i < items - 2; i++) {
                ptr = SvPV (ST(i+2), len);
                vars[i].len_used = vars[i].len_alloc = len;
                vars[i].buf_addr = ptr;
        }
        rc = ydb_tp_s (my_transaction, (void *) func, transid, items - 2, vars);
        MYDEBUG("ydb_tp_s", rc);
        if (rc != YDB_TP_ROLLBACK
            && rc != YDB_TP_RESTART)
                YDB_CROAK(rc);
        if (SvTRUE(ERRSV))
                croak_sv (ERRSV);
        /* we croak in void-context if rc != 0 */
        if (GIMME_V == G_VOID && rc) {
            croak ("y_trans: ydb_tp_s rc=%d in void context.", rc);
        }
        RETVAL = rc;
OUTPUT:
        RETVAL


IV
y_child_init ()
    CODE:
        RETVAL = ydb_child_init (0);
OUTPUT:
        RETVAL

IV
y_exit ()
    CODE:
        RETVAL = ydb_exit ();
OUTPUT:
        RETVAL

