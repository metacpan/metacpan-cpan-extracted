/*

Copyright (C) 2008, 2009, 2012 by Thomas Pfau < tfpfau@gmail.com >

This module is free software.  You can redistribute it and/or modify
it under the terms of the Artistic License 2.0.  For details, see the
full text of the Artistic License in the file LICENSE.

This module is distributed in the hope that it will be useful but it
is provided "as is"and without any express or implied warranties.

*/

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include <starlet.h>
#include <str$routines.h>
#include <lib$routines.h>
#include <lnmdef.h>
#include <descrip.h>

/* this table is used to translate attributes */
#define WHERE_LOG_DEF	1
#define WHERE_LOG_TX	2
#define WHERE_EQV_DEF	4
#define WHERE_EQV_TX	8
#define WHERE_TBL_DEF	16
struct {
    int where_used;
    int value;
    char *name;
} attributes[] = {
    { WHERE_LOG_DEF|WHERE_LOG_TX|WHERE_TBL_DEF,
	LNM$M_CONFINE,     "CONFINE" },
    { WHERE_LOG_TX,
	LNM$M_CRELOG,      "CRELOG" },
    { WHERE_LOG_DEF|WHERE_LOG_TX|WHERE_TBL_DEF,
	LNM$M_NO_ALIAS,    "NO_ALIAS" },
    { WHERE_LOG_TX,
	LNM$M_TABLE,       "TABLE" },
    { WHERE_LOG_TX,
	LNM$M_CLUSTERWIDE, "CLUSTERWIDE" },
    { WHERE_EQV_DEF|WHERE_EQV_TX,
	LNM$M_CONCEALED,   "CONCEALED" },
    { WHERE_EQV_TX,
	LNM$M_EXISTS,      "EXISTS" },
    { WHERE_EQV_DEF|WHERE_EQV_TX,
	LNM$M_TERMINAL,    "TERMINAL" },
    { WHERE_TBL_DEF,
 	LNM$M_CREATE_IF,   "CREATE_IF" },
};
#define NUM_ATTRS (sizeof(attributes)/sizeof(attributes[0]))

/* itemlist */
typedef struct {
    short buffer_size;
    short item_code;
    void *buffer;
    short *return_length;
} itemlist;

/* access modes */
static char *access_modes[] = { "KERNEL", "EXECUTIVE", "SUPERVISOR", "USER" };

/* create hash entries for attributes */
SV *store_attributes(int attr, int which)
{
    int i;
    HV *hv = newHV();
    for (i=0; i<NUM_ATTRS; i++)
    {
        if (attributes[i].where_used & which)
        {
            hv_store(hv, attributes[i].name, strlen(attributes[i].name),
                    (attr & attributes[i].value) ? newSViv(1) : &PL_sv_undef,
                     0);
        }
    }
    return newRV_noinc((SV *) hv);
}            

/* translate hash entries into an attributes mask */
int translate_attributes(HV *hv, int which)
{
    int attr = 0, i;
    for (i=0; i<NUM_ATTRS; i++)
    {
        SV **sv;
	if (!(attributes[i].where_used & which))
	    continue;
        sv = hv_fetch(hv, attributes[i].name, strlen(attributes[i].name), 0);
        if (sv && SvTRUE(*sv))
            attr |= attributes[i].value;
    }
    return attr;
}

/* get an entry from a hash and return as descriptor */
struct dsc$descriptor *get_hash_string_desc(HV *hv, const char *key)
{
    SV **sv;
    struct dsc$descriptor *desc;
    sv = hv_fetch(hv, key, strlen(key), 0);
    if (sv == 0) return 0;
    desc = (struct dsc$descriptor *)calloc(1,sizeof(struct dsc$descriptor));
    desc->dsc$b_class = DSC$K_CLASS_S;
    desc->dsc$b_dtype = DSC$K_DTYPE_T;
    desc->dsc$a_pointer = SvPV_nolen(*sv);
    desc->dsc$w_length = SvCUR(*sv);
    return desc;
}

