/*
 *     Copyright (c) 2006 - 2007 Piers Harding.
 *         All rights reserved.
 *
 *         */

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>


/* SAP flag for Windows NT or 95 */
#ifdef _WIN32
#  ifndef SAPonNT
#    define SAPonNT
#  endif
#endif

#include <sapnwrfc.h>

#if defined(SAPonNT)
#include "windows.h"
#endif

#ifdef __cplusplus
extern "C" {
#endif
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#ifdef __cplusplus
}
#endif


/*
 * local prototypes & declarations
 */

/* fake up a definition of bool if it doesnt exist */
#ifndef bool
typedef SAP_RAW    bool;
#endif

/* create my true and false */
#ifndef false
typedef enum { false, true } mybool;
#endif


typedef struct SAPNW_CONN_INFO_rec {
    RFC_CONNECTION_HANDLE handle;
    RFC_CONNECTION_PARAMETER * loginParams;
    unsigned loginParamsLength;
} SAPNW_CONN_INFO;

typedef struct SAPNW_FUNC_DESC_rec {
    RFC_FUNCTION_DESC_HANDLE handle;
    SAPNW_CONN_INFO * conn_handle;
    char * name;
} SAPNW_FUNC_DESC;

typedef struct SAPNW_FUNC_rec {
    RFC_FUNCTION_HANDLE handle;
    SAPNW_FUNC_DESC * desc_handle;
} SAPNW_FUNC;

HV* hv_global_server_functions;


static SV* get_field_value(DATA_CONTAINER_HANDLE hcont, RFC_FIELD_DESC fieldDesc);
void set_field_value(DATA_CONTAINER_HANDLE hcont, RFC_FIELD_DESC fieldDesc, SV* sv_value);
SV * get_table_value(DATA_CONTAINER_HANDLE hcont, SAP_UC *name);
void set_table_value(DATA_CONTAINER_HANDLE hcont, SAP_UC *name, SV* sv_value);



#define ENTRIES( tab ) ( sizeofR(tab)/sizeofR((tab)[0]) )



/* create a parameter space and zero it */
static void * make_space(int len){

    char * ptr;
    ptr = malloc( len + 2 );
    if ( ptr == NULL ) {
        return NULL;
    }
    memset(ptr, 0, len + 2);
    return ptr;
}


/* copy the value of a parameter to a new pointer variable to be passed back onto the
   parameter pointer argument without the length supplied */
static void * make_strdup( SV* value ){

    char * ptr;
    int len;
    STRLEN slen;
    char *sptr;

    len = SvCUR(value);

    ptr = malloc( len + 1 );
    if ( ptr == NULL ) {
        return 0;
    }
    memset(ptr, 0, len + 1);
    sptr = SvPV(value, slen);
    memcpy((char *)ptr, sptr, len);
    return ptr;
}

// make mortal and return the pointer char *
char * sv_pv_2mortal(SV* sv) {
    return sv_pv(sv_2mortal(sv));
}


/*
 *     RFC_RC SAP_API RfcUTF8ToSAPUC(const RFC_BYTE *utf8, unsigned utf8Length,  SAP_UC *sapuc,  unsigned *sapucSize, unsigned *resultLength, RFC_ERROR_INFO *info);
 *
*/

SAP_UC * u8to16c(char * str) {
    RFC_RC rc;
    RFC_ERROR_INFO errorInfo;
    SAP_UC *sapuc;
    unsigned sapucSize, resultLength;

    sapucSize = strlen(str) + 1;
    sapuc = mallocU(sapucSize);
    memsetU(sapuc, 0, sapucSize);

    resultLength = 0;

    rc = RfcUTF8ToSAPUC((RFC_BYTE *)str, strlen(str), sapuc, &sapucSize, &resultLength, &errorInfo);
    return sapuc;
}


SAP_UC * u8to16(SV * str) {
    RFC_RC rc;
    RFC_ERROR_INFO errorInfo;
    SAP_UC *sapuc;
    unsigned sapucSize, resultLength;

    if (SvUTF8(str)) { // must put the indicator for utf8 back on
        SvUTF8_off(str);
        sapucSize = SvCUR(str) + 1;
        SvUTF8_on(str);
    }
    else {
        sapucSize = SvCUR(str) + 1;
    }
    sapuc = mallocU(sapucSize);
    memsetU(sapuc, 0, sapucSize);

    resultLength = 0;

    rc = RfcUTF8ToSAPUC((RFC_BYTE *)SvPV(str, SvCUR(str)), SvCUR(str), sapuc, &sapucSize, &resultLength, &errorInfo);
    return sapuc;
}


SV * u16to8c(SAP_UC * str, int len) {
    RFC_RC rc;
    RFC_ERROR_INFO errorInfo;
    unsigned utf8Size, resultLength;
    char * utf8;
    SV * perl_str;

    utf8Size = len * 4;
    utf8 = malloc(utf8Size + 2);
    memset(utf8, 0, utf8Size + 2);

    resultLength = 0;

    rc = RfcSAPUCToUTF8(str, len, (RFC_BYTE *)utf8, &utf8Size, &resultLength, &errorInfo);
    perl_str = newSVpv(utf8, resultLength);
    free(utf8);

    SvUTF8_on(perl_str);
    return perl_str;
}


/*
    RFC_RC SAP_API RfcSAPUCToUTF8(const SAP_UC *sapuc,  unsigned sapucLength, RFC_BYTE *utf8, unsigned *utf8Size,  unsigned *resultLength, RFC_ERROR_INFO *info);
*/
SV * u16to8(SAP_UC * str) {
    RFC_RC rc;
    RFC_ERROR_INFO errorInfo;
    unsigned utf8Size, resultLength;
    char * utf8;
    SV * perl_str;

    utf8Size = strlenU(str) * 4;
    utf8 = malloc(utf8Size + 2);
    memset(utf8, 0, utf8Size + 2);

    resultLength = 0;

    rc = RfcSAPUCToUTF8(str, strlenU(str), (RFC_BYTE *)utf8, &utf8Size, &resultLength, &errorInfo);
    perl_str = newSVpv(utf8, resultLength);
    free(utf8);
    SvUTF8_on(perl_str);
    return perl_str;
}


/* build a connection to an SAP system */
SV*  SAPNWRFC_connect(SV* sv_self){

    RFC_ERROR_INFO errorInfo;
    HV* h_self;
    HV* h_config;
    HE* h_entry;
    SV* sv_handle;
    SV* sv_config;
    SV* sv_key;
    SV* sv_value;
    SAPNW_CONN_INFO *hptr;
    RFC_CONNECTION_PARAMETER * loginParams;
    int idx, i;
    bool server;


    hptr = malloc(sizeof(SAPNW_CONN_INFO));
    hptr->handle = NULL;

    h_self =  (HV*)SvRV( sv_self );
    sv_config = *hv_fetch(h_self, (char *) "config", 6, FALSE);

    // must be a hash
    if (SvTYPE(SvRV(sv_config)) != SVt_PVHV) {
        croak("No connection parameters\n");
    }
    h_config =  (HV*)SvRV(sv_config);
    idx = hv_iterinit(h_config);

    if (idx == 0) {
        croak("No connection parameters\n");
    }

    loginParams = malloc(idx*sizeof(RFC_CONNECTION_PARAMETER));
    memset(loginParams, 0,idx*sizeof(RFC_CONNECTION_PARAMETER));

    server = false;
    for (i = 0; i < idx; i++) {
        h_entry = hv_iternext( h_config );
        sv_key = hv_iterkeysv( h_entry );
        sv_value = hv_iterval(h_config, h_entry);
        if (strcmp(sv_pv(sv_key), "tpname") == 0)
            server = true;
        loginParams[i].name = (SAP_UC *) u8to16(sv_key);
        loginParams[i].value = (SAP_UC *) u8to16(sv_value);
    }
    if (server) {
        hptr->handle = RfcRegisterServer(loginParams, idx, &errorInfo);
        hptr->loginParams = loginParams;
        hptr->loginParamsLength = idx;
    } else {
        hptr->handle = RfcOpenConnection(loginParams, idx, &errorInfo);
    };

    if (! server || hptr->handle == NULL) {
        for (i = 0; i < idx; i++) {
            free((char *) loginParams[i].name);
            free((char *) loginParams[i].value);
        }
        free(loginParams);
    }
    if (hptr->handle == NULL) {
        croak("RFC connection open failed: %d / %s / %s\n",
                                    errorInfo.code,
                                    sv_pv(u16to8(errorInfo.key)),
                                    sv_pv(u16to8(errorInfo.message)));
    }
    //fprintf(stderr, "Created conn_handle: %p - %p\n", hptr, hptr->handle);

    sv_handle = newSViv(PTR2IV(hptr));
    if (hv_exists(h_self, (char *) "handle", 6)) {
        hv_delete(h_self, (char *) "handle", 6, 0);
    }
    SvREFCNT_inc(sv_handle);
    if (hv_store_ent(h_self, sv_2mortal(newSVpv("handle", 0)), sv_handle, 0) == NULL) {
        SvREFCNT_dec(sv_handle);
    }
    return newSViv(1);
}

/* Disconnect from an SAP system */
SV*  SAPNWRFC_disconnect(SV* sv_self){

    RFC_ERROR_INFO errorInfo;
    RFC_RC rc = RFC_OK;
    SAPNW_CONN_INFO *hptr;
    HV* h_self;
    SV* sv_handle;

    h_self =  (HV*)SvRV( sv_self );
    if (hv_exists(h_self, (char *) "handle", 6)) {
        sv_handle = *hv_fetch(h_self, (char *) "handle", 6, FALSE);
        if (SvTRUE(sv_handle)) {
            hptr = INT2PTR(SAPNW_CONN_INFO *, SvIV(sv_handle));
            rc = RfcCloseConnection(hptr->handle, &errorInfo);
            hptr->handle = NULL;
            free(hptr);
            hv_delete(h_self, (char *) "handle", 6, 0);
            sv_2mortal(sv_handle);
            if (rc != RFC_OK) {
                croak("Problem closing RFC connection handle: %d / %s / %s\n",
                                                    errorInfo.code,
                                                    sv_pv(u16to8(errorInfo.key)),
                                                    sv_pv(u16to8(errorInfo.message)));
                return(newSV(0));
            } else {
                return newSViv(1);
            }
        } else {
            return newSViv(1);
        }
    } else {
        return newSViv(1);
    }
}


/* Get the attributes of a connection handle */
SV* SAPNWRFC_connection_attributes(SV* sv_self){

    SAPNW_CONN_INFO *hptr;
    RFC_ATTRIBUTES attribs;
    RFC_ERROR_INFO errorInfo;
    RFC_RC rc = RFC_OK;
    HV* h_self;
    SV* sv_handle;
    HV* hv_attrib;
    char * ptr;

    h_self =  (HV*)SvRV( sv_self );
    if (! hv_exists(h_self, (char *) "handle", 6)) {
        return(newSV(0));
    }
    sv_handle = *hv_fetch(h_self, (char *) "handle", 6, FALSE);
    if (! SvTRUE(sv_handle)) {
        return(newSV(0));
    }

    hptr = INT2PTR(SAPNW_CONN_INFO *, SvIV(sv_handle));

    rc = RfcGetConnectionAttributes(hptr->handle, &attribs, &errorInfo);

    /* bail on a bad return code */
    if (rc != RFC_OK) {
        croak("Problem getting connection attributes: %d / %s / %s\n",
                            errorInfo.code,
                            sv_pv(u16to8(errorInfo.key)),
                            sv_pv(u16to8(errorInfo.message)));
    }

    /* else return a hash of connection attributes */
    hv_attrib = newHV();
    hv_store_ent(hv_attrib, sv_2mortal(newSVpv("dest", 0)), u16to8(attribs.dest),0);
    hv_store_ent(hv_attrib, sv_2mortal(newSVpv("host", 0)), u16to8(attribs.host),0);
    hv_store_ent(hv_attrib, sv_2mortal(newSVpv("partnerHost", 0)), u16to8(attribs.partnerHost),0);
    hv_store_ent(hv_attrib, sv_2mortal(newSVpv("sysNumber", 0)), u16to8(attribs.sysNumber),0);
    hv_store_ent(hv_attrib, sv_2mortal(newSVpv("sysId", 0)), u16to8(attribs.sysId),0);
    hv_store_ent(hv_attrib, sv_2mortal(newSVpv("client", 0)), u16to8(attribs.client),0);
    hv_store_ent(hv_attrib, sv_2mortal(newSVpv("user", 0)), u16to8(attribs.user),0);
    hv_store_ent(hv_attrib, sv_2mortal(newSVpv("language", 0)), u16to8(attribs.language),0);
    hv_store_ent(hv_attrib, sv_2mortal(newSVpv("trace", 0)), u16to8(attribs.trace),0);
    hv_store_ent(hv_attrib, sv_2mortal(newSVpv("isoLanguage", 0)), u16to8(attribs.isoLanguage),0);
    hv_store_ent(hv_attrib, sv_2mortal(newSVpv("codepage", 0)), u16to8(attribs.codepage),0);
    hv_store_ent(hv_attrib, sv_2mortal(newSVpv("partnerCodepage", 0)), u16to8(attribs.partnerCodepage),0);
    hv_store_ent(hv_attrib, sv_2mortal(newSVpv("rfcRole", 0)), u16to8(attribs.rfcRole),0);
    hv_store_ent(hv_attrib, sv_2mortal(newSVpv("type", 0)), u16to8(attribs.type),0);
    hv_store_ent(hv_attrib, sv_2mortal(newSVpv("rel", 0)), u16to8(attribs.rel),0);
    hv_store_ent(hv_attrib, sv_2mortal(newSVpv("partnerType", 0)), u16to8(attribs.partnerType),0);
    hv_store_ent(hv_attrib, sv_2mortal(newSVpv("partnerRel", 0)), u16to8(attribs.partnerRel),0);
    hv_store_ent(hv_attrib, sv_2mortal(newSVpv("kernelRel", 0)), u16to8(attribs.kernelRel),0);
    hv_store_ent(hv_attrib, sv_2mortal(newSVpv("cpicConvId", 0)), u16to8(attribs.cpicConvId),0);
    hv_store_ent(hv_attrib, sv_2mortal(newSVpv("progName", 0)), u16to8(attribs.progName),0);

    return newRV_noinc((SV *) hv_attrib);
}


static void add_parameter_call (SV* sv_descriptor, SV* sv_parmName, SV* sv_direction, SV* sv_type, SV* sv_nucLength, SV* sv_ucLength, SV* sv_decimals) {

    dSP;
    // initial the argument stack
    ENTER;
    SAVETMPS;
    PUSHMARK(SP);

    XPUSHs(sv_descriptor);
    XPUSHs(sv_2mortal(sv_parmName));
    XPUSHs(sv_2mortal(sv_direction));
    XPUSHs(sv_2mortal(sv_type));
    XPUSHs(sv_2mortal(sv_nucLength));
    XPUSHs(sv_2mortal(sv_ucLength));
    XPUSHs(sv_2mortal(sv_decimals));

    PUTBACK;

    perl_call_pv("SAPNW::RFC::FunctionDescriptor::addParameter", G_EVAL | G_SCALAR );

    if(SvTRUE(ERRSV)) {
        croak("callback SAPNW::RFC::FunctionDescriptor::addParameter - failed: %s", SvPV(ERRSV, PL_na));
    }

    SPAGAIN;
    PUTBACK;
    FREETMPS;
    LEAVE;

    return;
}


