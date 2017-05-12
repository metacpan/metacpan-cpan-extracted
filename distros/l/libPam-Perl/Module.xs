#define PERL_NO_GET_CONTEXT	/* we want efficiency */
#include <EXTERN.h>
#include <perl.h>
#include <XSUB.h>
#include <security/_pam_types.h>
#include <security/pam_modules.h>
#include "const.h"

//#define TEST_FAST_LOAD

typedef struct {
	pam_handle_t* pamh;
	HV* hv;
} pam_handle_x;
//typedef int xint;
#define xint int


#include "const-c.inc"

MODULE = Authen::PAM::Module		PACKAGE = Authen::PAM::Module::_user

#VERSIONCHECK: DISABLE ### needed for fast boot test

void
FETCH(handle)
	pam_handle_x handle
	PROTOTYPE: $;
	PREINIT:
		const char* user;
		int ret;
	CODE:
		ret=pam_get_user(handle.pamh, &user, SvPVX(*(hv_fetch(handle.hv,"user_prompt",11,0))));
		if(ret != PAM_SUCCESS) XSRETURN_QV2(ret, &QContext_ret);
		XSRETURN_PV(user);


MODULE = Authen::PAM::Module		PACKAGE = Authen::PAM::Module::_env

void
FETCH(pamh, name)
	pam_handle_x pamh;
	const char * name
	PROTOTYPE: $$;
    PPCODE:
	const char* val=pam_getenv(pamh.pamh, name);
	XSRETURN_PV(val);

void
DELETE(pamh, name)
	pam_handle_x pamh;
	const char * name
	PROTOTYPE: $$;
	PREINIT:
		int ret;
	PPCODE:
		ret=pam_putenv(pamh.pamh, name);
		XSRETURN_QV2(ret, &QContext_ret);

MODULE = Authen::PAM::Module		PACKAGE = Authen::PAM::Module::_item

void
FETCH(pamh, item_type)
	pam_handle_x pamh;
	xint item_type
	PROTOTYPE: $$;
    PREINIT:
	const void *item;
	int ret;
    PPCODE:
		if(item_type == PAM_FAIL_DELAY) XSRETURN_QV("PAM_BAD_ITEM",PAM_BAD_ITEM);
	ret=pam_get_item(pamh.pamh, item_type, &item);
	if(ret != PAM_SUCCESS) XSRETURN_QV2(ret, &QContext_ret);
	if(item_type == PAM_XAUTHDATA){
		SV** tmp=hv_store(pamh.hv,"faild_fn",8,sv_setref_pv(newSV(0), "Authen::PAM::Module::_xauth", (void*)item),0);
		if(tmp) XSRETURN_QV("PAM_SUCCESS",PAM_SUCCESS);
		XSRETURN_QV("PAM_SYSTEM_ERR",PAM_SYSTEM_ERR);
	}
	if(item_type == PAM_CONV){
		SV** tmp=hv_store(pamh.hv,"conv_fn",7,sv_setref_pv(newSV(0), "Authen::PAM::Module::_conv", (void*)item),0);
		if(tmp) XSRETURN_QV("PAM_SUCCESS",PAM_SUCCESS);
		XSRETURN_QV("PAM_SYSTEM_ERR",PAM_SYSTEM_ERR);
	}
	XSRETURN_PV((char*)item);

void
STORE(pamh, item_type, item)
	pam_handle_x pamh;
	xint item_type
	const char * item
	PROTOTYPE: $$$;
	PREINIT:
		int ret;
	INIT:
		if(item_type == PAM_CONV) XSRETURN_QV("PAM_BAD_ITEM",PAM_BAD_ITEM);
		if(item_type == PAM_XAUTHDATA) XSRETURN_QV("PAM_BAD_ITEM",PAM_BAD_ITEM);
		if(item_type == PAM_FAIL_DELAY) XSRETURN_QV("PAM_BAD_ITEM",PAM_BAD_ITEM);
	PPCODE:
		ret=pam_set_item(pamh.pamh, item_type, item);
		if(ret != PAM_SUCCESS) XSRETURN_QV2(ret, &QContext_ret);
		XSRETURN_PV((char*)item);

MODULE = Authen::PAM::Module		PACKAGE = Authen::PAM::Module		PREFIX = pam_

void
tie(class,parent)
	SV* class
	SV* parent
	PROTOTYPE: $$;
	CODE:
		ST(0) = sv_bless(newRV_inc(newSVsv(parent)),gv_stashsv(class, GV_ADD));
		XSRETURN(1);

