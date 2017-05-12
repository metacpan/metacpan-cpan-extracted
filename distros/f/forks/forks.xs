#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#define NEED_PL_signals
#include "ppport.h"

#define MY_CXT_KEY "threads::shared::_guts" XS_VERSION

typedef struct {
    int dummy;          /* you can access this elsewhere as MY_CXT.dummy */
} my_cxt_t;

START_MY_CXT

/* Scope hook to determine when a locked variable should be unlocked */

void
exec_leave(pTHX_ SV *both) {
    U32 process;
    U32 ordinal;
    AV *av_ord_lock;

    dSP;
    ENTER;
    SAVETMPS;

    av_ord_lock = (AV*)SvRV(both);
    process = (U32)SvUV((SV*)*av_fetch(av_ord_lock, 1, 0));
    ordinal = (U32)SvUV((SV*)*av_fetch(av_ord_lock, 2, 0));
  /*  printf ("unlock: ordinal = %d, process = %d\n",ordinal,process); */
    SvREFCNT_dec(av_ord_lock);
    SvREFCNT_dec(both);

    PUSHMARK(SP);
    XPUSHs(sv_2mortal(newSVuv(ordinal)));
    PUTBACK;

    if (process == getpid()) {
        call_pv( "threads::shared::_unlock",G_DISCARD );
    }

    SPAGAIN;
    PUTBACK;
    FREETMPS;
    LEAVE;
}

/* Implements Perl-level share() and :shared */

void
Perl_sharedsv_share(pTHX_ SV *sv)
{
    dSP;
    switch(SvTYPE(sv)) {
/*    case SVt_PVGV:
        Perl_croak(aTHX_ "Cannot share globs yet");
        break; */

    case SVt_PVCV:
        Perl_croak(aTHX_ "Cannot share subs yet");
        break;

    default:
        ENTER;
        SAVETMPS;

        PUSHMARK(sp);
        XPUSHs(sv_2mortal(newRV_inc(sv)));
        PUTBACK;

        call_pv( "threads::shared::_share",G_DISCARD );

        SPAGAIN;
        PUTBACK;
        FREETMPS;
        LEAVE;

        break;
    }
}

/* Inititalize core Perl hooks */

void
Perl_sharedsv_init(pTHX)
{
/*    PL_lockhook = &Perl_sharedsv_locksv; */
#ifdef PL_sharehook
    PL_sharehook = &Perl_sharedsv_share;
#endif
#ifdef PL_destroyhook
/*    PL_destroyhook = &Perl_shared_object_destroy; */
#endif
}


MODULE = forks               PACKAGE = threads::shared

#----------------------------------------------------------------------
# OUT: 1 boolean value indicating whether core hook PL_sharehook exists 

bool
__DEF_PL_sharehook()
    CODE:
#ifdef PL_sharehook
        RETVAL = 1;
#else
        RETVAL = 0;
#endif
    OUTPUT:
        RETVAL

#----------------------------------------------------------------------
# OUT: 1 boolean value indicating whether unsafe signals are in use 

bool
_check_pl_signal_unsafe_flag()
    PREINIT:
        U32 flags;
    CODE:
        flags = PL_signals & PERL_SIGNALS_UNSAFE_FLAG;
        if (flags == 0) {
            RETVAL = 0;
        } else {
            RETVAL = 1;
        }
    OUTPUT:
        RETVAL

#----------------------------------------------------------------------
#  IN: 1 any variable (scalar,array,hash,glob)
# OUT: 1 reference to that variable

SV*
share(SV *myref)
    PROTOTYPE: \[$@%]
    CODE:
        if (!SvROK(myref))
            Perl_croak(aTHX_ "Argument to share needs to be passed as ref");
        myref = SvRV(myref);
        if(SvROK(myref))
            myref = SvRV(myref);
            
        Perl_sharedsv_share(aTHX_ myref);

        RETVAL = newRV_inc(myref);
    OUTPUT:
        RETVAL

#----------------------------------------------------------------------
#  IN: 1 any variable (scalar,array,hash,glob)