SV* accept_global_callback (SV* sv_global_callback, SV* sv_attribs) {
    unsigned count;
    SV* sv_value;

    dSP;
    // initial the argument stack
    ENTER;
    SAVETMPS;
    PUSHMARK(SP);

    XPUSHs(sv_global_callback);
    XPUSHs(sv_2mortal(sv_attribs));

    PUTBACK;

    count = perl_call_pv("SAPNW::Connection::handler", G_EVAL | G_SCALAR );

    if(SvTRUE(ERRSV)) {
        croak("callback SAPNW::Connection::handler - failed: %s", SvPV(ERRSV,PL_na));
    }

    SPAGAIN;

    if (count != 1) {
        croak("Big problem in SAPNW::Connection::handler call\n");
    }
    sv_value = newSVsv(POPs);

    PUTBACK;
    FREETMPS;
    LEAVE;

    return sv_value;
}


/* Disconnect from an SAP system */
SV* SAPNWRFC_accept(SV* sv_self, SV* sv_wait, SV* sv_global_callback){

    RFC_RC rc = RFC_OK;
    RFC_ERROR_INFO errorInfo;
    SAPNW_CONN_INFO *hptr;
    SV* sv_result;
    HV* h_self;
    SV* sv_handle;

    h_self =  (HV*)SvRV( sv_self );
    if (! hv_exists(h_self, (char *) "handle", 6)) {
        return(newSV(0));
    }
    sv_handle = *hv_fetch(h_self, (char *) "handle", 6, FALSE);
    if (! SvTRUE(sv_handle)) {
        return(newSV(0));
    }

    hptr = INT2PTR(SAPNW_CONN_INFO *, SvIV(sv_handle));

    if(SvTYPE(sv_wait) != SVt_IV && SvTYPE(sv_wait) != SVt_PVIV) {
        croak("wait value for server.accept must be a FIXNUM type\n");
    }

    while(RFC_OK == rc || RFC_RETRY == rc || RFC_ABAP_EXCEPTION == rc){
        rc = RfcListenAndDispatch(hptr->handle, SvIV(sv_wait), &errorInfo);

        /* jump out of the accept loop on command */
        if (rc == RFC_CLOSED) {
            hv_delete(h_self, (char *) "handle", 6, 0);
            break;
        }

        switch (rc){
            case RFC_RETRY:    // This only notifies us, that no request came in within the timeout period.
                        // We just continue our loop.
                break;
            case RFC_NOT_FOUND:    // R/3 tried to invoke a function module, for which we did not supply
                            // an implementation. R/3 has been notified of this through a SYSTEM_FAILURE,
                            // so we need to refresh our connection.
            case RFC_ABAP_MESSAGE:        // And in this case a fresh connection is needed as well
                hptr->handle = RfcRegisterServer(hptr->loginParams, hptr->loginParamsLength, &errorInfo);
                rc = errorInfo.code;
                break;
            case RFC_ABAP_EXCEPTION:    // Our function module implementation has returned RFC_ABAP_EXCEPTION.
                            // This is equivalent to an ABAP function module throwing an ABAP Exception.
                            // The Exception has been returned to R/3 and our connection is still open.
                            // So we just loop around.
                break;
            case RFC_OK:
                break;
            default:
                fprintf(stderr, "This return code is not implemented (%d) - abort\n", rc);
                exit(1);
                break;
            }

            /* invoke the global callback */
            sv_result = accept_global_callback(sv_global_callback, SAPNWRFC_connection_attributes(sv_self));
            if (! SvTRUE(sv_result)) {
                /* the callback has asked for termination */
                break;
            }
    }
    return newSViv(1);
}


/* Disconnect from an SAP system */
SV* SAPNWRFC_process(SV* sv_self, SV* sv_wait){

    RFC_RC rc = RFC_OK;
    RFC_ERROR_INFO errorInfo;
    SAPNW_CONN_INFO *hptr;
    HV* h_self;
    SV* sv_handle;

    h_self =  (HV*)SvRV( sv_self );
    if (! hv_exists(h_self, (char *) "handle", 6)) {
        return(newSV(0));
    }
    sv_handle = *hv_fetch(h_self, (char *) "handle", 6, FALSE);
    if (! SvTRUE(sv_handle)) {
        return(newSV(0));
    }

    hptr = INT2PTR(SAPNW_CONN_INFO *, SvIV(sv_handle));


    if(SvTYPE(sv_wait) != SVt_IV && SvTYPE(sv_wait) != SVt_PVIV) {
        croak("wait value for server.process must be a FIXNUM type\n");
    }

    rc = RfcListenAndDispatch(hptr->handle, SvIV(sv_wait), &errorInfo);

    /* jump out of the accept loop on command */
    if (rc == RFC_CLOSED) {
        hv_delete(h_self, (char *) "handle", 6, 0);
        return newSViv(rc);
    }

    switch (rc){
        case RFC_RETRY:    // This only notifies us, that no request came in within the timeout period.
                // We just continue our loop.
            break;
        case RFC_NOT_FOUND:    // R/3 tried to invoke a function module, for which we did not supply
                    // an implementation. R/3 has been notified of this through a SYSTEM_FAILURE,
                    // so we need to refresh our connection.
        case RFC_ABAP_MESSAGE:        // And in this case a fresh connection is needed as well
            hptr->handle = RfcRegisterServer(hptr->loginParams, hptr->loginParamsLength, &errorInfo);
            //rc = errorInfo.code;
            break;
        case RFC_ABAP_EXCEPTION:    // Our function module implementation has returned RFC_ABAP_EXCEPTION.
                        // This is equivalent to an ABAP function module throwing an ABAP Exception.
                        // The Exception has been returned to R/3 and our connection is still open.
                        // So we just loop around.
            break;
        case RFC_OK:
            break;
        default:
            fprintf(stderr, "This return code is not implemented (%d) - abort\n", rc);
            exit(1);
            break;
    }

    return newSViv(rc);
}


/* allocate a new RFC_FIELD_DESC to be subsequently used in types, structures, and parameters */
RFC_FIELD_DESC * SAPNW_alloc_field(SAP_UC * name, RFCTYPE type, unsigned nucLength, unsigned nucOffset, unsigned ucLength, unsigned ucOffset, unsigned decimals, RFC_TYPE_DESC_HANDLE typeDescHandle, void* extendedDescription) {

    RFC_FIELD_DESC * fieldDesc;
    SAP_UC * useless_void;

    fieldDesc = malloc(sizeof(RFC_FIELD_DESC));
    memset(fieldDesc, 0,sizeof(RFC_FIELD_DESC));

    // set name space to 0
//    memsetU(fieldDesc->name, 0, (size_t)(strlenU(name)+1));
    useless_void = memcpyU(fieldDesc->name, name, (size_t)strlenU(name));
    fieldDesc->type = type;
    fieldDesc->nucLength = nucLength;
    fieldDesc->nucOffset = nucOffset;
    fieldDesc->ucLength = ucLength;
    fieldDesc->ucOffset = ucOffset;
    fieldDesc->decimals = decimals;
    fieldDesc->typeDescHandle = typeDescHandle;
    fieldDesc->extendedDescription = extendedDescription;

//    fprintfU(stderr, cU("field: %s type: %d nucL: %d nucO: %d ucL: %d ucO: %d dec: %d\n"),
//            fieldDesc->name, fieldDesc->type, fieldDesc->nucLength, fieldDesc->nucOffset,
//            fieldDesc->ucLength, fieldDesc->ucOffset, fieldDesc->decimals);
    return fieldDesc;
}


/* allocate a new RFC_PARAMETER-DESC to be subsequently used in an interface description */
RFC_TYPE_DESC_HANDLE SAPNW_alloc_type(SAP_UC * name) {

    RFC_TYPE_DESC_HANDLE typeDesc;
    RFC_ERROR_INFO errorInfo;

    typeDesc = RfcCreateTypeDesc(name, &errorInfo);

    /* bail on a bad return code */
    if (typeDesc == NULL) {
        croak("Problem RfcCreateTypeDesc (%s): %d / %s / %s\n",
                         sv_pv(u16to8(name)),
                         errorInfo.code,
                         sv_pv(u16to8(errorInfo.key)),
                         sv_pv(u16to8(errorInfo.message)));
    }

    return typeDesc;
}


/* allocate a new RFC_PARAMETER-DESC to be subsequently used in an interface description */
RFC_TYPE_DESC_HANDLE SAPNW_build_type(SV* sv_name, SV* sv_fields) {

    RFC_TYPE_DESC_HANDLE typeDesc;
    RFC_TYPE_DESC_HANDLE field_type_desc;
    SAP_UC * pname;
    SAP_UC * pfname;
    RFC_ERROR_INFO errorInfo;
    RFC_RC rc = RFC_OK;
    unsigned i, fidx, off, uoff;
    SV* sv_field;
    SV* sv_fname;
    SV* sv_ftype;
    SV* sv_flen;
    SV* sv_fulen;
    SV* sv_fdecimals;
    SV* sv_type_name;
    SV* sv_type_fields;
    SV* sv_ptypedef;
    RFC_ABAP_NAME abap_name;
    AV* av_fields;
    HV* hv_field;
    HV* hv_ptypedef;

    typeDesc = SAPNW_alloc_type((pname = u8to16(sv_name)));
    free(pname);
    RfcGetTypeName(typeDesc, abap_name, &errorInfo);

    off = 0;
    uoff = 0;

    av_fields =  (AV*)SvRV( sv_fields );
    if(SvTYPE(av_fields) != SVt_PVAV) {
        croak("fields in build_type not an ARRAY: %s\n", sv_pv(sv_name));
    }

    fidx = av_len(av_fields);
    for (i = 0; i <= fidx; i++) {
        sv_field = *av_fetch(av_fields, i, FALSE);
        hv_field =  (HV*)SvRV(sv_field);
        if(SvTYPE(hv_field) != SVt_PVHV) {
          croak("build_type (%s): not a HASH\n", sv_pv(sv_name));
        }

        sv_fname = *hv_fetch(hv_field, (char *) "name", 4, FALSE);
        sv_ftype = *hv_fetch(hv_field, (char *) "type", 4, FALSE);
        sv_flen = *hv_fetch(hv_field, (char *) "len", 3, FALSE);
        sv_fulen = *hv_fetch(hv_field, (char *) "ulen", 4, FALSE);
        sv_fdecimals = *hv_fetch(hv_field, (char *) "decimals", 8, FALSE);
        if (SvIV(sv_ftype) == RFCTYPE_STRUCTURE || SvIV(sv_ftype) == RFCTYPE_TABLE) {
          sv_ptypedef = *hv_fetch(hv_field, (char *) "typedef", 7, FALSE);
          if (! SvTRUE(sv_ptypedef)) {
              fprintf(stderr, "Field does not have typedef - %s\n", sv_pv(sv_fname));
              exit(1);
          }

          hv_ptypedef =  (HV*)SvRV( sv_ptypedef );
          if (! hv_exists(hv_ptypedef, (char *) "fields", 6))
             croak("typedef does not have fields: %s\n", sv_pv(sv_fname));
          sv_type_name = *hv_fetch(hv_ptypedef, (char *) "name", 4, FALSE);
          sv_type_fields = *hv_fetch(hv_ptypedef, (char *) "fields", 6, FALSE);
          if (! SvTRUE(sv_type_fields)) {
              fprintf(stderr, "Field (%s) does not have @fields - %s\n", sv_pv(sv_fname), sv_pv(sv_type_name));
                exit(1);
          }
          field_type_desc = SAPNW_build_type(sv_type_name, sv_type_fields);
          rc = RfcAddTypeField(typeDesc, SAPNW_alloc_field((pfname = u8to16(sv_fname)),
                               SvIV(sv_ftype), SvIV(sv_flen), off, SvIV(sv_fulen),
                               uoff, SvIV(sv_fdecimals), field_type_desc, NULL), &errorInfo);
        } else {
          rc = RfcAddTypeField(typeDesc, SAPNW_alloc_field((pfname = u8to16(sv_fname)),
                               SvIV(sv_ftype), SvIV(sv_flen), off, SvIV(sv_fulen),
                               uoff, SvIV(sv_fdecimals), NULL, NULL), &errorInfo);
        }
        free(pfname);
        if (rc != RFC_OK) {
            croak("Problem RfcAddTypefield (%s): %d / %s / %s\n",
                             sv_pv(sv_name),
                             errorInfo.code,
                             sv_pv(u16to8(errorInfo.key)),
                             sv_pv(u16to8(errorInfo.message)));
        }
        off += SvIV(sv_flen);
        uoff += SvIV(sv_fulen);
    }

    rc = RfcSetTypeLength(typeDesc, off, uoff, &errorInfo);
    if (rc != RFC_OK) {
        croak("Problem RfcSetTypeLength (%s): %d / %s / %s\n",
                                    sv_pv(sv_name),
                                    errorInfo.code,
                                    sv_pv(u16to8(errorInfo.key)),
                                    sv_pv(u16to8(errorInfo.message)));
    }
    return typeDesc;
}


/* allocate a new RFC_PARAMETER-DESC to be subsequently used in an interface description */
RFC_PARAMETER_DESC * SAPNW_alloc_parameter(SAP_UC * name, RFCTYPE type, RFC_DIRECTION direction, unsigned nucLength, unsigned ucLength, unsigned decimals, RFC_TYPE_DESC_HANDLE typeDescHandle, void* extendedDescription) {

    RFC_PARAMETER_DESC * parameterDesc;
    SAP_UC * useless_void;

    parameterDesc = malloc(sizeof(RFC_PARAMETER_DESC));
    memset(parameterDesc, 0,sizeof(RFC_PARAMETER_DESC));

    // set name space to 0
//    memsetU(parameterDesc->name, 0, (size_t)(strlenU(name)+1));
    useless_void = memcpyU(parameterDesc->name, name, (size_t)strlenU(name));
    parameterDesc->type = type;
    parameterDesc->direction = direction;
    parameterDesc->nucLength = nucLength;
    parameterDesc->ucLength = ucLength;
    parameterDesc->decimals = decimals;
    parameterDesc->typeDescHandle = typeDescHandle;
    parameterDesc->extendedDescription = extendedDescription;

    return parameterDesc;
}


