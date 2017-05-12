/* $Id: oci.c,v 1.13 2006/04/05 20:38:58 jeff Exp $ */

#include <oci.h>
#include <EXTERN.h>
#include <perl.h>
#include "extproc_perl.h"

/* int ep_OCIExtProcGetEnv(EP_CONTEXT *c)
 * wrapper around oracle's OCIExtProcGetEnv
 * we can't call getenv twice in the same transaction, so we need to save
 * our handles for later use by DBI
 */
int ep_OCIExtProcGetEnv(EP_CONTEXT *c)
{
    int err;

    dTHX;

    if (!c->connected) {
        err = OCIExtProcGetEnv(c->oci_context.ctx,
            &c->oci_context.envhp, &c->oci_context.svchp,
            &c->oci_context.errhp);
        if (err == OCI_SUCCESS || err == OCI_SUCCESS_WITH_INFO) {
            c->connected = 1;
        }
    }
    else {
        /* return success if we've already connected */
        err = OCI_SUCCESS;
    }
    return(err);
}

/* fetch current subroutine version from database */
/* returns -1 and throws an exception on error */
/* returns 0 if version not available */
/* returns positive version if found */
int fetch_sub_version(EP_CONTEXT *c, char *name)
{
    char sql[255];
    ocictx *this_ctxp = &(c->oci_context);
    OCIDefine *def1 = (OCIDefine *) 0;
    OCIBind *bind1 = (OCIBind *) 0;
    OCIInd ind1;
    int version, err;

    EP_DEBUGF(c, "IN fetch_sub_version(%p, \"%s\")", c, name);

    err = ep_OCIExtProcGetEnv(c);

    if (err) {
        ora_exception(c,"getenv");
        return(-1);
    }

    snprintf(sql, 255, "select version from %s where name = :name", c->code_table);

    err = OCIHandleAlloc(this_ctxp->envhp,
        (dvoid **)&this_ctxp->stmtp,
        OCI_HTYPE_STMT,
        0,
        0);

    if (err) {
        ora_exception(c,"handlealloc");
        return(-1);
    }

    err = OCIStmtPrepare(this_ctxp->stmtp,
        this_ctxp->errhp,
        (text *) sql,
        strlen(sql),
        OCI_NTV_SYNTAX,
        OCI_DEFAULT);

    if (err) {
        ora_exception(c,"prepare");
        return(-1);
    }

    err = OCIDefineByPos(this_ctxp->stmtp,
        &def1,
        this_ctxp->errhp,
        1,
        &version,
        sizeof(int),
        SQLT_INT,
        &ind1,
        (dvoid *) 0,
        (dvoid *) 0,
        OCI_DEFAULT);

    if ((err != OCI_SUCCESS) && (err != OCI_SUCCESS_WITH_INFO)) {
        ora_exception(c,"define3");
        return(-1);
    }

    err = OCIBindByPos(this_ctxp->stmtp,
        &bind1,
        this_ctxp->errhp,
        1,
        name,
        strlen(name),
        SQLT_CHR,
        (dvoid *) 0,
        (ub2 *) 0,
        (ub2 *) 0,
        (ub4) 0,
        (ub4 *) 0,
        OCI_DEFAULT);

    if ((err != OCI_SUCCESS) && (err != OCI_SUCCESS_WITH_INFO)) {
        ora_exception(c,"bind");
        return(err);
    }

    err = OCIStmtExecute(this_ctxp->svchp,
        this_ctxp->stmtp,
        this_ctxp->errhp,
        1,
        0,
        NULL,
        NULL,
        OCI_DEFAULT);

    if ((err != OCI_SUCCESS) && (err != OCI_SUCCESS_WITH_INFO)) {
        /* don't throw an exception for a valid empty result */
        if (err != OCI_NO_DATA) {
            ora_exception(c,"exec");
            return(-1);
        }
        OCIHandleFree(this_ctxp->stmtp, OCI_HTYPE_STMT);
        return(0);
    }

    err = OCIHandleFree(this_ctxp->stmtp, OCI_HTYPE_STMT);
    if ((err != OCI_SUCCESS) && (err != OCI_SUCCESS_WITH_INFO)) {
        ora_exception(c,"OCIHandleFree");
        return(-1);
    }

    return(version);
}


