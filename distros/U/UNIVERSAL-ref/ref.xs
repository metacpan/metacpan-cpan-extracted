#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

typedef OP	*B__OP;

int init_done = 0;

#if 0
#define UNIVERSAL_REF_DEBUG(x) x
#else
#define UNIVERSAL_REF_DEBUG(x)
#endif

OP* (*real_pp_ref)(pTHX);
PP(pp_universal_ref) { 
    dSP; dTARG;
    SV* thing;
    SV* result;
    int count;

    if ( OP_REF != PL_op->op_type ) {
        /* WTF called us? Whatever it is, I don't want to screw with it. */
        return real_pp_ref(aTHX);
    }

    /* Delegate to the pre-existing function if it isn't an object. */
    if ( ! sv_isobject( TOPs ) ) {
        /* I only mess with objects. */
        return real_pp_ref(aTHX);
    }

    /* Start our scope. */
    thing = POPs;
    ENTER;
    SAVETMPS;

    /* Pass that as an argument to the callback. */
    /* TODO: list context. */
    PUSHMARK(SP);
    XPUSHs(thing);
    PUTBACK;
    count = call_pv( "UNIVERSAL::ref::_hook", G_SCALAR );
    if ( 1 != count )
        croak("UNIVERSAL::ref::_hook returned %d elements, expected 1", count);

    /* Get our result and increase its refcount so it won't be reaped
       by closing this scope. */
    /* TODO: list context. */
    SPAGAIN;
    result = POPs;
    SvREFCNT_inc(result);

    /* Close our scope. */
    FREETMPS;
    LEAVE;
    
    /* Just return whatever the callback returned. */
    assert( 1 == SvREFCNT(result));
    XPUSHs(result);
    RETURN;
}

void universal_ref_fixupop( OP* o ) {
  /* I'm seeing completely fruity ->op_sibling pointers and I think
     perhaps I shouldn't be looking at some ops. I'm hoping that
     requiring that I have a valid sort of class will prevent me
     from wandering into places I shouldn't be. */
  U32 opclass;

  UNIVERSAL_REF_DEBUG(printf( "fixing op=%x\n", o ));
  opclass = (OA_CLASS_MASK & PL_opargs[o->op_type]) >> OCSHIFT;
  if ( opclass < OA_UNOP ) {
    return;
  }
  
  /* printf("# OP=%x\n",o); */
  if ( o->op_type == OP_REF || o->op_ppaddr == real_pp_ref ) {
    UNIVERSAL_REF_DEBUG(printf("# XXX\n"));
    o->op_ppaddr = Perl_pp_universal_ref;
  }

  UNIVERSAL_REF_DEBUG(printf("# op_type=%d\n",o->op_type));
  UNIVERSAL_REF_DEBUG(printf("# opargs=%x\n",PL_opargs[o->op_type] & ~OA_CLASS_MASK));
  UNIVERSAL_REF_DEBUG(printf("# class=%x\n", opclass));

  if ( cUNOPx(o)->op_first ) {
    UNIVERSAL_REF_DEBUG(printf("# ->first=%x\n",cUNOPx(o)->op_first));
    universal_ref_fixupop(cUNOPx(o)->op_first);
  }

  if ( o->op_sibling ) {
    UNIVERSAL_REF_DEBUG(printf("# ->sibling=%x\n",o->op_sibling));
    universal_ref_fixupop(o->op_sibling);
  }
}

void universal_ref_fixupworld () {
    I32 i = 0;

    /* TODO: This finds all existing code and replaces ppaddr with the
       new pointer. */

    /* Fixup stuff that exists. */
/*
    if ( PL_main_root ) {
        UNIVERSAL_REF_DEBUG(printf("# FIXING PL_main_root\n"));
        universal_ref_fixupop( PL_main_root );
    }
    if ( PL_eval_root ) {
        UNIVERSAL_REF_DEBUG(printf("# FIXING PL_eval_root\n"));
        universal_ref_fixupop(PL_eval_root);
    }
    if ( PL_main_cv && CvROOT(PL_main_cv) ) {
        UNIVERSAL_REF_DEBUG(printf("# FIXING PL_main_cv\n"));
        universal_ref_fixupop(CvROOT(PL_main_cv));
    }
    if ( PL_compcv && CvROOT(PL_compcv) ) {
        UNIVERSAL_REF_DEBUG(printf("# FIXING PL_compcv\n"));
        universal_ref_fixupop(CvROOT(PL_compcv));
    }
*/

    /* Is this too sneaky to live? Dunno. */
/*    for ( i = 2; i < PL_savestack_max; i += 2 ) {
        if ( PL_savestack[i].any_i32 == SAVEt_SPTR
             && (    &PL_compcv  == PL_savestack[i-1].any_ptr
                  || &PL_main_cv == PL_savestack[i-1].any_ptr )
             && PL_savestack[i-2].any_ptr ) {
            UNIVERSAL_REF_DEBUG(printf("# PL_compcv=%x\n", PL_savestack[i-2].any_ptr));
            UNIVERSAL_REF_DEBUG(printf("#   file=%s\n",CvFILE((CV*)(PL_savestack[i-2].any_ptr))));
            UNIVERSAL_REF_DEBUG(printf("#   root=%x\n",CvROOT((CV*)(PL_savestack[i-2].any_ptr))));
            UNIVERSAL_REF_DEBUG(printf("#   gv=%x\n",CvGV((CV*)(PL_savestack[i-2].any_ptr))));
            UNIVERSAL_REF_DEBUG(printf("#   xsubany=%x\n",CvXSUBANY((CV*)(PL_savestack[i-2].any_ptr))));
            UNIVERSAL_REF_DEBUG(printf("#   xsub=%x\n",CvXSUB((CV*)(PL_savestack[i-2].any_ptr))));
            UNIVERSAL_REF_DEBUG(printf("#   start=%x\n",CvSTART((CV*)(PL_savestack[i-2].any_ptr))));
            UNIVERSAL_REF_DEBUG(printf("#   stash=%x\n",CvSTASH((CV*)(PL_savestack[i-2].any_ptr))));
            UNIVERSAL_REF_DEBUG(printf("#   depth=%x\n",CvDEPTH((CV*)(PL_savestack[i-2].any_ptr))));
            UNIVERSAL_REF_DEBUG(printf("#   padlist=%x\n",CvPADLIST((CV*)(PL_savestack[i-2].any_ptr))));
            UNIVERSAL_REF_DEBUG(printf("#   outside=%x\n",CvOUTSIDE((CV*)(PL_savestack[i-2].any_ptr))));
            UNIVERSAL_REF_DEBUG(printf("#   flags=%x\n",CvFLAGS((CV*)(PL_savestack[i-2].any_ptr)))); */
            /* universal_ref_fixupop(CvROOT((CV*)(PL_savestack[i-2].any_ptr))); */
/*        }
    } */
}

MODULE = UNIVERSAL::ref	PACKAGE = UNIVERSAL::ref PREFIX = universal_ref_

PROTOTYPES: ENABLE

BOOT:
if ( ! init_done++  ) {
    /* Is this a race in threaded perl? */
    real_pp_ref = PL_ppaddr[OP_REF];
    PL_ppaddr[OP_REF] = Perl_pp_universal_ref;
/*    universal_ref_fixupworld(); */
}

void
universal_ref__fixupop( o )
        B::OP o
    CODE:
        universal_ref_fixupop( o );

void
universal_ref__fixupworld()
    CODE:
        universal_ref_fixupworld();