/* Create a Function Module handle to be used for an RFC call */
SV* SAPNWRFC_add_parameter(SV* sv_self, SV* sv_parameter){

    SAPNW_FUNC_DESC *dptr;
    RFC_RC rc = RFC_OK;
    RFC_ERROR_INFO errorInfo;
    SV* sv_name;
    SV* sv_type;
    SV* sv_direction;
    SV* sv_nucLength;
    SV* sv_ucLength;
    SV* sv_decimals;
    SV* sv_fields;
    SV* sv_ptypedef;
    SV* sv_type_name;
    SAP_UC * pname;
    RFC_PARAMETER_DESC * parm_desc;
    RFC_TYPE_DESC_HANDLE type_desc;
    HV* h_self;
    HV* hv_parameter;
    HV* hv_ptypedef;
    SV* sv_func_def;

    h_self =  (HV*)SvRV( sv_self );
    if (hv_exists(h_self, (char *) "funcdef", 7)) {
        sv_func_def = *hv_fetch(h_self, (char *) "funcdef", 7, FALSE);
        if (SvTRUE(sv_func_def)) {
            dptr = INT2PTR(SAPNW_FUNC_DESC *, SvIV(sv_func_def));
        } else {
            croak("Corrupt function descriptor pointer in add_parameter\n");
        }
    } else {
        croak("Non-existent function descriptor pointer in add_parameter\n");
    }

    /* register parameter definition */
    hv_parameter =  (HV*)SvRV(sv_parameter);
    if(SvTYPE(hv_parameter) != SVt_PVHV) {
        croak("sv_parameter in add_parameter: not a HASH\n");
    }
    sv_name = *hv_fetch(hv_parameter, (char *) "name", 4, FALSE);
    sv_type = *hv_fetch(hv_parameter, (char *) "type", 4, FALSE);
    sv_direction = *hv_fetch(hv_parameter, (char *) "direction", 9, FALSE);
    sv_nucLength = *hv_fetch(hv_parameter, (char *) "len", 3, FALSE);
    sv_ucLength = *hv_fetch(hv_parameter, (char *) "ulen", 4, FALSE);
    sv_decimals = *hv_fetch(hv_parameter, (char *) "decimals", 8, FALSE);
    if (SvIV(sv_type) == RFCTYPE_STRUCTURE || SvIV(sv_type) == RFCTYPE_TABLE) {
        sv_ptypedef = *hv_fetch(hv_parameter, (char *) "typedef", 7, FALSE);
        hv_ptypedef =  (HV*)SvRV(sv_ptypedef);
        if(SvTYPE(hv_ptypedef) != SVt_PVHV) {
            croak("sv_ptypedef in add_parameter: not a HASH\n");
        }
        sv_type_name = *hv_fetch(hv_ptypedef, (char *) "name", 4, FALSE);
        sv_fields = *hv_fetch(hv_ptypedef, (char *) "fields", 6, FALSE);
        type_desc = SAPNW_build_type(sv_type_name, sv_fields);

        parm_desc = SAPNW_alloc_parameter((pname = u8to16(sv_name)), SvIV(sv_type), SvIV(sv_direction), 0, 0, 0, type_desc, NULL);
    } else {
        parm_desc = SAPNW_alloc_parameter((pname = u8to16(sv_name)), SvIV(sv_type), SvIV(sv_direction), SvIV(sv_nucLength), SvIV(sv_ucLength), SvIV(sv_decimals), NULL, NULL);
    }
    free(pname);
    rc = RfcAddParameter(dptr->handle, parm_desc, &errorInfo);
    if (rc != RFC_OK) {
      croak("Problem with RfcAddParameter (%s): %d / %s / %s\n",
                                    sv_pv(sv_name),
                                    errorInfo.code,
                                    sv_pv(u16to8(errorInfo.key)),
                                    sv_pv(u16to8(errorInfo.message)));
    }

    SvREFCNT_inc(sv_parameter);
    return sv_parameter;
}


/* Get the Metadata description of a Function Module */
SV * SAPNWRFC_create_function_descriptor(SV * sv_func){

    SAPNW_FUNC_DESC *dptr;
    RFC_RC rc = RFC_OK;
    RFC_ERROR_INFO errorInfo;
    SV * sv_function_def;
    SV * sv_descriptor;
    HV* h_func_def;
    HV* h_parameters;
    SAP_UC * fname;
    RFC_FUNCTION_DESC_HANDLE func_desc_handle;
    RFC_ABAP_NAME func_name;

    func_desc_handle = RfcCreateFunctionDesc((fname = u8to16(sv_func)), &errorInfo);
    free((char *)fname);

    /* bail on a bad lookup */
    if (func_desc_handle == NULL) {
      croak("Problem with RfcCreateFunctionDesc (%s): %d / %s / %s\n",
                                        sv_pv(sv_func),
                                        errorInfo.code,
                                        sv_pv(u16to8(errorInfo.key)),
                                        sv_pv(u16to8(errorInfo.message)));
    }

    dptr = malloc(sizeof(SAPNW_FUNC_DESC));
    dptr->handle = func_desc_handle;
    dptr->conn_handle = NULL;
    dptr->name = make_strdup(sv_func);
    sv_function_def = newSViv(PTR2IV(dptr));

  /* read back the function name */
    rc = RfcGetFunctionName(dptr->handle, func_name, &errorInfo);

  /* bail on a bad RfcGetFunctionName */
    if (rc != RFC_OK) {
        croak("(FunctionDescriptor create)Problem in RfcGetFunctionName (%s): %d / %s / %s\n",
                                        sv_pv(sv_func),
                                        errorInfo.code,
                                        sv_pv(u16to8(errorInfo.key)),
                                        sv_pv(u16to8(errorInfo.message)));
    }

    h_func_def = newHV();
    hv_store_ent(h_func_def, sv_2mortal(newSVpv("funcdef", 0)), SvREFCNT_inc(sv_function_def), 0);
//    hv_store_ent(h_func_def, sv_2mortal(newSVpv("funcdef", 0)), sv_function_def, 0);
    hv_store_ent(h_func_def, sv_2mortal(newSVpv("name", 0)), u16to8(func_name), 0);
    h_parameters = newHV();
    hv_store_ent(h_func_def, sv_2mortal(newSVpv("parameters", 0)),  newRV_noinc((SV*) h_parameters), 0);
    sv_descriptor = sv_bless(newRV_noinc((SV *) h_func_def), gv_stashpv("SAPNW::RFC::FunctionDescriptor", 0));

    return sv_descriptor;
}


/* Get the Metadata description of a Function Module */
SV * SAPNWRFC_function_lookup(SV * sv_self, SV * sv_func){

    SAPNW_CONN_INFO *hptr;
    SAPNW_FUNC_DESC *dptr;
    RFC_RC rc = RFC_OK;
    RFC_ERROR_INFO errorInfo;
    SV * sv_function_def;
    SV * sv_parm_name;
    SV * sv_descriptor;
    HV* h_self;
    HV* h_func_def;
    HV* h_parameters;
    SV* sv_handle;
    SAP_UC * fname;
    RFC_FUNCTION_DESC_HANDLE func_desc_handle;
    RFC_ABAP_NAME func_name;
    RFC_PARAMETER_DESC parm_desc;
    unsigned parm_count;
    int i;

    h_self =  (HV*)SvRV( sv_self );
    if (hv_exists(h_self, (char *) "handle", 6)) {
    sv_handle = *hv_fetch(h_self, (char *) "handle", 6, FALSE);
      if (SvTRUE(sv_handle)) {
        hptr = INT2PTR(SAPNW_CONN_INFO *, SvIV(sv_handle));
      } else {
        croak("Corrupt connection handle in function_lookup\n");
        }
    } else {
      croak("Non-existent connection handle in function_lookup\n");
    }

    func_desc_handle = RfcGetFunctionDesc(hptr->handle, fname = u8to16(sv_func), &errorInfo);
    free((char *)fname);

    /* bail on a bad lookup */
    if (func_desc_handle == NULL) {
        croak("Problem looking up RFC (%s): %d / %s / %s\n",
                                    sv_pv(sv_func),
                                    errorInfo.code,
                                    sv_pv(u16to8(errorInfo.key)),
                                    sv_pv(u16to8(errorInfo.message)));
    }

    dptr = malloc(sizeof(SAPNW_FUNC_DESC));
    dptr->handle = func_desc_handle;
    dptr->conn_handle = hptr;
    dptr->name = make_strdup(sv_func);
    sv_function_def = newSViv(PTR2IV(dptr));

    /* read back the function name */
    rc = RfcGetFunctionName(dptr->handle, func_name, &errorInfo);

    /* bail on a bad RfcGetFunctionName */
    if (rc != RFC_OK) {
      croak("Problem in RfcGetFunctionName (%s): %d / %s / %s\n",
                                        sv_pv(sv_func),
                                        errorInfo.code,
                                        sv_pv(u16to8(errorInfo.key)),
                                        sv_pv(u16to8(errorInfo.message)));
    }

    h_func_def = newHV();
    // XXX remove ref counter inc
//    SvREFCNT_inc(sv_function_def);
    hv_store_ent(h_func_def, sv_2mortal(newSVpv("funcdef", 0)), sv_function_def, 0);
    hv_store_ent(h_func_def, sv_2mortal(newSVpv("name", 0)), u16to8(func_name), 0);

    /* Get the parameter details */
    rc = RfcGetParameterCount(dptr->handle, &parm_count, &errorInfo);

    /* bail on a bad RfcGetParameterCount */
    if (rc != RFC_OK) {
      croak("Problem in RfcGetParameterCount (%s): %d / %s / %s\n",
                                            sv_pv(sv_func),
                                            errorInfo.code,
                                            sv_pv(u16to8(errorInfo.key)),
                                            sv_pv(u16to8(errorInfo.message)));
    }

    h_parameters = newHV();
    hv_store_ent(h_func_def, sv_2mortal(newSVpv("parameters", 0)),  newRV_noinc((SV*) h_parameters), 0);

    sv_descriptor = sv_bless(newRV_noinc((SV *) h_func_def),
                             gv_stashpv("SAPNW::RFC::FunctionDescriptor", 0));

    for (i = 0; i < parm_count; i++) {
        rc = RfcGetParameterDescByIndex(dptr->handle, i, &parm_desc, &errorInfo);
        /* bail on a bad RfcGetParameterDescByIndex */
        if (rc != RFC_OK) {
            croak("Problem in RfcGetParameterDescByIndex (%s): %d / %s / %s\n",
                                                        sv_pv(sv_func),
                                                        errorInfo.code,
                                                        sv_pv(u16to8(errorInfo.key)),
                                                        sv_pv(u16to8(errorInfo.message)));
        }

        /* create a new parameter obj */
//        fprintfU(stderr, cU("Parameter (%d): %s - direction: (%d) - type(%d)\n"), i, parm_desc.name, parm_desc.direction, parm_desc.type);
        sv_parm_name = u16to8(parm_desc.name);

        add_parameter_call(sv_descriptor, sv_parm_name, newSViv(parm_desc.direction),
                           newSViv(parm_desc.type), newSViv(parm_desc.nucLength),
                           newSViv(parm_desc.ucLength), newSViv(parm_desc.decimals));
    }

    return sv_descriptor;
}


SV * SAPNWRFC_destroy_function_descriptor(SV* sv_self){

    SAPNW_FUNC_DESC *dptr;
    RFC_ERROR_INFO errorInfo;
    RFC_RC rc = RFC_OK;
    HV* h_self;
    SV* sv_func_def;

    h_self =  (HV*)SvRV( sv_self );
    if (hv_exists(h_self, (char *) "funcdef", 7)) {
        sv_func_def = *hv_fetch(h_self, (char *) "funcdef", 7, FALSE);
        if (SvTRUE(sv_func_def)) {
            dptr = INT2PTR(SAPNW_FUNC_DESC *, SvIV(sv_func_def));
        } else {
            croak("Corrupt function descriptor pointer in destroy_function_descriptor\n");
        }
    } else {
        croak("Non-existent function descriptor pointer in destroy_function_descriptor\n");
    }

    rc = RfcDestroyFunctionDesc(dptr->handle, &errorInfo);
    dptr->handle = NULL;
    /*
  if (rc != RFC_OK) {
      fprintf(stderr, "Problem in RfcDestroyFunctonDesc: %d \n", rc);
      fprintfU(stderr, cU("Problem in RfcDestroyFunctonDesc : %d / %s / %s\n"),
                         errorInfo.code,
                                             errorInfo.key,
                                              errorInfo.message);
      fprintf(stderr, "Problem in RfcDestroyFunctonDesc (%s)\n",
                           dptr->name);
      croak("Problem in RfcDestroyFunctonDesc (%s): %d / %s / %s\n",
                           dptr->name,
                         errorInfo.code,
                                             sv_pv(u16to8(errorInfo.key)),
                                              sv_pv(u16to8(errorInfo.message)));
    }
    */
    dptr->handle = NULL;
    dptr->conn_handle = NULL;
    free(dptr->name);
    free(dptr);
    return newSViv(1);
}


static void init_function_call (SV* sv_self, SV* sv_func_desc) {

    dSP;
    // initial the argument stack
    ENTER;
    SAVETMPS;
    PUSHMARK(SP);
    XPUSHs(sv_self);
    XPUSHs(sv_func_desc);
    PUTBACK;

    perl_call_pv("SAPNW::RFC::FunctionCall::initialise", G_EVAL | G_SCALAR );

    if(SvTRUE(ERRSV)) {
        croak("callback SAPNW::RFC::FunctionDescriptor::initialise - failed: %s", SvPV(ERRSV,PL_na));
    }

    SPAGAIN;
    PUTBACK;
    FREETMPS;
    LEAVE;

    return;
}


/* Create a Function Module handle to be used for an RFC call */
SV * SAPNWRFC_create_function_call(SV* sv_func_desc){

    SAPNW_FUNC_DESC *dptr;
    SAPNW_FUNC *fptr;
    RFC_ERROR_INFO errorInfo;
    RFC_FUNCTION_HANDLE func_handle;
    SV* sv_func_def;
    SV* sv_function;
    SV* sv_func_call;
    HV* h_self;
    HV* h_func_call;

    h_self =  (HV*)SvRV( sv_func_desc );
    if (hv_exists(h_self, (char *) "funcdef", 7)) {
        sv_func_def = *hv_fetch(h_self, (char *) "funcdef", 7, FALSE);
        if (SvTRUE(sv_func_def)) {
            dptr = INT2PTR(SAPNW_FUNC_DESC *, SvIV(sv_func_def));
        } else {
            croak("Corrupt function descriptor pointer in create_function_call\n");
        }
    } else {
        croak("Non-existent function descriptor pointer in create_function_call\n");
    }

    func_handle = RfcCreateFunction(dptr->handle, &errorInfo);

    /* bail on a bad lookup */
    if (func_handle == NULL) {
        croak("Problem creating Function Data Container RFC (%s): %d / %s / %s\n",
                                            dptr->name,
                                            errorInfo.code,
                                            sv_pv(u16to8(errorInfo.key)),
                                            sv_pv(u16to8(errorInfo.message)));
    }

    /* wrap in SAPNW::RFC::FunctionCall  Object */
    fptr = malloc(sizeof(SAPNW_FUNC));
    fptr->handle = func_handle;
    fptr->desc_handle = dptr;
    sv_function = newSViv(PTR2IV(fptr));
    h_func_call = newHV();
    SvREFCNT_inc(sv_function);
    hv_store_ent(h_func_call, sv_2mortal(newSVpv("funccall", 0)), sv_function, 0);
    hv_store_ent(h_func_call, sv_2mortal(newSVpv("name", 0)), newSVpv(dptr->name, 0), 0);
    sv_func_call = sv_bless(newRV_noinc((SV *) h_func_call),
                             gv_stashpv("SAPNW::RFC::FunctionCall", 0));
    init_function_call(sv_func_call, sv_func_desc);
    return sv_func_call;
}


