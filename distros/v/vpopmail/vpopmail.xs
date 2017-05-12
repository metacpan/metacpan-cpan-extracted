/*	$Id: vpopmail.xs,v 1.10 2001/11/24 06:24:26 sps Exp $		*/
#ifdef __cplusplus
extern "C" {
#endif
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#ifdef __cplusplus
}
#endif

#include <vpopmail.h>
#include <vpopmail_config.h>
#include <vauth.h>


/* #define V_DEBUG */

#ifdef PREFIVE
#include <pwd.h>
#define _passwd passwd
#endif

#ifndef _passwd
#define _passwd vqpasswd
#endif

static int
not_here(s)
char *s;
{
    croak("%s not implemented on this architecture", s);
    return -1;
}

static double
constant(name, arg)
char *name;
int arg;
{
    errno = 0;
    switch (*name) {
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}


MODULE = vpopmail		PACKAGE = vpopmail		


double
constant(name,arg)
	char *name
	int arg

int
vadddomain(domain, dir, uid, gid)
	char *domain
	char *dir
	int uid
	int gid

int
vdeldomain(domain)
	char *domain
    OUTPUT:
        RETVAL

int
vadduser(username, domain, password, gecos, apop )
	char *username
	char *domain
	char *password
	char *gecos
	int apop
    OUTPUT:
        RETVAL

int
vdeluser(user, domain)
	char *user
	char *domain
    OUTPUT:
        RETVAL

int
vpasswd(user, domain, password, apop)
        char *user
        char *domain
        char *password
        int apop
    OUTPUT:
        RETVAL

int
vsetuserquota(user, domain, quota)
        char *user
        char *domain
        char *quota
    OUTPUT:
        RETVAL

int
vauth_user(user, domain, password, apop)
        char *user
        char *domain
        char *password
        char *apop


SV *
vauth_getpw(user, domain)
        char *user
        char *domain
	PREINIT:
	HV *h;
	char name[100];
	SV **ssv;
	SV *svval;
    CODE:
	struct _passwd *pwd = NULL;
	pwd = vauth_getpw(user, domain);
	if ( pwd == NULL ) {
		XSRETURN_UNDEF;
	}
	h = newHV(); /* allocate new hash */
	RETVAL = newRV_inc( (SV *) h ); /* return a ref to the hash */
	SvREFCNT_dec( h ); /* free the hash whenever the ref is gone */

	/* SET HASH->{pw_name} */
	if (pwd->pw_name != NULL) {
		svval = newSVpv( pwd->pw_name, strlen(pwd->pw_name) );
		/* make the string that will be the key */
		strcpy( name, "pw_name");
		ssv = hv_store( h, name, strlen( name ), svval, 0 );
		if ( ssv == NULL ) {
			croak( "oops: key %s not stored", name );
		}
	}

	/* SET HASH->{pw_passwd} */
	if (pwd->pw_passwd != NULL) {
		/* warn("pw_passwd = %s\n", pwd->pw_passwd); */
		svval = newSVpv( pwd->pw_passwd, strlen(pwd->pw_passwd) );
		/* make the string that will be the key */
		strcpy( name, "pw_passwd");
		ssv = hv_store( h, name, strlen( name ), svval, 0 );
		if ( ssv == NULL ) {
			croak( "oops: key %s not stored", name );
		}
	}


	/* SET HASH->{pw_gecos} */
	if (pwd->pw_gecos != NULL) {
		/* warn("pw_gecos = %s\n", pwd->pw_gecos); */
		svval = newSVpv( pwd->pw_gecos, strlen(pwd->pw_gecos) );
		/* make the string that will be the key */
		strcpy( name, "pw_gecos");
		ssv = hv_store( h, name, strlen( name ), svval, 0 );
		if ( ssv == NULL ) {
			croak( "oops: key %s not stored", name );
		}
	}

	/* SET HASH->{pw_shell} */
	if (pwd->pw_shell != NULL) {
		/* warn("pw_gecos = %s\n", pwd->pw_gecos); */
		svval = newSVpv( pwd->pw_shell, strlen(pwd->pw_shell) );
		/* make the string that will be the key */
		strcpy( name, "pw_shell");
		ssv = hv_store( h, name, strlen( name ), svval, 0 );
		if ( ssv == NULL ) {
			croak( "oops: key %s not stored", name );
		}
	}

	/* SET HASH->{pw_dir} */
	/* warn("pw_dir = %s\n", pwd->pw_dir); */
	if (pwd->pw_dir != NULL) {
		/* warn("pw_dir = %s\n", pwd->pw_dir); */
		svval = newSVpv( pwd->pw_dir, strlen(pwd->pw_dir) );
		/* make the string that will be the key */
		strcpy( name, "pw_dir");
		ssv = hv_store( h, name, strlen( name ), svval, 0 );
		if ( ssv == NULL ) {
			croak( "oops: key %s not stored", name );
		}
	}
    OUTPUT:
        RETVAL

SV *
vauth_getall(domain, first, sort_it)
        char *domain
	int first
	int sort_it
	PREINIT:
	HV *h;
	char name[100];
	SV **ssv;
	SV *svval;
    CODE:
	struct _passwd *pwd = NULL;
	pwd = vauth_getall(domain, first, sort_it);
	if ( pwd == NULL ) {
		XSRETURN_UNDEF;
	}
	h = newHV(); /* allocate new hash */
	RETVAL = newRV_inc( (SV *) h ); /* return a ref to the hash */
	SvREFCNT_dec( h ); /* free the hash whenever the ref is gone */

	/* SET HASH->{pw_name} */
	if (pwd->pw_name != NULL) {
		svval = newSVpv( pwd->pw_name, strlen(pwd->pw_name) );
		/* make the string that will be the key */
		strcpy( name, "pw_name");
		ssv = hv_store( h, name, strlen( name ), svval, 0 );
		if ( ssv == NULL ) {
			croak( "oops: key %s not stored", name );
		}
	}


	/* SET HASH->{pw_passwd} */
	if (pwd->pw_passwd != NULL) {
		/* warn("pw_passwd = %s\n", pwd->pw_passwd); */
		svval = newSVpv( pwd->pw_passwd, strlen(pwd->pw_passwd) );
		/* make the string that will be the key */
		strcpy( name, "pw_passwd");
		ssv = hv_store( h, name, strlen( name ), svval, 0 );
		if ( ssv == NULL ) {
			croak( "oops: key %s not stored", name );
		}
	}

	/* SET HASH->{pw_shell} */
	if (pwd->pw_shell != NULL) {
		svval = newSVpv( pwd->pw_shell, strlen(pwd->pw_shell) );
		/* make the string that will be the key */
		strcpy( name, "pw_shell");
		ssv = hv_store( h, name, strlen( name ), svval, 0 );
		if ( ssv == NULL ) {
			croak( "oops: key %s not stored", name );
		}
	}

	/* SET HASH->{pw_gecos} */
	if (pwd->pw_gecos != NULL) {
		/* warn("pw_gecos = %s\n", pwd->pw_gecos); */
		svval = newSVpv( pwd->pw_gecos, strlen(pwd->pw_gecos) );
		/* make the string that will be the key */
		strcpy( name, "pw_gecos");
		ssv = hv_store( h, name, strlen( name ), svval, 0 );
		if ( ssv == NULL ) {
			croak( "oops: key %s not stored", name );
		}
	}

	/* SET HASH->{pw_dir} */
	/* warn("pw_dir = %s\n", pwd->pw_dir); */
	if (pwd->pw_dir != NULL) {
		/* warn("pw_dir = %s\n", pwd->pw_dir); */
		svval = newSVpv( pwd->pw_dir, strlen(pwd->pw_dir) );
		/* make the string that will be the key */
		strcpy( name, "pw_dir");
		ssv = hv_store( h, name, strlen( name ), svval, 0 );
		if ( ssv == NULL ) {
			croak( "oops: key %s not stored", name );
		}
	}
    OUTPUT:
        RETVAL


SV *
vgetversion()
	CODE:
	RETVAL = newSVpv( VERSION, strlen(VERSION) );
    OUTPUT:
        RETVAL

SV *
vgetatchars()
	CODE:
	RETVAL = newSVpv( ATCHARS, strlen(ATCHARS) );
    OUTPUT:
        RETVAL


SV *
QMAILDIR()
	CODE:
	RETVAL = newSVpv( QMAILDIR, strlen(QMAILDIR) );
    OUTPUT:
        RETVAL

SV *
VPOPMAILDIR()
	CODE:
	RETVAL = newSVpv( VPOPMAILDIR, strlen(VPOPMAILDIR) );
    OUTPUT:
        RETVAL

SV *
VPOPUSER()
	CODE:
	RETVAL = newSVpv( VPOPUSER, strlen(VPOPUSER) );
    OUTPUT:
        RETVAL

SV *
VPOPGROUP()
	CODE:
	RETVAL = newSVpv( VPOPGROUP, strlen(VPOPGROUP) );
    OUTPUT:
        RETVAL

SV *
VPOPMAILUID()
	CODE:
	RETVAL = newSViv( VPOPMAILUID );
    OUTPUT:
        RETVAL

SV *
VPOPMAILGID()
	CODE:
	RETVAL = newSViv( VPOPMAILGID );
    OUTPUT:
        RETVAL

int
vauth_setpw(inpwd, domain)
	INPUT:
	SV *inpwd;
	char *domain;


	CODE:
	char key[100];
	SV *hval;
	struct _passwd pwd;
	if (SvROK(inpwd) && SvTYPE(SvRV(inpwd)) == SVt_PVHV) {

	strcpy(key, "pw_name");

	if ( hv_exists( (HV *)SvRV(inpwd), key, strlen(key)) ) {
	  hval = *hv_fetch((HV *)SvRV(inpwd), key,strlen(key),0);
	  if (hval != NULL ) {
	    pwd.pw_name = SvPV(hval,PL_na);
#ifdef V_DEBUG
	    warn("user = %s (%d)\n", pwd.pw_name, strlen(pwd.pw_name));
#endif
	  }
	  
	} 

	/* pw_passwd */
	strcpy(key, "pw_passwd");

	if ( hv_exists( (HV *)SvRV(inpwd), key, strlen(key)) ) {
	  hval = *hv_fetch((HV *)SvRV(inpwd), key,strlen(key),0);
	  if (hval != NULL ) {
	    pwd.pw_passwd = SvPV(hval,PL_na);
#ifdef V_DEBUG
	    warn("pw_passwd = %s\n", pwd.pw_passwd);
#endif

	  }
	  
	} 
	

	strcpy(key, "pw_gecos");

	if ( hv_exists( (HV *)SvRV(inpwd), key, strlen(key)) ) {
	  hval = *hv_fetch((HV *)SvRV(inpwd), key,strlen(key),0);
	  if (hval != NULL ) {
	    pwd.pw_gecos = SvPV(hval,PL_na);
#ifdef V_DEBUG
	    warn("pw_gecos = %s \n", pwd.pw_gecos);
#endif
	  }
	  
	} 

	strcpy(key, "pw_dir");

	if ( hv_exists( (HV *)SvRV(inpwd), key, strlen(key)) ) {
	  hval = *hv_fetch((HV *)SvRV(inpwd), key,strlen(key),0);
	  if (hval != NULL ) {
	    pwd.pw_dir = SvPV(hval,PL_na);
#ifdef V_DEBUG
	    warn("pw_dir = %s \n", pwd.pw_dir);
#endif
	  }
	  
	} 


	strcpy(key, "pw_shell");

	if ( hv_exists( (HV *)SvRV(inpwd), key, strlen(key)) ) {
	  hval = *hv_fetch((HV *)SvRV(inpwd), key,strlen(key),0);
	  if (hval != NULL ) {
	    pwd.pw_shell = SvPV(hval,PL_na);
#ifdef V_DEBUG
	    warn("pw_shell = %s \n", pwd.pw_shell);
#endif
	  }
	  
	} 


	strcpy(key, "pw_uid");

	if ( hv_exists( (HV *)SvRV(inpwd), key, strlen(key)) ) {
	  hval = *hv_fetch((HV *)SvRV(inpwd), key,strlen(key),0);
	  if (hval != NULL ) {
	    pwd.pw_uid = SvIV(hval);
#ifdef V_DEBUG
	    warn("pw_uid = %d \n", pwd.pw_uid);
#endif
	  }
	  
	} 

	strcpy(key, "pw_gid");

	if ( hv_exists( (HV *)SvRV(inpwd), key, strlen(key)) ) {
	  hval = *hv_fetch((HV *)SvRV(inpwd), key,strlen(key),0);
	  if (hval != NULL ) {
	    pwd.pw_gid = SvIV(hval);
#ifdef V_DEBUG
	    warn("pw_gid = %d \n", pwd.pw_gid);
#endif
	  }
	  
	} 

	} else {
	  /* It's not */
	  warn("vauth_setpw(arg1): need a hash reference\n");
	}
	
	RETVAL = newSViv(vauth_setpw(&pwd, domain));
	OUTPUT: 
		RETVAL


