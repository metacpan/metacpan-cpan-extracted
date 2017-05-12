#include "text-mecab.h"
#include "config-const.h"

static int
TextMeCab_mg_free(pTHX_ SV *const sv, MAGIC* const mg)
{
    TextMeCab* const mecab = (TextMeCab*) mg->mg_ptr;

    PERL_UNUSED_VAR(sv);
    mecab_destroy(XS_2MECAB(mecab));
    if (mecab->argc > 0) {
        unsigned int i;
        for ( i = 0; i < mecab->argc; i++) {
            Safefree(mecab->argv[i]);
        }
        Safefree(mecab->argv);
    }
    return 0;
}

static int
TextMeCab_mg_dup(pTHX_ MAGIC *const mg, CLONE_PARAMS *const param)
{
#ifdef USE_ITHREADS
    TextMeCab* const mecab = (TextMeCab*) mg->mg_ptr;
    TextMeCab* newmecab;

    PERL_UNUSED_VAR(param);

    newmecab = TextMeCab_create(mecab->argv, mecab->argc);
    mg->mg_ptr = (char *) newmecab;
#else
    PERL_UNUSED_VAR(mg);
    PERL_UNUSED_VAR(param);
#endif
    return 0;
}

static MAGIC*
TextMeCab_mg_find(pTHX_ SV* const sv, const MGVTBL* const vtbl){
    MAGIC* mg;

    assert(sv   != NULL);
    assert(vtbl != NULL);

    for(mg = SvMAGIC(sv); mg; mg = mg->mg_moremagic){
        if(mg->mg_virtual == vtbl){
            assert(mg->mg_type == PERL_MAGIC_ext);
            return mg;
        }
    }

    croak("PerlMeCab: Invalid PerlMeCab object was passed");
    return NULL; /* not reached */
}

static MGVTBL TextMeCab_vtbl = { /* for identity */
    NULL, /* get */
    NULL, /* set */
    NULL, /* len */
    NULL, /* clear */
    TextMeCab_mg_free, /* free */
    NULL, /* copy */
    TextMeCab_mg_dup, /* dup */
    NULL,  /* local */
};

static void
register_constants()
{
    HV *stash = gv_stashpv("Text::MeCab", TRUE);

#if HAVE_MECAB_NOR_NODE
    newCONSTSUB(stash, "MECAB_NOR_NODE", newSViv(MECAB_NOR_NODE));
#endif
#if HAVE_MECAB_UNK_NODE
    newCONSTSUB(stash, "MECAB_UNK_NODE", newSViv(MECAB_UNK_NODE));
#endif
#if HAVE_MECAB_BOS_NODE
    newCONSTSUB(stash, "MECAB_BOS_NODE", newSViv(MECAB_BOS_NODE));
#endif
#if HAVE_MECAB_EOS_NODE
    newCONSTSUB(stash, "MECAB_EOS_NODE", newSViv(MECAB_EOS_NODE));
#endif
#if HAVE_MECAB_EON_NODE
    newCONSTSUB(stash, "MECAB_EON_NODE", newSViv(MECAB_EON_NODE));
#endif

#if HAVE_MECAB_SYS_DIC
    newCONSTSUB(stash, "MECAB_SYS_DIC", newSViv(MECAB_SYS_DIC));
#endif
#if HAVE_MECAB_USR_DIC
    newCONSTSUB(stash, "MECAB_USR_DIC", newSViv(MECAB_USR_DIC));
#endif
#if HAVE_MECAB_UNK_DIC
    newCONSTSUB(stash, "MECAB_UNK_DIC", newSViv(MECAB_UNK_DIC));
#endif

#if HAVE_MECAB_ONE_BEST
    newCONSTSUB(stash, "MECAB_ONE_BEST",      newSViv(MECAB_ONE_BEST));
#endif
#if HAVE_MECAB_NBEST
    newCONSTSUB(stash, "MECAB_NBEST",         newSViv(MECAB_NBEST));
#endif
#if HAVE_MECAB_PARTIAL
    newCONSTSUB(stash, "MECAB_PARTIAL",       newSViv(MECAB_PARTIAL));
#endif
#if HAVE_MECAB_MARGINAL_PROB
    newCONSTSUB(stash, "MECAB_MARGINAL_PROB", newSViv(MECAB_MARGINAL_PROB));
#endif
#if HAVE_MECAB_ALTERNATIVE
    newCONSTSUB(stash, "MECAB_ALTERNATIVE",   newSViv(MECAB_ALTERNATIVE));
#endif
#if HAVE_MECAB_ALL_MORPHS
    newCONSTSUB(stash, "MECAB_ALL_MORPHS",    newSViv(MECAB_ALL_MORPHS));
#endif
#if HAVE_MECAB_ALLOCATE_SENTENCE
    newCONSTSUB(stash, "MECAB_ALLOCATE_SENTENCE", newSViv(MECAB_ALLOCATE_SENTENCE));
#endif
}


MODULE = Text::MeCab    PACKAGE = Text::MeCab    PREFIX = TextMeCab_

PROTOTYPES: DISABLE