SV * SAPNWRFC_destroy_function_call(SV* sv_self){

    SAPNW_FUNC *fptr;
    RFC_ERROR_INFO errorInfo;
    RFC_RC rc = RFC_OK;
    HV* h_self;
    SV* sv_function;
    SV* sv_name;

    h_self =  (HV*)SvRV( sv_self );
    if (hv_exists(h_self, (char *) "funccall", 8)) {
        sv_function = *hv_fetch(h_self, (char *) "funccall", 8, FALSE);
        if (SvTRUE(sv_function)) {
            fptr = INT2PTR(SAPNW_FUNC *, SvIV(sv_function));
        } else {
            return newSViv(1);
            // this can happen from the rfc server call - no func call handed in
        }
    } else {
        return newSViv(1);
        // this can happen from the rfc server call - no func call handed in
    }

    rc = RfcDestroyFunction(fptr->handle, &errorInfo);
    fptr->handle = NULL;
    sv_2mortal(sv_function);
    if (rc != RFC_OK) {
        croak("Problem in RfcDestroyFuncton (%s): %d / %s / %s\n",
                                            fptr->desc_handle->name,
                                            errorInfo.code,
                                            sv_pv(u16to8(errorInfo.key)),
                                            sv_pv(u16to8(errorInfo.message)));
    }

    fptr->desc_handle = NULL;
    free(fptr);
    return newSViv(1);
}


SV * get_time_value(DATA_CONTAINER_HANDLE hcont, SAP_UC *name){

    RFC_RC rc = RFC_OK;
    RFC_ERROR_INFO errorInfo;
    RFC_TIME timeBuff;
    SV* sv_val;

    rc = RfcGetTime(hcont, name, timeBuff, &errorInfo);
    if (rc != RFC_OK) {
      croak("Problem with RfcGetTime (%s): %d / %s / %s\n",
                                    sv_pv(u16to8(name)),
                                    errorInfo.code,
                                    sv_pv(u16to8(errorInfo.key)),
                                    sv_pv(u16to8(errorInfo.message)));
    }
    sv_val = u16to8c(timeBuff, 6);
    return sv_val;
}


SV * get_date_value(DATA_CONTAINER_HANDLE hcont, SAP_UC *name){

    RFC_RC rc = RFC_OK;
    RFC_ERROR_INFO errorInfo;
    RFC_DATE dateBuff;
    SV* sv_val;

    rc = RfcGetDate(hcont, name, dateBuff, &errorInfo);
    if (rc != RFC_OK) {
        croak("Problem with RfcGetDate (%s): %d / %s / %s\n",
                                    sv_pv(u16to8(name)),
                                    errorInfo.code,
                                    sv_pv(u16to8(errorInfo.key)),
                                    sv_pv(u16to8(errorInfo.message)));
    }
    sv_val = u16to8c(dateBuff, 8);
    return sv_val;
}


SV * get_int_value(DATA_CONTAINER_HANDLE hcont, SAP_UC *name){

    RFC_RC rc = RFC_OK;
    RFC_ERROR_INFO errorInfo;
    RFC_INT rfc_int;

    rc = RfcGetInt(hcont, name, &rfc_int, &errorInfo);
    if (rc != RFC_OK) {
        croak("Problem with RfcGetInt (%s): %d / %s / %s\n",
                                    sv_pv(u16to8(name)),
                                    errorInfo.code,
                                    sv_pv(u16to8(errorInfo.key)),
                                    sv_pv(u16to8(errorInfo.message)));
    }
    return newSViv((int) rfc_int);
}


SV * get_int1_value(DATA_CONTAINER_HANDLE hcont, SAP_UC *name){

    RFC_RC rc = RFC_OK;
    RFC_ERROR_INFO errorInfo;
    RFC_INT1 rfc_int1;

    rc = RfcGetInt1(hcont, name, &rfc_int1, &errorInfo);
    if (rc != RFC_OK) {
        croak("Problem with RfcGetInt1 (%s): %d / %s / %s\n",
                                    sv_pv(u16to8(name)),
                                    errorInfo.code,
                                    sv_pv(u16to8(errorInfo.key)),
                                    sv_pv(u16to8(errorInfo.message)));
    }
    return newSViv((int) rfc_int1);
}


SV * get_int2_value(DATA_CONTAINER_HANDLE hcont, SAP_UC *name){

    RFC_RC rc = RFC_OK;
    RFC_ERROR_INFO errorInfo;
    RFC_INT2 rfc_int2;

    rc = RfcGetInt2(hcont, name, &rfc_int2, &errorInfo);
    if (rc != RFC_OK) {
        croak("Problem with RfcGetInt2 (%s): %d / %s / %s\n",
                                    sv_pv(u16to8(name)),
                                    errorInfo.code,
                                    sv_pv(u16to8(errorInfo.key)),
                                    sv_pv(u16to8(errorInfo.message)));
    }
    return newSViv((int) rfc_int2);
}


SV * get_float_value(DATA_CONTAINER_HANDLE hcont, SAP_UC *name){

    RFC_RC rc = RFC_OK;
    RFC_ERROR_INFO errorInfo;
    RFC_FLOAT rfc_float;

    rc = RfcGetFloat(hcont, name, &rfc_float, &errorInfo);
    if (rc != RFC_OK) {
        croak("Problem with RfcGetFloat (%s): %d / %s / %s\n",
                                    sv_pv(u16to8(name)),
                                    errorInfo.code,
                                    sv_pv(u16to8(errorInfo.key)),
                                    sv_pv(u16to8(errorInfo.message)));
    }
    return newSVnv((double) rfc_float);
}


SV * get_string_value(DATA_CONTAINER_HANDLE hcont, SAP_UC *name){

    RFC_RC rc = RFC_OK;
    RFC_ERROR_INFO errorInfo;
    SV* sv_val;
    unsigned strLen, retStrLen;
    char * buffer;

    rc = RfcGetStringLength(hcont, name, &strLen, &errorInfo);
    if (rc != RFC_OK) {
        croak("Problem with RfcGetStringLength (%s): %d / %s / %s\n",
                                        sv_pv(u16to8(name)),
                                        errorInfo.code,
                                        sv_pv(u16to8(errorInfo.key)),
                                        sv_pv(u16to8(errorInfo.message)));
    }

    /* bail out if string is empty */
    if (strLen == 0) {
        return newSV(0);
    }

    buffer = make_space(strLen*4);
    rc = RfcGetString(hcont, name, (SAP_UC *)buffer, strLen + 2, &retStrLen, &errorInfo);
    if (rc != RFC_OK) {
        croak("Problem with RfcGetString (%s): %d / %s / %s\n",
                                        sv_pv(u16to8(name)),
                                        errorInfo.code,
                                        sv_pv(u16to8(errorInfo.key)),
                                        sv_pv(u16to8(errorInfo.message)));
    }

    sv_val = u16to8c((SAP_UC *)buffer, retStrLen);
    free(buffer);
    return sv_val;
}


SV * get_xstring_value(DATA_CONTAINER_HANDLE hcont, SAP_UC *name){

    RFC_RC rc = RFC_OK;
    RFC_ERROR_INFO errorInfo;
    SV* sv_val;
    unsigned strLen, retStrLen;
    char * buffer;

    rc = RfcGetStringLength(hcont, name, &strLen, &errorInfo);
    if (rc != RFC_OK) {
        croak("Problem with RfcGetStringLength in XSTRING (%s): %d / %s / %s\n",
                                        sv_pv(u16to8(name)),
                                        errorInfo.code,
                                        sv_pv(u16to8(errorInfo.key)),
                                        sv_pv(u16to8(errorInfo.message)));
    }

    /* bail out if string is empty */
    if (strLen == 0) {
        return newSV(0);
    }

    buffer = make_space(strLen);
    rc = RfcGetXString(hcont, name, (SAP_RAW *)buffer, strLen, &retStrLen, &errorInfo);
    if (rc != RFC_OK) {
        croak("Problem with RfcGetXString (%s): %d / %s / %s\n",
                                        sv_pv(u16to8(name)),
                                        errorInfo.code,
                                        sv_pv(u16to8(errorInfo.key)),
                                        sv_pv(u16to8(errorInfo.message)));
    }

    sv_val = newSVpv(buffer, strLen);
    free(buffer);
    return sv_val;
}



SV * get_num_value(DATA_CONTAINER_HANDLE hcont, SAP_UC *name, unsigned ulen){

    RFC_RC rc = RFC_OK;
    RFC_ERROR_INFO errorInfo;
    char * buffer;
    SV* sv_val;

    buffer = make_space(ulen*2); /* seems that you need 2 null bytes to terminate a string ...*/
    rc = RfcGetNum(hcont, name, (RFC_NUM *)buffer, ulen, &errorInfo);
    if (rc != RFC_OK) {
        croak("Problem with RfcGetNum (%s): %d / %s / %s\n",
                                        sv_pv(u16to8(name)),
                                        errorInfo.code,
                                        sv_pv(u16to8(errorInfo.key)),
                                        sv_pv(u16to8(errorInfo.message)));
    }
    sv_val = u16to8((SAP_UC *)buffer);
    free(buffer);
    return sv_val;
}


SV * get_bcd_value(DATA_CONTAINER_HANDLE hcont, SAP_UC *name){

    RFC_RC rc = RFC_OK;
    RFC_ERROR_INFO errorInfo;
    SV* sv_val;
    unsigned strLen, retStrLen;
    char * buffer;

    /* select a random long length for a BCD */
    strLen = 100;

    buffer = make_space(strLen*2);
    rc = RfcGetString(hcont, name, (SAP_UC *)buffer, strLen, &retStrLen, &errorInfo);
    if (rc != RFC_OK) {
        croak("(bcd)Problem with RfcGetString (%s): %d / %s / %s\n",
                                        sv_pv(u16to8(name)),
                                        errorInfo.code,
                                        sv_pv(u16to8(errorInfo.key)),
                                        sv_pv(u16to8(errorInfo.message)));
    }

    sv_val = u16to8c((SAP_UC *)buffer, retStrLen);
    free(buffer);
    return sv_val;
}


SV * get_char_value(DATA_CONTAINER_HANDLE hcont, SAP_UC *name, unsigned ulen){

    RFC_RC rc = RFC_OK;
    RFC_ERROR_INFO errorInfo;
    char * buffer;
    SV* sv_val;
    buffer = make_space(ulen*4); /* seems that you need 2 null bytes to terminate a string ...*/
    rc = RfcGetChars(hcont, name, (RFC_CHAR *)buffer, ulen, &errorInfo);
    if (rc != RFC_OK) {
        croak("Problem with RfcGetChars (%s): %d / %s / %s\n",
                                        sv_pv(u16to8(name)),
                                        errorInfo.code,
                                        sv_pv(u16to8(errorInfo.key)),
                                        sv_pv(u16to8(errorInfo.message)));
    }
    sv_val = u16to8((SAP_UC *)buffer);
    free(buffer);
    return sv_val;
}


SV * get_byte_value(DATA_CONTAINER_HANDLE hcont, SAP_UC *name, unsigned len){

    RFC_RC rc = RFC_OK;
    RFC_ERROR_INFO errorInfo;
    char * buffer;
    SV* sv_val;

    buffer = make_space(len);
    rc = RfcGetBytes(hcont, name, (SAP_RAW *)buffer, len, &errorInfo);
    if (rc != RFC_OK) {
        croak("Problem with RfcGetBytes (%s): %d / %s / %s\n",
                                        sv_pv(u16to8(name)),
                                        errorInfo.code,
                                        sv_pv(u16to8(errorInfo.key)),
                                        sv_pv(u16to8(errorInfo.message)));
    }
    sv_val = newSVpv(buffer, len);
    free(buffer);
    return sv_val;
}


SV * get_structure_value(DATA_CONTAINER_HANDLE hcont, SAP_UC *name){

    RFC_RC rc = RFC_OK;
    RFC_ERROR_INFO errorInfo;
    RFC_STRUCTURE_HANDLE line;
    RFC_TYPE_DESC_HANDLE typeHandle;
    RFC_FIELD_DESC fieldDesc;
    unsigned fieldCount, i;
    HV* hv_val;

    rc = RfcGetStructure(hcont, name, &line, &errorInfo);
    if (rc != RFC_OK) {
        croak("Problem with RfcGetStructure (%s): %d / %s / %s\n",
                                        sv_pv(u16to8(name)),
                                        errorInfo.code,
                                        sv_pv(u16to8(errorInfo.key)),
                                        sv_pv(u16to8(errorInfo.message)));
    }

    typeHandle = RfcDescribeType(line, &errorInfo);
    if (typeHandle == NULL) {
        croak("Problem with RfcDescribeType (%s): %d / %s / %s\n",
                                        sv_pv(u16to8(name)),
                                        errorInfo.code,
                                        sv_pv(u16to8(errorInfo.key)),
                                        sv_pv(u16to8(errorInfo.message)));
    }

    rc = RfcGetFieldCount(typeHandle, &fieldCount, &errorInfo);
    if (rc != RFC_OK) {
        croak("Problem with RfcGetFieldCount (%s): %d / %s / %s\n",
                                        sv_pv(u16to8(name)),
                                        errorInfo.code,
                                        sv_pv(u16to8(errorInfo.key)),
                                        sv_pv(u16to8(errorInfo.message)));
    }

    hv_val = newHV();
    for (i = 0; i < fieldCount; i++) {
        rc = RfcGetFieldDescByIndex(typeHandle, i, &fieldDesc, &errorInfo);
        if (rc != RFC_OK) {
            croak("Problem with RfcGetFieldDescByIndex (%s): %d / %s / %s\n",
                                        sv_pv(u16to8(name)),
                                        errorInfo.code,
                                        sv_pv(u16to8(errorInfo.key)),
                                        sv_pv(u16to8(errorInfo.message)));
        }

        /* process each field type ...*/
        hv_store_ent(hv_val, sv_2mortal(u16to8(fieldDesc.name)), get_field_value(line, fieldDesc), 0);
    }

    return newRV_noinc((SV*)hv_val);
}