int fetch_code(EP_CONTEXT *c, EP_CODE *code, char *name)
{
    char sql[255], *buf;
    ocictx *this_ctxp = &(c->oci_context);
    OCIDefine *def1 = (OCIDefine *) 0;
    OCIDefine *def2 = (OCIDefine *) 0;
    OCIDefine *def3 = (OCIDefine *) 0;
    OCIBind *bind1 = (OCIBind *) 0;
    OCIInd ind1, ind2, ind3;
    OCILobLocator *lobl;
    int err, loblen, amtp;
    boolean flag;
    
    EP_DEBUGF(c, "IN fetch_code(%p, %p, \"%s\")", c, code, name);

    err = ep_OCIExtProcGetEnv(c);

    if (err) {
        ora_exception(c,"getenv");
        return(err);
    }

    snprintf(sql, 255, "select code, language, version from %s where name = :name", c->code_table);

    err = OCIHandleAlloc(this_ctxp->envhp,
        (dvoid **)&this_ctxp->stmtp,
        OCI_HTYPE_STMT,
        0,
        0);

    if (err) {
        ora_exception(c,"handlealloc");
        return(err);
    }

    err = OCIStmtPrepare(this_ctxp->stmtp,
        this_ctxp->errhp,
        (text *) sql,
        strlen(sql),
        OCI_NTV_SYNTAX,
        OCI_DEFAULT);

    if (err) {
        ora_exception(c,"prepare");
        return(err);
    }

    err = OCIDescriptorAlloc(this_ctxp->envhp, (dvoid *)&lobl,
        OCI_DTYPE_LOB, 0, 0);

    if (err) {
        ora_exception(c,"OCIDescriptorAlloc");
        return(err);
    }

    err = OCIDefineByPos(this_ctxp->stmtp,
        &def1,
        this_ctxp->errhp,
        1,
        &lobl,
        -1,
        SQLT_CLOB,
        &ind1,
        (dvoid *) 0,
        (dvoid *) 0,
        OCI_DEFAULT);

    if ((err != OCI_SUCCESS) && (err != OCI_SUCCESS_WITH_INFO)) {
        ora_exception(c, "define1");
        return(err);
    }

    err = OCIDefineByPos(this_ctxp->stmtp,
        &def2,
        this_ctxp->errhp,
        2,
        code->language,
        255,
        SQLT_STR,
        &ind2,
        (dvoid *) 0,
        (dvoid *) 0,
        OCI_DEFAULT);

    if ((err != OCI_SUCCESS) && (err != OCI_SUCCESS_WITH_INFO)) {
        ora_exception(c,"define2");
        return(err);
    }

    err = OCIDefineByPos(this_ctxp->stmtp,
        &def3,
        this_ctxp->errhp,
        3,
        &(code->version),
        sizeof(int),
        SQLT_INT,
        &ind3,
        (dvoid *) 0,
        (dvoid *) 0,
        OCI_DEFAULT);

    if ((err != OCI_SUCCESS) && (err != OCI_SUCCESS_WITH_INFO)) {
        ora_exception(c,"define3");
        return(err);
    }

    err = OCIBindByPos(this_ctxp->stmtp,
        &bind1,
        this_ctxp->errhp,
        1,
        name,
        strlen(name),
        SQLT_CHR,
        (dvoid *) 0,
        (ub2 *) 0,
        (ub2 *) 0,
        (ub4) 0,
        (ub4 *) 0,
        OCI_DEFAULT);

    if ((err != OCI_SUCCESS) && (err != OCI_SUCCESS_WITH_INFO)) {
        ora_exception(c,"bind");
        return(err);
    }

    err = OCIStmtExecute(this_ctxp->svchp,
        this_ctxp->stmtp,
        this_ctxp->errhp,
        1,
        0,
        NULL,
        NULL,
        OCI_DEFAULT);

    if ((err != OCI_SUCCESS) && (err != OCI_SUCCESS_WITH_INFO)) {
        /* don't throw an exception for a valid empty result */
        if (err != OCI_NO_DATA) {
            ora_exception(c,"exec");
        }
        OCIHandleFree(this_ctxp->stmtp, OCI_HTYPE_STMT);
        return(err);
    }

    err = OCIHandleFree(this_ctxp->stmtp, OCI_HTYPE_STMT);
    if ((err != OCI_SUCCESS) && (err != OCI_SUCCESS_WITH_INFO)) {
        ora_exception(c,"OCIHandleFree");
        return(err);
    }

    /* XXX - IS THIS USED ANYMORE??? */
    /* if code is NULL, this is a stub -- code is in bootstrap file */
    if (ind1 == OCI_IND_NULL) {
        EP_DEBUG(c, "code is NULL -- will check symbol table for CV");
        code->code = NULL;
    }
    else {
        err = OCILobLocatorIsInit(this_ctxp->envhp, this_ctxp->errhp, lobl, &flag);
        if ((err != OCI_SUCCESS) && (err != OCI_SUCCESS_WITH_INFO)) {
            ora_exception(c, "OCILobLocatorIsInit");
            return(err);
        }
        if (!flag) {
            ora_exception(c, "LOB locator is not initialized");
            return(err);
        }
        err = OCILobGetLength(this_ctxp->svchp, this_ctxp->errhp, lobl,
            &loblen);
        if ((err != OCI_SUCCESS) && (err != OCI_SUCCESS_WITH_INFO)) {
            ora_exception(c, "OCILobGetLength");
            return(err);
        }
        if (loblen > c->max_code_size) {
            ora_exception(c, "code too large for buffer");
            return(-1);
        }
        amtp = loblen;
        buf = OCIExtProcAllocCallMemory(this_ctxp->ctx, amtp+1);
        err = OCILobRead(this_ctxp->svchp, this_ctxp->errhp, lobl,
            &amtp, 1, (dvoid *)buf, c->max_code_size, 0, 0, 0,
            SQLCS_IMPLICIT);
        if ((err != OCI_SUCCESS) && (err != OCI_SUCCESS_WITH_INFO)) {
            ora_exception(c, "OCILobRead");
            return(err);
        }
        buf[amtp] = '\0';

        code->code = buf;
    }

    return(OCI_SUCCESS);
}