BOOT:
    TextMeCab_bootstrap();
    register_constants();

TextMeCab *
TextMeCab__xs_create(class_sv, args = NULL)
        SV *class_sv;
        AV *args;
    CODE:
        RETVAL = TextMeCab_create_from_av(args);
    OUTPUT:
        RETVAL

TextMeCab_Node *
TextMeCab_parse(mecab, string)
        TextMeCab *mecab;
        char *string;

char *
TextMeCab_version()
    CODE:
        RETVAL = (char *) mecab_version();
    OUTPUT:
        RETVAL

MODULE = Text::MeCab    PACKAGE = Text::MeCab::Node    PREFIX = TextMeCab_Node_

PROTOTYPES: DISABLE

unsigned int
TextMeCab_Node_id(node)
    TextMeCab_Node *node

unsigned int
TextMeCab_Node_length(node)
    TextMeCab_Node *node

unsigned int
TextMeCab_Node_rlength(node)
    TextMeCab_Node *node

TextMeCab_Node *
TextMeCab_Node_next(node)
    TextMeCab_Node *node

TextMeCab_Node *
TextMeCab_Node_prev(node)
    TextMeCab_Node *node

SV *
TextMeCab_Node_surface(node)
    TextMeCab_Node *node;

const char *
TextMeCab_Node_feature(node)
    TextMeCab_Node *node;

unsigned short
TextMeCab_Node_rcattr(node)
    TextMeCab_Node *node;

unsigned short
TextMeCab_Node_lcattr(node)
    TextMeCab_Node *node;

unsigned short
TextMeCab_Node_posid(node)
    TextMeCab_Node *node;

unsigned char
TextMeCab_Node_char_type(node)
    TextMeCab_Node *node;

unsigned char
TextMeCab_Node_stat(node)
    TextMeCab_Node *node;

unsigned char
TextMeCab_Node_isbest(node)
    TextMeCab_Node *node;

float
TextMeCab_Node_alpha(node)
    TextMeCab_Node *node;

float
TextMeCab_Node_beta(node)
    TextMeCab_Node *node;

float
TextMeCab_Node_prob(node)
    TextMeCab_Node *node;

short
TextMeCab_Node_wcost(node)
    TextMeCab_Node *node;

long
TextMeCab_Node_cost(node)
    TextMeCab_Node *node;

const char *
TextMeCab_Node_format(node, mecab)
        TextMeCab_Node *node;
        TextMeCab      *mecab;

TextMeCab_Node_Cloned*
TextMeCab_Node_dclone(node)
    TextMeCab_Node *node;

MODULE = Text::MeCab    PACKAGE = Text::MeCab::Node::Cloned    PREFIX = TextMeCab_Node_Cloned_

PROTOTYPES: DISABLE

unsigned int
TextMeCab_Node_Cloned_id(node)
        TextMeCab_Node_Cloned *node

unsigned int
TextMeCab_Node_Cloned_length(node)
        TextMeCab_Node_Cloned *node

unsigned int
TextMeCab_Node_Cloned_rlength(node)
        TextMeCab_Node_Cloned *node

TextMeCab_Node_Cloned *
TextMeCab_Node_Cloned_next(node)
        TextMeCab_Node_Cloned *node

TextMeCab_Node_Cloned *
TextMeCab_Node_Cloned_prev(node)
        TextMeCab_Node_Cloned *node

const char *
TextMeCab_Node_Cloned_surface(node)
        TextMeCab_Node_Cloned *node;

const char *
TextMeCab_Node_Cloned_feature(node)
        TextMeCab_Node_Cloned *node;

unsigned short
TextMeCab_Node_Cloned_rcattr(node)
        TextMeCab_Node_Cloned *node;

unsigned short
TextMeCab_Node_Cloned_lcattr(node)
        TextMeCab_Node_Cloned *node;

unsigned short
TextMeCab_Node_Cloned_posid(node)
        TextMeCab_Node_Cloned *node;

unsigned char
TextMeCab_Node_Cloned_char_type(node)
        TextMeCab_Node_Cloned *node;

unsigned char
TextMeCab_Node_Cloned_stat(node)
        TextMeCab_Node_Cloned *node;

unsigned char
TextMeCab_Node_Cloned_isbest(node)
        TextMeCab_Node_Cloned *node;

float
TextMeCab_Node_Cloned_alpha(node)
        TextMeCab_Node_Cloned *node;

float
TextMeCab_Node_Cloned_beta(node)
        TextMeCab_Node_Cloned *node;

float
TextMeCab_Node_Cloned_prob(node)
        TextMeCab_Node_Cloned *node;

short
TextMeCab_Node_Cloned_wcost(node)
        TextMeCab_Node_Cloned *node;

long
TextMeCab_Node_Cloned_cost(node)
        TextMeCab_Node_Cloned *node;

const char *
TextMeCab_Node_Cloned_format(node, mecab)
        TextMeCab_Node_Cloned *node;
        TextMeCab             *mecab;

void 
TextMeCab_Node_Cloned_DESTROY(node)
        TextMeCab_Node_Cloned *node;
    CODE:
        TextMeCab_Node_Cloned_free(node);
