/* -*- Mode: C; tab-width: 8; indent-tabs-mode: nil; c-basic-offset: 4 -*-
 * The contents of this file are subject to the Mozilla Public
 * License Version 1.1 (the "License"); you may not use this file
 * except in compliance with the License. You may obtain a copy of
 * the License at http://www.mozilla.org/MPL/
 * 
 * Software distributed under the License is distributed on an "AS
 * IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or
 * implied. See the License for the specific language governing
 * rights and limitations under the License.
 * 
 * The Original Code is the XML::Sablotron module.
 * 
 * The Initial Developer of the Original Code is Ginfer Alliance Ltd.
 * Portions created by Ginger Alliance are 
 * Copyright (C) 1999-2000 Ginger Alliance Ltd..  
 * All Rights Reserved.
 * 
 * Contributor(s): science+computing ag:
 *                 Nicolas Trebst, n.trebst@science-computing.de
 *                 Anselm Kruis,    a.kruis@science-computing.de
 *
 * Alternatively, the contents of this file may be used under the
 * terms of the GNU General Public License Version 2 or later (the
 * "GPL"), in which case the provisions of the GPL are applicable 
 * instead of those above.  If you wish to allow use of your 
 * version of this file only under the terms of the GPL and not to
 * allow others to use your version of this file under the MPL,
 * indicate your decision by deleting the provisions above and
 * replace them with the notice and other provisions required by
 * the GPL.  If you do not delete the provisions above, a recipient
 * may use your version of this file under either the MPL or the
 * GPL.
 */

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include <sablot.h>
#include <shandler.h>
#include <sdom.h>
#include <sxpath.h>
#include "common.h"

#if defined(WIN32)
#if defined(__cplusplus) && !defined(PERL_OBJECT)
#include <malloc.h>
#endif
#else
#include <stdlib.h>
#include <stdio.h>
#endif


/* struct MHCallbackVector{
   SV *makeCodeProc;
   SV *logProc;
   SV *errorProc;
 };


typedef struct MHCallbackVector MHCallbackVector;

struct SHCallbackVector {
  SV *openProc;
  SV *getProc;
  SV *putProc;
  SV *closeProc;
};

typedef struct SHCallbackVector SHCallbackVector;

struct XHCallbackVector {
  SV *openProc;
  SV *getProc;
  SV *putProc;
  SV *closeProc;
};

typedef struct XHCallbackVector XHCallbackVector;

MHCallbackVector mh_callback_vector;
SHCallbackVector sh_callback_vector;
XHCallbackVector xh_callback_vector;

*/

#include "DOM/DOM.h"
#include "Processor/Processor.h"
#include "SXP/SXP.h"
#include "Situation/Situation.h"

/*
############################################################
############################################################
## real xs stuff
############################################################
############################################################
*/

MODULE = XML::Sablotron	PACKAGE = XML::Sablotron PREFIX = Sablot
PROTOTYPES: ENABLE

############################################################
#old non- object interface
############################################################

int
SablotProcessStrings(sheet,input,result)
	char * 		sheet
	char * 		input
	char * 		result
	PREINIT:
	char *foo;
	CODE:
        RETVAL = SablotProcessStrings(sheet, input, &foo);
	result = foo;  
	OUTPUT:
	result
	RETVAL
	CLEANUP:
	if (! RETVAL && foo) SablotFree(foo);

#/* renamed to avoid the conflict with the new object method process */

int
SablotProcess(sheetURI, inputURI, resultURI, params, arguments, result)
	char * 		sheetURI
	char *		inputURI
	char *		resultURI
	SV *		params
	SV *		arguments
	char * 		result
	PREINIT:
	char **params_ptr, **args_ptr;
	AV *params_av, *args_av;
	int i, size;
	SV *aux_sv;
	char *hoo;
	CODE:
	
	if (SvOK(params)) {
	  if (! SvROK(params) || !(SvFLAGS(params) & SVt_PVAV))
	    croak("4-th argument to SablotProcess has to be ARRAYREF");
          params_av = (AV*)SvRV(params);
          size = av_len(params_av) + 1;
          params_ptr = (char**)malloc((size + 1) * sizeof(char*));
          for (i = 0; i < size; i++) {
            aux_sv = *av_fetch(params_av, i, 0);
            params_ptr[i] = SvPV(aux_sv, PL_na);
          }
          params_ptr[size] = NULL;
	} else {
	  params_ptr = NULL;
	}

	if (SvOK(arguments)) {
	  if (! SvROK(arguments) || !(SvFLAGS(arguments) & SVt_PVAV))
	    croak("5-th argument to SablotProcess has to be ARRAYREF");
	  args_av = (AV*)SvRV(arguments);
	  size = av_len(args_av) + 1;
          args_ptr = (char**)malloc((size + 1) * sizeof(char*));
          for (i = 0; i < size; i++) {
            aux_sv = *av_fetch(args_av, i, 0);
            args_ptr[i] = SvPV(aux_sv, PL_na);
          }
          args_ptr[size] = NULL;
	} else {
	  args_ptr = NULL;
	}

       	RETVAL = SablotProcess(sheetURI, inputURI, resultURI, 
		               (const char**)params_ptr, 
                               (const char**)args_ptr, &hoo);
	if (params_ptr) free(params_ptr);
	if (args_ptr) free(args_ptr);
	result = hoo;
	OUTPUT:
	RETVAL
	result
	CLEANUP:
	if (! RETVAL && hoo) SablotFree(hoo);


INCLUDE: DOM/DOM.xsh

INCLUDE: Processor/Processor.xsh

INCLUDE: SXP/SXP.xsh

INCLUDE: Situation/Situation.xsh
