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
 * The Original Code is the XML::Sablotron::DOM module.
 * 
 * The Initial Developer of the Original Code is Ginfer Alliance Ltd.
 * Portions created by Ginger Alliance are 
 * Copyright (C) 1999-2000 Ginger Alliance Ltd..  
 * All Rights Reserved.
 * 
 * Contributor(s):
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

/*
 *
 *  ../Sablotron.xs includes this file
 *
 */ 

#include "DOMhandler_stubs.h"

DOMHandler DOMH_handler_vector = {
  NULL,                              /* DOMH_getNodeType */
  NULL,                              /* DOMH_getNodeName */
  NULL,                              /* DOMH_getNodeNameURI */
  NULL,                              /* DOMH_getNodeNameLocal */
  NULL,                              /* DOMH_getNodeValue */
  NULL,                              /* DOMH_getNextSibling */
  NULL,                              /* DOMH_getPreviousSibling */
  NULL,                              /* DOMH_getNextAttrNS */
  NULL,                              /* DOMH_getPreviousAttrNS */
  NULL,                              /* DOMH_getChildCount */
  NULL,                              /* DOMH_getAttributeCount */
  NULL,                              /* DOMH_getNamespaceCount */
  NULL,                              /* DOMH_getChildNo */
  NULL,                              /* DOMH_getAttributeNo */
  NULL,                              /* DOMH_getNamespaceNo */
  NULL,                              /* DOMH_getParent */
  NULL,                              /* DOMH_getOwnerDocument */
  NULL,                              /* DOMH_compareNodes */
  NULL,                              /* DOMH_retrieveDocument */
  NULL,                              /* DOMH_getNodeWithID */
  /* optional entries - driven by sxpOptions */
  NULL,                              /* DOMH_freeBuffer */
  /* entries with userData acces */
  DOMHandlerGetNodeTypeStub,         /* DOMH_getNodeTypeExt */
  DOMHandlerGetNodeNameStub,         /* DOMH_getNodeNameExt */
  DOMHandlerGetNodeNameURIStub,      /* DOMH_getNodeNameURIExt */
  DOMHandlerGetNodeNameLocalStub,    /* DOMH_getNodeNameLocalExt */
  DOMHandlerGetNodeValueStub,        /* DOMH_getNodeValueExt */
  DOMHandlerGetNextSiblingStub,      /* DOMH_getNextSiblingExt */
  DOMHandlerGetPreviousSiblingStub,  /* DOMH_getPreviousSiblingExt */
  DOMHandlerGetNextAttrNSStub,       /* DOMH_getNextAttrNSExt */
  DOMHandlerGetPreviousAttrNSStub,   /* DOMH_getPreviousAttrNSExt */
  DOMHandlerGetChildCountStub,       /* DOMH_getChildCountExt */
  DOMHandlerGetAttributeCountStub,   /* DOMH_getAttributeCountExt */
  DOMHandlerGetNamespaceCountStub,   /* DOMH_getNamespaceCountExt */
  DOMHandlerGetChildNoStub,          /* DOMH_getChildNoExt */
  DOMHandlerGetAttributeNoStub,      /* DOMH_getAttributeNoExt */
  DOMHandlerGetNamespaceNoStub,      /* DOMH_getNamespaceNoExt */
  DOMHandlerGetParentStub,           /* DOMH_getParentExt */
  DOMHandlerGetOwnerDocumentStub,    /* DOMH_getOwnerDocumentExt */
  DOMHandlerCompareNodesStub,        /* DOMH_compareNodesExt */
  DOMHandlerRetrieveDocumentStub,    /* DOMH_retrieveDocumentExt */
  DOMHandlerGetNodeWithIDStub,       /* DOMH_getNodeWithIDExt */
  /*optional entries - driven by sxpOptions */
  DOMHandlerFreeBufferStub           /* DOMH_freeBufferExt */
};


/*************************************************************
 *
 *  stubs for all DOMHandler
 *
 * In functions returning other values than integers or chars,
 * it might be necessary to define some macros retrieving those
 * values from the SV.
 *
 *************************************************************/

