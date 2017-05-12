#define PERL_NO_GET_CONTEXT	/* we want efficiency */
#include <EXTERN.h>
#include <perl.h>
#include <XSUB.h>
#include <security/_pam_types.h>
#include <security/pam_modules.h>
#include "const.h"

//typedef int xint;
#define xint int

void P_sv_setqvn(pTHX_ SV* m, int i, const char* s, STRLEN len){
	sv_setpvn(m,s,len);
	SvIV_set(m,i);
	SvPOK_on(m);
}
SV* P_newSVqv2(pTHX_ int i, const char* (*func)(int i,int* len)){
	int len;
	const char* s=(*func)(i,&len);
	SV* m=newSVpv(s,len);
	sv_setiv(m,i);
	SvPOK_on(m);
	return m;
}
SV* P_newSVqvn(pTHX_ const char* s, STRLEN len, int i){
	SV* m=newSVpv(s,len);
	sv_setiv(m,i);
	SvPOK_on(m);
	return m;
}
SV* P_newSVqv(pTHX_ const char* s, int i){
	SV* m=newSVpv(s,strlen(s));
	sv_setiv(m,i);
	SvPOK_on(m);
	return m;
}

SV* Q_intorconst(pTHX_ SV* s){
	int count;
	SV* m;

	dSP;

	//ENTER;
	//SAVETMPS;

	PUSHMARK(SP);
	XPUSHs(s);
	PUTBACK;

	count=call_pv("Authen::PAM::Module::intorconst", G_SCALAR);

	SPAGAIN;

	if (count != 1) croak("Big trouble\n");

	m=POPs;

	PUTBACK;
	//FREETMPS;
	//LEAVE;
	return m;
}

#include "const.c.inc"