/* free a string descriptor */
void free_desc(struct dsc$descriptor *desc)
{
    if (desc->dsc$b_class = DSC$K_CLASS_D)
        str$free1_dx(desc);
    free(desc);
}

/* get an entry from a hash and return as (pointer to) integer */
int *get_hash_int(HV *hv, const char *key)
{
    SV **sv;
    int *i;
    sv = hv_fetch(hv, key, strlen(key), 0);
    if (sv == 0) return 0;
    if (!SvIOK(*sv)) return 0;
    i = malloc(sizeof(int));
    *i = SvIV(*sv);
    return i;
}

/* find the specified access mode and return its index */
int find_access_mode(SV *sv)
{
    int i;
    for (i=0; i<4; i++)
    {
        if (strncmp(access_modes[i], SvPV_nolen(sv), SvCUR(sv)) == 0)
            return i;
    }
    return -1;
}

/*

The hash looks like this:

    lognam -> string
    table -> string
    acmode -> string
    attr -> hash
        confine -> integer
        crelog -> integer
        no_alias -> integer
        table -> integer
        clusterwide -> integer
    equiv -> array of hashes
        string -> string
        attr -> hash
            concealed -> integer
            terminal -> integer

For input to define, equiv can be removed, string can be moved up, and
the equivalence attributes can be merged into the logical name
attributes.

*/

MODULE = VMS::Logical		PACKAGE = VMS::Logical		

