/* This file is part of the Thread::Cleanup Perl module.
 * See http://search.cpan.org/dist/Thread-Cleanup/ */

#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#define __PACKAGE__     "Thread::Cleanup"
#define __PACKAGE_LEN__ (sizeof(__PACKAGE__)-1)

#define TC_HAS_PERL(R, V, S) (PERL_REVISION > (R) || (PERL_REVISION == (R) && (PERL_VERSION > (V) || (PERL_VERSION == (V) && (PERL_SUBVERSION >= (S))))))

STATIC void tc_callback(pTHX_ void *ud) {
 dSP;

 ENTER;
 SAVETMPS;

 PUSHMARK(SP);
 PUTBACK;

 call_pv(__PACKAGE__ "::_CLEANUP", G_VOID | G_EVAL);

 PUTBACK;

 FREETMPS;
 LEAVE;
}

STATIC int tc_endav_free(pTHX_ SV *sv, MAGIC *mg) {
 SAVEDESTRUCTOR_X(tc_callback, NULL);

 return 0;
}

STATIC MGVTBL tc_endav_vtbl = {
 0,
 0,
 0,
 0,
 tc_endav_free
#if MGf_COPY
 , 0
#endif
#if MGf_DUP
 , 0
#endif
#if MGf_LOCAL
 , 0
#endif
};

MODULE = Thread::Cleanup            PACKAGE = Thread::Cleanup

PROTOTYPES: DISABLE

void
CLONE(...)
PREINIT:
 GV *gv;
PPCODE:
 gv = gv_fetchpv(__PACKAGE__ "::_CLEANUP", 0, SVt_PVCV);
 if (gv) {
  CV *cv = GvCV(gv);
  if (!PL_endav)
   PL_endav = newAV();
  SvREFCNT_inc(cv);
  if (!av_store(PL_endav, av_len(PL_endav) + 1, (SV *) cv))
   SvREFCNT_dec(cv);
  sv_magicext((SV *) PL_endav, NULL, PERL_MAGIC_ext, &tc_endav_vtbl, NULL, 0);
 }
 XSRETURN(0);
