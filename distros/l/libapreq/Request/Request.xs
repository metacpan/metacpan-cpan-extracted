/* Copyright 2000-2004  The Apache Software Foundation
**
** Licensed under the Apache License, Version 2.0 (the "License");
** you may not use this file except in compliance with the License.
** You may obtain a copy of the License at
**
**     http://www.apache.org/licenses/LICENSE-2.0
**
** Unless required by applicable law or agreed to in writing, software
** distributed under the License is distributed on an "AS IS" BASIS,
** WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
** See the License for the specific language governing permissions and
** limitations under the License.
*/

#define PERL_NO_GET_CONTEXT     /* we want efficiency */

#ifdef WIN32

#ifdef uid_t
#define apache_uid_t uid_t
#undef uid_t
#endif
#define uid_t apache_uid_t

#ifdef gid_t
#define apache_gid_t gid_t
#undef gid_t
#endif
#define gid_t apache_gid_t

#ifdef stat
#define apache_stat stat
#undef stat
#endif

#ifdef lstat
#define apache_lstat lstat
#undef lstat
#endif

#ifdef isnan
#define apache_isnan isnan
#undef isnan
#endif

#ifdef sleep
#define apache_sleep sleep
#undef sleep
#endif

#endif /* WIN32 */

#undef __attribute__
#include "mod_perl.h"
#include "apache_request.h"
#include "patchlevel.h"

#ifdef WIN32

#undef uid_t
#ifdef apache_uid_t
#define uid_t apache_uid_t
#undef apache_uid_t
#endif

#undef gid_t
#ifdef apache_gid_t
#define gid_t apache_gid_t
#undef apache_gid_t
#endif

#ifdef apache_isnan
#undef isnan
#define isnan apache_isnan
#undef apache_isnan
#endif

#ifdef apache_lstat
#undef lstat
#define lstat apache_lstat
#undef apache_lstat
#endif

#ifdef apache_stat
#undef stat
#define stat apache_stat
#undef apache_stat
#endif

#ifdef apache_sleep
#undef sleep
#define sleep apache_sleep
#undef apache_sleep
#endif

#endif /* WIN32 */

typedef ApacheRequest * Apache__Request;
typedef ApacheUpload  * Apache__Upload;

typedef struct {
    SV *data;
    SV *sub;
    PerlInterpreter *perl;
} UploadHook;

#define XsUploadHook       ((UploadHook *)RETVAL->hook_data)
#define XsUploadHookNew(p) (void *)ap_pcalloc(p, sizeof(UploadHook))

#ifdef USE_ITHREADS
#define XsUploadHookNew_perl XsUploadHook->perl = aTHX
#else
#define XsUploadHookNew_perl 
#endif

#define XsUploadHookSet(slot, sv) \
     if (RETVAL->hook_data) { \
         if (XsUploadHook->slot) { \
             SvREFCNT_dec(XsUploadHook->slot); \
         } \
     } \
     else { \
         RETVAL->hook_data = XsUploadHookNew(r->pool); \
         XsUploadHookNew_perl; \
         ap_register_cleanup(r->pool, (void*)XsUploadHook, \
                             upload_hook_cleanup, ap_null_cleanup); \
     } \
     XsUploadHook->slot = SvREFCNT_inc(sv)

#define ApacheUpload_fh(upload)       upload->fp
#define ApacheUpload_name(upload)     upload->name
#define ApacheUpload_filename(upload) upload->filename
#define ApacheUpload_next(upload)     upload->next
#define ApacheUpload_tempname(upload) upload->tempname

#ifdef PerlIO
typedef PerlIO * ApreqInputStream;

/* XXX: or should this be #ifdef PERL_IMPLICIT_SYS ? */
#ifdef WIN32
#   ifndef PerlIO_importFILE
#      define PerlIO_importFILE(fp,flags)	(PerlIO*)fp
#   endif
#endif

#ifdef SFIO
#undef PerlIO_importFILE
#define PerlIO_importFILE(fp,flags) 	(PerlIO*)fp
#endif /*SFIO*/

#else /*PerlIO not defined*/

typedef FILE * ApreqInputStream;
#define PerlIO_importFILE(fp,flags) 	fp
#define PerlIO_write(a,b,c)  		fwrite((b),1,(c),(a))

#endif /*PerlIO*/

static char *r_keys[] = { "_r", "r", NULL };