void
conv(handle, ...)
	pam_handle_x handle;
	PROTOTYPE: $@;
	PREINIT:
		struct pam_message** msg=NULL;
		struct pam_response** resp=NULL;
		int ret, i, j;
		const struct pam_conv *pam_conv=NULL;
	PPCODE:
		msg=calloc(items+1,sizeof(void*));
		*msg=calloc(items+1,sizeof(struct pam_message));
		for(i=1,j=0;i<items;i++,j++){
			if(j)msg[j]=msg[j-1]+1/*sizeof(struct pam_message)*/;
			if(SvTYPE(ST(i))==SVt_RV){
				if(SvTYPE(SvRV(ST(i)))==SVt_PVHV){
					HV* a=(HV*)SvRV(ST(i));
					SV** b=hv_fetch(a,"msg_style",3,0);
					if(b==NULL) croak("null dref");
					(*(msg[j])).msg_style=SvIV(Q_intorconst(aTHX_ *b));
					b=hv_fetch(a,"msg",3,0);
					if(b==NULL) croak("null dref");
					(*(msg[j])).msg=SvPVX(*b);
				}else if(SvTYPE(SvRV(ST(i)))==SVt_PVAV){
					AV* a=(AV*)SvRV(ST(i));
					SV** b=av_fetch(a,0,0);
					if(b==NULL) croak("null dref");
					(*(msg[j])).msg_style=SvIV(Q_intorconst(aTHX_ *b));
					b=av_fetch(a,1,0);
					if(b==NULL) croak("null dref");
					(*(msg[j])).msg=SvPVX(*b);
				}else{
					printf("debug  %d %d\n",i,SvTYPE(SvRV(ST(i))));
					croak("msg is not array or hash");
				}
			}else if(SvTYPE(ST(i))==SVt_PVHV){
				HV* a=(HV*)ST(i);
				SV** b=hv_fetch(a,"msg_style",3,0);
				if(b==NULL) croak("null dref");
				(*(msg[j])).msg_style=SvIV(Q_intorconst(aTHX_ *b));
				b=hv_fetch(a,"msg",3,0);
				if(b==NULL) croak("null dref");
				(*(msg[j])).msg=SvPVX(*b);
			}else if(SvTYPE(ST(i))==SVt_PVAV){
				AV* a=(AV*)ST(i);
				SV** b=av_fetch(a,0,0);
				if(b==NULL) croak("null dref");
				(*(msg[j])).msg_style=SvIV(Q_intorconst(aTHX_ *b));
				b=av_fetch(a,1,0);
				if(b==NULL) croak("null dref");
				(*(msg[j])).msg=SvPVX(*b);
			}else{
				printf("debug %d %d\n",i,SvTYPE(ST(i)));
				croak("msg is not array or hash");
			}
		}
		resp=calloc(items-1,sizeof(void*));
#if 0
		*resp=calloc(items-1,sizeof(struct pam_response));
		for(i=1,j=0;i<items;i++,j++){
			if(j)resp[j]=resp[0]+1/*sizeof(struct pam_response)*/;
		}
#endif
		SV** tmp2 = hv_fetch(handle.hv,"conv_fn",7,0);
		if(tmp2==NULL){
			ret=pam_get_item(handle.pamh, PAM_CONV, (const void**)(&pam_conv));
			if(ret != PAM_SUCCESS) XSRETURN_QV2(ret, &QContext_ret);
			SV** tmp=hv_store(handle.hv,"conv_fn",7,sv_setref_pv(newSV(0), "Authen::PAM::Module::_conv", (void*)pam_conv),0);
			PERL_UNUSED_VAR(tmp); /* -Wall */
		}else{
			pam_conv = INT2PTR(struct pam_conv*, SvIV((SV*)SvRV(*tmp2)));
		}
		ret = (*((*pam_conv).conv))(items-1, (const struct pam_message **)msg, resp, (*pam_conv).appdata_ptr);
		if(ret != PAM_SUCCESS) XSRETURN_QV2(ret, &QContext_ret);
		for(i=1,j=0;i<items;i++,j++){
			if(((*resp)[j]).resp){
				XPUSHs(sv_2mortal(newSVqv(((*resp)[j]).resp,((*resp)[j]).resp_retcode)));
				free(((*resp)[j]).resp);
			}else{
				XPUSHs(sv_2mortal(newSVqv("NULL",((*resp)[j]).resp_retcode)));
			}
		}
		free(resp[0]);
		free(msg[0]);
		free(resp);
		free(msg);


int
pam_putenv(pamh, name_value)
	pam_handle_t *pamh;
	const char *name_value;
	PROTOTYPE: $$;

void
pam_getenvlist(pamh)
	pam_handle_t *pamh
	PROTOTYPE: $;
    PREINIT:
	char ** env;
	int i;
    PPCODE:
	env=pam_getenvlist(pamh);
	for(i=0;env[i];i++){
		XPUSHs(sv_2mortal(newSVpv(env[i],strlen(env[i]))));
		free(env[i]);
	}
	free(env);

const char *
pam_strerror(pamh, errnum)
	pam_handle_t *pamh
	int errnum
	PROTOTYPE: $$;

int
pam_fail_delay(pamh, usec)
	pam_handle_t *pamh
	unsigned int usec
	PROTOTYPE: $$;

INCLUDE: const-xs.inc
INCLUDE: const.xs.inc

BOOT:
	newXSproto("Authen::PAM::Module::_user::TIESCALAR",	XS_Authen__PAM__Module_tie, file, "$$;");
	newXSproto("Authen::PAM::Module::_out::TIEHANDLE",	XS_Authen__PAM__Module_tie, file, "$$;");
	newXSproto("Authen::PAM::Module::_err::TIEHANDLE",	XS_Authen__PAM__Module_tie, file, "$$;");
	newXSproto("Authen::PAM::Module::_item::TIEHASH",	XS_Authen__PAM__Module_tie, file, "$$;");
	newXSproto("Authen::PAM::Module::_env::TIEHASH",	XS_Authen__PAM__Module_tie, file, "$$;");
