/* $Id: ONC.xs,v 1.1 1997/05/01 22:08:11 jake Exp $ */

/*  Copyright 1997 Jake Donham <jake@organic.com>

    You may distribute under the terms of either the GNU General
    Public License or the Artistic License, as specified in the README
    file.
*/

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <rpc/rpc.h>
#include <rpc/svc_soc.h>

typedef SVCXPRT *RPC__ONC__Svcxprt;
typedef CLIENT *RPC__ONC__Client;
typedef AUTH *RPC__ONC__Auth;
typedef struct svc_req *RPC__ONC__svc_req;
typedef struct opaque_auth *RPC__ONC__opaque_auth;
typedef struct authsys_parms *RPC__ONC__authsys_parms;
typedef struct authdes_cred *RPC__ONC__authdes_cred;

static int
not_here(s)
char *s;
{
    croak("%s not implemented on this architecture", s);
    return -1;
}

static int
constant(name, arg)
char *name;
int arg;
{
  errno = 0;
  switch (*name) {
    case 'A':
      if (strEQ(name, "AUTH_NONE"))
	return AUTH_NONE;
      if (strEQ(name, "AUTH_NULL"))
	return AUTH_NULL;
      if (strEQ(name, "AUTH_SYS"))
	return AUTH_SYS;
      if (strEQ(name, "AUTH_UNIX"))
	return AUTH_UNIX;
      if (strEQ(name, "AUTH_SHORT"))
	return AUTH_SHORT;
      if (strEQ(name, "AUTH_DES"))
	return AUTH_DES;
      if (strEQ(name, "AUTH_KERB"))
	return AUTH_KERB;
      break;
    case 'C':
      if (strEQ(name, "CLSET_TIMEOUT"))
	return CLSET_TIMEOUT;
      if (strEQ(name, "CLGET_TIMEOUT"))
	return CLGET_TIMEOUT;
      if (strEQ(name, "CLGET_FD"))
	return CLGET_FD;
      if (strEQ(name, "CLGET_SVC_ADDR"))
	return CLGET_SVC_ADDR;
      if (strEQ(name, "CLSET_FD_CLOSE"))
	return CLSET_FD_CLOSE;
      if (strEQ(name, "CLSET_FD_NCLOSE"))
	return CLSET_FD_NCLOSE;
      if (strEQ(name, "CLGET_VERS"))
	return CLGET_VERS;
      if (strEQ(name, "CLSET_VERS"))
	return CLSET_VERS;
      if (strEQ(name, "CLGET_XID"))
	return CLGET_XID;
      if (strEQ(name, "CLSET_XID"))
	return CLSET_XID;
      if (strEQ(name, "CLSET_RETRY_TIMEOUT"))
	return CLSET_RETRY_TIMEOUT;
      if (strEQ(name, "CLGET_RETRY_TIMEOUT"))
	return CLGET_RETRY_TIMEOUT;
      break;
    case 'R':
      if (strEQ(name, "RPC_SUCCESS"))
	return RPC_SUCCESS;
      if (strEQ(name, "RPC_CANTENCODEARGS"))
	return RPC_CANTENCODEARGS;
      if (strEQ(name, "RPC_CANTDECODEARGS"))
	return RPC_CANTDECODEARGS;
      if (strEQ(name, "RPC_CANTSEND"))
	return RPC_CANTSEND;
      if (strEQ(name, "RPC_CANTRECV"))
	return RPC_CANTRECV;
      if (strEQ(name, "RPC_TIMEDOUT"))
	return RPC_TIMEDOUT;
      if (strEQ(name, "RPC_INTR"))
	return RPC_INTR;
      if (strEQ(name, "RPC_UDERROR"))
	return RPC_UDERROR;
      if (strEQ(name, "RPC_VERSMISMATCH"))
	return RPC_VERSMISMATCH;
      if (strEQ(name, "RPC_AUTHERROR"))
	return RPC_AUTHERROR;
      if (strEQ(name, "RPC_PROGUNAVAIL"))
	return RPC_PROGUNAVAIL;
      if (strEQ(name, "RPC_PROGVERSMISMATCH"))
	return RPC_PROGVERSMISMATCH;
      if (strEQ(name, "RPC_PROCUNAVAIL"))
	return RPC_PROCUNAVAIL;
      if (strEQ(name, "RPC_CANTDECODEARGS"))
	return RPC_CANTDECODEARGS;
      if (strEQ(name, "RPC_SYSTEMERROR"))
	return RPC_SYSTEMERROR;
      if (strEQ(name, "RPC_UNKNOWNHOST"))
	return RPC_UNKNOWNHOST;
      if (strEQ(name, "RPC_UNKNOWNPROTO"))
	return RPC_UNKNOWNPROTO;
      if (strEQ(name, "RPC_UNKNOWNADDR"))
	return RPC_UNKNOWNADDR;
      if (strEQ(name, "RPC_NOBROADCAST"))
	return RPC_NOBROADCAST;
      if (strEQ(name, "RPC_RPCBFAILURE"))
	return RPC_RPCBFAILURE;
      if (strEQ(name, "RPC_PMAPFAILURE"))
	return RPC_PMAPFAILURE;
      if (strEQ(name, "RPC_PROGNOTREGISTERED"))
	return RPC_PROGNOTREGISTERED;
      if (strEQ(name, "RPC_N2AXLATEFAILURE"))
	return RPC_N2AXLATEFAILURE;
      if (strEQ(name, "RPC_TLIERROR"))
	return RPC_TLIERROR;
      if (strEQ(name, "RPC_FAILED"))
	return RPC_FAILED;
      if (strEQ(name, "RPC_INPROGRESS"))
	return RPC_INPROGRESS;
      if (strEQ(name, "RPC_STALERACHANDLE"))
	return RPC_STALERACHANDLE;
      if (strEQ(name, "RPC_CANTCONNECT"))
	return RPC_CANTCONNECT;
      if (strEQ(name, "RPC_XPRTFAILED"))
	return RPC_XPRTFAILED;
      if (strEQ(name, "RPC_CANCREATESTREAM"))
	return RPC_CANTCREATESTREAM;
      break;
    }
    errno = EINVAL;
    return 0;
}

