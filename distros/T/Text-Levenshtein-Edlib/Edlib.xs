#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include <edlib.h>

#include "const-c.inc"

MODULE = Text::Levenshtein::Edlib		PACKAGE = Text::Levenshtein::Edlib

INCLUDE: const-xs.inc
PROTOTYPES: ENABLE

SV*
edlibAlign(const char *query, int length(query), const char *target, int length(target), int k, int mode, int task)
PREINIT:
	EdlibAlignResult align_result;
	SV *returned_av_ref;
	AV *returned_av, *endAV, *startAV, *alignAV;
	int i;
CODE:
	align_result = edlibAlign(query, XSauto_length_of_query, target, XSauto_length_of_target, edlibNewAlignConfig(k, mode, task));
	returned_av = newAV();
	av_push(returned_av, newSViv(align_result.editDistance));
	av_push(returned_av, newSViv(align_result.alphabetLength));
	if(align_result.endLocations == NULL)
		av_push(returned_av, &PL_sv_undef);
	else {
		endAV = newAV();
		for(i = 0 ; i < align_result.numLocations ; i++)
			av_push(endAV, newSViv(align_result.endLocations[i]));
		av_push(returned_av, newRV_noinc((SV*)endAV));
	}
	if(align_result.startLocations == NULL)
		av_push(returned_av, &PL_sv_undef);
	else {
		startAV = newAV();
		for(i = 0 ; i < align_result.numLocations ; i++)
			av_push(startAV, newSViv(align_result.startLocations[i]));
		av_push(returned_av, newRV_noinc((SV*)startAV));
	}
	if(align_result.alignment == NULL)
		av_push(returned_av, &PL_sv_undef);
	else {
		startAV = newAV();
		for(i = 0 ; i < align_result.alignmentLength ; i++)
			av_push(startAV, newSViv(align_result.alignment[i]));
		av_push(returned_av, newRV_noinc((SV*)startAV));
	}
	edlibFreeAlignResult(align_result);
	RETVAL = newRV_noinc((SV*)returned_av);
OUTPUT:
	RETVAL


char*
edlibAlignmentToCigar(unsigned char *alignment, int length(alignment), int format)
