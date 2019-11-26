/*  You may distribute under the terms of either the GNU General Public License
 *  or the Artistic License (the same terms as Perl itself)
 *
 *  (C) Paul Evans, 2019 -- leonerd@leonerd.org.uk
 */


#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <tickit.h>
#include <tickit-evloop.h>

#define newSVio_rdonly(fd)  S_newSVio_rdonly(aTHX_ fd)
SV *S_newSVio_rdonly(pTHX_ int fd)
{
  /* inspired by
   *   https://metacpan.org/source/LEONT/Linux-Epoll-0.016/lib/Linux/Epoll.xs#L192
   */
  PerlIO *pio = PerlIO_fdopen(fd, "r");
  GV *gv = newGVgen("Tickit::Async");
  SV *ret = newRV_noinc((SV *)gv);
  IO *io = GvIOn(gv);
  IoTYPE(io) = '<';
  IoIFP(io) = pio;
  sv_bless(ret, gv_stashpv("IO::Handle", TRUE));
  return ret;
}

static XS(invoke_watch);
static XS(invoke_watch)
{
  dXSARGS;
  TickitWatch *watch = XSANY.any_ptr;

  tickit_evloop_invoke_watch(watch, TICKIT_EV_FIRE);

  XSRETURN(0);
}

#define newSVcallback_tickit_invoke(watch)  S_newSVcallback_tickit_invoke(aTHX_ watch)
SV *S_newSVcallback_tickit_invoke(pTHX_ TickitWatch *watch)
{
  CV *cv = newXS(NULL, invoke_watch, __FILE__);
  CvXSUBANY(cv).any_ptr = watch;
  return newRV_noinc((SV *)cv);
}

typedef struct {
#ifdef tTHX
  tTHX myperl;
#endif
  SV *loop;
  SV *signalid;
} EventLoopData;

static XS(invoke_sigwinch);
static XS(invoke_sigwinch)
{
  Tickit *t = XSANY.any_ptr;
  tickit_evloop_sigwinch(t);
}

static void *evloop_init(Tickit *t, void *initdata)
{
  EventLoopData *evdata = initdata;
  dTHXa(evdata->myperl);

  CV *invoke_sigwinch_cv = newXS(NULL, invoke_sigwinch, __FILE__);
  CvXSUBANY(invoke_sigwinch_cv).any_ptr = t;

  /* We need to call
   *   $loop->attach_signal( "WINCH", $invoke_sigwinch )
   */
  dSP;
  SAVETMPS;

  EXTEND(SP, 3);
  PUSHMARK(SP);
  PUSHs(evdata->loop);
  mPUSHp("WINCH", 5);
  mPUSHs(newRV_noinc((SV *)invoke_sigwinch_cv));

  PUTBACK;

  call_method("attach_signal", G_SCALAR);

  SPAGAIN;

  evdata->signalid = SvREFCNT_inc(POPs);

  FREETMPS;

  return initdata;
}

static void evloop_destroy(void *data)
{
  EventLoopData *evdata = data;
  dTHXa(evdata->myperl);

  SvREFCNT_dec(evdata->loop);
}

static void evloop_run(void *data, TickitRunFlags flags)
{
  EventLoopData *evdata = data;
  dTHXa(evdata->myperl);

  /* We need to call
   *   $loop->run
   */
  dSP;
  SAVETMPS;

  EXTEND(SP, 1);
  PUSHMARK(SP);
  PUSHs(evdata->loop);

  PUTBACK;

  call_method("run", G_VOID);

  FREETMPS;
}

static void evloop_stop(void *data)
{
  EventLoopData *evdata = data;
  dTHXa(evdata->myperl);

  /* We need to call
   *   $loop->stop
   */
  dSP;
  SAVETMPS;

  EXTEND(SP, 1);
  PUSHMARK(SP);
  PUSHs(evdata->loop);

  PUTBACK;

  call_method("stop", G_VOID);

  FREETMPS;
}

static bool evloop_io_read(void *data, int fd, TickitBindFlags flags, TickitWatch *watch)
{
  EventLoopData *evdata = data;
  dTHXa(evdata->myperl);

  SV *fh = newSVio_rdonly(fd);

  /* We need to call
   *   $loop->watch_io( handle => $fh, on_read_ready => $code )
   */
  dSP;
  SAVETMPS;

  EXTEND(SP, 5);
  PUSHMARK(SP);
  PUSHs(evdata->loop);

  mPUSHp("handle", 6);
  PUSHs(fh);
  mPUSHp("on_read_ready", 13);
  mPUSHs(newSVcallback_tickit_invoke(watch));
  PUTBACK;

  call_method("watch_io", G_VOID);

  FREETMPS;

  tickit_evloop_set_watch_data(watch, fh);

  return true;
}