int get_sessionid(EP_CONTEXT *c, int *sessionid)
{
    char *sql;
    ocictx *this_ctxp = &(c->oci_context);
    OCIDefine *def1 = (OCIDefine *) 0;
    int err;
    
    EP_DEBUGF(c, "IN get_sessionid(%p, %p)", c, sessionid);

    err = ep_OCIExtProcGetEnv(c);

    if (err) {
        ora_exception(c,"getenv");
        return(err);
    }

    err = OCIHandleAlloc(this_ctxp->envhp,
        (dvoid **)&this_ctxp->stmtp,
        OCI_HTYPE_STMT,
        0,
        0);

    if (err) {
        ora_exception(c,"handlealloc");
        return(err);
    }

    sql = "select USERENV('sessionid') from dual";
    err = OCIStmtPrepare(this_ctxp->stmtp,
        this_ctxp->errhp,
        (text *) sql,
        strlen(sql),
        OCI_NTV_SYNTAX,
        OCI_DEFAULT);

    if (err) {
        ora_exception(c,"prepare");
        return(err);
    }

    err = OCIDefineByPos(this_ctxp->stmtp,
        &def1,
        this_ctxp->errhp,
        1,
        sessionid,
        sizeof(int),
        SQLT_INT,
        (dvoid *) 0,
        (dvoid *) 0,
        (dvoid *) 0,
        OCI_DEFAULT);

    if ((err != OCI_SUCCESS) && (err != OCI_SUCCESS_WITH_INFO)) {
        ora_exception(c,"define1");
        return(err);
    }

    err = OCIStmtExecute(this_ctxp->svchp,
        this_ctxp->stmtp,
        this_ctxp->errhp,
        1,
        0,
        NULL,
        NULL,
        OCI_DEFAULT);

    if ((err != OCI_SUCCESS) && (err != OCI_SUCCESS_WITH_INFO)) {
        ora_exception(c,"exec");
        return(err);
    }

    err = OCIHandleFree(this_ctxp->stmtp, OCI_HTYPE_STMT);
    if ((err != OCI_SUCCESS) && (err != OCI_SUCCESS_WITH_INFO)) {
        ora_exception(c,"OCIHandleFree");
        return(err);
    }

    return(OCI_SUCCESS);
}

