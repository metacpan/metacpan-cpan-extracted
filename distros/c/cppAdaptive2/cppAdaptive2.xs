
#define __INLINE_CPP_STANDARD_HEADERS 1
#define __INLINE_CPP_NAMESPACE_STD 1

#define __INLINE_CPP 1
#ifndef bool
#include <iostream>
#endif
extern "C" {
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
}
#ifdef bool
#undef bool
#include <iostream>
#endif

#undef seed
#undef do_open
#undef do_close
#undef PP

#include "cppAdaptive.cpp"

AV* _update(char* obsVector, char* futVector, char* betaVector, int n_observed) {
    string obsVector1(obsVector);
    string futVector1(futVector);
    string betaVector1(betaVector);

    cppAdaptive(obsVector1, futVector1, betaVector1, n_observed);

    // cout << "betaVector: \n" << betaVector1 << endl;
    // cout << "futVector: \n" << futVector1 << endl;

    AV* av = newAV();
    sv_2mortal((SV*)av);

    av_push( av, newSVpv(betaVector1.c_str(), betaVector1.size()) );
    av_push( av, newSVpv(futVector1.c_str(), futVector1.size()) );

    return av;
}

MODULE = cppAdaptive2        PACKAGE = cppAdaptive2  

PROTOTYPES: DISABLE

AV *
_update(obsVector, futVector, betaVector, n_observed)
	char *	obsVector
	char *	futVector
	char *	betaVector
	int	n_observed
    
