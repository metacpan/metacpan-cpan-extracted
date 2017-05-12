/*
 * This code is a part of tux_perl, and is released under the GPL.
 * Copyright 2002 by Yale Huang<mailto:yale@sdf-eu.org>.
 * See README and COPYING for more information, or see
 *   http://tux-perl.sourceforge.net/.
 *
 * $Id: Tux.xs,v 1.3 2002/11/11 11:15:25 yaleh Exp $
 */

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include "const-c.inc"

#include <string.h>
#include <tuxmodule.h>

typedef user_req_t * Tux;

MODULE = Tux		PACKAGE = Tux

INCLUDE: const-xs.inc

int
version_major(req)
	Tux req

	CODE:
	RETVAL = req->version_major;

	OUTPUT:
	RETVAL

int
version_minor(req)
	Tux req

	CODE:
	RETVAL = req->version_minor;

	OUTPUT:
	RETVAL

int
version_patch(req)
	Tux req

	CODE:
	RETVAL = req->version_patch;

	OUTPUT:
	RETVAL

int
http_version(req)
	Tux req

	CODE:
	RETVAL = req->http_version;

	OUTPUT:
	RETVAL

int
http_method(req)
	Tux req

	CODE:
	RETVAL = req->http_method;

	OUTPUT:
	RETVAL

int
event(req, ...)
	Tux req

	CODE:
	RETVAL = req->event;

	if(items>1){
		req->event=SvIVX(ST(1));
	}

	OUTPUT:
	RETVAL

int
thread_nr(req)
	Tux req

	CODE:
	RETVAL = req->thread_nr;

	OUTPUT:
	RETVAL

int
http_status(req, ...)
	Tux req

	CODE:
	RETVAL = req->http_status;

	if(items>1){
		req->http_status=SvIVX(ST(1));
	}

	OUTPUT:
	RETVAL

int
module_index(req)
	Tux req

	CODE:
	RETVAL = req->module_index;

	OUTPUT:
	RETVAL

unsigned int
client_host(req)
	Tux req

	CODE:
	RETVAL = req->client_host;

	OUTPUT:
	RETVAL

const char *
object_addr(req, ...)
	Tux req
	
	CODE:
	RETVAL = req->object_addr;
	
	if (items > 1){
		req->object_addr=SvPVX(ST(1));
		if(items > 2){
			req->objectlen=SvIVX(ST(2));
		}else{
			req->objectlen=(req->object_addr==NULL)?0:strlen(req->object_addr);
		}
	}

	OUTPUT:
	RETVAL

unsigned int
objectlen(req, ...)
	Tux req

	CODE:
	RETVAL = req->objectlen;
	
	if (items > 1){
		req->objectlen=SvIVX(ST(1));
	}

	OUTPUT:
	RETVAL

const char *
objectname(req, ...)
	Tux req
	
	CODE:
	RETVAL = req->objectname;
	
	if (items > 1){
		strncpy(req->objectname,SvPVX(ST(1)),MAX_FIELD_LEN-1);
	}

	OUTPUT:
	RETVAL

const char *
query(req, ...)
	Tux req
	
	CODE:
	RETVAL = req->query;
	
	if (items > 1){
		strncpy(req->query,SvPVX(ST(1)),MAX_FIELD_LEN-1);
	}

	OUTPUT:
	RETVAL

const char *
cookies(req, ...)
	Tux req
	
	CODE:
	RETVAL = req->cookies;
	
	if (items > 1){
		strncpy(req->cookies,SvPVX(ST(1)),MAX_FIELD_LEN-1);
		req->cookies_len=strlen(req->cookies);
	}

	OUTPUT:
	RETVAL

const char *
content_type(req, ...)
	Tux req
	
	CODE:
	RETVAL = req->content_type;
	
	if (items > 1){
		strncpy(req->content_type,SvPVX(ST(1)),MAX_FIELD_LEN-1);
	}

	OUTPUT:
	RETVAL

const char *
user_agent(req, ...)
	Tux req
	
	CODE:
	RETVAL = req->user_agent;
	
	if (items > 1){
		strncpy(req->user_agent,SvPVX(ST(1)),MAX_FIELD_LEN-1);
	}

	OUTPUT:
	RETVAL

const char *
accept(req, ...)
	Tux req
	
	CODE:
	RETVAL = req->accept;
	
	if (items > 1){
		strncpy(req->accept,SvPVX(ST(1)),MAX_FIELD_LEN-1);
	}

	OUTPUT:
	RETVAL

const char *
accept_charset(req, ...)
	Tux req
	
	CODE:
	RETVAL = req->accept_charset;
	
	if (items > 1){
		strncpy(req->accept_charset,SvPVX(ST(1)),MAX_FIELD_LEN-1);
	}

	OUTPUT:
	RETVAL

const char *
accept_encoding(req, ...)
	Tux req
	
	CODE:
	RETVAL = req->accept_encoding;
	
	if (items > 1){
		strncpy(req->accept_encoding,SvPVX(ST(1)),MAX_FIELD_LEN-1);
	}

	OUTPUT:
	RETVAL

const char *
accept_language(req, ...)
	Tux req
	
	CODE:
	RETVAL = req->accept_language;
	
	if (items > 1){
		strncpy(req->accept_language,SvPVX(ST(1)),MAX_FIELD_LEN-1);
	}

	OUTPUT:
	RETVAL

const char *
cache_control(req, ...)
	Tux req
	
	CODE:
	RETVAL = req->cache_control;
	
	if (items > 1){
		strncpy(req->cache_control,SvPVX(ST(1)),MAX_FIELD_LEN-1);
	}

	OUTPUT:
	RETVAL

const char *
if_modified_since(req, ...)
	Tux req
	
	CODE:
	RETVAL = req->if_modified_since;
	
	if (items > 1){
		strncpy(req->if_modified_since,SvPVX(ST(1)),MAX_FIELD_LEN-1);
	}

	OUTPUT:
	RETVAL


const char *
negotiate(req, ...)
	Tux req
	
	CODE:
	RETVAL = req->negotiate;
	
	if (items > 1){
		strncpy(req->negotiate,SvPVX(ST(1)),MAX_FIELD_LEN-1);
	}

	OUTPUT:
	RETVAL

const char *
pragma(req, ...)
	Tux req
	
	CODE:
	RETVAL = req->pragma;
	
	if (items > 1){
		strncpy(req->pragma,SvPVX(ST(1)),MAX_FIELD_LEN-1);
	}

	OUTPUT:
	RETVAL

const char *
referer(req, ...)
	Tux req
	
	CODE:
	RETVAL = req->referer;
	
	if (items > 1){
		strncpy(req->referer,SvPVX(ST(1)),MAX_FIELD_LEN-1);
	}

	OUTPUT:
	RETVAL

const char *
post_data(req)
	Tux req

	CODE:
	RETVAL = req->post_data;

	OUTPUT:
	RETVAL

const char *
new_date(req)
	Tux req
	
	CODE:
	RETVAL = req->new_date;
	
	OUTPUT:
	RETVAL

int
keep_alive(req, ...)
	Tux req

	CODE:
	RETVAL = req->keep_alive;

	if(items>1){
		req->keep_alive=SvIVX(ST(1));
	}

	OUTPUT:
	RETVAL

int
tux(req,action)
	Tux req
	int action

	CODE:
	RETVAL=tux(action,req);

	OUTPUT:
	RETVAL