int get_dbname(EP_CONTEXT *c, char *dbname)
{
    char *sql;
    ocictx *this_ctxp = &(c->oci_context);
    OCIDefine *def1 = (OCIDefine *) 0;
    int err;
    
    EP_DEBUGF(c, "IN get_dbname(%p, %p)", c, dbname);

    err = ep_OCIExtProcGetEnv(c);

    if (err) {
        ora_exception(c,"getenv");
        return(err);
    }

    err = OCIHandleAlloc(this_ctxp->envhp,
        (dvoid **)&this_ctxp->stmtp,
        OCI_HTYPE_STMT,
        0,
        0);

    if (err) {
        ora_exception(c,"handlealloc");
        return(err);
    }

    sql = "select ora_database_name from dual";
    err = OCIStmtPrepare(this_ctxp->stmtp,
        this_ctxp->errhp,
        (text *) sql,
        strlen(sql),
        OCI_NTV_SYNTAX,
        OCI_DEFAULT);

    if (err) {
        ora_exception(c,"prepare");
        return(err);
    }

    err = OCIDefineByPos(this_ctxp->stmtp,
        &def1,
        this_ctxp->errhp,
        1,
        (text *)dbname,
        255, /* should be max length of database name */
        SQLT_STR,
        (dvoid *) 0,
        (dvoid *) 0,
        (dvoid *) 0,
        OCI_DEFAULT);

    if ((err != OCI_SUCCESS) && (err != OCI_SUCCESS_WITH_INFO)) {
        ora_exception(c,"define1");
        return(err);
    }

    err = OCIStmtExecute(this_ctxp->svchp,
        this_ctxp->stmtp,
        this_ctxp->errhp,
        1,
        0,
        NULL,
        NULL,
        OCI_DEFAULT);

    if ((err != OCI_SUCCESS) && (err != OCI_SUCCESS_WITH_INFO)) {
        ora_exception(c,"exec");
        return(err);
    }

    err = OCIHandleFree(this_ctxp->stmtp, OCI_HTYPE_STMT);
    if ((err != OCI_SUCCESS) && (err != OCI_SUCCESS_WITH_INFO)) {
        ora_exception(c,"OCIHandleFree");
        return(err);
    }

    return(OCI_SUCCESS);
}

/* convert string to OCIDate */
OCIDate *string_to_ocidate(EP_CONTEXT *c, char *s, char *fmt)
{
    OCIDate *d;
    int err;
    ocictx *this_ctxp = &(c->oci_context);

    err = ep_OCIExtProcGetEnv(c);
    if ((err != OCI_SUCCESS) && (err != OCI_SUCCESS_WITH_INFO)) {
        ora_exception(c,"getenv");
        return(NULL);
    }

    err = OCIDateFromText(
        this_ctxp->errhp,
        (const text *)(s), strlen(s),
        (const text *)(fmt), strlen(fmt),
        NULL,
        0,
        d);

    if ((err != OCI_SUCCESS) && (err != OCI_SUCCESS_WITH_INFO)) {
        ora_exception(c,"OCIDateFromText");
        return(NULL);
    }

    return(d);
}

/* convert OCIDate to string */
char *ocidate_to_string(EP_CONTEXT *c, OCIDate *d, char *fmt)
{
    char *s;
    int err, len;
    ocictx *this_ctxp = &(c->oci_context);

    err = ep_OCIExtProcGetEnv(c);
    if ((err != OCI_SUCCESS) && (err != OCI_SUCCESS_WITH_INFO)) {
        ora_exception(c,"getenv");
        return(NULL);
    }

    len = 255;
    s = OCIExtProcAllocCallMemory(c->oci_context.ctx, len);

    err = OCIDateToText(
        this_ctxp->errhp,
        d,
        (const text *)(fmt), strlen(fmt),
        NULL,
        0,
        &len,
        (text *)s
    );

    if ((err != OCI_SUCCESS) && (err != OCI_SUCCESS_WITH_INFO)) {
        ora_exception(c,"OCIDateToText");
        s = NULL;
    }

    return(s);
}