void set_perl_error(int errno, char *errstr)
{
  static SV *sv_errno = 0;
  static SV *sv_errstr = 0;

  if (!sv_errno) sv_errno = perl_get_sv("RPC::ONC::errno", TRUE);
  if (!sv_errstr) sv_errstr = perl_get_sv("RPC::ONC::errstr", TRUE);
  sv_setiv(sv_errno, (IV) errno);
  sv_setpv(sv_errstr, errstr);
}

MODULE = RPC::ONC		PACKAGE = RPC::ONC

PROTOTYPES: DISABLE

int
constant(name,arg)
	char *		name
	int		arg

MODULE = RPC::ONC	PACKAGE = RPC::ONC::Client

RPC::ONC::Client
clnt_create(host,prognum,versnum,nettype)
    char *host
    long prognum
    long versnum
    char *nettype

    CODE:
	char *msg;
	if ((RETVAL = clnt_create(host, prognum, versnum, nettype)) == 0) {
	  char *msg = clnt_spcreateerror("RPC::ONC::clnt_create");
	  set_perl_error(rpc_createerr.cf_stat, msg);
     	  croak(msg);
	}

    OUTPUT:
	RETVAL

int
clnt_control(clnt,req,info)
    RPC::ONC::Client clnt
    int req
    char *info

    CODE:
	RETVAL = clnt_control(clnt, req, info);

    OUTPUT:
	RETVAL

void
clnt_destroy(clnt)
    RPC::ONC::Client clnt

    CODE:
	clnt_destroy(clnt);

void
DESTROY(clnt)
    RPC::ONC::Client clnt

    CODE:
	clnt_destroy(clnt);

void
set_cl_auth(clnt,auth)
    RPC::ONC::Client clnt
    RPC::ONC::Auth auth

    CODE:
	clnt->cl_auth = auth;

MODULE = RPC::ONC	PACKAGE = RPC::ONC::Auth