static void evloop_cancel_io(void *data, TickitWatch *watch)
{
  EventLoopData *evdata = data;
  dTHXa(evdata->myperl);

  SV *fh = tickit_evloop_get_watch_data(watch);

  /* Don't bother during global destruction, as the perl object we're about to
   * call methods on might not be in a good state any more
   */
  if(PL_phase == PERL_PHASE_DESTRUCT)
    return;

  /* We need to call
   *   $loop->unwatch_io( handle => $fh, on_read_ready => 1 )
   */
  dSP;
  SAVETMPS;

  EXTEND(SP, 5);
  PUSHMARK(SP);
  PUSHs(evdata->loop);

  mPUSHp("handle", 6);
  PUSHs(fh);
  mPUSHp("on_read_ready", 13);
  mPUSHi(1);
  PUTBACK;

  call_method("unwatch_io", G_VOID);

  FREETMPS;

  SvREFCNT_dec(fh);
  tickit_evloop_set_watch_data(watch, NULL);
}

static bool evloop_timer(void *data, const struct timeval *at, TickitBindFlags flags, TickitWatch *watch)
{
  EventLoopData *evdata = data;
  dTHXa(evdata->myperl);

  NV at_time = at->tv_sec + ((NV)at->tv_usec / 1E6);

  /* We need to call
   *   $loop->watch_time( at => $at_time, code => $code )
   */
  dSP;
  SAVETMPS;

  PUSHMARK(SP);
  PUSHs(evdata->loop);

  mPUSHp("at", 2);
  mPUSHn(at_time);
  mPUSHp("code", 4);
  mPUSHs(newSVcallback_tickit_invoke(watch));
  PUTBACK;

  call_method("watch_time", G_SCALAR);

  SPAGAIN;

  SV *timerid = SvREFCNT_inc(POPs);

  FREETMPS;

  tickit_evloop_set_watch_data(watch, timerid);

  return true;
}

static void evloop_cancel_timer(void *data, TickitWatch *watch)
{
  EventLoopData *evdata = data;
  dTHXa(evdata->myperl);

  SV *timerid = tickit_evloop_get_watch_data(watch);

  /* Don't bother during global destruction, as the perl object we're about to
   * call methods on might not be in a good state any more
   */
  if(PL_phase == PERL_PHASE_DESTRUCT)
    return;

  /* We need to call
   *   $loop->unwatch_time( $id )
   */
  dSP;
  SAVETMPS;

  PUSHMARK(SP);
  PUSHs(evdata->loop);

  PUSHs(timerid);
  PUTBACK;

  call_method("unwatch_time", G_VOID);

  FREETMPS;

  SvREFCNT_dec(timerid);
  tickit_evloop_set_watch_data(watch, NULL);
}

static bool evloop_later(void *data, TickitBindFlags flags, TickitWatch *watch)
{
  EventLoopData *evdata = data;
  dTHXa(evdata->myperl);

  /* We need to call
   *   $loop->watch_idle( when => "later", code => $code )
   */
  dSP;
  SAVETMPS;

  PUSHMARK(SP);
  PUSHs(evdata->loop);

  mPUSHp("when", 4);
  mPUSHp("later", 5);
  mPUSHp("code", 4);
  mPUSHs(newSVcallback_tickit_invoke(watch));
  PUTBACK;

  call_method("watch_idle", G_VOID);

  FREETMPS;

  return true;
}

static void evloop_cancel_later(void *data, TickitWatch *watch)
{
  /* Don't bother during global destruction, as the perl object we're about to
   * call methods on might not be in a good state any more
   */
  if(PL_phase == PERL_PHASE_DESTRUCT)
    return;

  fprintf(stderr, "Should cancel later here\n");
}

static TickitEventHooks evhooks = {
  .init         = evloop_init,
  .destroy      = evloop_destroy,
  .run          = evloop_run,
  .stop         = evloop_stop,
  .io_read      = evloop_io_read,
  .cancel_io    = evloop_cancel_io,
  .timer        = evloop_timer,
  .cancel_timer = evloop_cancel_timer,
  .later        = evloop_later,
  .cancel_later = evloop_cancel_later,

};

MODULE = Tickit::Async   PACKAGE = Tickit::Async

SV *
_new_tickit(term, loop)
  SV   *term
  SV   *loop
  INIT:
    TickitTerm *tt = NULL;
    Tickit *t;
    EventLoopData *evdata;
  CODE:
    if(!term || !SvOK(term))
      tt = NULL;
    else if(SvROK(term) && sv_derived_from(term, "Tickit::Term"))
      tt = INT2PTR(TickitTerm *, SvIV((SV*)SvRV(term)));
    else
      Perl_croak(aTHX_ "term is not of type Tickit::Term");

    if(!SvROK(loop) || !sv_derived_from(loop, "IO::Async::Loop"))
      Perl_croak(aTHX_ "loop is not of type IO::Async::Loop");

    if(tt)
      tickit_term_ref(tt);

    Newx(evdata, 1, EventLoopData);
#ifdef tTHX
    evdata->myperl = aTHX;
#endif
    evdata->loop = newSVsv(loop);

    t = tickit_new_with_evloop(tt, &evhooks, evdata);
    if(!t)
      XSRETURN_UNDEF;

    RETVAL = newSV(0);
    sv_setref_pv(RETVAL, "Tickit::_Tickit", t);
  OUTPUT:
    RETVAL