static SXP_Node _SV2SXP_Node(SV * sv)
{
    SXP_Node ret = NULL;
#if SIT_DEBUG
    int retIsSv = 0;
#endif

    if (sv) { 
#if SIT_DEBUG
        fprintf(stderr, "Situation.h::_SV2SXP_Node: sv %p (%d) ",sv,SvREFCNT(sv));
#endif
        if (! SvROK(sv)) {
            ret = (SXP_Node) SvIV(sv);
#if SIT_DEBUG
            fprintf(stderr, "ret int=%p\n", ret);
#endif
        } else {
            ret = SvRV(sv);
#if SIT_DEBUG
            retIsSv = 1;
#endif
        }
        SvREFCNT_dec(sv);
#if SIT_DEBUG
        if( retIsSv )
            fprintf(stderr, "ret %p (%d)\n", ret, SvREFCNT((SV*)ret));
#endif
    }
#if SIT_DEBUG
    else
    {
        fprintf(stderr, "Situation.h::_SV2SXP_Node: sv=NULL\n");
    }
#endif
    return ret;
}

#define XPUSH_WRAPPER_AND_SIT( userData )                                     \
    do{                                                           \
       XPUSHs( *hv_fetch((HV*) (userData), "DOMHandler", 10, 0)  ); \
       XPUSHs( sv_2mortal(newRV_inc((SV*) (userData) )) );          \
    }while(0)
       

SXP_NodeType
DOMHandlerGetNodeTypeStub( SXP_Node node, void *userData ) 
{
  SV *node_obj;
  SXP_NodeType ret = (SXP_NodeType) SXP_NONE;

  node_obj = (SV*) node;

  {
    dSP;
    
    ENTER;
    SAVETMPS;

    PUSHMARK(SP);  
    XPUSH_WRAPPER_AND_SIT( userData );
    if (node_obj) 
      XPUSHs(sv_2mortal(newRV_inc(node_obj)));
    else
      XPUSHs(&PL_sv_undef);
    PUTBACK;

    perl_call_method("DHGetNodeType", G_SCALAR);

    SPAGAIN;
	
    ret = (SXP_NodeType) POPi;

    PUTBACK;
    FREETMPS;
    LEAVE;
  }

  return ret;
}

const SXP_char*
DOMHandlerGetNodeNameStub( SXP_Node node, void *userData ) 
{
  SV *node_obj;
  SV *retsv;

  SXP_char* ret = NULL;

  node_obj = (SV*) node;

  { 
    dSP;

    ENTER;
    SAVETMPS;

    PUSHMARK(SP); 
    XPUSH_WRAPPER_AND_SIT( userData );
    if (node_obj) 
      XPUSHs(sv_2mortal(newRV_inc(node_obj)));
    else
      XPUSHs(&PL_sv_undef);
    PUTBACK;

    perl_call_method("DHGetNodeName", G_SCALAR);

    SPAGAIN;

    /* ??? Do we keep the memory reserved for the string ??? */
    retsv = POPs; 
    if ( SvPOK(retsv) )
        ret = savepv( SvPV_nolen(retsv) );

    PUTBACK;
    FREETMPS;
    LEAVE;
  }
  
  return ret;
}

const SXP_char*
DOMHandlerGetNodeNameURIStub( SXP_Node node, void *userData ) 
{
  SV *node_obj;
  SV *retsv;

  SXP_char* ret = NULL;

  node_obj = (SV*) node;

  { 
    dSP;

    ENTER;
    SAVETMPS;

    PUSHMARK(SP);  
    XPUSH_WRAPPER_AND_SIT( userData );
    if (node_obj) 
      XPUSHs(sv_2mortal(newRV_inc(node_obj)));
    else
      XPUSHs(&PL_sv_undef);
    PUTBACK;

    perl_call_method("DHGetNodeNameURI", G_SCALAR);

    SPAGAIN;
	
    retsv = POPs; 
    if ( SvPOK(retsv) )
        ret = savepv( SvPV_nolen(retsv) );

    PUTBACK;
    FREETMPS;
    LEAVE;
  }
  
  return ret;
}