SV * get_field_value(DATA_CONTAINER_HANDLE hcont, RFC_FIELD_DESC fieldDesc){

    SV* sv_pvalue;
    RFC_RC rc = RFC_OK;
    RFC_ERROR_INFO errorInfo;
    RFC_TABLE_HANDLE tableHandle;

    switch (fieldDesc.type) {
        case RFCTYPE_DATE:
            sv_pvalue = get_date_value(hcont, fieldDesc.name);
            break;
        case RFCTYPE_TIME:
            sv_pvalue = get_time_value(hcont, fieldDesc.name);
            break;
        case RFCTYPE_NUM:
            sv_pvalue = get_num_value(hcont, fieldDesc.name, fieldDesc.nucLength);
            break;
        case RFCTYPE_BCD:
            sv_pvalue = get_bcd_value(hcont, fieldDesc.name);
            break;
        case RFCTYPE_CHAR:
            sv_pvalue = get_char_value(hcont, fieldDesc.name, fieldDesc.nucLength);
            break;
        case RFCTYPE_BYTE:
            sv_pvalue = get_byte_value(hcont, fieldDesc.name, fieldDesc.nucLength);
            break;
        case RFCTYPE_FLOAT:
            sv_pvalue = get_float_value(hcont, fieldDesc.name);
            break;
        case RFCTYPE_INT:
            sv_pvalue = get_int_value(hcont, fieldDesc.name);
            break;
        case RFCTYPE_INT2:
            sv_pvalue = get_int2_value(hcont, fieldDesc.name);
            break;
        case RFCTYPE_INT1:
            sv_pvalue = get_int1_value(hcont, fieldDesc.name);
            break;
        case RFCTYPE_STRUCTURE:
            sv_pvalue = get_structure_value(hcont, fieldDesc.name);
            break;
        case RFCTYPE_TABLE:
            rc = RfcGetTable(hcont, fieldDesc.name, &tableHandle, &errorInfo);
            if (rc != RFC_OK) {
                croak("Problem with RfcGetTable (%s): %d / %s / %s\n",
                                            sv_pv(u16to8(fieldDesc.name)),
                                            errorInfo.code,
                                            sv_pv(u16to8(errorInfo.key)),
                                            sv_pv(u16to8(errorInfo.message)));
            }
            sv_pvalue = get_table_value(tableHandle, fieldDesc.name);
            break;
        case RFCTYPE_XMLDATA:
            fprintf(stderr, "shouldnt get a XMLDATA type parameter - abort\n");
            exit(1);
            break;
        case RFCTYPE_STRING:
            sv_pvalue = get_string_value(hcont, fieldDesc.name);
            break;
        case RFCTYPE_XSTRING:
            sv_pvalue = get_xstring_value(hcont, fieldDesc.name);
            break;
        default:
            fprintf(stderr, "This type is not implemented (%d) - abort\n", fieldDesc.type);
            exit(1);
            break;
    }

    return sv_pvalue;
}


SV * get_table_line(RFC_STRUCTURE_HANDLE line){

    RFC_RC rc = RFC_OK;
    RFC_ERROR_INFO errorInfo;
    RFC_TYPE_DESC_HANDLE typeHandle;
    RFC_FIELD_DESC fieldDesc;
    unsigned fieldCount, i;
    HV* hv_val;

    typeHandle = RfcDescribeType(line, &errorInfo);
    if (typeHandle == NULL) {
        croak("Problem with RfcDescribeType: %d / %s / %s\n",
                                        errorInfo.code,
                                        sv_pv(u16to8(errorInfo.key)),
                                        sv_pv(u16to8(errorInfo.message)));
    }

    rc = RfcGetFieldCount(typeHandle, &fieldCount, &errorInfo);
    if (rc != RFC_OK) {
        croak("Problem with RfcGetFieldCount: %d / %s / %s\n",
                                        errorInfo.code,
                                        sv_pv(u16to8(errorInfo.key)),
                                        sv_pv(u16to8(errorInfo.message)));
    }

    hv_val = newHV();
    for (i = 0; i < fieldCount; i++) {
        rc = RfcGetFieldDescByIndex(typeHandle, i, &fieldDesc, &errorInfo);
        if (rc != RFC_OK) {
            croak("Problem with RfcGetFieldDescByIndex: %d / %s / %s\n",
                                        errorInfo.code,
                                        sv_pv(u16to8(errorInfo.key)),
                                        sv_pv(u16to8(errorInfo.message)));
        }

        /* process each field type ...*/
        hv_store_ent(hv_val, sv_2mortal(u16to8(fieldDesc.name)), sv_2mortal(SvREFCNT_inc(get_field_value(line, fieldDesc))), 0);
    }

    return newRV_noinc((SV*)sv_2mortal(SvREFCNT_inc(hv_val)));
}


SV * get_table_value(DATA_CONTAINER_HANDLE hcont, SAP_UC *name){

    RFC_RC rc = RFC_OK;
    RFC_ERROR_INFO errorInfo;
    unsigned tabLen, r;
    RFC_STRUCTURE_HANDLE line;
    AV* av_val;

    rc = RfcGetRowCount(hcont, &tabLen, NULL);
    if (rc != RFC_OK) {
        croak("Problem with RfcGetRowCount (%s): %d / %s / %s\n",
                                        sv_pv(u16to8(name)),
                                        errorInfo.code,
                                        sv_pv(u16to8(errorInfo.key)),
                                        sv_pv(u16to8(errorInfo.message)));
    }
    av_val = newAV();
    for (r = 0; r < tabLen; r++){
        RfcMoveTo(hcont, r, NULL);
        line = RfcGetCurrentRow(hcont, NULL);
        av_push(av_val, get_table_line(line));
    }

    return newRV_noinc((SV*)av_val);
}


SV * get_parameter_value(SV* sv_name, SAPNW_FUNC *fptr){

    SAPNW_CONN_INFO *cptr;
    SAPNW_FUNC_DESC *dptr;
    RFC_RC rc = RFC_OK;
    RFC_ERROR_INFO errorInfo;
    RFC_PARAMETER_DESC paramDesc;
    RFC_TABLE_HANDLE tableHandle;
    SAP_UC *p_name;
    SV* sv_pvalue;

    dptr = fptr->desc_handle;
    cptr = dptr->conn_handle;

    /* get the parameter description */
    rc = RfcGetParameterDescByName(dptr->handle, (p_name = u8to16(sv_name)), &paramDesc, &errorInfo);

    /* bail on a bad call for parameter description */
    if (rc != RFC_OK) {
        free(p_name);
        croak("Problem with RfcGetParameterDescByName (%s): %d / %s / %s\n",
                                        sv_pv(sv_name),
                                        errorInfo.code,
                                        sv_pv(u16to8(errorInfo.key)),
                                        sv_pv(u16to8(errorInfo.message)));
    }

    switch (paramDesc.type) {
        case RFCTYPE_DATE:
            sv_pvalue = get_date_value(fptr->handle, p_name);
            break;
        case RFCTYPE_TIME:
            sv_pvalue = get_time_value(fptr->handle, p_name);
            break;
        case RFCTYPE_NUM:
            sv_pvalue = get_num_value(fptr->handle, p_name, paramDesc.nucLength);
            break;
        case RFCTYPE_BCD:
            sv_pvalue = get_bcd_value(fptr->handle, p_name);
            break;
        case RFCTYPE_CHAR:
            sv_pvalue = get_char_value(fptr->handle, p_name, paramDesc.nucLength);
            break;
        case RFCTYPE_BYTE:
            sv_pvalue = get_byte_value(fptr->handle, p_name, paramDesc.nucLength);
            break;
        case RFCTYPE_FLOAT:
            sv_pvalue = get_float_value(fptr->handle, p_name);
            break;
        case RFCTYPE_INT:
            sv_pvalue = get_int_value(fptr->handle, p_name);
            break;
        case RFCTYPE_INT2:
            sv_pvalue = get_int2_value(fptr->handle, p_name);
            break;
        case RFCTYPE_INT1:
            sv_pvalue = get_int1_value(fptr->handle, p_name);
            break;
        case RFCTYPE_STRUCTURE:
            sv_pvalue = get_structure_value(fptr->handle, p_name);
            break;
        case RFCTYPE_TABLE:
            rc = RfcGetTable(fptr->handle, p_name, &tableHandle, &errorInfo);
            if (rc != RFC_OK) {
                croak("Problem with RfcGetTable (%s): %d / %s / %s\n",
                                            sv_pv(u16to8(p_name)),
                                            errorInfo.code,
                                            sv_pv(u16to8(errorInfo.key)),
                                            sv_pv(u16to8(errorInfo.message)));
            }
            sv_pvalue = get_table_value(tableHandle, p_name);
            break;
        case RFCTYPE_XMLDATA:
            fprintf(stderr, "shouldnt get a XMLDATA type parameter - abort\n");
            exit(1);
            break;
        case RFCTYPE_STRING:
            sv_pvalue = get_string_value(fptr->handle, p_name);
            break;
        case RFCTYPE_XSTRING:
            sv_pvalue = get_xstring_value(fptr->handle, p_name);
            break;
        default:
            fprintf(stderr, "This type is not implemented (%d) - abort\n", paramDesc.type);
            exit(1);
            break;
    }
    free(p_name);

    return sv_pvalue;
}


void set_date_value(DATA_CONTAINER_HANDLE hcont, SAP_UC *name, SV* sv_value){

    RFC_RC rc = RFC_OK;
    RFC_ERROR_INFO errorInfo;
    SAP_UC *p_value;
    RFC_DATE date_value;

    if(SvTYPE(sv_value) != SVt_PV && SvTYPE(sv_value) != SVt_PVIV && SvTYPE(sv_value) != SVt_PVNV && SvTYPE(sv_value) != SVt_PVMG)
        croak("RfcSetDate (%s): not a Scalar\n", sv_pv(u16to8(name)));
    if (SvCUR(sv_value) != 8)
        croak("RfcSetDate invalid date format (%s): %s\n", sv_pv(u16to8(name)), sv_pv(sv_value));
    p_value = u8to16(sv_value);
    memcpy((char *)date_value+0, (char *)p_value, 16);
    free(p_value);

    rc = RfcSetDate(hcont, name, date_value, &errorInfo);
    if (rc != RFC_OK) {
        croak("Problem with RfcSetDate (%s): %d / %s / %s\n",
                                sv_pv(u16to8(name)),
                                errorInfo.code,
                                sv_pv(u16to8(errorInfo.key)),
                                sv_pv(u16to8(errorInfo.message)));
    }

    return;
}


void set_time_value(DATA_CONTAINER_HANDLE hcont, SAP_UC *name, SV* sv_value){

    RFC_RC rc = RFC_OK;
    RFC_ERROR_INFO errorInfo;
    SAP_UC *p_value;
    RFC_TIME time_value;

    if(SvTYPE(sv_value) != SVt_PV && SvTYPE(sv_value) != SVt_PVIV && SvTYPE(sv_value) != SVt_PVNV && SvTYPE(sv_value) != SVt_PVMG)
        croak("RfcSetTime (%s): not a Scalar\n", sv_pv(u16to8(name)));
    if (SvCUR(sv_value) != 6)
        croak("RfcSetTime invalid input date format (%s): %s\n", sv_pv(u16to8(name)), sv_pv(sv_value));
    p_value = u8to16(sv_value);
    memcpy((char *)time_value+0, (char *)p_value, 12);
    free(p_value);

    rc = RfcSetTime(hcont, name, time_value, &errorInfo);
    if (rc != RFC_OK) {
        croak("Problem with RfcSetTime (%s): %d / %s / %s\n",
                                sv_pv(u16to8(name)),
                                errorInfo.code,
                                sv_pv(u16to8(errorInfo.key)),
                                sv_pv(u16to8(errorInfo.message)));
    }

    return;
}


void set_num_value(DATA_CONTAINER_HANDLE hcont, SAP_UC *name, SV* sv_value, unsigned max){

    RFC_RC rc = RFC_OK;
    RFC_ERROR_INFO errorInfo;
    SAP_UC *p_value;

    if(SvTYPE(sv_value) != SVt_PV && SvTYPE(sv_value) != SVt_PVIV && SvTYPE(sv_value) != SVt_PVNV && SvTYPE(sv_value) != SVt_PVMG)
        croak("RfcSetNum (%s): not a Scalar\n", sv_pv(u16to8(name)));
    if (SvCUR(sv_value) > max)
        croak("RfcSetNum invalid input num (%s): %s\n", sv_pv(u16to8(name)), sv_pv(sv_value));

    p_value = u8to16(sv_value);
    rc = RfcSetNum(hcont, name, (RFC_NUM *)p_value, strlenU(p_value), &errorInfo);
    free(p_value);
    if (rc != RFC_OK) {
        croak("Problem with RfcSetNum (%s): %d / %s / %s\n",
                                sv_pv(u16to8(name)),
                                errorInfo.code,
                                sv_pv(u16to8(errorInfo.key)),
                                sv_pv(u16to8(errorInfo.message)));
    }

    return;
}


void set_bcd_value(DATA_CONTAINER_HANDLE hcont, SAP_UC *name, SV* sv_value){

    RFC_RC rc = RFC_OK;
    RFC_ERROR_INFO errorInfo;
    SAP_UC *p_value;

    if(SvTYPE(sv_value) != SVt_PV && SvTYPE(sv_value) != SVt_PVIV && SvTYPE(sv_value) != SVt_PVNV && SvTYPE(sv_value) != SVt_PVMG)
        croak("set_bcd_value (%s): not a Scalar\n", sv_pv(u16to8(name)));
    p_value = u8to16(sv_value);
    rc = RfcSetString(hcont, name, p_value, strlenU(p_value), &errorInfo);
    free(p_value);
    if (rc != RFC_OK) {
        croak("(bcd)Problem with RfcSetString (%s): %d / %s / %s\n",
                                sv_pv(u16to8(name)),
                                errorInfo.code,
                                sv_pv(u16to8(errorInfo.key)),
                                sv_pv(u16to8(errorInfo.message)));
    }

    return;
}


void set_char_value(DATA_CONTAINER_HANDLE hcont, SAP_UC *name, SV* sv_value, unsigned max){

    RFC_RC rc = RFC_OK;
    RFC_ERROR_INFO errorInfo;
    SAP_UC *p_value;


    if(SvTYPE(sv_value) != SVt_PV && SvTYPE(sv_value) != SVt_PVIV && SvTYPE(sv_value) != SVt_PVNV && SvTYPE(sv_value) != SVt_PVMG) {
        croak("RfcSetChar (%s): not a Scalar\n", sv_pv(u16to8(name)));
    }

    p_value = u8to16(sv_value);
    if (strlenU(p_value) > max) {
        croak("RfcSetChar string too long (%s): %s\n", sv_pv(u16to8(name)), sv_pv(sv_value));
    }
    rc = RfcSetChars(hcont, name, p_value, strlenU(p_value), &errorInfo);
//    fprintfU(stderr, cU("set %s value max(%d) len(%d): %s - rc: %d\n"), name, max, strlenU(p_value), p_value, rc);
    free(p_value);
    if (rc != RFC_OK) {
        croak("Problem with RfcSetChars (%s): %d / %s / %s\n",
                                sv_pv(u16to8(name)),
                                errorInfo.code,
                                sv_pv(u16to8(errorInfo.key)),
                                sv_pv(u16to8(errorInfo.message)));
    }

    return;
}


