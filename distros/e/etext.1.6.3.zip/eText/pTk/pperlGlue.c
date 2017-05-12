#include "pperl.h"

int 
LangArgEval(interp,arg)				
     Tcl_Interp *interp;
     Arg	arg;
{
/*     AV *av = SvROK(arg) ? (AV*)SvRV(arg) : (AV*)arg; */
/*     SV **svp = AvARRAY(av); */
/*     CV *cv = (CV*) *svp; */
/*     I32 items = AvFILL(av), item = 0, count; */

/*     ENTER; */
/*     SAVETMPS; */

/*     PUSHMARK(sp) ; */
/*     EXTEND(stack_sp, 1 + items); */
/*     while (item++ < items) { */
/* 	PUSHs(svp+item); */
/*     } */
/*     PUTBACK; */
/*     count = perl_call_sv((SV*)cv, G_ARRAY | G_EVAL); */

/*     SPAGAIN ; */

/*     { */
/* 	int offset = count; */
/* 	SV **p = sp - count; */
/* 	AV *resAv = ResultAv(interp, "Tcl_AppendArg", 1); */

/* 	while (count-- > 0) { */
/* 	    av_push(resAv, *++p); */
/* 	} */
/* 	sp -= offset; */
/*     } */

/*     PUTBACK; */
/*     FREETMPS; */
/*     LEAVE; */
    
    
  LangCallback *cb = LangMakeCallback(arg);		
  int res;

  res = LangDoCallback(interp,cb,2 /* G_ARRAY */,0,"");		
  LangFreeCallback(cb);					
  return res;
}

void
LangDumpArg(arg, count)
    Arg arg;
    I32 count;
{
    dSP;
    SV *sv = newSViv(count);
    
    PUSHMARK(sp) ;
    EXTEND(stack_sp, 3);
    XPUSHs((SV*)arg);
    XPUSHs(sv);
    PUTBACK;
    perl_call_pv("Devel::Peek::Dump", G_DISCARD | G_EVAL);
}
