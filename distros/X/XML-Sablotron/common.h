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
 * Contributor(s): Nicolas Trebst, science+computing ag
 *                 n.trebst@science-computing.de
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

#ifndef CommonHIncl
#define CommonHIncl

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

/* include declare macro via sxpath -> sablot() */
#include <sxpath.h>

/***********************************************************
 * useful macros
 ***********************************************************/

#define SIT_HANDLE(sit) (SablotSituation)SvIV(*hv_fetch((HV*)SvRV(sit), "_handle", 7, 0))
#define NODE_HANDLE(node) (NodeHandle)SvIV(*hv_fetch((HV*)SvRV(node), "_handle", 7, 0))

#define VALIDATE_RV(sv)  (! SvOK(sv) || (SvROK(sv) && \
                          (SvTYPE(SvRV(sv)) == SVt_PVCV)))

#define VALIDATE_HASHREF(object) (SvOK(object) && (SvROK(object)) && \
                       (SvTYPE(SvRV(object)) == SVt_PVHV))

#define GET_PROCESSOR(object) (void*)(SvIV(*hv_fetch((HV*)SvRV(object), \
                              "_handle", 7, 0)))

#define DOC_HANDLE(doc) (SDOM_Document)SvIV(*hv_fetch((HV*)SvRV(doc), \
                         "_handle", 7, 0))

/* classes */
/* must match to SDOM_NodeType */
#define CLASSNAMES \
{ \
    "",                            /* zero is not defined */ \
    "XML::Sablotron::DOM::Element",               /*  1 */ \
    "XML::Sablotron::DOM::Attribute",             /*  2 */ \
    "XML::Sablotron::DOM::Text",                  /*  3 */ \
    "XML::Sablotron::DOM::CDATASection",          /*  4 */ \
    "XML::Sablotron::DOM::EntityReference",       /*  5 */ \
    "XML::Sablotron::DOM::Entity",                /*  6 */ \
    "XML::Sablotron::DOM::ProcessingInstruction", /*  7 */ \
    "XML::Sablotron::DOM::Comment",               /*  8 */ \
    "XML::Sablotron::DOM::Document",              /*  9 */ \
    "XML::Sablotron::DOM::DocumentType",          /* 10 */ \
    "XML::Sablotron::DOM::DocumentFragment",      /* 11 */ \
    "XML::Sablotron::DOM::Notation",              /* 12 */ \
    "XML::Sablotron::SXP::Namespace"              /* 13 */ \
}

/* must match to SXP_ExpressionType */
#define EXPRESSIONTYPES \
{ \
    "XML::Sablotron::SXP::None",     \
    "XML::Sablotron::SXP::Number",   \
    "XML::Sablotron::SXP::String",   \
    "XML::Sablotron::SXP::Boolean",  \
    "XML::Sablotron::SXP::Nodeset"   \
}

/* keep sync with SDOM_Exception enumeration */
#define ERRORNAMES \
{ \
    "DOM_OK",                      /*  0 */ \
    "INDEX_SIZE_ERR",              /*  1 */ \
    "DOMSTRING_SIZE_ERR",          /*  2 */ \
    "HIERARCHY_REQUEST_ERR",       /*  3 */ \
    "WRONG_DOCUMENT_ERR",          /*  4 */ \
    "INVALID_CHARACTER_ERR",       /*  5 */ \
    "NO_DATA_ALLOWED_ERR",         /*  6 */ \
    "NO_MODIFICATION_ALLOWED_ERR", /*  7 */ \
    "NOT_FOUND_ERR",               /*  8 */ \
    "NOT_SUPPORTED_ERR",           /*  9 */ \
    "INUSE_ATTRIBUTE_ERR",         /* 10 */ \
    "INVALID_STATE_ERR",           /* 11 */ \
    "SYNTAX_ERR",                  /* 12 */ \
    "INVALID_MODIFICATION_ERR",    /* 13 */ \
    "NAMESPACE_ERR",               /* 14 */ \
    "INVALID_ACCESS_ERR",          /* 15 */ \
    /*non spec errors - continued*/         \
    "INVALID_NODE_TYPE_ERR",       /* 16 */ \
    "QUERY_PARSE_ERR",             /* 17 */ \
    "QUERY_EXECUTION_ERR",         /* 18 */ \
    "NOT_OK"                       /* 19 */ \
}

Declare
(
 void perl_report_err( const char * msg );
) 


#endif /* defined CommonHIncl */