static SV *r_key_sv(pTHX_ SV *in)
{
    SV *sv;
    int i;

    for (i=0; r_keys[i]; i++) {
	int klen = strlen(r_keys[i]);
	if(hv_exists((HV*)SvRV(in), r_keys[i], klen) &&
	   (sv = *hv_fetch((HV*)SvRV(in), 
			   r_keys[i], klen, FALSE)))
	{
	    return sv;
	}
    }

    return Nullsv;
}

static ApacheRequest *sv_2apreq(pTHX_ SV *sv)
{
    if (SvROK(sv) && sv_derived_from(sv, "Apache::Request")) { 
	SV *obj = sv;

	switch (SvTYPE(SvRV(obj))) {
	case SVt_PVHV :
            do {
                obj = r_key_sv(aTHX_ obj);
            } while (SvROK(obj) && (SvTYPE(SvRV(obj)) == SVt_PVHV));
	    break;
	default:
	    break;
	};
	return (ApacheRequest *)SvIV((SV*)SvRV(obj)); 
    }
    else {
	return ApacheRequest_new(perl_request_rec(NULL));
    }
} 

static SV *upload_bless(pTHX_ ApacheUpload *upload) 
{ 
    SV *sv = newSV(0);  
    sv_setref_pv(sv, "Apache::Upload", (void*)upload);  
    return sv; 
} 

static int upload_hook(void *ptr, char *buf, int len, ApacheUpload *upload)
{
    UploadHook *hook = (UploadHook *)ptr;
#ifdef USE_ITHREADS
    dTHXa(hook->perl);
#endif
    
    if (!(upload->fp || ApacheRequest_tmpfile(upload->req, upload)))
        return -1; /* error */

    {
    	SV *sv;
    	dSP;

    	PUSHMARK(SP);
    	EXTEND(SP, 4);
        ENTER;
    	SAVETMPS;

    	sv = sv_newmortal();
    	sv_setref_pv(sv, "Apache::Upload", (void*)upload);
    	PUSHs(sv);

    	sv = sv_2mortal(newSVpvn(buf,len));
    	SvTAINT(sv);
    	PUSHs(sv);

    	sv = sv_2mortal(newSViv(len));
    	SvTAINT(sv);
    	PUSHs(sv);

    	PUSHs(hook->data);

    	PUTBACK;
    	perl_call_sv(hook->sub, G_EVAL|G_DISCARD);
    	FREETMPS;
    	LEAVE;
    }

    if (SvTRUE(ERRSV))
        return -1;

    return fwrite(buf, 1, len, upload->fp);
}

static void upload_hook_cleanup(void *ptr)
{
    UploadHook *hook = (UploadHook *)ptr;
#ifdef USE_ITHREADS
    dTHXa(hook->perl);
#endif
    
    if (hook->sub) {
        SvREFCNT_dec(hook->sub);
        hook->sub = Nullsv;
    }
    if (hook->data) {
        SvREFCNT_dec(hook->data);
        hook->data = Nullsv;
    }
}

#define upload_push(upload) \
    XPUSHs(sv_2mortal(upload_bless(upload))) 

static void apreq_add_magic(pTHX_ SV *sv, SV *obj, ApacheRequest *req)
{
    sv_magic(SvRV(sv), obj, '~', "dummy", -1);
    SvMAGIC(SvRV(sv))->mg_ptr = (char *)req->r;
}

#ifdef CGI_COMPAT
static void register_uploads (pTHX_ ApacheRequest *req) {
    ApacheUpload *upload;

    for (upload = req->upload; upload; upload = upload->next) {
	if(upload->fp && upload->filename) {
	    GV *gv = gv_fetchpv(upload->filename, TRUE, SVt_PVIO);
	    if (do_open(gv, "<&", 2, FALSE, 0, 0, upload->fp)) { 
		ap_register_cleanup(req->r->pool, (void*)gv, 
				    apreq_close_handle, ap_null_cleanup);
	    } 
	}
    }
}
#else
#define register_uploads(req)
#endif

MODULE = Apache::Request    PACKAGE = Apache::Request   PREFIX = ApacheRequest_

PROTOTYPES: DISABLE 

BOOT:
    av_push(perl_get_av("Apache::Request::ISA",TRUE), newSVpv("Apache",6));