const SXP_char*
DOMHandlerGetNodeNameLocalStub( SXP_Node node, void *userData ) 
{
  SV *node_obj;
  SV *retsv;

  SXP_char* ret = NULL;

  node_obj = (SV*) node;

  { 
    dSP;

    ENTER;
    SAVETMPS;

    PUSHMARK(SP);  
    XPUSH_WRAPPER_AND_SIT( userData );
    if (node_obj) 
      XPUSHs(sv_2mortal(newRV_inc(node_obj)));
    else
      XPUSHs(&PL_sv_undef);
    PUTBACK;

    perl_call_method("DHGetNodeNameLocal", G_SCALAR);

    SPAGAIN;
	
    retsv = POPs; 
    if ( SvPOK(retsv) )
        ret = savepv( SvPV_nolen(retsv) );

    PUTBACK;
    FREETMPS;
    LEAVE;
  }
  
  return ret;
}

const SXP_char*
DOMHandlerGetNodeValueStub( SXP_Node node, void *userData ) 
{
  SV *node_obj;
  SV *retsv;

  SXP_char* ret = NULL;

  node_obj = (SV*) node;

  { 
    dSP;

    ENTER;
    SAVETMPS;

    PUSHMARK(SP);  
    XPUSH_WRAPPER_AND_SIT( userData );
    if (node_obj) 
      XPUSHs(sv_2mortal(newRV_inc(node_obj)));
    else
      XPUSHs(&PL_sv_undef);
    PUTBACK;

    perl_call_method("DHGetNodeValue", G_SCALAR);

    SPAGAIN;
	
    retsv = POPs; 
    if ( SvPOK(retsv) )
        ret = savepv( SvPV_nolen(retsv) );

    PUTBACK;
    FREETMPS;
    LEAVE;
  }
  
  return ret;
}

SXP_Node 
DOMHandlerGetNextSiblingStub( SXP_Node node, void *userData ) 
{
  SV *node_obj;
  SV *retsv;

  node_obj = (SV*) node;

  { 
    dSP;

    ENTER;
    SAVETMPS;

    PUSHMARK(SP);  
    XPUSH_WRAPPER_AND_SIT( userData );
    if (node_obj) 
      XPUSHs(sv_2mortal(newRV_inc(node_obj)));
    else
      XPUSHs(&PL_sv_undef);
    PUTBACK;

    perl_call_method("DHGetNextSibling", G_SCALAR);

    SPAGAIN;

    retsv = POPs;
    retsv = SvOK(retsv) ? SvREFCNT_inc(retsv) : NULL;

    PUTBACK;
    FREETMPS;
    LEAVE;
  }

  return _SV2SXP_Node( retsv );
}

SXP_Node 
DOMHandlerGetPreviousSiblingStub( SXP_Node node, void *userData ) 
{
  SV *node_obj;
  SV *retsv;

  node_obj = (SV*) node;

 { 
    dSP;

    ENTER;
    SAVETMPS;

    PUSHMARK(SP);  
    XPUSH_WRAPPER_AND_SIT( userData );
    if (node_obj) 
      XPUSHs(sv_2mortal(newRV_inc(node_obj)));
    else
      XPUSHs(&PL_sv_undef);
    PUTBACK;

    perl_call_method("DHGetPreviousSibling", G_SCALAR);
 
    SPAGAIN;
	
    retsv = POPs;
    retsv = SvOK(retsv) ? SvREFCNT_inc(retsv) : NULL;

    PUTBACK;
    FREETMPS;
    LEAVE;
  }

  return _SV2SXP_Node( retsv );
}

SXP_Node 
DOMHandlerGetNextAttrNSStub( SXP_Node node, void *userData ) 
{
  SV *node_obj;
  SV *retsv;
  
  node_obj = (SV*) node;

  { 
    dSP;

    ENTER;
    SAVETMPS;

    PUSHMARK(SP);  
    XPUSH_WRAPPER_AND_SIT( userData );
    if (node_obj) 
      XPUSHs(sv_2mortal(newRV_inc(node_obj)));
    else
      XPUSHs(&PL_sv_undef);
    PUTBACK;

     perl_call_method("DHGetNextAttrNS", G_SCALAR);

    SPAGAIN;
	
    retsv = POPs;
    retsv = SvOK(retsv) ? SvREFCNT_inc(retsv) : NULL;

    PUTBACK;
    FREETMPS;
    LEAVE;
  }

  return _SV2SXP_Node( retsv );
}