# translate a logical name and return a hash
SV *
translate(lnm)
    SV *lnm
  CODE:
    struct dsc$descriptor *lognam_d = NULL, *tabnam_d = NULL;
    int attr = 0, acmode_v, *acmode = NULL;
    itemlist *il;
    char r_acmode = 0;
    int r_attr = 0;
    char equiv[255], tabnam[31];
    short equiv_len=0, tabnam_len=0;
    struct TX {
        int index;
        int attr;
        short equiv_len;
        char equiv[255];
    } *tx;
    int *index;
    int max_index = 0;
    int sts;
    STRLEN len;
    HV *hv;

    if (!SvROK(lnm))
    {
	# arg is not a reference, assume a string
        lognam_d = calloc(1, sizeof(struct dsc$descriptor));
        lognam_d->dsc$a_pointer = SvPVx(lnm, len);
        lognam_d->dsc$w_length = len;
        lognam_d->dsc$b_dtype = DSC$K_DTYPE_T;
        lognam_d->dsc$b_class = DSC$K_CLASS_S;
    } else {
        # arg is a reference, make sure it's a hash
        HV *opt;
        SV **sv;
        if (SvTYPE(SvRV(lnm)) != SVt_PVHV)
        {
            croak("Argument must be a string or a hash ref");
        }
        opt = (HV *) SvRV(lnm);
        lognam_d = get_hash_string_desc(opt, "lognam");
        sv = hv_fetch(opt, "case_blind", 10, 0);
        if (sv && SvIOK(*sv) && SvIV(*sv))
            attr |= LNM$M_CASE_BLIND;
        sv = hv_fetch(opt, "interlocked", 11, 0);
        if (sv && SvIOK(*sv) && SvIV(*sv))
            attr |= LNM$M_INTERLOCKED;
        tabnam_d = get_hash_string_desc(opt, "table");
        sv = hv_fetch(opt, "acmode", 6, 0);
        if (sv)
        {
            acmode_v = find_access_mode(*sv);
            if (acmode_v == -1)
                croak("Invalid access mode");
            acmode = &acmode_v;
        }
    }
    if (tabnam_d == NULL)
    {
        tabnam_d = calloc(1, sizeof(struct dsc$descriptor));
        tabnam_d->dsc$a_pointer = "LNM$FILE_DEV";
        tabnam_d->dsc$w_length = strlen(tabnam_d->dsc$a_pointer);
        tabnam_d->dsc$b_dtype = DSC$K_DTYPE_T;
        tabnam_d->dsc$b_class = DSC$K_CLASS_S;
    }
    il = calloc(7, sizeof(itemlist));

    il[0].item_code = LNM$_ACMODE;
    il[0].buffer = &r_acmode;
    il[0].buffer_size = sizeof(r_acmode);

    il[1].item_code = LNM$_MAX_INDEX;
    il[1].buffer = &max_index;
    il[1].buffer_size = sizeof(max_index);

    il[2].item_code = LNM$_TABLE;
    il[2].buffer = tabnam;
    il[2].buffer_size = sizeof(tabnam);
    il[2].return_length = &tabnam_len;

    tx = calloc(1, sizeof(struct TX));
    tx->index = 0;

    il[3].item_code = LNM$_INDEX;
    il[3].buffer = &tx->index;
    il[3].buffer_size = sizeof(tx->index);

    il[4].item_code = LNM$_ATTRIBUTES;
    il[4].buffer = &tx->attr;
    il[4].buffer_size = sizeof(tx->attr);

    il[5].item_code = LNM$_STRING;
    il[5].buffer = tx->equiv;
    il[5].buffer_size = sizeof(tx->equiv);
    il[5].return_length = &tx->equiv_len;

    sts = sys$trnlnm(&attr, tabnam_d, lognam_d, acmode, il);
    free(il);
    if (!(sts & 1))
    {
	RETVAL = &PL_sv_undef;
	SETERRNO(EVMSERR,sts);
    }
    else
    {
	hv = newHV();
	hv_store(hv, "sts", 3, newSViv(sts), 0);
	hv_store(hv, "lognam", 6, newSVpvn(lognam_d->dsc$a_pointer,
					   lognam_d->dsc$w_length), 0);
	hv_store(hv, "table", 5, newSVpvn(tabnam, tabnam_len), 0);
	hv_store(hv, "acmode", 6, newSVpv(access_modes[r_acmode], 0), 0);
	hv_store(hv, "max_index", 9, newSViv(max_index), 0);
	hv_store(hv, "attr", 4, store_attributes(tx->attr, WHERE_LOG_TX), 0);

	if (max_index >= 0)
	{
	    int i,ilp;
	    AV *av = newAV();
	    av_extend(av, max_index);
	    HV *hvt = newHV();
	    hv_store(hvt, "attr", 4, store_attributes(tx->attr, WHERE_EQV_TX), 0);
	    hv_store(hvt, "string", 6, newSVpvn(tx->equiv, tx->equiv_len), 0);
	    av_push(av, newRV_noinc((SV *) hvt));
	    free(tx);
	    tx = calloc(max_index, sizeof(struct TX));
	    il = calloc((max_index * 3) + 1, sizeof(itemlist));
	    for (i=0,ilp=0; i<max_index; i++)
	    {
		tx[i].index = i+1;
		il[ilp].item_code = LNM$_INDEX;
		il[ilp].buffer = &tx[i].index;
		il[ilp].buffer_size = sizeof(tx[i].index);
		ilp++;
		il[ilp].item_code = LNM$_ATTRIBUTES;
		il[ilp].buffer = &tx[i].attr;
		il[ilp].buffer_size = sizeof(tx[i].attr);
		ilp++;
		il[ilp].item_code = LNM$_STRING;
		il[ilp].buffer = tx[i].equiv;
		il[ilp].buffer_size = sizeof(tx[i].equiv);
		il[ilp].return_length = &tx[i].equiv_len;
		ilp++;
	    }
	    sts = sys$trnlnm(&attr, tabnam_d, lognam_d, acmode, il);
	    free(il);
	    for (i=0; i<max_index; i++)
	    {
		hvt = newHV();
		hv_store(hvt, "attr", 4,
			 store_attributes(tx[i].attr, WHERE_EQV_TX), 0);
		hv_store(hvt, "string", 6,
			 newSVpvn(tx[i].equiv, tx[i].equiv_len), 0);
		av_push(av, newRV_noinc((SV *) hvt));
	    }
	    hv_store(hv, "equiv", 5, newRV_noinc((SV *) av), 0);
	}
    	RETVAL = newRV_noinc((SV *) hv);
    }
    free(tx);

  OUTPUT:
    RETVAL

