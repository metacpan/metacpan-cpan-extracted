/*
 * VMS::Stat.xs - VMS extensions to stat.h
 * 
 * Peter Prymmer
 * Version  0.03
 * Revision: 15-MAY-2004
 *
 * Version  0.01
 * Revision: 26-APR-2004
 */

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <libdef.h> /* LIB$_INVARG */

#include "ppport.h"

#include <stat.h>  /* prototype for mkdir() (also provides package name and a raison d'etre) */
#include <rms.h>   /* struct FAB and cc$rms_fab (via inclusion of fabdef.h) */
#include <starlet.h>  /* prototype for sys$open() and sys$close() */
#define VMS_STAT_FAB_ITEMS 32


MODULE = VMS::Stat		PACKAGE = VMS::Stat		

void
vmsmkdir(dir_spec,...)
	char * dir_spec
	PROTOTYPE: @
	CODE:
	    mode_t mode;
	    mode_t default_mode = 0777;
	    unsigned int uic;
	    unsigned short max_versions;
	    unsigned short r_v_number;
	    int rc;

	    if (!dir_spec || !*dir_spec) {
	        SETERRNO(EINVAL,LIB$_INVARG);
	        XSRETURN_UNDEF;
	    }
	    if (items > 5) croak("too many args");

	    /* This hack stolen right out of vmsopen() */
	    switch (items) {
              case 1:
                rc = mkdir(dir_spec,default_mode);
                break;
              case 2:
	        mode = (mode_t)SvIV(ST(1));
                rc = mkdir(dir_spec,mode);
                break;
              case 3:
	        mode = (mode_t)SvIV(ST(1));
	        uic = (unsigned int)SvIV(ST(2));
                rc = mkdir(dir_spec,mode,uic);
                break;
              case 4:
	        mode = (mode_t)SvIV(ST(1));
	        uic = (unsigned int)SvIV(ST(2));
	        max_versions = (unsigned short)SvIV(ST(3));
                rc = mkdir(dir_spec,mode,uic,max_versions);
                break;
              case 5:
	        mode = (mode_t)SvIV(ST(1));
	        uic = (unsigned int)SvIV(ST(2));
	        max_versions = (unsigned short)SvIV(ST(3));
	        r_v_number = (unsigned short)SvIV(ST(4));
                rc = mkdir(dir_spec,mode,uic,max_versions,r_v_number);
                break;
	    }
	    ST(0) = (rc == 0) ?  &PL_sv_yes : &PL_sv_undef;

