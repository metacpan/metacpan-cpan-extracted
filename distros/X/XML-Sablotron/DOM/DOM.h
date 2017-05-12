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

/************************************************************/
/* globals */
/************************************************************/

/* classes moved to common.h */
char *__classNames[] = CLASSNAMES;

/************************************************************/
/* error handling */
/************************************************************/

/* errorNames moved to common.h */
char* __errorNames[] = ERRORNAMES;

/* check function return value */
#define DE(sit, status) if (status) \
                      croak("XML::Sablotron::DOM(Code=%d, Name=%s, Msg=%s)", \
                            status, __errorNames[status], \
                            SDOM_getExceptionMessage(sit))

/* check the validity of the node */
#define CN(node) if (! node) croak("XML::Sablotron::DOM(Code=-1, Name='INVALID_NODE_ERR')")

/************************************************************/
/* globals for document */
/************************************************************/
#define DOC_HANDLE(doc) (SDOM_Document)SvIV(*hv_fetch((HV*)SvRV(doc), "_handle", 7, 0))

#define SIT_HANDLE(sit) (SablotSituation)SvIV(*hv_fetch((HV*)SvRV(sit), "_handle", 7, 0))

#define SIT_PARAM(cnt) ((items >= cnt) ? ST(cnt - 1) : &PL_sv_undef)

#define SIT_SMART(sit) (SvOK(sit) ? SIT_HANDLE(sit) : __sit)


bool __useUniqueDOMWrappers( void ) 
{
    SV* flag = get_sv( "XML::Sablotron::DOM::useUniqueWrappers", FALSE );
    return flag && SvTRUE(flag);
}

static SV* __createNodeOld(SablotSituation situa, SDOM_Node handle)
{
    HV* hash;
    SV* retval;
    SDOM_NodeType type;
    /* check and/or create inner SV* - used for validity checks*/
    SV* inner = (SV*)SDOM_getNodeInstanceData(handle);
    if (!inner) {
        /* printf("+++> creating new inner\n"); */
        inner = newSViv((IV)handle);
        /* store inner SV to node */
        SDOM_setNodeInstanceData(handle, inner);
    } else {
        /* printf("---> reusing the inner %d\n", SvIV(inner)); */
    }
    
    /* create new hash and store the handle into it */
    hash = newHV();
    hv_store(hash, "_handle", 7, SvREFCNT_inc(inner), 0);
    /* create blessed reference */
    retval = newRV_noinc((SV*)hash);
    DE( situa, SDOM_getNodeType(situa, handle, &type) );
    sv_bless(retval, gv_stashpv(__classNames[type], 0));

    return retval;
}


void __checkNodeInstanceData( SDOM_Node handle, HV * inner )
{
    if ( ! inner ) {
        croak("XML::Sablotron::DOM(Code=-1, Name='INVALID_NODE_ERR', Msg='InstanceData corrupted: NULL')");
    } else if ( SvTYPE( (SV*)inner ) != SVt_PVHV ) {
        croak("XML::Sablotron::DOM(Code=-1, Name='INVALID_NODE_ERR', Msg='InstanceData corrupted: not a HV')");
    } else {
        SV * ref = newRV_inc((SV*) inner);
        if ( ! ( sv_isobject( ref ) && sv_derived_from( ref , "XML::Sablotron::DOM::Node" ) ) ) {
            SvREFCNT_dec(ref);
            croak("XML::Sablotron::DOM(Code=-1, Name='INVALID_NODE_ERR', Msg='InstanceData corrupted: not a XML::Sablotron::DOM::Node");
        }  else if ( NODE_HANDLE( ref ) != handle ) {
            SvREFCNT_dec(ref);
            croak("XML::Sablotron::DOM(Code=-1, Name='INVALID_NODE_ERR', Msg='InstanceData corrupted: points to wrong node");
        }
        SvREFCNT_dec(ref);    
    }
}


static SV* __createNodeNew(SablotSituation situa, SDOM_Node handle)
{
    SV* retval;
    HV * hash;
    SDOM_NodeType type;
    /* we create only one wrapper object and one ref for each handle */
 
    /* is there already an wrapper ? */
    hash = (HV*)SDOM_getNodeInstanceData(handle);
    if ( hash ) {
        /* validity test */ 
        __checkNodeInstanceData( handle, hash );
        /* hash handle is ok. Return a new reference to it.  */
        retval = newRV_inc((SV*)hash);
#if 0
        fprintf(stderr,"DOM.h::__createNodeNew(%p): new rv %p reusing hv %p (%d)\n", 
                handle, retval, hash,(int)SvREFCNT((SV*)hash)); 
#endif
        return retval;
    }
    
    
    /* create new hash and store the handle into it */
    hash = newHV();
    hv_store(hash, "_handle", 7, newSViv( (IV) handle ), 0);
    SDOM_setNodeInstanceData(handle, hash);

    /* create blessed reference */
    retval = newRV_inc((SV*)hash);
    DE( situa, SDOM_getNodeType(situa, handle, &type) );
    retval = sv_bless(retval, gv_stashpv(__classNames[type], 0));
#if 0
    fprintf(stderr,"DOM.h::__createNodeNew(%p): new rv %p hash %p (%d)\n", 
            handle, retval, hash,(int)SvREFCNT((SV*)hash) );
#endif
    /* sv_dump( retval );
       sv_dump( (SV*) hash ); */
    return retval;
}

static SV* __createNode(SablotSituation situa, SDOM_Node handle)
{
    if ( __useUniqueDOMWrappers() ) {
        return __createNodeNew(situa, handle);
    }
    return __createNodeOld(situa, handle);
}


/************************************************************/
/* dispose calback */
/************************************************************/

static void __nodeDisposeCallbackOld(SDOM_Node node) 
{
    SV* pnode = (SV*)SDOM_getNodeInstanceData(node);
    if ( pnode ) sv_setiv(pnode, 0);
}

static void __nodeDisposeCallbackNew(SDOM_Node node) 
{
    HV * inner = (HV*)SDOM_getNodeInstanceData( node );
    if ( inner ) {
        __checkNodeInstanceData( node , inner );
        sv_setiv( *hv_fetch( inner, "_handle", 7, 0), 0 );
        SvREFCNT_dec( inner );
    }
}

void __nodeDisposeCallback(SDOM_Node node) 
{
    if ( __useUniqueDOMWrappers() )
        __nodeDisposeCallbackNew(node);
    else
        __nodeDisposeCallbackOld(node);
}

/*************************************************************/
/*  get implicit situation */
/*************************************************************/
SablotSituation __sit;