RPC::ONC::Auth
authnone_create()

    CODE:
	RETVAL = authnone_create();
	EXTEND(sp, 1);

    OUTPUT:
	RETVAL

RPC::ONC::Auth
authsys_create_default()

    CODE:
	RETVAL = authsys_create_default();
	EXTEND(sp, 1);

    OUTPUT:
	RETVAL

void
auth_destroy(auth)
    RPC::ONC::Auth auth

    CODE:
	auth_destroy(auth);

MODULE = RPC::ONC		PACKAGE = RPC::ONC::svc_req

u_long
rq_prog(svc_req)
    RPC::ONC::svc_req svc_req

    CODE:
	RETVAL = svc_req->rq_prog;

    OUTPUT:
	RETVAL

u_long
rq_vers(svc_req)
    RPC::ONC::svc_req svc_req

    CODE:
	RETVAL = svc_req->rq_vers;

    OUTPUT:
	RETVAL

u_long
rq_proc(svc_req)
    RPC::ONC::svc_req svc_req

    CODE:
	RETVAL = svc_req->rq_proc;

    OUTPUT:
	RETVAL

RPC::ONC::opaque_auth
rq_cred(svc_req)
    RPC::ONC::svc_req svc_req

    CODE:
	RETVAL = &(svc_req->rq_cred);

    OUTPUT:
	RETVAL

RPC::ONC::authsys_parms
authsys_parms(svc_req)
    RPC::ONC::svc_req svc_req

    CODE:
	if (svc_req->rq_cred.oa_flavor == AUTH_SYS)
	  RETVAL = (struct authsys_parms *)svc_req->rq_clntcred;
	else
	  croak("auth flavor is not AUTH_SYS");

    OUTPUT:
	RETVAL

RPC::ONC::authdes_cred
authdes_cred(svc_req)
    RPC::ONC::svc_req svc_req

    CODE:
	if (svc_req->rq_cred.oa_flavor == AUTH_DES)
	  RETVAL = (struct authdes_cred *)svc_req->rq_clntcred;
	else
	croak("auth flavor is not AUTH_DES");

    OUTPUT:
	RETVAL

MODULE = RPC::ONC		PACKAGE = RPC::ONC::opaque_auth

int
oa_flavor(opaque_auth)
    RPC::ONC::opaque_auth opaque_auth

    CODE:
	RETVAL = opaque_auth->oa_flavor;

    OUTPUT:
	RETVAL

MODULE = RPC::ONC		PACKAGE = RPC::ONC::authsys_parms

u_long
aup_time(authsys_parms)
    RPC::ONC::authsys_parms authsys_parms

    CODE:
	RETVAL = authsys_parms->aup_time;

    OUTPUT:
	RETVAL

char *
aup_machname(authsys_parms)
    RPC::ONC::authsys_parms authsys_parms

    CODE:
	RETVAL = authsys_parms->aup_machname;

    OUTPUT:
	RETVAL

uid_t
aup_uid(authsys_parms)
    RPC::ONC::authsys_parms authsys_parms

    CODE:
	RETVAL = authsys_parms->aup_uid;

    OUTPUT:
	RETVAL

gid_t
aup_gid(authsys_parms)
    RPC::ONC::authsys_parms authsys_parms

    CODE:
	RETVAL = authsys_parms->aup_gid;

    OUTPUT:
	RETVAL

AV *
aup_gids(authsys_parms)
    RPC::ONC::authsys_parms authsys_parms

    CODE:
	{
	  int i;
	  RETVAL = newAV();
	  av_extend(RETVAL, authsys_parms->aup_len);
	  for (i=0; i < authsys_parms->aup_len; i++) {
	    av_store(RETVAL, i,
		     sv_2mortal(newSViv(authsys_parms->aup_gids[i])));
	  }
	}

    OUTPUT:
	RETVAL

MODULE = RPC::ONC		PACKAGE = RPC::ONC::Svcxprt

struct sockaddr_in *
svc_getcaller(transp)
    RPC::ONC::Svcxprt transp

    CODE:
	RETVAL = svc_getcaller(transp);

    OUTPUT:
	RETVAL
