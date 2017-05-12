# 
# The contents of this file are subject to the Mozilla Public
# License Version 1.1 (the "License"); you may not use this file
# except in compliance with the License. You may obtain a copy of
# the License at http://www.mozilla.org/MPL/
# 
# Software distributed under the License is distributed on an "AS
# IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or
# implied. See the License for the specific language governing
# rights and limitations under the License.
# 
# The Original Code is the XML::Sablotron::DOM module.
# 
# The Initial Developer of the Original Code is Ginger Alliance Ltd.
# Portions created by Ginger Alliance are 
# Copyright (C) 1999-2000 Ginger Alliance Ltd.
# All Rights Reserved.
# 
# Contributor(s): science+computing ag:
#                 Nicolas Trebst, n.trebst@science-computing.de
#                 Anselm Kruis,    a.kruis@science-computing.de
# 
# Alternatively, the contents of this file may be used under the
# terms of the GNU General Public License Version 2 or later (the
# "GPL"), in which case the provisions of the GPL are applicable 
# instead of those above.  If you wish to allow use of your 
# version of this file only under the terms of the GPL and not to
# allow others to use your version of this file under the MPL,
# indicate your decision by deleting the provisions above and
# replace them with the notice and other provisions required by
# the GPL.  If you do not delete the provisions above, a recipient
# may use your version of this file under either the MPL or the
# GPL.
# 

#
# ../Sablotron.xs includes this file. 
#


MODULE = XML::Sablotron PACKAGE = XML::Sablotron::Processor  PREFIX = Sablot
PROTOTYPES: ENABLE

void*
_createProcessor(object)
	SV 	*object
    	PREINIT: 
     	void *processor;
     	CODE:
     	SablotCreateProcessor(&processor);
	SablotSetInstanceData(processor, SvREFCNT_inc(object));
	RETVAL = processor;
     	OUTPUT:
     	RETVAL

void*
_createProcessorForSituation( object, situation )
	SV 	*object
	SV      *situation
    	PREINIT: 
     	void *processor;
     	CODE:
     	SablotCreateProcessorForSituation( SIT_HANDLE(situation), &processor );
        SablotSetInstanceData(processor, SvREFCNT_inc(object));	
	RETVAL = processor;
     	OUTPUT:
     	RETVAL

void
_destroyProcessor(object)
	SV 	*object
	PREINIT:
	void *processor;
	CODE:
	processor = GET_PROCESSOR(object);
	if ( SablotDestroyProcessor(processor) ) 
	  croak("SablotDestroyProcesso failed");

#break circular reference
void
_release(object)
	SV	*object
	PREINIT:
	void *processor;
	SV *processor_obj;
	CODE:
	processor = GET_PROCESSOR(object);
	processor_obj = (struct sv*) SablotGetInstanceData(processor);
	if (processor_obj) SvREFCNT_dec(processor_obj);
	SablotSetInstanceData(processor, NULL);

int
SablotRunProcessor(object, sheetURI, inputURI, resultURI, params, arguments)
	SV *		object
	char * 		sheetURI
	char *		inputURI
	char *		resultURI
	SV *		params
	SV *		arguments
	PREINIT:
	char **params_ptr, **args_ptr;
	AV *params_av, *args_av;
	int i, size;
	SV *aux_sv;
	void *processor;
	CODE:
	processor = GET_PROCESSOR(object);

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

       	RETVAL = SablotRunProcessor(processor, sheetURI, inputURI, resultURI, 
                                    (const char**)params_ptr, 
                                    (const char**)args_ptr);
	if (params_ptr) free(params_ptr);
	if (args_ptr) free(args_ptr);
	OUTPUT:
	RETVAL

int
addArg(object, sit, name, buff)
        SV*     object
        SV*     sit
        char*   name
        char*   buff
	PREINIT:
	void *processor;
        CODE:
        SablotSituation situa = SIT_HANDLE(sit);
	processor = GET_PROCESSOR(object);
        RETVAL = SablotAddArgBuffer(situa, processor, name, buff);
        OUTPUT:
        RETVAL

int
addArgTree(object, sit, name, tree)
        SV*     object
        SV*     sit
        char*   name
        SV*     tree
	PREINIT:
	void *processor;
        SDOM_Document doc;
        CODE:
        SablotSituation situa = SIT_HANDLE(sit);
	processor = GET_PROCESSOR(object);
        doc = DOC_HANDLE(tree);
        SablotLockDocument(situa, doc);
        RETVAL = SablotAddArgTree(situa, processor, name, doc);
        OUTPUT:
        RETVAL

int
addParam(object, sit, name, value)
        SV*     object
        SV*     sit
        char*   name
        char*   value
	PREINIT:
	void *processor;
        CODE:
        SablotSituation situa = SIT_HANDLE(sit);
	processor = GET_PROCESSOR(object);
        RETVAL = SablotAddParam(situa, processor, name, value);
        OUTPUT:
        RETVAL