void set_byte_value(DATA_CONTAINER_HANDLE hcont, SAP_UC *name, SV* sv_value, unsigned max){

    RFC_RC rc = RFC_OK;
    RFC_ERROR_INFO errorInfo;


    if(SvTYPE(sv_value) != SVt_PV && SvTYPE(sv_value) != SVt_PVIV && SvTYPE(sv_value) != SVt_PVNV && SvTYPE(sv_value) != SVt_PVMG)
        croak("RfcSetByte (%s): not a Scalar\n", sv_pv(u16to8(name)));
    if (SvCUR(sv_value) > max)
        croak("RfcSetByte string too long (%s): %s\n", sv_pv(u16to8(name)), sv_pv(sv_value));
    rc = RfcSetBytes(hcont, name, (SAP_RAW *)SvPV(sv_value, SvCUR(sv_value)), SvCUR(sv_value), &errorInfo);
    if (rc != RFC_OK) {
        croak("Problem with RfcSetBytes (%s): %d / %s / %s\n",
                                sv_pv(u16to8(name)),
                                errorInfo.code,
                                sv_pv(u16to8(errorInfo.key)),
                                sv_pv(u16to8(errorInfo.message)));
    }

    return;
}


void set_float_value(DATA_CONTAINER_HANDLE hcont, SAP_UC *name, SV* sv_value){

    RFC_RC rc = RFC_OK;
    RFC_ERROR_INFO errorInfo;

    if(SvTYPE(sv_value) != SVt_NV && SvTYPE(sv_value) != SVt_PVNV)
        croak("RfcSetFloat (%s): not a Scalar or Int\n", sv_pv(u16to8(name)));
    rc = RfcSetFloat(hcont, name, (RFC_FLOAT) SvNV(sv_value), &errorInfo);
    if (rc != RFC_OK) {
        croak("Problem with RfcSetFloat (%s): %d / %s / %s\n",
                                sv_pv(u16to8(name)),
                                errorInfo.code,
                                sv_pv(u16to8(errorInfo.key)),
                                sv_pv(u16to8(errorInfo.message)));
    }

    return;
}


void set_int_value(DATA_CONTAINER_HANDLE hcont, SAP_UC *name, SV* sv_value){

    RFC_RC rc = RFC_OK;
    RFC_ERROR_INFO errorInfo;

    //fprintf(stderr, "sv_type: %s - %d \n", sv_pv(u16to8(name)), SvTYPE(sv_value));
    if(SvTYPE(sv_value) != SVt_IV && SvTYPE(sv_value) != SVt_PVIV)
        croak("RfcSetInt (%s): not an Integer\n", sv_pv(u16to8(name)));
    rc = RfcSetInt(hcont, name, (RFC_INT) SvIV(sv_value), &errorInfo);
    if (rc != RFC_OK) {
        croak("Problem with RfcSetInt (%s): %d / %s / %s\n",
                                sv_pv(u16to8(name)),
                                errorInfo.code,
                                sv_pv(u16to8(errorInfo.key)),
                                sv_pv(u16to8(errorInfo.message)));
    }

    return;
}


void set_int1_value(DATA_CONTAINER_HANDLE hcont, SAP_UC *name, SV* sv_value){

    RFC_RC rc = RFC_OK;
    RFC_ERROR_INFO errorInfo;

    if(SvTYPE(sv_value) != SVt_IV && SvTYPE(sv_value) != SVt_PVIV)
        croak("RfcSetInt1 (%s): not an Integer\n", sv_pv(u16to8(name)));
    if (SvIV(sv_value) > 255)
        croak("RfcSetInt1 invalid input value too big on (%s): %s\n", sv_pv(u16to8(name)), sv_pv(sv_value));
    rc = RfcSetInt1(hcont, name, (RFC_INT1) SvIV(sv_value), &errorInfo);
    if (rc != RFC_OK) {
        croak("Problem with RfcSetInt1 (%s): %d / %s / %s\n",
                                sv_pv(u16to8(name)),
                                errorInfo.code,
                                sv_pv(u16to8(errorInfo.key)),
                                sv_pv(u16to8(errorInfo.message)));
    }

    return;
}


void set_int2_value(DATA_CONTAINER_HANDLE hcont, SAP_UC *name, SV* sv_value){

    RFC_RC rc = RFC_OK;
    RFC_ERROR_INFO errorInfo;

    if(SvTYPE(sv_value) != SVt_IV && SvTYPE(sv_value) != SVt_PVIV)
        croak("RfcSetInt2 (%s): not an Integer\n", sv_pv(u16to8(name)));
    if (SvIV(sv_value) > 4095)
        croak("RfcSetInt2 invalid input value too big on (%s): %s\n", sv_pv(u16to8(name)), sv_pv(sv_value));
    rc = RfcSetInt2(hcont, name, (RFC_INT2) SvIV(sv_value), &errorInfo);
    if (rc != RFC_OK) {
        croak("Problem with RfcSetInt2 (%s): %d / %s / %s\n",
                                sv_pv(u16to8(name)),
                                errorInfo.code,
                                sv_pv(u16to8(errorInfo.key)),
                                sv_pv(u16to8(errorInfo.message)));
    }

    return;
}


void set_string_value(DATA_CONTAINER_HANDLE hcont, SAP_UC *name, SV* sv_value){

    RFC_RC rc = RFC_OK;
    RFC_ERROR_INFO errorInfo;
    SAP_UC *p_value;

    if(SvTYPE(sv_value) != SVt_PV && SvTYPE(sv_value) != SVt_PVIV && SvTYPE(sv_value) != SVt_PVNV && SvTYPE(sv_value) != SVt_PVMG)
        croak("RfcSetString (%s): not a Scalar\n", sv_pv(u16to8(name)));
    p_value = u8to16(sv_value);
    rc = RfcSetString(hcont, name, p_value, strlenU(p_value), &errorInfo);
    free(p_value);
    if (rc != RFC_OK) {
        croak("Problem with RfcSetString (%s): %d / %s / %s\n",
                                sv_pv(u16to8(name)),
                                errorInfo.code,
                                sv_pv(u16to8(errorInfo.key)),
                                sv_pv(u16to8(errorInfo.message)));
    }

    return;
}


void set_xstring_value(DATA_CONTAINER_HANDLE hcont, SAP_UC *name, SV* sv_value){

    RFC_RC rc = RFC_OK;
    RFC_ERROR_INFO errorInfo;

    if(SvTYPE(sv_value) != SVt_PV && SvTYPE(sv_value) != SVt_PVIV && SvTYPE(sv_value) != SVt_PVNV && SvTYPE(sv_value) != SVt_PVMG)
        croak("RfcSetXString (%s): not a Scalar\n", sv_pv(u16to8(name)));
    rc = RfcSetXString(hcont, name, (SAP_RAW *)SvPV(sv_value, SvCUR(sv_value)), SvCUR(sv_value), &errorInfo);
    if (rc != RFC_OK) {
        croak("Problem with RfcSetXString (%s): %d / %s / %s\n",
                                sv_pv(u16to8(name)),
                                errorInfo.code,
                                sv_pv(u16to8(errorInfo.key)),
                                sv_pv(u16to8(errorInfo.message)));
    }

    return;
}


void set_structure_value(DATA_CONTAINER_HANDLE hcont, SAP_UC *name, SV* sv_value){

    RFC_RC rc = RFC_OK;
    RFC_ERROR_INFO errorInfo;
    RFC_STRUCTURE_HANDLE line;
    RFC_TYPE_DESC_HANDLE typeHandle;
    RFC_FIELD_DESC fieldDesc;
    SAP_UC *p_name;
    unsigned i, idx;
    HV* hv_value;
    HE* h_entry;
    SV* sv_key;
    SV* sv_val;


    hv_value =  (HV*)SvRV( sv_value );
    if(SvTYPE(hv_value) != SVt_PVHV)
        croak("RfcSetStructure (%s): not a HASH\n", sv_pv(u16to8(name)));

    idx = hv_iterinit(hv_value);

    if (idx == 0) {
        croak("RfcSetStructure (%s): no fieldname keys\n", sv_pv(u16to8(name)));
    }

    rc = RfcGetStructure(hcont, name, &line, &errorInfo);
    if (rc != RFC_OK) {
        croak("(set)Problem with RfcGetStructure (%s): %d / %s / %s\n",
                                        sv_pv(u16to8(name)),
                                        errorInfo.code,
                                        sv_pv(u16to8(errorInfo.key)),
                                        sv_pv(u16to8(errorInfo.message)));
    }

    typeHandle = RfcDescribeType(line, &errorInfo);
    if (typeHandle == NULL) {
        croak("(set)Problem with RfcDescribeType (%s): %d / %s / %s\n",
                                        sv_pv(u16to8(name)),
                                        errorInfo.code,
                                        sv_pv(u16to8(errorInfo.key)),
                                        sv_pv(u16to8(errorInfo.message)));
    }


    for (i = 0; i < idx; i++) {
        h_entry = hv_iternext( hv_value );
        sv_key = hv_iterkeysv( h_entry );
        sv_val = hv_iterval(hv_value, h_entry);

        rc = RfcGetFieldDescByName(typeHandle, (p_name = u8to16(sv_key)), &fieldDesc, &errorInfo);
        if (rc != RFC_OK) {
            croak("(set)Problem with RfcGetFieldDescByName (%s/%s): %d / %s / %s\n",
                                        sv_pv(u16to8(name)),
                                        sv_pv(sv_key),
                                        errorInfo.code,
                                        sv_pv(u16to8(errorInfo.key)),
                                        sv_pv(u16to8(errorInfo.message)));
        }
        // XXX dodgey copy back of field name !!!!!
//        memcpy(fieldDesc.name, p_name, strlenU(p_name)*2+2);
        free(p_name);
        set_field_value(line, fieldDesc, sv_val);
    }

    return;
}


void set_field_value(DATA_CONTAINER_HANDLE hcont, RFC_FIELD_DESC fieldDesc, SV* sv_value){
    RFC_RC rc = RFC_OK;
    RFC_ERROR_INFO errorInfo;
    RFC_TABLE_HANDLE tableHandle;

    switch (fieldDesc.type) {
        case RFCTYPE_DATE:
            set_date_value(hcont, fieldDesc.name, sv_value);
            break;
        case RFCTYPE_TIME:
            set_time_value(hcont, fieldDesc.name, sv_value);
            break;
        case RFCTYPE_NUM:
            set_num_value(hcont, fieldDesc.name, sv_value, fieldDesc.nucLength);
            break;
        case RFCTYPE_BCD:
            set_bcd_value(hcont, fieldDesc.name, sv_value);
            break;
        case RFCTYPE_CHAR:
            set_char_value(hcont, fieldDesc.name, sv_value, fieldDesc.nucLength);
            break;
        case RFCTYPE_BYTE:
            set_byte_value(hcont, fieldDesc.name, sv_value, fieldDesc.nucLength);
            break;
        case RFCTYPE_FLOAT:
            set_float_value(hcont, fieldDesc.name, sv_value);
            break;
        case RFCTYPE_INT:
            set_int_value(hcont, fieldDesc.name, sv_value);
            break;
        case RFCTYPE_INT2:
            set_int2_value(hcont, fieldDesc.name, sv_value);
            break;
        case RFCTYPE_INT1:
            set_int1_value(hcont, fieldDesc.name, sv_value);
            break;
        case RFCTYPE_STRUCTURE:
            set_structure_value(hcont, fieldDesc.name, sv_value);
            break;
        case RFCTYPE_TABLE:
            rc = RfcGetTable(hcont, fieldDesc.name, &tableHandle, &errorInfo);
            if (rc != RFC_OK) {
                croak("(set_tabl_value)Problem with RfcGetTable (%s): %d / %s / %s\n",
                                            sv_pv(u16to8(fieldDesc.name)),
                                            errorInfo.code,
                                            sv_pv(u16to8(errorInfo.key)),
                                            sv_pv(u16to8(errorInfo.message)));
            }
            set_table_value(tableHandle, fieldDesc.name, sv_value);
            break;
        case RFCTYPE_XMLDATA:
            fprintf(stderr, "shouldnt get a XMLDATA type parameter - abort\n");
            exit(1);
            break;
        case RFCTYPE_STRING:
            set_string_value(hcont, fieldDesc.name, sv_value);
            break;
        case RFCTYPE_XSTRING:
            set_xstring_value(hcont, fieldDesc.name, sv_value);
            break;
        default:
            fprintf(stderr, "Set field - This type is not implemented (%d) - abort\n", fieldDesc.type);
            exit(1);
            break;
    }

    return;
}


void set_table_line(RFC_STRUCTURE_HANDLE line, SV* sv_value){

    RFC_RC rc = RFC_OK;
    RFC_ERROR_INFO errorInfo;
    RFC_TYPE_DESC_HANDLE typeHandle;
    RFC_FIELD_DESC fieldDesc;
    unsigned i, idx;
    SAP_UC * p_name;
    HV* hv_value;
    HE* h_entry;
    SV* sv_key;
    SV* sv_val;


    hv_value =  (HV*)SvRV( sv_value );
    idx = hv_iterinit(hv_value);

    if(SvTYPE(hv_value) != SVt_PVHV)
        croak("set_table_line: not a HASH\n");

    if (idx == 0) {
        croak("set_table_line - no values: no fieldname keys\n");
    }

    typeHandle = RfcDescribeType(line, &errorInfo);
    if (typeHandle == NULL) {
        croak("(set_table_line)Problem with RfcDescribeType: %d / %s / %s\n",
                                            errorInfo.code,
                                            sv_pv(u16to8(errorInfo.key)),
                                            sv_pv(u16to8(errorInfo.message)));
    }

    for (i = 0; i < idx; i++) {
        h_entry = hv_iternext( hv_value );
        sv_key = hv_iterkeysv( h_entry );
        sv_val = hv_iterval(hv_value, h_entry);

        rc = RfcGetFieldDescByName(typeHandle, (p_name = u8to16(sv_key)), &fieldDesc, &errorInfo);
        if (rc != RFC_OK) {
            croak("(set_table_line)Problem with RfcGetFieldDescByName (%s): %d / %s / %s\n",
                                            sv_pv(sv_key),
                                            errorInfo.code,
                                            sv_pv(u16to8(errorInfo.key)),
                                            sv_pv(u16to8(errorInfo.message)));
        }

        // XXX dodgey copy back of field name !!!!!
//        memcpy(fieldDesc.name, p_name, strlenU(p_name)*2+2);
        free(p_name);
        set_field_value(line, fieldDesc, sv_val);
    }
    return;
}