char *
get_fab(filespec)
	SV * filespec
	PROTOTYPE: $
	INIT:
	    struct FAB fab;
	    int i;
	    int rc;
	    STRLEN len;
	    fab = cc$rms_fab;  /* initialize data structures */
            fab.fab$l_fna = SvPV(filespec,len);
            fab.fab$b_fns = len;
	CODE:
	    rc = sys$open( &fab );
            if ( ! ( rc & 1 ) ) {
	        SETERRNO(rc,rc);
	        ST(0) = sv_newmortal();
	        sv_setpv(ST(0),"");
	        ST(1) = sv_newmortal();
	        ST(1) = &PL_sv_undef;
	        XSRETURN(2);
	    }
            rc = sys$close ( &fab );
            if ( ! ( rc & 1 ) ) {
	        SETERRNO(rc,rc);
	        ST(0) = sv_newmortal();
	        sv_setpv(ST(0),"");
	        ST(1) = sv_newmortal();
	        ST(1) = &PL_sv_undef;
	        XSRETURN(2);
	    }
	    SETERRNO(rc,rc);
	    /* extend perl return ST-ack pointer sp by an appropriate amount */
            EXTEND(sp,VMS_STAT_FAB_ITEMS);
	    for ( i=0; i<VMS_STAT_FAB_ITEMS; i++) {
	        ST(i) = sv_newmortal();
            }
	    i = 0;
	    sv_setpv(ST(i),"ai"); i++;
	    ST(i) = ( fab.fab$v_ai ) ? &PL_sv_yes : &PL_sv_no; i++;
	    sv_setpv(ST(i),"alq"); i++;
	    sv_setiv(ST(i),fab.fab$l_alq); i++;
            /* bdt skipped for now */
	    /* sv_setpv(ST(i),"bdt"); i++; */
	    sv_setpv(ST(i),"bi"); i++;
	    ST(i) = ( fab.fab$v_bi ) ? &PL_sv_yes : &PL_sv_no; i++;
	    sv_setpv(ST(i),"bks"); i++;
	    sv_setiv(ST(i),fab.fab$b_bks); i++;
	    sv_setpv(ST(i),"bls"); i++;
	    sv_setiv(ST(i),fab.fab$w_bls); i++;
	    sv_setpv(ST(i),"cbt"); i++;
	    ST(i) = ( fab.fab$v_cbt ) ? &PL_sv_yes : &PL_sv_no; i++;
	    /* cdt skipped for now */
	    /* sv_setpv(ST(i),"cdt"); i++; */
	    sv_setpv(ST(i),"ctg"); i++;
            ST(i) = ( fab.fab$v_ctg ) ? &PL_sv_yes : &PL_sv_no; i++;
	    sv_setpv(ST(i),"deq"); i++;
	    sv_setiv(ST(i),fab.fab$w_deq); i++;
	    /* did skipped for now */
	    /* sv_setpv(ST(i),"did"); i++; */
	    /* directory skipped for now */
	    /* sv_setpv(ST(i),"directory"); i++; */
	    /* dvi skipped for now */
	    /* sv_setpv(ST(i),"dvi"); i++; */
	    /* edt skipped for now */
	    /* sv_setpv(ST(i),"edt"); i++; */
	    /* eof skipped for now */
	    /* sv_setpv(ST(i),"eof"); i++; */
	    /* erl aka ERASE */
	    sv_setpv(ST(i),"erase"); i++;
            ST(i) = ( fab.fab$v_erl ) ? &PL_sv_yes : &PL_sv_no; i++;
	    /* ffb */
	    sv_setpv(ST(i),"fsz"); i++;
	    sv_setiv(ST(i),fab.fab$b_fsz); i++;
	    sv_setpv(ST(i),"gbc"); i++;
	    sv_setiv(ST(i),fab.fab$w_gbc); i++;
	    /* sv_setpv(ST(i),"journal_file"); i++; */
            /* ST(i) = ( fab$v_journal_file ) ? &PL_sv_yes : &PL_sv_no; i++; */
	    /* sv_setpv(ST(i),"known"); i++; */
            /* ST(i) = ( fab$v_kfo ) ? &PL_sv_yes : &PL_sv_no; i++; */
	    sv_setpv(ST(i),"mrn"); i++;
	    sv_setiv(ST(i),fab.fab$l_mrn); i++;
	    sv_setpv(ST(i),"mrs"); i++;
	    sv_setiv(ST(i),fab.fab$w_mrs); i++;
	    /* noa */
	    /* nobackup */
	    /* nok */
	    sv_setpv(ST(i),"org"); i++;
	    sv_setiv(ST(i),fab.fab$b_org); i++;
	    sv_setpv(ST(i),"rat"); i++;
	    sv_setiv(ST(i),fab.fab$b_rat); i++;
	    /* sv_setpv(ST(i),"rck"); i++; */
            /* ST(i) = ( fab$v_rck ) ? &PL_sv_yes : &PL_sv_no; i++; */
	    sv_setpv(ST(i),"rfm"); i++;
	    sv_setiv(ST(i),fab.fab$b_rfm); i++;
	    /* sv_setpv(ST(i),"ru"); i++; */
            /* ST(i) = ( fab$v_ru ) ? &PL_sv_yes : &PL_sv_no; i++; */
	    /* sv_setpv(ST(i),"wck"); i++; */
            /* ST(i) = ( fab$v_wck ) ? &PL_sv_yes : &PL_sv_no; i++; */
	    XSRETURN(VMS_STAT_FAB_ITEMS);
