/*
	ptr_table.h - ptr_table compatible functions for older perls

	This file is originated from sv.c of 5.10.0.
*/

/*
 * LISENCE AND COPYRIGHT in sv.c:
 *
 *    Copyright (C) 1991, 1992, 1993, 1994, 1995, 1996, 1997, 1998, 1999,
 *    2000, 2001, 2002, 2003, 2004, 2005, 2006, 2007, by Larry Wall and others
 *
 *    You may distribute under the terms of either the GNU General Public
 *    License or the Artistic License, as specified in the README file.
 *
*/

#ifdef TESTING_PTR_TABLE_COMPAT
#undef ptr_table_new
#undef ptr_table_find
#undef ptr_table_fetch
#undef ptr_table_store
#undef ptr_table_split
#undef ptr_table_clear
#undef ptr_table_free
#endif

#ifndef ptr_table_new

/*
    PTR_TBL_t and PTR_TBL_ENT_t are defined in perl.h
*/

#define PTE_SVSLOT
#define new_body_inline(pte, type) Newx(pte, 1, PTR_TBL_ENT_t)
#define del_pte(pte)               Safefree(pte)

#define ptr_table_new()                my_ptr_table_new(aTHX)
#define ptr_table_find(tbl, sv)        my_ptr_table_find(aTHX_ tbl, sv)
#define ptr_table_fetch(tbl, key)      my_ptr_table_fetch(aTHX_ tbl, key)
#define ptr_table_store(tbl, key, val) my_ptr_table_store(aTHX_ tbl, key, val)
#define ptr_table_split(tbl)           my_ptr_table_split(aTHX_ tbl)
#define ptr_table_clear(tbl)           my_ptr_table_clear(aTHX_ tbl)
#define ptr_table_free(tbl)            my_ptr_table_free(aTHX_ tbl)


#define PTR_TABLE_HASH(ptr) \
  ((PTR2UV(ptr) >> 3) ^ (PTR2UV(ptr) >> (3 + 7)) ^ (PTR2UV(ptr) >> (3 + 17)))


static PTR_TBL_t *
my_ptr_table_new(pTHX)
{
    PTR_TBL_t *tbl;
    PERL_UNUSED_CONTEXT;

    Newxz(tbl, 1, PTR_TBL_t);
    tbl->tbl_max	= 511;
    tbl->tbl_items	= 0;
    Newxz(tbl->tbl_ary, tbl->tbl_max + 1, PTR_TBL_ENT_t*);
    return tbl;
}

static void
my_ptr_table_split(pTHX_ PTR_TBL_t * const tbl)
{
    PTR_TBL_ENT_t **ary = tbl->tbl_ary;
    const UV oldsize = tbl->tbl_max + 1;
    UV newsize = oldsize * 2;
    UV i;
    PERL_UNUSED_CONTEXT;

    Renew(ary, newsize, PTR_TBL_ENT_t*);
    Zero(&ary[oldsize], newsize-oldsize, PTR_TBL_ENT_t*);
    tbl->tbl_max = --newsize;
    tbl->tbl_ary = ary;
    for (i=0; i < oldsize; i++, ary++) {
	PTR_TBL_ENT_t **curentp, **entp, *ent;
	if (!*ary)
	    continue;
	curentp = ary + oldsize;
	for (entp = ary, ent = *ary; ent; ent = *entp) {
	    if ((newsize & PTR_TABLE_HASH(ent->oldval)) != i) {
		*entp = ent->next;
		ent->next = *curentp;
		*curentp = ent;
		continue;
	    }
	    else
		entp = &ent->next;
	}
    }
}

static PTR_TBL_ENT_t *
my_ptr_table_find(pTHX_ PTR_TBL_t const * const tbl, const void * const sv) {
    PTR_TBL_ENT_t *tblent;
    PERL_UNUSED_CONTEXT;

    assert(tbl);
    tblent = tbl->tbl_ary[PTR_TABLE_HASH(sv) & tbl->tbl_max];
    for (; tblent; tblent = tblent->next) {
	if (tblent->oldval == sv)
	    return tblent;
    }
    return NULL;
}

static void *
my_ptr_table_fetch(pTHX_ const PTR_TBL_t * const tbl, const void * const sv)
{
    PTR_TBL_ENT_t const *const tblent = ptr_table_find(tbl, sv);
    PERL_UNUSED_CONTEXT;
    return tblent ? tblent->newval : NULL;
}

static void
my_ptr_table_store(pTHX_ PTR_TBL_t * const tbl, const void * const oldsv, void * const newsv)
{
    PTR_TBL_ENT_t *tblent = ptr_table_find(tbl, oldsv);

    if (tblent) {
	tblent->newval = newsv;
    } else {
	const UV entry = PTR_TABLE_HASH(oldsv) & tbl->tbl_max;

	new_body_inline(tblent, PTE_SVSLOT);

	tblent->oldval = oldsv;
	tblent->newval = newsv;
	tblent->next = tbl->tbl_ary[entry];
	tbl->tbl_ary[entry] = tblent;
	tbl->tbl_items++;
	if (tblent->next && tbl->tbl_items > tbl->tbl_max)
	    ptr_table_split(tbl);
    }
}


static void
my_ptr_table_clear(pTHX_ PTR_TBL_t * const tbl)
{
    assert(tbl);
    if (tbl->tbl_items) {
	PTR_TBL_ENT_t * const * const array = tbl->tbl_ary;
	UV riter = tbl->tbl_max;

	do {
	    PTR_TBL_ENT_t *entry = array[riter];

	    while (entry) {
		PTR_TBL_ENT_t * const oentry = entry;
		entry = entry->next;
		del_pte(oentry);
	    }
	} while (riter--);

	tbl->tbl_items = 0;
    }
}

static void
my_ptr_table_free(pTHX_ PTR_TBL_t * const tbl)
{
    assert(tbl);
    ptr_table_clear(tbl);
    Safefree(tbl->tbl_ary);
    Safefree(tbl);
}

#endif /* !ptr_table_new */