void set_table_value(DATA_CONTAINER_HANDLE hcont, SAP_UC *name, SV* sv_value){

    RFC_ERROR_INFO errorInfo;
    RFC_STRUCTURE_HANDLE line;
    unsigned r, idx;
    AV* av_value;
    SV* sv_row;

    av_value =  (AV*)SvRV( sv_value );
    if(SvTYPE(av_value) != SVt_PVAV)
        croak("set_tabl_value (%s): not an ARRAY\n", sv_pv(u16to8(name)));

    idx = av_len(av_value);
    for (r = 0; r <= idx; r++) {
        sv_row = *av_fetch(av_value, r, FALSE);
        line = RfcAppendNewRow(hcont, &errorInfo);
        if (line == NULL) {
            croak("(set_tabl_value)Problem with RfcAppendNewRow (%s): %d / %s / %s\n",
                                            sv_pv(u16to8(name)),
                                            errorInfo.code,
                                            sv_pv(u16to8(errorInfo.key)),
                                            sv_pv(u16to8(errorInfo.message)));
        }
        set_table_line(line, sv_row);
    }
    return;
}


void set_parameter_value(SAPNW_FUNC *fptr, SV* sv_name, SV* sv_value){

    SAPNW_CONN_INFO *cptr;
    SAPNW_FUNC_DESC *dptr;
    RFC_RC rc = RFC_OK;
    RFC_ERROR_INFO errorInfo;
    RFC_TABLE_HANDLE tableHandle;
    RFC_PARAMETER_DESC paramDesc;
    SAP_UC *p_name;

    if (! SvTRUE(sv_value)) {
        return;
    }

    dptr = fptr->desc_handle;
    cptr = dptr->conn_handle;

    /* get the parameter description */
    rc = RfcGetParameterDescByName(dptr->handle, (p_name = u8to16(sv_name)), &paramDesc, &errorInfo);

    /* bail on a bad call for parameter description */
    if (rc != RFC_OK) {
        free(p_name);
        croak("(Set)Problem with RfcGetParameterDescByName (%s): %d / %s / %s\n",
                                            sv_pv(sv_name),
                                            errorInfo.code,
                                            sv_pv(u16to8(errorInfo.key)),
                                            sv_pv(u16to8(errorInfo.message)));
    }

    switch (paramDesc.type) {
        case RFCTYPE_DATE:
            set_date_value(fptr->handle, p_name, sv_value);
            break;
        case RFCTYPE_TIME:
            set_time_value(fptr->handle, p_name, sv_value);
            break;
        case RFCTYPE_NUM:
            set_num_value(fptr->handle, p_name, sv_value, paramDesc.nucLength);
            break;
        case RFCTYPE_BCD:
            set_bcd_value(fptr->handle, p_name, sv_value);
            break;
        case RFCTYPE_CHAR:
            set_char_value(fptr->handle, p_name, sv_value, paramDesc.nucLength);
            break;
        case RFCTYPE_BYTE:
            set_byte_value(fptr->handle, p_name, sv_value, paramDesc.nucLength);
            break;
        case RFCTYPE_FLOAT:
            set_float_value(fptr->handle, p_name, sv_value);
            break;
        case RFCTYPE_INT:
            set_int_value(fptr->handle, p_name, sv_value);
            break;
        case RFCTYPE_INT2:
            set_int2_value(fptr->handle, p_name, sv_value);
            break;
        case RFCTYPE_INT1:
            set_int1_value(fptr->handle, p_name, sv_value);
            break;
        case RFCTYPE_STRUCTURE:
            set_structure_value(fptr->handle, p_name, sv_value);
            break;
        case RFCTYPE_TABLE:
            rc = RfcGetTable(fptr->handle, p_name, &tableHandle, &errorInfo);
            if (rc != RFC_OK) {
                croak("(set_tabl_value)Problem with RfcGetTable (%s): %d / %s / %s\n",
                                                    sv_pv(u16to8(p_name)),
                                                    errorInfo.code,
                                                    sv_pv(u16to8(errorInfo.key)),
                                                    sv_pv(u16to8(errorInfo.message)));
            }
            set_table_value(tableHandle, p_name, sv_value);
            break;
        case RFCTYPE_XMLDATA:
            fprintf(stderr, "shouldnt get a XMLDATA type parameter - abort\n");
            exit(1);
            break;
        case RFCTYPE_STRING:
            set_string_value(fptr->handle, p_name, sv_value);
            break;
        case RFCTYPE_XSTRING:
            set_xstring_value(fptr->handle, p_name, sv_value);
            break;
        default:
            fprintf(stderr, "This type is not implemented (%d) - abort\n", paramDesc.type);
            exit(1);
            break;
    }
    free(p_name);
    return;
}


/* Create a Function Module handle to be used for an RFC call */
SV * SAPNWRFC_set_parameter_active(SV* sv_func_call, SV* sv_name, SV* sv_active){

    SAPNW_CONN_INFO *cptr;
    SAPNW_FUNC_DESC *dptr;
    SAPNW_FUNC *fptr;
    RFC_RC rc = RFC_OK;
    RFC_ERROR_INFO errorInfo;
    SAP_UC *p_name;
    HV* h_self;
    SV* sv_pointer;

    h_self =  (HV*)SvRV( sv_func_call );
    if (hv_exists(h_self, (char *) "funccall", 8)) {
        sv_pointer = *hv_fetch(h_self, (char *) "funccall", 8, FALSE);
        if (SvTRUE(sv_pointer)) {
            fptr = INT2PTR(SAPNW_FUNC *, SvIV(sv_pointer));
        } else {
            croak("Corrupt function call pointer in set_parameter_active\n");
        }
    } else {
        croak("Non-existent function call pointer in set_parameter_active\n");
    }

    dptr = fptr->desc_handle;
    cptr = dptr->conn_handle;

    rc = RfcSetParameterActive(fptr->handle, (p_name = u8to16(sv_name)), SvIV(sv_active), &errorInfo);
    free(p_name);
    if (rc != RFC_OK) {
        croak("Problem with RfcSetParameterActive (%s): %d / %s / %s\n",
                                        sv_pv(sv_name),
                                        errorInfo.code,
                                        sv_pv(u16to8(errorInfo.key)),
                                        sv_pv(u16to8(errorInfo.message)));
    }
    return newSViv(1);
}


SV* parameter_attrib (SV* sv_self, char * attrib, SV* sv_set_value) {

    SV* sv_method;
    SV* sv_value;
    int count;
    dSP;
    // initial the argument stack
    ENTER;
    SAVETMPS;
    PUSHMARK(SP);
    XPUSHs(sv_self);
    if (SvTRUE(sv_set_value)) {
        XPUSHs(sv_set_value);
    }
    PUTBACK;

    sv_method = newSVpv("SAPNW::RFC::Parameter::", 0);
    sv_catsv(sv_method, sv_2mortal(newSVpvn(attrib, strlen(attrib))));
    count = perl_call_sv(sv_method, G_EVAL | G_SCALAR );
    sv_2mortal(sv_method);

    if(SvTRUE(ERRSV)) {
        croak("callback SAPNW::RFC::Parameter::%s - failed: %s", attrib, SvPV(ERRSV,PL_na));
    }

    SPAGAIN;

    if (count != 1) {
        croak("Big problem in SAPNW::RFC::Parameter attribute(%s) call\n", attrib);
    }
    sv_value = newSVsv(POPs);

    PUTBACK;
    FREETMPS;
    LEAVE;

    return sv_2mortal(sv_value);
}


SV* function_callback (SV* sv_function, SV* sv_parameters) {
    unsigned count;
    SV* sv_value;

    dSP;
    // initial the argument stack
    ENTER;
    SAVETMPS;
    PUSHMARK(SP);

    XPUSHs(sv_function);
    XPUSHs(sv_parameters);

    PUTBACK;

    count = perl_call_pv("SAPNW::Connection::main_handler", G_EVAL | G_SCALAR );

    if(SvTRUE(ERRSV)) {
        croak("callback SAPNW::Connection::main_handler - failed: %s", SvPV(ERRSV,PL_na));
    }

    SPAGAIN;

    if (count != 1) {
        croak("Big problem in SAPNW::Connection::main_handler call\n");
    }
    sv_value = newSVsv(POPs);

    PUTBACK;
    FREETMPS;
    LEAVE;

    return sv_2mortal(sv_value);
}


RFC_RC SAP_API myrfc_function_callback(RFC_CONNECTION_HANDLE rfcHandle, RFC_FUNCTION_HANDLE funcHandle, RFC_ERROR_INFO* errorInfoP){

    RFC_RC rc = RFC_OK;
    RFC_ERROR_INFO errorInfo;
    RFC_FUNCTION_DESC_HANDLE func_desc_handle;
    RFC_ABAP_NAME func_name;
    SAPNW_FUNC_DESC *dptr;
    SAPNW_FUNC *fptr;
    SV* sv_parameters;
    SV* sv_function;
    SV* sv_parm;
    SV* sv_name;
    SV* sv_func_name;
    SV* sv_value;
    SV* sv_row;
    SV* sv_result;
    SV* sv_ecode;
    SV* sv_ekey;
    SV* sv_emessage;
    HV* hv_parameters;
    HV* hv_error;
    HE* he_entry;
    AV* av_value;
    SAP_UC *p_name;
    SAP_UC *pkey;
    SAP_UC *pmessage;
    SAP_UC *useless_void;
    unsigned i, r, idx, tidx;
    unsigned tabLen;
    unsigned parm_count;
    RFC_PARAMETER_DESC parm_desc;
    RFC_TABLE_HANDLE tableHandle;
    RFC_STRUCTURE_HANDLE line;

    /* find out what Function Call this is */
    func_desc_handle = RfcDescribeFunction(funcHandle, &errorInfo);
    if (func_desc_handle == NULL) {
        croak("Problem with RfcDescribeFunction: %d / %s / %s\n",
                                errorInfo.code,
                                sv_pv(u16to8(errorInfo.key)),
                                sv_pv(u16to8(errorInfo.message)));
    }

    dptr = malloc(sizeof(SAPNW_FUNC_DESC));
    dptr->handle = func_desc_handle;
    dptr->conn_handle = NULL;

    rc = RfcGetFunctionName(dptr->handle, func_name, &errorInfo);
    if (rc != RFC_OK) {
        dptr->handle = NULL;
        free(dptr);
        croak("Problem with RfcGetFunctionName (%s): %d / %s / %s\n",
                                sv_pv(u16to8(func_name)),
                                errorInfo.code,
                                sv_pv(u16to8(errorInfo.key)),
                                sv_pv(u16to8(errorInfo.message)));
    }

    /* create a function call container to pass into the all back */
    sv_func_name = u16to8(func_name);
    sv_function = *hv_fetch(hv_global_server_functions, sv_pv(sv_func_name), SvCUR(sv_func_name), FALSE);
    if (!SvTRUE(sv_function)) {
        /* we dont know this function - so error */
        dptr->handle = NULL;
        free(dptr);
        sv_2mortal(sv_func_name);
        return RFC_NOT_FOUND;
    }

    fptr = malloc(sizeof(SAPNW_FUNC));
    fptr->handle = funcHandle;
    fptr->desc_handle = dptr;

    /* Get the parameter details */
    rc = RfcGetParameterCount(dptr->handle, &parm_count, &errorInfo);

    hv_parameters = newHV();

    for (i = 0; i < parm_count; i++) {
        rc = RfcGetParameterDescByIndex(dptr->handle, i, &parm_desc, &errorInfo);
        /* bail on a bad RfcGetParameterDescByIndex */
        if (rc != RFC_OK) {
            fptr->desc_handle = NULL;
            fptr->handle = NULL;
            free(fptr);
            dptr->conn_handle = NULL;
            dptr->handle = NULL;
            free(dptr);
            sv_2mortal(sv_func_name);
            croak("Problem in RfcGetParameterDescByIndex (%s): %d / %s / %s\n",
                                                        sv_pv(sv_func_name),
                                                        errorInfo.code,
                                                        sv_pv(u16to8(errorInfo.key)),
                                                        sv_pv(u16to8(errorInfo.message)));
        }

        /* create a new parameter obj */
//        fprintfU(stderr, cU("Parameter (%d): %s - direction: (%d) - type(%d) len: %d ulen: %d\n"), i, parm_desc.name, parm_desc.direction, parm_desc.type, parm_desc.nucLength, parm_desc.ucLength);
        sv_name = u16to8(parm_desc.name);
        switch(parm_desc.direction) {
            case RFC_IMPORT:
                hv_store_ent(hv_parameters, sv_name, sv_2mortal(SvREFCNT_inc(newSV(0))), 0);
                break;
            case RFC_EXPORT:
            case RFC_CHANGING:
                sv_value = get_parameter_value(sv_name, fptr);
                hv_store_ent(hv_parameters, sv_name, sv_2mortal(SvREFCNT_inc(sv_value)), 0);
                break;
            case RFC_TABLES:
                rc = RfcGetTable(fptr->handle, (p_name = u8to16(sv_name)), &tableHandle, &errorInfo);
                if (rc != RFC_OK) {
                    free(p_name);
                    fptr->desc_handle = NULL;
                    fptr->handle = NULL;
                    free(fptr);
                    dptr->conn_handle = NULL;
                    dptr->handle = NULL;
                    free(dptr);
                    sv_2mortal(sv_func_name);
                    croak("(get)Problem with RfcGetTable (%s): %d / %s / %s\n",
                                                    sv_pv(sv_name),
                                                    errorInfo.code,
                                                    sv_pv(u16to8(errorInfo.key)),
                                                    sv_pv(u16to8(errorInfo.message)));
                }
                rc = RfcGetRowCount(tableHandle, &tabLen, NULL);
                if (rc != RFC_OK) {
                    free(p_name);
                    fptr->desc_handle = NULL;
                    fptr->handle = NULL;
                    free(fptr);
                    dptr->conn_handle = NULL;
                    dptr->handle = NULL;
                    free(dptr);
                    sv_2mortal(sv_func_name);
                    croak("(get)Problem with RfcGetRowCount (%s): %d / %s / %s\n",
                                                    sv_pv(sv_name),
                                                    errorInfo.code,
                                                    sv_pv(u16to8(errorInfo.key)),
                                                    sv_pv(u16to8(errorInfo.message)));
                }
                av_value = newAV();
                for (r = 0; r < tabLen; r++){
                    RfcMoveTo(tableHandle, r, NULL);
                    line = RfcGetCurrentRow(tableHandle, NULL);
                    av_push(av_value, get_table_line(line));
                }
                free(p_name);
                hv_store_ent(hv_parameters, sv_name, newRV_noinc(sv_2mortal(SvREFCNT_inc((SV*)av_value))), 0);
                break;
        }
        sv_2mortal(sv_name);
    }

    /* do Perl callback */
    sv_parameters = newRV_noinc((SV*)hv_parameters);
    sv_result = function_callback(sv_function, sv_parameters);
    if (!SvTRUE(sv_result)) {
        /* the callback has asked for termination */
        fptr->desc_handle = NULL;
        fptr->handle = NULL;
        free(fptr);
        dptr->conn_handle = NULL;
        dptr->handle = NULL;
        free(dptr);
        sv_2mortal(sv_func_name);
        return RFC_CLOSED;
    } else {
        /* check for an error thrown - pass it on to RFC stack ... */
        hv_error =  (HV*)SvRV(sv_result);
        if(SvTYPE(hv_error) == SVt_PVHV) {
            sv_ecode = *hv_fetch(hv_error, (char *) "code", 4, FALSE);
            sv_ekey = *hv_fetch(hv_error, (char *) "key", 3, FALSE);
            sv_emessage = *hv_fetch(hv_error, (char *) "message", 7, FALSE);
            errorInfoP->code = RFC_ABAP_EXCEPTION;
            errorInfoP->group = SvIV(sv_ecode);
            pkey = u8to16(sv_ekey);
            useless_void = memcpyU(errorInfoP->key, pkey, (size_t)strlenU(pkey));
            free(pkey);
            pmessage = u8to16(sv_emessage);
            useless_void = memcpyU(errorInfoP->message, pmessage, (size_t)strlenU(pmessage));
            free(pmessage);
            fptr->desc_handle = NULL;
            fptr->handle = NULL;
            free(fptr);
            dptr->conn_handle = NULL;
            dptr->handle = NULL;
            free(dptr);
            sv_2mortal(sv_func_name);
            return RFC_ABAP_EXCEPTION;
        }
    }

    for (i = 0; i < parm_count; i++) {
        rc = RfcGetParameterDescByIndex(dptr->handle, i, &parm_desc, &errorInfo);
        /* bail on a bad RfcGetParameterDescByIndex */
        if (rc != RFC_OK) {
            fptr->desc_handle = NULL;
            fptr->handle = NULL;
            free(fptr);
            dptr->conn_handle = NULL;
            dptr->handle = NULL;
            free(dptr);
            sv_2mortal(sv_func_name);
            croak("Problem in RfcGetParameterDescByIndex (%s): %d / %s / %s\n",
                                                        sv_pv(sv_func_name),
                                                        errorInfo.code,
                                                        sv_pv(u16to8(errorInfo.key)),
                                                        sv_pv(u16to8(errorInfo.message)));
        }

        /* create a new parameter obj */
//        fprintfU(stderr, cU("Parameter (%d): %s - direction: (%d) - type(%d)\n"), i, parm_desc.name, parm_desc.direction, parm_desc.type);
        sv_name = u16to8(parm_desc.name);
        sv_value = *hv_fetch(hv_parameters, sv_pv(sv_name), SvCUR(sv_name), FALSE);
        switch(parm_desc.direction) {
        case RFC_EXPORT:
            break;
        case RFC_IMPORT:
        case RFC_CHANGING:
            set_parameter_value(fptr, sv_name, sv_value);
            break;
        case RFC_TABLES:
            if (! SvTRUE(sv_value)) {
                continue;
            }
            av_value =  (AV*)SvRV(sv_value);
            if(SvTYPE(av_value) != SVt_PVAV)
                croak("invoke outbound parameter (%s): not an ARRAY\n", SvPV(sv_name, SvCUR(sv_name)));
            rc = RfcGetTable(fptr->handle, (p_name = u8to16(sv_name)), &tableHandle, &errorInfo);
            if (rc != RFC_OK) {
                free(p_name);
                fptr->desc_handle = NULL;
                fptr->handle = NULL;
                free(fptr);
                dptr->conn_handle = NULL;
                dptr->handle = NULL;
                free(dptr);
                sv_2mortal(sv_func_name);
                croak("(set)Problem with RfcGetTable (%s): %d / %s / %s\n",
                                                sv_pv(sv_name),
                                                errorInfo.code,
                                                sv_pv(u16to8(errorInfo.key)),
                                                sv_pv(u16to8(errorInfo.message)));
            }
            tidx = av_len(av_value);
            for (r = 0; r <= tidx; r++) {
                sv_row = *av_fetch(av_value, r, FALSE);
                line = RfcAppendNewRow(tableHandle, &errorInfo);
                if (line == NULL) {
                    free(p_name);
                    fptr->desc_handle = NULL;
                    fptr->handle = NULL;
                    free(fptr);
                    dptr->conn_handle = NULL;
                    dptr->handle = NULL;
                    free(dptr);
                    sv_2mortal(sv_func_name);
                    croak("(set)Problem with RfcAppendNewRow (%s): %d / %s / %s\n",
                                                    sv_pv(sv_name),
                                                    errorInfo.code,
                                                    sv_pv(u16to8(errorInfo.key)),
                                                    sv_pv(u16to8(errorInfo.message)));
                }
                 set_table_line(line, sv_row);
            }
            av_undef(av_value);
            free(p_name);
            break;
        default:
            fprintf(stderr, "shouldnt get here!\n");
            exit(1);
            break;
        }
        sv_2mortal(sv_name);
    }


    /* send it home */
    sv_2mortal(sv_func_name);
    fptr->desc_handle = NULL;
    fptr->handle = NULL;
    free(fptr);
    dptr->handle = NULL;
    dptr->conn_handle = NULL;
    free(dptr);
    FREETMPS;
    return RFC_OK;
}


