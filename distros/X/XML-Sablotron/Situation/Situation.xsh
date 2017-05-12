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


MODULE  = XML::Sablotron PACKAGE = XML::Sablotron::Situation  PREFIX  = Sablot
PROTOTYPES: ENABLE
##############################################################

int
_getNewSituationHandle(object)
        SV*      object
        CODE:
        SablotSituation sit;
        SablotCreateSituation(&sit);
        RETVAL = (int)sit;
        OUTPUT:
        RETVAL

void
_releaseHandle(object)
        SV*      object
        CODE:
        SablotDestroySituation(SIT_HANDLE(object));

void
_regDOMHandler( object )
	SV * 	object
        PREINIT:
        SablotSituation sit;
	CODE:
        sit = SIT_HANDLE( object );
        SvREFCNT_inc( SvRV( object )  );
        SXP_registerDOMHandler( sit, &DOMH_handler_vector, SvRV( object ) );
	OUTPUT: 

void
_unregDOMHandler( object )
	SV * 	object
        PREINIT:
        SablotSituation sit;
	CODE:
        sit = SIT_HANDLE( object );
        SXP_unregisterDOMHandler( sit );
 	SvREFCNT_dec( SvRV( object ) );
        OUTPUT:
	
void
setOptions(object, flags)
        SV*      object
        int      flags
        CODE:
        SablotSetOptions(SIT_HANDLE(object), flags);

void
clear(object)
        SV*      object
        CODE:
        SablotClearSituation(SIT_HANDLE(object));

char*
getErrorURI(object)
        SV* object
        CODE:
        char *uri=NULL;
	/* fixme */
        /*uri =  (char*)SablotGetErrorURI(SIT_HANDLE(object)); */
        RETVAL = uri;
        OUTPUT:
        RETVAL

int
getErrorLine(object)
        SV* object
        CODE:
        /* RETVAL = SablotGetErrorLine(SIT_HANDLE(object)); */
        OUTPUT:
        RETVAL

char*
getErrorMsg(object)
        SV* object
        CODE:
        char *msg=NULL;
	/* fixme */
        /* msg = (char*)SablotGetErrorMessage(SIT_HANDLE(object)); */
        RETVAL = msg;
        OUTPUT:
        RETVAL
        CLEANUP:
        if (msg) SablotFree(msg);

int
getDOMExceptionCode(object)
        SV*      object
        CODE:
        RETVAL = SDOM_getExceptionCode(SIT_HANDLE(object));
        OUTPUT:
        RETVAL

char*
getDOMExceptionMessage(object)
        SV*      object
        CODE:
        char *message = SDOM_getExceptionMessage(SIT_HANDLE(object));
        RETVAL = message;
        OUTPUT:
        RETVAL
        CLEANUP:
        if (message) SablotFree(message);

AV*
getDOMExceptionDetails(object)
        SV*      object
        CODE:
        int code;
        char *message;
        char *documentURI;
        int fileLine;
        SDOM_getExceptionDetails(SIT_HANDLE(object), &code,
                                 &message, &documentURI, &fileLine);
        RETVAL = (AV*)sv_2mortal((SV*)newAV());
        av_push(RETVAL, newSViv(code));
        av_push(RETVAL, newSVpv(message, 0));
        av_push(RETVAL, newSVpv(documentURI, 0));
        av_push(RETVAL, newSViv(fileLine));
        OUTPUT:
        RETVAL
        CLEANUP:
        if (message) SablotFree(message);
        if (documentURI) SablotFree(documentURI);

void 
setSXPOptions(object, options)
        SV*      object
        unsigned long      options
        CODE:
        SXP_setOptions(SIT_HANDLE(object), options);

unsigned long 
getSXPOptions(object)
        SV*      object
        CODE:
        RETVAL = SXP_getOptions(SIT_HANDLE(object));
        OUTPUT:
        RETVAL
        