SXP_Node 
DOMHandlerGetPreviousAttrNSStub( SXP_Node node, void *userData ) 
{
  SV *node_obj;
  SV *retsv;

  node_obj = (SV*) node;

  { 
    dSP;

    ENTER;
    SAVETMPS;

    PUSHMARK(SP);  
    XPUSH_WRAPPER_AND_SIT( userData );
    if (node_obj) 
      XPUSHs(sv_2mortal(newRV_inc(node_obj)));
    else
      XPUSHs(&PL_sv_undef);
    PUTBACK;

    perl_call_method("DHGetPreviousAttrNS", G_SCALAR);
    
    SPAGAIN;
	
    retsv = POPs;
    retsv = SvOK(retsv) ? SvREFCNT_inc(retsv) : NULL;

    PUTBACK;
    FREETMPS;
    LEAVE;
  }

  return _SV2SXP_Node( retsv );
}

int 
DOMHandlerGetChildCountStub( SXP_Node node, void *userData ) 
{
  SV *node_obj;

  int ret = 0;

  node_obj = (SV*) node;

  { 
    dSP;

    ENTER;
    SAVETMPS;

    PUSHMARK(SP);  
    XPUSH_WRAPPER_AND_SIT( userData );
    if (node_obj) 
      XPUSHs(sv_2mortal(newRV_inc(node_obj)));
    else
      XPUSHs(&PL_sv_undef);
    PUTBACK;

    perl_call_method("DHGetChildCount", G_SCALAR);
 
    SPAGAIN;
	
    ret = POPi;

    PUTBACK;
    FREETMPS;
    LEAVE;
  }
  
  return ret;
}

int 
DOMHandlerGetAttributeCountStub( SXP_Node node, void *userData ) 
{
  SV *node_obj;

  int ret = 0;

  node_obj = (SV*) node;

  { 
    dSP;

    ENTER;
    SAVETMPS;

    PUSHMARK(SP);  
    XPUSH_WRAPPER_AND_SIT( userData );
    if (node_obj) 
      XPUSHs(sv_2mortal(newRV_inc(node_obj)));
    else
      XPUSHs(&PL_sv_undef);
    PUTBACK;

    perl_call_method("DHGetAttributeCount", G_SCALAR);

    SPAGAIN;
	
    ret = POPi;

    PUTBACK;
    FREETMPS;
    LEAVE;
  }
  
  return ret;
}

int 
DOMHandlerGetNamespaceCountStub( SXP_Node node, void *userData ) 
{
  SV *node_obj;

  int ret = 0;

  node_obj = (SV*) node;

  { 
    dSP;

    ENTER;
    SAVETMPS;

    PUSHMARK(SP);  
    XPUSH_WRAPPER_AND_SIT( userData );
    if (node_obj) 
      XPUSHs(sv_2mortal(newRV_inc(node_obj)));
    else
      XPUSHs(&PL_sv_undef);
    PUTBACK;

    perl_call_method("DHGetNamespaceCount", G_SCALAR);

    SPAGAIN;
	
    ret = POPi;

    PUTBACK;
    FREETMPS;
    LEAVE;
  }
  
  return ret;
}

SXP_Node 
DOMHandlerGetChildNoStub( SXP_Node node, int index, void *userData ) 
{
  SV *node_obj;
  SV *retsv;

  node_obj = (SV*) node;

  { 
    dSP;

    ENTER;
    SAVETMPS;

    PUSHMARK(SP);  
    XPUSH_WRAPPER_AND_SIT( userData );
    if (node_obj) 
      XPUSHs(sv_2mortal(newRV_inc(node_obj)));
    else
      XPUSHs(&PL_sv_undef);
    XPUSHs(sv_2mortal(newSViv(index)));
    PUTBACK;

    perl_call_method("DHGetChildNo", G_SCALAR);

    SPAGAIN;
	
    retsv = POPs;
    retsv = SvOK(retsv) ? SvREFCNT_inc(retsv) : NULL;

    PUTBACK;
    FREETMPS;
    LEAVE;
  }

  return _SV2SXP_Node( retsv );
}