/* install a RFC Server function */
SV* SAPNWRFC_install(SV* sv_self, SV* sv_sysid){

    RFC_RC rc = RFC_OK;
    SAPNW_FUNC_DESC *dptr;
    RFC_ERROR_INFO errorInfo;
    SAP_UC * psysid;
    HV* h_self;
    SV* sv_func_def;

    h_self =  (HV*)SvRV( sv_self );
    if (hv_exists(h_self, (char *) "funcdef", 7)) {
        sv_func_def = *hv_fetch(h_self, (char *) "funcdef", 7, FALSE);
        if (SvTRUE(sv_func_def)) {
            dptr = INT2PTR(SAPNW_FUNC_DESC *, SvIV(sv_func_def));
        } else {
            croak("Corrupt function descriptor pointer in add_parameter\n");
        }
    } else {
        croak("Non-existent function descriptor pointer in add_parameter\n");
    }

    rc = RfcInstallServerFunction((psysid = u8to16(sv_sysid)), dptr->handle, myrfc_function_callback, &errorInfo);
    free(psysid);

    /* bail on a bad lookup */
    if (rc != RFC_OK) {
        croak("Problem with RfcInstallServerFunction (%s): %d / %s / %s\n",
                                        dptr->name,
                                        errorInfo.code,
                                        sv_pv(u16to8(errorInfo.key)),
                                        sv_pv(u16to8(errorInfo.message)));
    }

    /* store a global pointer the the func desc for the function call back */
    if (hv_global_server_functions == NULL) {
        hv_global_server_functions = newHV();
    }
    SvREFCNT_inc(sv_self);
    hv_store_ent(hv_global_server_functions, sv_2mortal(newSVpv(dptr->name, 0)), sv_self, 0);

    return newSViv(1);
}


/* Create a Function Module handle to be used for an RFC call */
SV * SAPNWRFC_invoke(SV* sv_func_call){

    SAPNW_CONN_INFO *cptr;
    SAPNW_FUNC_DESC *dptr;
    SAPNW_FUNC *fptr;
    RFC_RC rc = RFC_OK;
    RFC_ERROR_INFO errorInfo;
    RFC_TABLE_HANDLE tableHandle;
    SAP_UC *p_name;
    int i, r, idx, tidx;
    unsigned tabLen;
    RFC_STRUCTURE_HANDLE line;
    HV* h_self;
    HV* h_parameters;
    HV* hv_parm;
    HE* h_entry;
    SV* sv_parameters;
    SV* sv_function;
    SV* sv_name;
    SV* sv_parm;
    SV* sv_value;
    AV* av_value;
    SV* sv_row;

    h_self =  (HV*)SvRV( sv_func_call );
    if (hv_exists(h_self, (char *) "funccall", 8)) {
        sv_function = *hv_fetch(h_self, (char *) "funccall", 8, FALSE);
        if (SvTRUE(sv_function)) {
            fptr = INT2PTR(SAPNW_FUNC *, SvIV(sv_function));
        } else {
            croak("Corrupt Function Call pointer in invoke\n");
        }
    } else {
        croak("Non-existent Function Call pointer in invoke\n");
    }

    dptr = fptr->desc_handle;
    cptr = dptr->conn_handle;


    /* loop through all Input/Changing/tables parameters and set the values in the call */
    sv_parameters = *hv_fetch(h_self, (char *) "parameters", 10, FALSE);
    h_parameters =  (HV*)SvRV(sv_parameters);

    if(SvTYPE(h_parameters) != SVt_PVHV)
        croak("invoke: parameters not a HASH\n");

    idx = hv_iterinit(h_parameters);

    // some might not have parameters like RFC_PING
    for (i = 0; i < idx; i++) {
        h_entry = hv_iternext( h_parameters );
        sv_name = hv_iterkeysv( h_entry );
        sv_parm = hv_iterval(h_parameters, h_entry);

        switch(SvIV(parameter_attrib(sv_parm, "direction", &PL_sv_undef))) {
            case RFC_EXPORT:
                break;
            case RFC_IMPORT:
            case RFC_CHANGING:
                sv_value = parameter_attrib(sv_parm, "value", &PL_sv_undef);
                set_parameter_value(fptr, sv_name, sv_value);
                break;
            case RFC_TABLES:
                sv_value = parameter_attrib(sv_parm, "value", &PL_sv_undef);
                if (! SvTRUE(sv_value))
                    continue;
                av_value =  (AV*)SvRV(sv_value);
                if(SvTYPE(av_value) != SVt_PVAV)
                    croak("invoke outbound parameter (%s): not an ARRAY\n", SvPV(sv_name, SvCUR(sv_name)));
                rc = RfcGetTable(fptr->handle, (p_name = u8to16(sv_name)), &tableHandle, &errorInfo);
                if (rc != RFC_OK) {
                    croak("(set)Problem with RfcGetTable (%s): %d / %s / %s\n",
                                            sv_pv(sv_name),
                                            errorInfo.code,
                                            sv_pv(u16to8(errorInfo.key)),
                                            sv_pv(u16to8(errorInfo.message)));
                }
                tidx = av_len(av_value);
                for (r = 0; r <= tidx; r++) {
                    sv_row = *av_fetch(av_value, r, FALSE);
                     line = RfcAppendNewRow(tableHandle, &errorInfo);
                    if (line == NULL) {
                        croak("(set)Problem with RfcAppendNewRow (%s): %d / %s / %s\n",
                                            sv_pv(sv_name),
                                            errorInfo.code,
                                            sv_pv(u16to8(errorInfo.key)),
                                            sv_pv(u16to8(errorInfo.message)));
                    }
                    set_table_line(line, sv_row);
                }

                free(p_name);
                break;
            default:
                fprintf(stderr, "should get here!\n");
                exit(1);
                break;
        }
    }

    rc = RfcInvoke(cptr->handle, fptr->handle, &errorInfo);

    /* bail on a bad RFC Call */
    if (rc != RFC_OK) {
        croak("Problem Invoking RFC (%s): %d / %s / %s\n",
                                dptr->name,
                                errorInfo.code,
                                sv_pv(u16to8(errorInfo.key)),
                                sv_pv(u16to8(errorInfo.message)));
    }

    idx = hv_iterinit(h_parameters);

    for (i = 0; i < idx; i++) {
        h_entry = hv_iternext( h_parameters );
        sv_name = hv_iterkeysv( h_entry );
        sv_parm = hv_iterval(h_parameters, h_entry);
        hv_parm =  (HV*)SvRV(sv_parm);
        switch(SvIV(parameter_attrib(sv_parm, "direction", &PL_sv_undef))) {
            case RFC_IMPORT:
                break;
            case RFC_EXPORT:
            case RFC_CHANGING:
                sv_value = get_parameter_value(sv_name, fptr);
                hv_store_ent(hv_parm, sv_2mortal(newSVpv("value", 0)), sv_2mortal(SvREFCNT_inc(sv_value)), 0);
                break;
            case RFC_TABLES:
                rc = RfcGetTable(fptr->handle, (p_name = u8to16(sv_name)), &tableHandle, &errorInfo);
                if (rc != RFC_OK) {
                    croak("(get)Problem with RfcGetTable (%s): %d / %s / %s\n",
                                                sv_pv(sv_name),
                                                errorInfo.code,
                                                sv_pv(u16to8(errorInfo.key)),
                                                sv_pv(u16to8(errorInfo.message)));
                }
                rc = RfcGetRowCount(tableHandle, &tabLen, NULL);
                if (rc != RFC_OK) {
                    croak("(get)Problem with RfcGetRowCount (%s): %d / %s / %s\n",
                                                sv_pv(sv_name),
                                                errorInfo.code,
                                                sv_pv(u16to8(errorInfo.key)),
                                                sv_pv(u16to8(errorInfo.message)));
                }
                av_value = newAV();
                for (r = 0; r < tabLen; r++){
                    RfcMoveTo(tableHandle, r, NULL);
                    line = RfcGetCurrentRow(tableHandle, NULL);
                    av_push(av_value, get_table_line(line));
                }
                free(p_name);
                hv_store_ent(hv_parm, sv_2mortal(newSVpv("value", 0)), newRV_noinc(sv_2mortal(SvREFCNT_inc((SV*)av_value))), 0);
                break;
        }
    }

    return newSViv(1);
}


MODULE = SAPNW::Connection    PACKAGE = SAPNW::Connection    PREFIX = SAPNWRFC_

PROTOTYPES: DISABLE


SV *
SAPNWRFC_connect (sv_self)
    SV *    sv_self

SV *
SAPNWRFC_disconnect (sv_self)
    SV *    sv_self

SV *
SAPNWRFC_connection_attributes (sv_self)
    SV *    sv_self

SV *
SAPNWRFC_function_lookup (sv_self, sv_func)
    SV *    sv_self
    SV *    sv_func

SV *
SAPNWRFC_destroy_function_descriptor (sv_self)
    SV *    sv_self

SV *
SAPNWRFC_destroy_function_call (sv_self)
    SV *    sv_self

SV *
SAPNWRFC_create_function_call (sv_func_desc)
    SV *    sv_func_desc

SV *
SAPNWRFC_create_function_descriptor (sv_func)
    SV *    sv_func

SV *
SAPNWRFC_add_parameter (sv_self, sv_parameter)
    SV *    sv_self
    SV *    sv_parameter

SV *
SAPNWRFC_set_parameter_active (sv_func_call, sv_name, sv_active)
    SV *    sv_func_call
    SV *    sv_name
    SV *    sv_active

SV *
SAPNWRFC_invoke (sv_func_call)
    SV *    sv_func_call

SV *
SAPNWRFC_accept (sv_self, sv_wait, sv_global_callback)
    SV *    sv_self
    SV *    sv_wait
    SV *    sv_global_callback

SV *
SAPNWRFC_process (sv_self, sv_wait)
    SV *    sv_self
    SV *    sv_wait

SV *
SAPNWRFC_install (sv_self, sv_sysid)
    SV *    sv_self
    SV *    sv_sysid