void
lock(SV *myref)
    PROTOTYPE: \[$@%]
    PPCODE:
        int count;
        U32 process;
        U32 ordinal;
        AV *av_ord_lock;

        LEAVE;

        if (!SvROK(myref))
            Perl_croak(aTHX_ "Argument to lock needs to be passed as ref");
        myref = SvRV(myref);
        if(SvROK(myref))
            myref = SvRV(myref);

        ENTER;
        SAVETMPS;

        PUSHMARK(SP);
        XPUSHs(sv_2mortal(newSVpv("_lock",0)));
        XPUSHs(sv_2mortal(newRV_inc(myref)));
        PUTBACK;

        process = getpid();
        count = call_pv( "threads::shared::_remote",G_SCALAR );

        SPAGAIN;
        ordinal = POPl;
   /*     printf ("lock: ordinal = %d, process = %d\n",ordinal,process); */
        PUTBACK;

        FREETMPS;
        LEAVE;
        
        av_ord_lock = newAV();
        av_store(av_ord_lock, 1, newSVuv(process));
        av_store(av_ord_lock, 2, newSVuv(ordinal));

        SAVEDESTRUCTOR_X(exec_leave,newRV((SV*)av_ord_lock));
        ENTER;

#----------------------------------------------------------------------
#  IN: 1 any variable (scalar,array,hash,glob) -- signal variable
#      2 any variable (scalar,array,hash,glob) -- lock variable

void
cond_wait(SV *myref, SV *myref2 = 0)
    PROTOTYPE: \[$@%];\[$@%]
    CODE:
        if (!SvROK(myref))
            Perl_croak(aTHX_ "Argument to cond_wait needs to be passed as ref");
        myref = SvRV(myref);
        if(SvROK(myref))
            myref = SvRV(myref);
        
        ENTER;
        SAVETMPS;

        PUSHMARK(SP);
        XPUSHs(sv_2mortal(newSVpv("_wait",0)));
        XPUSHs(sv_2mortal(newRV_inc(myref)));
        if (myref2 && myref != myref2)
        {
            if (!SvROK(myref2))
                Perl_croak(aTHX_ "cond_wait lock needs to be passed as ref");
            myref2 = SvRV(myref2);
            if(SvROK(myref2))
                myref2 = SvRV(myref2);
            XPUSHs(sv_2mortal(newRV_inc(myref2)));
        }
        PUTBACK;

        call_pv( "threads::shared::_remote",G_DISCARD );

        FREETMPS;
        LEAVE;

#----------------------------------------------------------------------
#  IN: 1 any variable (scalar,array,hash,glob) -- signal variable
#      2 epoch time of event expiration
#      3 any variable (scalar,array,hash,glob) -- lock variable

int
cond_timedwait(SV *myref, double epochts, SV *myref2 = 0)
    PROTOTYPE: \[$@%]$;\[$@%]
    PREINIT:
        int count;
        bool retval;
        U32 ordinal;
    CODE:
        if (!SvROK(myref))
            Perl_croak(aTHX_ "Argument to cond_timedwait needs to be passed as ref");
        myref = SvRV(myref);
        if(SvROK(myref))
            myref = SvRV(myref);

        ENTER;
        SAVETMPS;

        PUSHMARK(SP);
        XPUSHs(sv_2mortal(newSVpv("_timedwait",0)));
        XPUSHs(sv_2mortal(newRV_inc(myref)));
        XPUSHs(sv_2mortal(newSVnv(epochts)));
        if (myref2 && myref != myref2)
        {
            if (!SvROK(myref2))
                Perl_croak(aTHX_ "cond_timedwait lock needs to be passed as ref");
            myref2 = SvRV(myref2);
            if(SvROK(myref2))
                myref2 = SvRV(myref2);
            XPUSHs(sv_2mortal(newRV_inc(myref2)));
        }
        PUTBACK;

        count = call_pv( "threads::shared::_remote",G_ARRAY );

        SPAGAIN;
        if (count != 2)
            croak ("Error receiving response value from _remote\n");

        retval = POPi;
        ordinal = POPi;
        PUTBACK;

        FREETMPS;
        LEAVE;
        RETVAL = retval;
        if (RETVAL == 0)
            XSRETURN_UNDEF;
    OUTPUT:
        RETVAL