SXP_Node 
DOMHandlerGetAttributeNoStub( SXP_Node node, int index, void *userData ) 
{
  SV *node_obj;
  SV *retsv;

  node_obj = (SV*) node;

  { 
    dSP;

    ENTER;
    SAVETMPS;

    PUSHMARK(SP);  
    XPUSH_WRAPPER_AND_SIT( userData );
    if (node_obj) 
      XPUSHs(sv_2mortal(newRV_inc(node_obj)));
    else
      XPUSHs(&PL_sv_undef);
    XPUSHs(sv_2mortal(newSViv(index)));
    PUTBACK;

    perl_call_method("DHGetAttributeNo", G_SCALAR);
 
    SPAGAIN;
	
    retsv = POPs;
    retsv = SvOK(retsv) ? SvREFCNT_inc(retsv) : NULL;

    PUTBACK;
    FREETMPS;
    LEAVE;
  }

  return _SV2SXP_Node( retsv );
}

SXP_Node 
DOMHandlerGetNamespaceNoStub( SXP_Node node, int index, void *userData ) 
{
  SV *node_obj;
  SV *retsv;

  node_obj = (SV*) node;

  { 
    dSP;

    ENTER;
    SAVETMPS;

    PUSHMARK(SP);  
    XPUSH_WRAPPER_AND_SIT( userData );
    if (node_obj) 
      XPUSHs(sv_2mortal(newRV_inc(node_obj)));
    else
      XPUSHs(&PL_sv_undef);
    XPUSHs(sv_2mortal(newSViv(index)));
    PUTBACK;

    perl_call_method("DHGetNamespaceNo", G_SCALAR);
 
    SPAGAIN;
	
    retsv = POPs;
    retsv = SvOK(retsv) ? SvREFCNT_inc(retsv) : NULL;

    PUTBACK;
    FREETMPS;
    LEAVE;
  }
  
  return _SV2SXP_Node( retsv );
}

SXP_Node 
DOMHandlerGetParentStub( SXP_Node node, void *userData ) 
{
  SV *node_obj;
  SV *retsv;

  node_obj = (SV*) node;

  { 
    dSP;

    ENTER;
    SAVETMPS;

    PUSHMARK(SP);  
    XPUSH_WRAPPER_AND_SIT( userData );
    if (node_obj) 
      XPUSHs(sv_2mortal(newRV_inc(node_obj)));
    else
      XPUSHs(&PL_sv_undef);
    PUTBACK;

    perl_call_method("DHGetParent", G_SCALAR);
 
    SPAGAIN;
	
    retsv = POPs;
    retsv = SvOK(retsv) ? SvREFCNT_inc(retsv) : NULL;

    PUTBACK;
    FREETMPS;
    LEAVE;
  }
  
  return _SV2SXP_Node( retsv );
}

SXP_Document 
DOMHandlerGetOwnerDocumentStub( SXP_Node node, void *userData ) 
{
  SV *node_obj;
  SV *retsv;

  node_obj = (SV*) node;

  { 
    dSP;

    ENTER;
    SAVETMPS;

    PUSHMARK(SP);  
    XPUSH_WRAPPER_AND_SIT( userData );
    if (node_obj) 
      XPUSHs(sv_2mortal(newRV_inc(node_obj)));
    else
      XPUSHs(&PL_sv_undef);
    PUTBACK;

    perl_call_method("DHGetOwnerDocument", G_SCALAR);

    SPAGAIN;
	
    retsv = POPs;
    retsv = SvOK(retsv) ? SvREFCNT_inc(retsv) : NULL;

    PUTBACK;
    FREETMPS;
    LEAVE;
  }
  
  return (SXP_Document)_SV2SXP_Node( retsv );
}