int 
process(object, sit, sheet, data, output)
        SV*     object
        SV*     sit
        char*   sheet
        char*   data
        char*   output
	PREINIT:
	void *processor;
        CODE:
        SablotSituation situa = SIT_HANDLE(sit);
	processor = GET_PROCESSOR(object);
        RETVAL = SablotRunProcessorGen(situa, processor, sheet, data, output);
        OUTPUT:
        RETVAL

int 
processExt(object, sit, sheet, data, output)
        SV*     object
        SV*     sit
        char*   sheet
        SV*     data
        char*   output
	PREINIT:
	void *processor;
        CODE:
        SablotSituation situa = SIT_HANDLE( sit );
	processor             = GET_PROCESSOR( object );
        if(SvROK( data ))
          data = SvRV( data );
        RETVAL = SablotRunProcessorExt(situa, processor, sheet, output, data);
        OUTPUT:
        RETVAL


char*
SablotGetResultArg(object, uri)
	SV *	object
	char * 	uri
	PREINIT:
	void *processor;
	char *hoo;
	int status;
	CODE:
	processor = GET_PROCESSOR(object);
	status = SablotGetResultArg(processor, uri, &hoo);
 	if ( status ) croak("Cann't get requested output buffer\n");
	RETVAL = hoo;
	OUTPUT:
	RETVAL
	CLEANUP:
	if (!status && hoo) SablotFree(hoo);
	
int 
SablotFreeResultArgs(object)
	SV *	object
	PREINIT:
	void *processor;
	CODE:
	processor = GET_PROCESSOR(object);
	RETVAL = SablotFreeResultArgs(processor);
	OUTPUT:
	RETVAL

int 
SablotSetBase(object, base)
	SV * 	object
	char *	base
	PREINIT:
	void *processor;
	CODE:
	processor = GET_PROCESSOR(object);
	RETVAL = SablotSetBase(processor, base);
	OUTPUT:
	RETVAL

int 
SablotSetBaseForScheme(object, scheme, base)
	SV * 	object
	char * 	scheme
	char *	base
	PREINIT:
	void *processor;
	CODE:
	processor = GET_PROCESSOR(object);
	RETVAL = SablotSetBaseForScheme(processor, scheme, base);
	OUTPUT:
	RETVAL

int 
SablotSetLog(object, filename, level)
	SV * 	object
	char *	filename
	int 	level
	PREINIT:
	void *processor;
	CODE:
	processor = GET_PROCESSOR(object);
	RETVAL = SablotSetLog(processor, filename, level);
	OUTPUT:
	RETVAL


int 
SablotClearError(object)
	SV * 	object
	PREINIT:
	void *processor;
	CODE:
	processor = GET_PROCESSOR(object);
	RETVAL = SablotClearError(processor);
	OUTPUT:
	RETVAL

void
SablotSetOutputEncoding(object, encoding)
	SV *	object
	char *	encoding
	PREINIT:
	void *processor;
	CODE:
	processor = GET_PROCESSOR(object);
	SablotSetEncoding(processor, encoding);

############################################################
# interface for handlers
############################################################

int
_regHandler(object, type, wrapper)
	SV * 	object
	int 	type
	SV * 	wrapper
	PREINIT:
	void *processor;
	void *vector;
	CODE:
	processor = GET_PROCESSOR(object);

	switch (type) {
	  case 0:
	    vector = &mh_handler_vector;
	    break;
          case 1:
	    vector = &sh_handler_vector;
            break;
          case 2:
            vector = &sax_handler_vector;
            break;
          case 3:
            vector = &xh_handler_vector;
            break;
	  otherwise:
            croak("Unsupported handler type");
	}
	SvREFCNT_inc(wrapper);
	RETVAL = SablotRegHandler(processor, (HandlerType) type, vector, wrapper);
	OUTPUT:
	RETVAL

int
_unregHandler(object, type, wrapper)
	SV	*object
	int 	type
	SV 	*wrapper
	PREINIT:
	void *processor;
	void *vector;
	CODE:
	processor = GET_PROCESSOR(object);
	switch (type) {
	  case 0:
	    vector = &mh_handler_vector;
	    break;
          case 1:
	    vector = &sh_handler_vector;
            break;
          case 2:
            vector = &sax_handler_vector;
            break;
          case 3:
            vector = &xh_handler_vector;
	    break;
	  otherwise:
            croak("Unsupported handler type");
	}
	RETVAL = SablotUnregHandler(processor, (HandlerType) type, vector, wrapper);
	SvREFCNT_dec(wrapper);
	OUTPUT:
	RETVAL