# define a logical name
SV *
define(lnm)
    SV *lnm
  CODE:
    HV *hv;
    SV **sv;
    struct dsc$descriptor *tabnam_d, *lognam_d;
    char table[32];
    short table_len;
    int l_attr_v = 0, *l_attr = NULL;
    int acmode_v, *acmode = NULL;
    itemlist *il = NULL;
    int *attr;
    int sts;

    if (!SvROK(lnm) || (SvTYPE(SvRV(lnm)) != SVt_PVHV))
        croak("Argument must be a hash ref");
    hv = (HV *) SvRV(lnm);
    tabnam_d = get_hash_string_desc(hv, "table");
    lognam_d = get_hash_string_desc(hv, "lognam");
    sv = hv_fetch(hv, "acmode", 6, 0);
    if (sv)
    {
        acmode_v = find_access_mode(*sv);
        if (acmode_v == -1)
            croak("Invalid access mode");
        acmode = &acmode_v;
    }
    sv = hv_fetch(hv, "attr", 4, 0);
    if (sv)
    {
        if (!SvROK(*sv) || (SvTYPE(SvRV(*sv)) != SVt_PVHV))
            croak("attr must be a hash ref");
        l_attr_v = translate_attributes((HV *)SvRV(*sv), WHERE_LOG_DEF);
        l_attr = &l_attr_v;
    }
    sv = hv_fetch(hv, "equiv", 5, 0);
    if (sv)
    {
        AV *av;
        int ilp = 0,ap=0,cnt,i;
        if (!SvROK(*sv) || (SvTYPE(SvRV(*sv)) != SVt_PVAV))
            croak("equiv must be an array ref");
        av = (AV *) SvRV(*sv);
        cnt = av_len(av) + 1;
        il = calloc(2*cnt+2, sizeof(itemlist));
        attr = calloc(cnt, sizeof(attr[0]));
        for (i=0;i<cnt;i++)
        {
            SV **sv2;
            sv = av_fetch(av, i, 0);
            if (!SvROK(*sv) || (SvTYPE(SvRV(*sv)) != SVt_PVHV))
                croak("equiv must contain hash refs");
            sv2 = hv_fetch((HV *)SvRV(*sv), "string", 6, 0);
            il[ilp].item_code = LNM$_STRING;
            il[ilp].buffer = SvPV_nolen(*sv2);
            il[ilp].buffer_size= SvCUR(*sv2);
            sv2 = hv_fetch((HV *)SvRV(*sv), "attr", 4, 0);
            if (sv2)
            {
                if (!SvROK(*sv2) || (SvTYPE(SvRV(*sv2)) != SVt_PVHV))
                    croak("attr must be a hash ref");
                attr[ap] = translate_attributes((HV *)SvRV(*sv2),
						WHERE_EQV_DEF);
                il[ilp+1] = il[ilp];
                il[ilp].item_code = LNM$_ATTRIBUTES;
                il[ilp].buffer = &attr[ap];
                il[ilp].buffer_size = sizeof(attr[ap]);
                ap++;
                ilp++;
            }
            ilp++;
        }
	il[ilp].item_code = LNM$_TABLE;
	il[ilp].buffer = table;
	il[ilp].buffer_size = sizeof(table);
	il[ilp].return_length = &table_len;
    }
    else if (sv = hv_fetch(hv, "string", 6, 0))
    {
        il = calloc(4, sizeof(itemlist));
        attr = calloc(1, sizeof(attr[0]));
	il[0].item_code = LNM$_TABLE;
	il[0].buffer = table;
	il[0].buffer_size = sizeof(table);
	il[0].return_length = &table_len;
        il[1].item_code = LNM$_STRING;
        il[1].buffer = SvPV_nolen(*sv);
        il[1].buffer_size = SvCUR(*sv);
        sv = hv_fetch(hv, "attr", 4, 0);
        if (sv)
        {
            if (!SvROK(*sv) || (SvTYPE(SvRV(*sv)) != SVt_PVHV))
                croak("attr must be a hash ref");
            *attr = translate_attributes((HV *)SvRV(*sv), WHERE_EQV_DEF);
            il[2] = il[1];
            il[1].item_code = LNM$_ATTRIBUTES;
            il[1].buffer = attr;
            il[1].buffer_size = sizeof(attr[0]);
        }
    } else {
        croak("Can't find equivalence string[s]");
    }
    sts = sys$crelnm(l_attr, tabnam_d, lognam_d, acmode, il);
    free(il);
    free(attr);
    if (sts & 1)
    {
	RETVAL = newSVpvn(table, table_len);
	SETERRNO(0,sts);
    }
    else
    {
	RETVAL = &PL_sv_undef;
	SETERRNO(EVMSERR,sts);
    }
  OUTPUT:
    RETVAL