Apache::Request
ApacheRequest_new(class, r, ...)
    SV *class
    Apache r

    PREINIT:
    int i;
    SV *robj;
	
    CODE:
    class = class; /* -Wall */ 
    robj = ST(1);
    RETVAL = ApacheRequest_new(r);
    register_uploads(aTHX_ RETVAL);

    for (i=2; i<items; i+=2) {
        char *key = SvPV(ST(i),na);

        switch (toLOWER(*key)) {
          case 'd':
            if (strcaseEQ(key, "disable_uploads")) {
                RETVAL->disable_uploads = (int)SvIV(ST(i+1));
                break;
            }

          case 'h':
            if (strcaseEQ(key, "hook_data")) {
                XsUploadHookSet(data, ST(i+1));
                break;
            }

          case 'p':
            if (strcaseEQ(key, "post_max")) {
                RETVAL->post_max = (int)SvIV(ST(i+1));
                break;
            }

          case 't':
            if (strcaseEQ(key, "temp_dir")) {
                RETVAL->temp_dir = ap_pstrdup(r->pool,SvPV(ST(i+1), PL_na));
                break;
            }

          case 'u':
            if (strcaseEQ(key, "upload_hook")) {
                XsUploadHookSet(sub, ST(i+1));
                RETVAL->upload_hook = upload_hook;
                break;
            }

          default:
            croak("[libapreq] unknown attribute: `%s'", key);
        }
    }

    OUTPUT:
    RETVAL

    CLEANUP:
    apreq_add_magic(aTHX_ ST(0), robj, RETVAL);

char *
ApacheRequest_script_name(req)
    Apache::Request req

int
ApacheRequest_parse(req)
    Apache::Request req


Apache::Table
ApacheRequest_query_params(req)
    Apache::Request req

    PREINIT:
    table *parms;

    CODE:
    parms = ApacheRequest_query_params(req, req->r->pool);
    ST(0) = mod_perl_tie_table(parms);

Apache::Table
ApacheRequest_post_params(req)
    Apache::Request req

    PREINIT:
    table *parms;

    CODE:
    parms = ApacheRequest_post_params(req, req->r->pool);
    ST(0) = mod_perl_tie_table(parms);


void
ApacheRequest_parms(req, parms=NULL)
    Apache::Request req
    Apache::Table parms

    CODE:
    if (parms) {
        req->parms = parms->utable;
        req->parsed = 1;
    }
    else {
        ApacheRequest_parse(req);
    }
    ST(0) = mod_perl_tie_table(req->parms);

void
ApacheRequest_param(req, key=NULL, sv=Nullsv)
    Apache::Request req	
    char *key
    SV *sv

    PPCODE:
    if ( !req->parsed ) ApacheRequest_parse(req);

    if (key) {

	if (sv != Nullsv) {

	    if (SvROK(sv) && SvTYPE(SvRV(sv)) == SVt_PVAV) {
	    	I32 i;
	    	AV *av = (AV*)SvRV(sv);
	    	const char *val;

            	ap_table_unset(req->parms, key);
	    	for (i=0; i<=AvFILL(av); i++) {
		    val = (const char *)SvPV(*av_fetch(av, i, FALSE),PL_na);
	            ap_table_add(req->parms, key, val);
	    	}
	    }
            else ap_table_set(req->parms, key, (const char *)SvPV(sv, PL_na));
	}

	switch (GIMME_V) {

        case G_SCALAR:			/* return (first) parameter value */
	    {
	    	const char *val = ap_table_get(req->parms, key);
	    	if (val) XPUSHs(sv_2mortal(newSVpv((char*)val,0)));
	    	else XSRETURN_UNDEF;
	    }
	    break;

	case G_ARRAY:			/* return list of parameter values */
	    {
  	        I32 i;
	        array_header *arr  = ap_table_elts(req->parms);
	        table_entry *elts = (table_entry *)arr->elts;
	        for (i = 0; i < arr->nelts; ++i) {
	            if (elts[i].key && strcaseEQ(elts[i].key, key))
	            	XPUSHs(sv_2mortal(newSVpv(elts[i].val,0)));
	        }
	    }
	    break;

	default:
            XSRETURN_UNDEF;
	} 
    } 
    else {		

	switch (GIMME_V) {

	case G_SCALAR:	    		/* like $apr->parms */
	    ST(0) = mod_perl_tie_table(req->parms);
	    XSRETURN(1); 
	    break;

	case G_ARRAY:			/* return list of unique keys */
            {
            	I32 i;
	    	array_header *arr  = ap_table_elts(req->parms);
	    	table_entry *elts = (table_entry *)arr->elts;
	    	for (i = 0; i < arr->nelts; ++i) {
		    I32 j;
	           if (!elts[i].key) continue;
		    /* simple but inefficient uniqueness check */
		    for (j = 0; j < i; ++j) { 
		        if (strcaseEQ(elts[i].key, elts[j].key))
			    break;
		    }
	            if ( i == j )
	                XPUSHs(sv_2mortal(newSVpv(elts[i].key,0)));
	        }
            }
	    break;

	default:
	    XSRETURN_UNDEF;
 	}
    }