#----------------------------------------------------------------------
#  IN: 1 any variable (scalar,array,hash,glob)

void
cond_signal(SV *myref)
    PROTOTYPE: \[$@%]
    CODE:
        if (!SvROK(myref))
            Perl_croak(aTHX_ "Argument to cond_signal needs to be passed as ref");
        myref = SvRV(myref);
        if(SvROK(myref))
            myref = SvRV(myref);

        ENTER;
        SAVETMPS;

        PUSHMARK(SP);
        XPUSHs(sv_2mortal(newSVpv("_signal",0)));
        XPUSHs(sv_2mortal(newRV_inc(myref)));
        PUTBACK;

        call_pv( "threads::shared::_remote",G_DISCARD );

        FREETMPS;
        LEAVE;

#----------------------------------------------------------------------
#  IN: 1 any variable (scalar,array,hash,glob)

void
cond_broadcast(SV *myref)
    PROTOTYPE: \[$@%]
    CODE:
        if (!SvROK(myref))
            Perl_croak(aTHX_ "Argument to cond_broadcast needs to be passed as ref");
        myref = SvRV(myref);
        if(SvROK(myref))
            myref = SvRV(myref);

        ENTER;
        SAVETMPS;

        PUSHMARK(SP);
        XPUSHs(sv_2mortal(newSVpv("_broadcast",0)));
        XPUSHs(sv_2mortal(newRV_inc(myref)));
        PUTBACK;

        call_pv( "threads::shared::_remote",G_DISCARD );

        FREETMPS;
        LEAVE;

#----------------------------------------------------------------------
#  IN: 1 scalar
#  IN: 1 optional scalar

void
bless(SV *myref, ...)
    PROTOTYPE: $;$
    PREINIT:
        HV* stash;
        SV* classname;
        STRLEN len;
        char *ptr;
        SV* myref2;
    CODE:
        if (items == 1) {
            stash = CopSTASH(PL_curcop);
        } else {
            classname = ST(1);

            if (classname &&
                ! SvGMAGICAL(classname) &&
                ! SvAMAGIC(classname) &&
                SvROK(classname))
            {
                Perl_croak(aTHX_ "Attempt to bless into a reference");
            }
            ptr = SvPV(classname, len);
            if (ckWARN(WARN_MISC) && len == 0) {
                Perl_warner(aTHX_ packWARN(WARN_MISC),
                        "Explicit blessing to '' (assuming package main)");
            }
            stash = gv_stashpvn(ptr, len, TRUE);
        }
        SvREFCNT_inc(myref);
        (void)sv_bless(myref, stash);
        ST(0) = sv_2mortal(myref);
        
        myref2 = SvRV(myref);
        if(SvROK(myref2)) {
            myref2 = SvRV(myref2);
        }

        ENTER;
        SAVETMPS;

        PUSHMARK(SP);
        XPUSHs(sv_2mortal(newRV(myref2)));
        XPUSHs(sv_2mortal(newSVpv(HvNAME(stash), 0)));
        PUTBACK;

        call_pv( "threads::shared::_bless",G_DISCARD );
        
        FREETMPS;
        LEAVE;

#----------------------------------------------------------------------
#  IN: 1 any variable (scalar,array,hash,glob)

UV
_id(SV *myref)
    PROTOTYPE: \[$@%]
    PREINIT:
        UV retval;
    CODE:
        if (!SvROK(myref))
            Perl_croak(aTHX_ "Argument to _id needs to be passed as ref");
        myref = SvRV(myref);
        SvGETMAGIC(myref);
        if(SvROK(myref))
            myref = SvRV(myref);

        ENTER;
        SAVETMPS;

        PUSHMARK(SP);
        XPUSHs(sv_2mortal(newRV_inc(myref)));
        PUTBACK;

        call_pv( "threads::shared::__id",G_SCALAR );

        SPAGAIN;

        retval = POPi;
        PUTBACK;

        FREETMPS;
        LEAVE;
        RETVAL = retval;
    OUTPUT:
        RETVAL

#----------------------------------------------------------------------

BOOT:
{
    MY_CXT_INIT;
    Perl_sharedsv_init(aTHX);
}