# deassign a logical name
SV *
deassign(lnm)
    SV *lnm
  CODE:
    HV *hv;
    SV **sv;
    struct dsc$descriptor *tabnam_d, *lognam_d;
    int acmode_v, *acmode = NULL;
    itemlist *il = NULL;
    int sts;

    if (!SvROK(lnm) || (SvTYPE(SvRV(lnm)) != SVt_PVHV))
        croak("Argument must be a hash ref");
    hv = (HV *) SvRV(lnm);
    tabnam_d = get_hash_string_desc(hv, "table");
    lognam_d = get_hash_string_desc(hv, "lognam");
    sv = hv_fetch(hv, "acmode", 6, 0);
    if (sv)
    {
        acmode_v = find_access_mode(*sv);
        if (acmode_v == -1)
            croak("Invalid access mode");
        acmode = &acmode_v;
    }
    sts = sys$dellnm(tabnam_d, lognam_d, acmode);
    free(il);
    if (sts & 1)
	RETVAL = newSViv(sts);
    else
    {
	RETVAL = &PL_sv_undef;
	SETERRNO(EVMSERR,sts);
    }
  OUTPUT:
    RETVAL

# create a logical name table
SV *
create_table(lnm)
    SV *lnm
  CODE:
    HV *hv;
    SV **sv;
    struct dsc$descriptor *tabnam_d, *partab_d;
    char resnam[32];
    $DESCRIPTOR(resnam_d, resnam);
    short reslen;
    int l_attr_v = 0, *l_attr = NULL;
    int quota_v = 0, *quota = NULL;
    int acmode_v, *acmode = NULL;
    int sts;

    if (!SvROK(lnm) || (SvTYPE(SvRV(lnm)) != SVt_PVHV))
        croak("Argument must be a hash ref");
    hv = (HV *) SvRV(lnm);
    sv = hv_fetch(hv, "quota", 5, 0);
    if (sv)
    {
        quota_v = SvIV(*sv);
	quota = &quota_v;
    }
    sv = hv_fetch(hv, "attr", 4, 0);
    if (sv)
    {
        if (!SvROK(*sv) || (SvTYPE(SvRV(*sv)) != SVt_PVHV))
            croak("attr must be a hash ref");
	l_attr_v = translate_attributes((HV *)SvRV(*sv), WHERE_TBL_DEF);
        l_attr = &l_attr_v;
    }
    tabnam_d = get_hash_string_desc(hv, "table");
    partab_d = get_hash_string_desc(hv, "partab");
    sv = hv_fetch(hv, "acmode", 6, 0);
    if (sv)
    {
        acmode_v = find_access_mode(*sv);
        if (acmode_v == -1)
            croak("Invalid access mode");
        acmode = &acmode_v;
    }
    sts = sys$crelnt(l_attr, &resnam_d, &reslen, quota, /* promask */0,
		     tabnam_d, partab_d, acmode);
    if (sts & 1)
    {
	RETVAL = newSVpvn(resnam,reslen);
	SETERRNO(0,sts);
    }
    else
    {
	RETVAL = &PL_sv_undef;
	SETERRNO(EVMSERR,sts);
    }
    if (tabnam_d)
        free_desc(tabnam_d);
    if (partab_d)
        free_desc(partab_d);
  OUTPUT:
    RETVAL
