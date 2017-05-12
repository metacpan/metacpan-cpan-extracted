#ifdef __cplusplus
#include <iostream>
extern "C" {
#endif
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#ifdef __cplusplus
}
#endif

#include "tx/tx.hpp"

int tx_free(int txi){
    delete INT2PTR(tx_tool::tx *, txi);
}

int tx_open(char *filename){
    tx_tool::tx *txp = new tx_tool::tx;
    if (txp->read(filename) == -1){
	delete txp;
	return 0;
    }
    return PTR2IV(txp);
}

static SV *
do_callback(SV *callback, SV *s){
    dSP;
    int argc;
    SV *retval;
    ENTER;
    SAVETMPS;
    PUSHMARK(sp);
    XPUSHs(s);
    PUTBACK;
    argc = call_sv(callback, G_SCALAR);
    SPAGAIN;
    if (argc != 1){
        croak("fallback sub must return scalar!");
    }
    retval = newSVsv(POPs);
    PUTBACK;
    FREETMPS;
    LEAVE;
    return retval;
}

SV *tx_gsub(int txi, SV *src, SV *callback){
    SV *result = newSV(0);
    tx_tool::tx *txp = INT2PTR(tx_tool::tx *, txi);

    char *head = SvPV_nolen(src);
    char *tail = head + SvCUR(src);
    size_t retLen;    

    while (head < tail) {
	if (txp->prefixSearch(head, tail-head, retLen) 
	    != tx_tool::tx::NOTFOUND){
	    SV *ret = do_callback(callback, newSVpvn(head, retLen));
	    sv_catsv(result, ret);
	    head += retLen;
	}else{
	    sv_catpvn(result, head, 1);
	    ++head; 
	}
    }
    return result;
}

MODULE = Text::Tx		PACKAGE = Text::Tx		

int
xs_free(txi)
    int  txi;
CODE:
    RETVAL = tx_free(txi);
OUTPUT:
    RETVAL

int
xs_open(filename)
   char *filename
CODE:
   RETVAL = tx_open(filename);
OUTPUT:
   RETVAL

SV *
xs_gsub(txi, src, callback)
   int txi;
   SV *src;
   SV *callback; 
CODE:
   RETVAL = tx_gsub(txi, src, callback);
OUTPUT:
   RETVAL