int 
DOMHandlerCompareNodesStub( SXP_Node node1, SXP_Node node2, void *userData ) 
{
  SV *node1_obj;
  SV *node2_obj;

  int ret = 0;

  node1_obj = (SV*) node1;
  node2_obj = (SV*) node2;

  { 
    dSP;

    ENTER;
    SAVETMPS;

    PUSHMARK(SP);  
    XPUSH_WRAPPER_AND_SIT( userData );
    if (node1_obj) 
      XPUSHs(sv_2mortal(newRV_inc(node1_obj)));
    else
      XPUSHs(&PL_sv_undef);
    if (node2_obj) 
      XPUSHs(sv_2mortal(newRV_inc(node2_obj)));
    else
      XPUSHs(&PL_sv_undef);
    PUTBACK;

    perl_call_method("DHCompareNodes", G_SCALAR);
    
    SPAGAIN;
	
    ret = POPi;

    PUTBACK;
    FREETMPS;
    LEAVE;
  }
  
  return ret;
}

SXP_Document 
DOMHandlerRetrieveDocumentStub( const SXP_char *uri, const SXP_char *baseUri, void *userData ) 
{
  SV *retsv;

  if (!baseUri) baseUri = "";

  { 
    dSP;

    ENTER;
    SAVETMPS;

    PUSHMARK(SP);  
    XPUSH_WRAPPER_AND_SIT( userData );
    /* !!! This can be a trap, if typedef of SXP_char changes !!! */
    XPUSHs(sv_2mortal(newSVpv(uri, strlen(uri))));
    XPUSHs(sv_2mortal(newSVpv(baseUri, strlen(baseUri))));
    PUTBACK;

    perl_call_method("DHRetrieveDocument", G_SCALAR);

    SPAGAIN;

    retsv = POPs;
    retsv = SvOK(retsv) ? SvREFCNT_inc(retsv) : NULL;

    PUTBACK;
    FREETMPS;
    LEAVE;
  }
  
  return (SXP_Document) _SV2SXP_Node( retsv );
}

SXP_Node
DOMHandlerGetNodeWithIDStub( SXP_Document doc, const SXP_char* id, void *userData ) 
{
  SV *doc_obj;
  SV *retsv;

  doc_obj  = (SV*) doc;

  { 
    dSP;

    ENTER;
    SAVETMPS;

    PUSHMARK(SP);  
    XPUSH_WRAPPER_AND_SIT( userData );
    if (doc_obj) 
      XPUSHs(sv_2mortal(newRV_inc(doc_obj)));
    else
      XPUSHs(&PL_sv_undef);
    /* !!! This can be a bad trap, if typedef of SXP_char changes !!! */
    XPUSHs(sv_2mortal(newSVpv(id, strlen(id))));
    PUTBACK;

      perl_call_method("DHGetNodeWithID", G_SCALAR);

    SPAGAIN;
	
    retsv = POPs;
    retsv = SvOK(retsv) ? SvREFCNT_inc(retsv) : NULL;

    PUTBACK;
    FREETMPS;
    LEAVE;
  }
  
  return _SV2SXP_Node( retsv );
}

void 
DOMHandlerFreeBufferStub( SXP_Node node, SXP_char *buff, void *userData )
{
  SV *node_obj;

  node_obj = (SV*) node;

  if(0) { 
    dSP;

    ENTER;
    SAVETMPS;

    PUSHMARK(SP);  
    XPUSH_WRAPPER_AND_SIT( userData );
    if (node_obj) 
      XPUSHs(sv_2mortal(newRV_inc(node_obj)));
    else
      XPUSHs(&PL_sv_undef);
    
    /* !!! This can be a trap, if typedef of SXP_char changes !!! */
    XPUSHs(sv_2mortal(newSVpv(buff, 0)));
    PUTBACK;

    perl_call_method("DHFreeBuffer", G_SCALAR);

    SPAGAIN;
	
    PUTBACK;
    FREETMPS;
    LEAVE;
  } else {
    Safefree( buff );
  }
}


#undef XPUSH_WRAPPER_AND_SIT