void
ApacheRequest_upload(req, sv=Nullsv)
    Apache::Request req
    SV *sv

    PREINIT:
    ApacheUpload *uptr;

    PPCODE:
    if (sv && SvOBJECT(sv) && sv_isa(sv, "Apache::Upload")) {
        req->upload = (ApacheUpload *)SvIV((SV*)SvRV(sv));
        XSRETURN_EMPTY;
    }

    if ( !req->parsed ) ApacheRequest_parse(req);

    if (GIMME == G_SCALAR) {
        STRLEN n_a;
        char *name = sv ? SvPV(sv, n_a) : NULL;

	if (name) {
	    uptr = ApacheUpload_find(req->upload, name);
	}
	else {
	    uptr = req->upload;
	}

	if (!uptr)
            XSRETURN_UNDEF;

	upload_push(aTHX_ uptr);
    }
    else {
	for (uptr = req->upload; uptr; uptr = uptr->next)
	    upload_push(aTHX_ uptr);
    }

char *
ApacheRequest_expires(req, time_str)
    Apache::Request req
    char *time_str

MODULE = Apache::Request    PACKAGE = Apache::Upload   PREFIX = ApacheUpload_

PROTOTYPES: DISABLE 

ApreqInputStream
ApacheUpload_fh(upload)
    Apache::Upload upload

    PREINIT:
    int fd;
    FILE *fp;

    CODE:
    fp = ApacheUpload_fh(upload);
    if (fp == NULL)
        XSRETURN_UNDEF;
#if PERL_REVISION == 5 && PERL_VERSION > 7
    fd = PerlLIO_dup(fileno(fp));
    /* XXX: user should check errno on undef returns */

    if (fd < 0) 
        XSRETURN_UNDEF;

    if ( !(RETVAL = PerlIO_fdopen(fd, "rb")) )
	XSRETURN_UNDEF;
#else
    if (  ( RETVAL = PerlIO_importFILE(fp,0) ) == NULL  )
	    XSRETURN_UNDEF;
#endif

    OUTPUT:
    RETVAL

    CLEANUP:
    /* XXX: there may be a leak/segfault in here somewhere */
#if PERL_REVISION == 5 && PERL_VERSION > 7
    if (ST(0) != &PL_sv_undef) {
        IO *io = GvIOn((GV*)SvRV(ST(0)));
        if (upload->req->parsed)
            PerlIO_seek(IoIFP(io), 0, 0);
    }
#else
    if (ST(0) != &PL_sv_undef) {
        IO *io = GvIOn((GV*)SvRV(ST(0)));
        int fd = PerlIO_fileno(IoIFP(io));
        PerlIO *fp;

        fd = PerlLIO_dup(fd);
        if (!(fp = PerlIO_fdopen(fd, "rb"))) { 
            PerlLIO_close(fd);
            croak("fdopen failed!");
        }
        if (upload->req->parsed)
            PerlIO_seek(fp, 0, 0);

        IoIFP(io) = fp;  	
    }
#endif

long
ApacheUpload_size(upload)
    Apache::Upload upload

char *
ApacheUpload_name(upload)
    Apache::Upload upload

char *
ApacheUpload_filename(upload)
    Apache::Upload upload

char *
ApacheUpload_tempname(upload)
    Apache::Upload upload

Apache::Upload
ApacheUpload_next(upload)
    Apache::Upload upload 

const char *
ApacheUpload_type(upload)
    Apache::Upload upload 

char *
ApacheUpload_link(upload, name)
    Apache::Upload upload
    char *name

	CODE:
	RETVAL = (link(upload->tempname, name)) ? NULL : name;
	
	OUTPUT:
	RETVAL	

void
ApacheUpload_info(upload, key=NULL)
    Apache::Upload upload 
    char *key

    CODE:
    if (key) {
	const char *val = ApacheUpload_info(upload, key);
	if (!val)
	    XSRETURN_UNDEF;

	ST(0) = sv_2mortal(newSVpv((char *)val,0));
    }   
    else {
        ST(0) = mod_perl_tie_table(upload->info);
    }
