#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "txs_hash.h"

#ifdef TXS_SUB_OP
#include "sub_op.h"
#endif

/*Change this if you care. Note that the memory used is this number
 multiplied by 256 again. The default is 256 * 256 == 65535 */

#define CHARTABLE_MAX 256

typedef unsigned char TXS_chartable_t[256];

#define txs_search_from_sv(sv) (struct TXS_Search*)(SvUVX(sv))
#define terms_from_search(srch) \
    (struct TXS_String*)(((char*)srch) + sizeof(struct TXS_Search))

#define TXS_COUNTERS

#ifdef TXS_COUNTERS
#define OPTIMIZE_STATS_FIELDS \
struct { \
    int opti_lengths; \
    int opti_chartable; \
    int opti_hash_firstpass; \
    int opti_hash_secondpass; \
    int opti_none; \
    int opti_8; \
    int opti_4; \
    int opti_2; \
} statistics ;

#define txs_inc_counter(srchp, v) \
    (srchp->statistics.opti_ ## v)++;

#define _txs_dumpstat(srchp, stat) \
    printf("%s: %d\n", "TXS Optimized: " #stat, srch->statistics.opti_ ## stat);

#define txs_dump_stats(srchp) \
    _txs_dumpstat(srchp, lengths); _txs_dumpstat(srchp, chartable); \
    _txs_dumpstat(srchp, hash_firstpass); _txs_dumpstat(srchp, hash_secondpass); \
    _txs_dumpstat(srch, none);
#else

#define OPTIMIZE_STATS_FIELDS
#define txs_inc_counter(a, b)
#define txs_dump_stats(a)

#endif


enum {
    TXSf_BAD_CHARTABLE = 1 << 0
};

typedef uint8_t TXS_termlen_t;

struct TXS_Search {    
    int flags;
    
    /*The number of prefixes*/
    int term_count;
    
    /*The minimum (or rather, maximum) common prefix length for all prefixes*/
    int min_len;
    
    /*The maximum length for a term*/
    int max_len;
    
    /*How many unique lengths*/
    int term_lengths_max;
    
    /*If being kept across threads, we make duplicate pointer
     references to our structure. This counter is set to one
     for new object creation, and then increased by one during
     each svt_dup, and decreased by one during svt_free*/
    int refcount;    
    
    /*Sparse array for checking the existence of a char in a given position
     for any term*/    
    TXS_chartable_t chartable[CHARTABLE_MAX];
        
    /*Static array of term_lengths_max lengths*/
    TXS_termlen_t term_lengths[CHARTABLE_MAX];
    
    /*Prefix tree - This is a hash which is checked in the first hash pass,
     and its keys are substrings of prefix, all exactly min_len length*/
    struct TXS_HashTable *ht_min;
    
    /*Full match index. This contains the actual prefixes in hash
     form, and is traversed on the second hash pass*/
    struct TXS_HashTable *ht_full;
        
    /*Optimizations and statistics*/
    OPTIMIZE_STATS_FIELDS;
};

static int txs_freehook(pTHX_ SV* mysv, MAGIC* mg);
static int txs_duphook(pTHX_ MAGIC *mg, CLONE_PARAMS *param);
static void THX_txs_sv_init(pTHX_ SV *mysv, struct TXS_Search *srch);
#define txs_sv_init(mysv, srch) THX_txs_sv_init(aTHX_ mysv, srch)

static MGVTBL txs_vtbl = {
    .svt_free = txs_freehook,
    .svt_dup = txs_duphook
};


typedef int(*txs_compar_fn_t)(const void*, const void*);

static int _compar(const TXS_termlen_t *i1, const TXS_termlen_t *i2)
{
    if(*i1 < *i2) {
        return -1;
    } else if ( *i1 == *i2 ) {
        die("Didn't expect to find equal!");
    } else {
        return 1;
    }
}

#define term_sanity_check(svpp, idx) \
    if(!svpp) { die("Terms list is partially empty at idx=%d", idx); } \
    if(SvROK(*svpp)) { die("Found reference in terms list at idx=%d", idx); } \
    if(sv_len(*svpp) > CHARTABLE_MAX ) { \
        die("Found string larger than %d at idx=%d", CHARTABLE_MAX, idx); \
    }

#define study_terms(srch, mortal_av) THX_study_terms(aTHX_ srch, mortal_av)
static void THX_study_terms(
    pTHX_
    struct TXS_Search *srch,
    AV *mortal_av)
{
    SV **old_sv = NULL;
    char *term_s = NULL;
    STRLEN term_len = 0;
    int i, j;
    int len_idx = 0;
    int sort_min = 0;
    
    int max = av_len(mortal_av);
    
    for(i = 0; i <= max; i++) {
        SV **old_sv = av_fetch(mortal_av, i, 0);
        term_sanity_check(old_sv, i);
        
        term_s = SvPV(*old_sv, term_len);
        for(j = 0; j < term_len; j++) {
            srch->chartable[j][(unsigned char)term_s[j]] = 1;
        }
        
        
        /*Avoid duplicates*/
        for(j = 0; j < len_idx; j++) {
            if(srch->term_lengths[j] == term_len) {
                j = -1;
                break;
            }
        }
        
        if(j == len_idx) {
            srch->term_lengths[len_idx++] = term_len;
        }
    }
    
    /*Sort the lengths list*/
    qsort(srch->term_lengths, len_idx, sizeof(TXS_termlen_t),
      (txs_compar_fn_t)&_compar);
    
    len_idx--;
    
    srch->term_lengths_max = len_idx;
    srch->max_len = srch->term_lengths[len_idx];
    srch->min_len = srch->term_lengths[0];
    
    srch->term_count = max;
    
    //build_chartable_cost(srch);
}

#define prefix_search_build(av) THX_prefix_search_build(aTHX_ av);
SV* THX_prefix_search_build(pTHX_ AV *mortal_av)
{
    int i = 0, j = 0;
    int max = av_len(mortal_av);
    int my_len = sizeof(struct TXS_Search);
	
    char *term_s = NULL;
    STRLEN term_len = 0;
    char *strlist_p = NULL;
        
    struct TXS_String *strp = NULL;
    struct TXS_Search *srch = NULL;
    struct TXS_String *terms = NULL;
    
    Newxz(srch, my_len, char);
    srch->refcount = 1;
    
    SV *mysv = newSVuv((UV)srch);
    HV *fullmatch = newHV();
    HV *trie = newHV();
	
	HV *stash;
	SV *blessed;
        
    study_terms(srch, mortal_av);
	
    for(i = 0; i <= max; i++) {
        SV **a_term = av_fetch(mortal_av, i, 0);
        term_s = SvPV(*a_term, term_len);
        hv_store(fullmatch, term_s, term_len, &PL_sv_undef, 0);
        hv_store(trie, term_s, srch->min_len, &PL_sv_undef, 0);
        
    }
    
    srch->ht_full = txs_ht_build(fullmatch);
    srch->ht_min = txs_ht_build(trie);
    
    SvREFCNT_dec(fullmatch);
    SvREFCNT_dec(trie);
    	
    /*Study the chartable, and see if it's worthwhile performing
     lookups against it*/
    txs_sv_init(mysv, srch);
	blessed = newRV_noinc(mysv);
	stash = gv_stashpv("Text::Prefix::XS", 0);
	if(!stash) {
		die("Couldn't get stash!");
	}
	sv_bless(blessed, stash);
	return blessed;
}

#define prefix_search(mysv, input_sv) THX_prefix_search(aTHX_ mysv, input_sv)
SV* THX_prefix_search(pTHX_ SV* mysv, SV *input_sv)
{
    register int i = 1, j = 0;

    SV *ret = &PL_sv_undef;
    
    register struct TXS_String *strp;
    register int strp_len;
    STRLEN input_len;
    
    register int term_len;
    int match_len = 0;
    int can_match = 0;
    
    char *input = SvPV(input_sv, input_len);
    if(!SvROK(mysv)) {
        die("Not a valid search blob");
    }
    struct TXS_Search *srch = txs_search_from_sv(SvRV(mysv));
    struct TXS_String *terms = terms_from_search(srch);
    
    if(input_len < srch->term_lengths[0]) {
        /*Too short!*/
        goto GT_RET;
    }
    
    /*FIRST PASS:
     * Check all prefix lengths, and see if we're eligible for any*/
    for(i = 0; i <= srch->term_lengths_max; i++) {
        term_len = srch->term_lengths[i];
        
        if(term_len > input_len) {
            break;
        }
        
        /*We can. Break*/
        if(srch->chartable[term_len-1][ (unsigned char)input[term_len-1] ]) {
            can_match = 1;
            break;
        }
    }
    
    if(!can_match) {
        txs_inc_counter(srch, lengths);
        goto GT_RET;
    }

    /* SECOND PASS:
     * In our little game of hangman, we know the that we have a last character
     * for at least one prefix.
     *
     * Now, check for non-existent characters in any of the rest of the
     * prefixes, for the smallest prefix size
    */
    for(i = 0; i < srch->min_len; i++) {
        if(!srch->chartable[i][ (unsigned char)input[i] ]) {
            txs_inc_counter(srch, chartable);
            goto GT_RET;
        }
    }

    /*THIRD PASS:
     * Check if the sequence up to the minimum prefix length is valid*/
    if(!txs_ht_check(srch->ht_min, input, srch->min_len)) {
        txs_inc_counter(srch, hash_firstpass);
        goto GT_RET;
    }
    
    /*FOURTH PASS:
     * Check if we have a valid full prefix. If can_match ends up being true, 
     * it essentially means we will ALWAYS have a match*/
    can_match = 0;
    for(i = 0; i <= srch->term_lengths_max; i++) {
        term_len = srch->term_lengths[i];
        if(term_len > input_len) {
            warn("Too short!");
            break;
        }
        
        if(txs_ht_check(srch->ht_full, input, term_len)) {
            can_match = 1;
            break;
        }
    }
    
    if(!can_match) {
        txs_inc_counter(srch, hash_secondpass);
        goto GT_RET;
    }

    match_len = term_len;
    for(j = srch->term_lengths_max; j > i; j--) {
        term_len = srch->term_lengths[j];
        if(term_len > input_len) { 
            continue;
        }

        if(txs_ht_check(srch->ht_full, input, term_len)) {
            match_len = term_len;
            break;
        }
    }
    ret = newSVpv(input, match_len);
    if(SvUTF8(input_sv)) {
        SvUTF8_on(ret);
    }
    goto GT_RET;
	
    GT_RET:
    return ret;        
}

#define _print_optimized(v) printf("%s: %d\n", #v, (Optimized_ ## v))


#define prefix_search_multi(mysv, input_strings) \
    THX_prefix_search_multi(aTHX_ mysv, input_strings)
SV* THX_prefix_search_multi(pTHX_ SV* mysv, AV *input_strings)
{
    int i = 0;
    int max = av_len(input_strings);
    HV *ret = newHV();
    
    SV **cur_sv;
    AV *tmpav = NULL;
    SV *prefix = NULL;
    HE *prefix_ret_ent = NULL;
    
    for(i = 0; i <= max; i++) {
        cur_sv = av_fetch(input_strings, i, 0);
        
        if(!cur_sv || (!SvPV_nolen(*cur_sv)) ) {
            /*Non existent or not a string. We don't care about SvPV since it's
            gonna get converted anyway*/
            continue;
        }
        
        prefix = prefix_search(mysv, *cur_sv);
        if(prefix == &PL_sv_undef) {
            continue;
        }
                
        prefix_ret_ent = hv_fetch_ent(ret, prefix, 0, 0);
        if(!prefix_ret_ent) {
            prefix_ret_ent = hv_store_ent(
                        ret, prefix, newRV_noinc((SV*)newAV()), 0);
        }
        
        tmpav = SvRV(HeVAL(prefix_ret_ent));
        av_store(tmpav, av_len(tmpav)+1, newSVsv(*cur_sv));
    }
    return newRV_noinc((SV*)ret);
}

#ifdef TXS_SUB_OP
static OP* TXS_OP_psearch(pTHX)
{
    dXSARGS;
    SV *input = POPs;
    SV *mysv = POPs;
    SV *ret = prefix_search(mysv, input);
    PUSHs(ret);
    XSRETURN(1);
}
#endif

#define prefix_search_dump(mysv) THX_prefix_search_dump(aTHX_ mysv)
SV* THX_prefix_search_dump(pTHX_ SV *mysv)
{
    if(!SvROK(mysv)) {
        die("Bad parameter!");
    }
    
    struct TXS_Search *srch = txs_search_from_sv(SvRV(mysv));
    txs_dump_stats(srch);
	
	printf("ht_min: ");
	txs_ht_dump_stats(srch->ht_min);
	
	printf("ht_full: ");
	txs_ht_dump_stats(srch->ht_full);
	
    return &PL_sv_undef;
}

static int txs_freehook(pTHX_ SV *mysv, MAGIC *mg)
{
    struct TXS_Search *srch = (struct TXS_Search*)mg->mg_ptr;
    if(PL_dirty) {
        return 0;
    }
    
    if(!srch) {
        warn("TXS_Search object has already been freed?");
        return 0;
    }
    
    srch->refcount--;
    
    //warn("srch->refcount: %d", srch->refcount);
    
    if(!srch->refcount) {
        //warn("TXS: Search being destroyed..");
        txs_ht_free(srch->ht_full);
        txs_ht_free(srch->ht_min);
        Safefree(srch);
        mg->mg_ptr = NULL;
    }
}

static int txs_duphook(pTHX_ MAGIC *mg, CLONE_PARAMS *param)
{
    struct TXS_Search *srch = txs_search_from_sv(mg->mg_obj);
    srch->refcount++;
}

static void THX_txs_sv_init(pTHX_ SV *mysv, struct TXS_Search *srch)
{
    MAGIC *mg = sv_magicext(mysv, mysv,
                PERL_MAGIC_ext, &txs_vtbl,
                (char*)srch, 0);
    srch->refcount = 1;
    mg->mg_flags |= MGf_DUP;    
}

MODULE = Text::Prefix::XS    PACKAGE = Text::Prefix::XS

BOOT:
{
#ifdef TXS_SUB_OP
     sub_op_config_t c;
     c.name    = "psearch";
     c.namelen = sizeof("psearch")-1;
     c.pp      = TXS_OP_psearch;
     c.check   = 0;
     c.ud      = NULL;
     sub_op_register(aTHX_ &c);
#else
     ;
#endif
}

PROTOTYPES: DISABLE


SV *
prefix_search_build (av_terms)
    AV *    av_terms

PROTOTYPES: ENABLE

SV *
prefix_search (mysv, input)
    SV *    mysv
    SV *    input
    PROTOTYPE: $$



SV *
prefix_search_multi (mysv, input_strings)
    SV *    mysv
    AV *    input_strings
    PROTOTYPE: $\@

SV *prefix_search_dump (mysv)
    SV *    mysv
