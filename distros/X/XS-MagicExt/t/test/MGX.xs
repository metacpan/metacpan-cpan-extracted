#define PERL_NO_GET_CONTEXT
#include <EXTERN.h>
#include <perl.h>
#include <XSUB.h>

#include "ppport.h"

#include "magic_ext.h"

#define FAIL warn("FAIL at %s line %d.\n", __FILE__, __LINE__)

STATIC IV
do_test(void){
	dTHX;
	SV* const sv    = sv_newmortal();
	SV* const obj1  = sv_newmortal();
	SV* const obj2  = sv_newmortal();
	SV* const data1 = sv_newmortal();
	MGVTBL id1;
	MGVTBL id2;
	MAGIC* mg1;
	MAGIC* mg2;
	IV success = 0;

	Zero(&id1, 1, MGVTBL);
	Zero(&id2, 2, MGVTBL);

	SvREFCNT_inc(obj1);
	SvREFCNT_inc(obj2);
	SvREFCNT_inc(data1);

	mg1 = mgx_attach_with_sv(sv, &id1, obj1, data1);
	mg2 = mgx_attach(sv, &id2, obj2);

	if(SvMAGICAL(sv)) success++; else FAIL;

	if(mgx_get(sv,   &id1) == mg1)   success++; else FAIL;
	if(MGX_FIND(sv,  &id1) == mg1)   success++; else FAIL;

	if(mgx_get(sv,   &id2) == mg2)   success++; else FAIL;
	if(MGX_FIND(sv,  &id2) == mg2)   success++; else FAIL;

	if(MGX_FIND(obj1, &id1) == NULL) success++; else FAIL;

	if(MG_obj(mg1) == obj1)  success++; else FAIL;
	if(MG_sv(mg1)  == data1) success++; else FAIL;

	if(MG_obj(mg2)  == obj2) success++; else FAIL;
	if(MG_vptr(mg2) == NULL) success++; else FAIL;

	if(SvREFCNT(obj1)  == 2) success++; else FAIL;
	if(SvREFCNT(obj2)  == 2) success++; else FAIL;
	if(SvREFCNT(data1) == 2) success++; else FAIL;

	mgx_detach(sv, &id1);

	if(SvMAGICAL(sv))              success++; else FAIL;
	if(MGX_FIND(sv, &id1) == NULL) success++; else FAIL;
	if(MGX_FIND(sv, &id2) == mg2)  success++; else FAIL;

	if(SvREFCNT(obj1) == 1)        success++; else FAIL;
	if(SvREFCNT(data1) == 1)       success++; else FAIL;
	if(SvREFCNT(obj2) == 2)        success++; else FAIL;

	mgx_detach(sv, &id2);

	if(!SvMAGICAL(sv))             success++; else FAIL;
	if(MGX_FIND(sv, &id2) == NULL) success++; else FAIL;
	if(SvREFCNT(obj2) == 1)        success++; else FAIL;

	return success;
}

MODULE = MGX	PACKAGE = MGX

PROTOTYPES: DISABLE

VERSIONCHECK: DISABLE

IV
do_test()
