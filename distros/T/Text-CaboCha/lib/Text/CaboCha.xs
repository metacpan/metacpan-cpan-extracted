#include "text-cabocha.h"

/* Text::CaboCha */
static MAGIC*
TextCaboCha_mg_find(pTHX_ SV* const sv, const MGVTBL* const vtbl){
    MAGIC* mg;

    assert(sv   != NULL);
    assert(vtbl != NULL);

    for (mg = SvMAGIC(sv); mg; mg = mg->mg_moremagic){
        if (mg->mg_virtual == vtbl) {
            assert(mg->mg_type == PERL_MAGIC_ext);
            return mg;
        }
    }

    croak("PerlCaboCha: Invalid PerlCaboCha object was passed");
    return NULL; /* not reached */
}

static int
TextCaboCha_mg_free(pTHX_ SV *const sv, MAGIC* const mg)
{
    TextCaboCha * const cabocha = (TextCaboCha *)mg->mg_ptr;

    PERL_UNUSED_VAR(sv);
    delete XS_2CABOCHA(cabocha);
    if (cabocha->argc > 0) {
        unsigned int i;
        for (i = 0; i < cabocha->argc; i++) {
            Safefree(cabocha->argv[i]);
        }
        Safefree(cabocha->argv);
    }
    return 0;
}

static int
TextCaboCha_mg_dup(pTHX_ MAGIC *const mg, CLONE_PARAMS *const param)
{
#ifdef USE_ITHREADS
    TextCaboCha* const cabocha = (TextCaboCha *)mg->mg_ptr;
    TextCaboCha* newcabocha;

    PERL_UNUSED_VAR(param);

    newcabocha = TextCaboCha_create(cabocha->argv, cabocha->argc);
    mg->mg_ptr = newcabocha;
#else
    PERL_UNUSED_VAR(mg);
    PERL_UNUSED_VAR(param);
#endif
    return 0;
}

static MGVTBL TextCaboCha_vtbl = { /* for identity */
    NULL, /* get */
    NULL, /* set */
    NULL, /* len */
    NULL, /* clear */
    TextCaboCha_mg_free, /* free */
    NULL, /* copy */
    TextCaboCha_mg_dup, /* dup */
    NULL,  /* local */
};

static void
register_constants()
{
    HV *stash;
    stash = gv_stashpv("Text::CaboCha", TRUE);

/* Format */
#if HAVE_CABOCHA_FORMAT_TREE
    newCONSTSUB(stash, "CABOCHA_FORMAT_TREE", newSViv(CABOCHA_FORMAT_TREE));
#endif
#if HAVE_CABOCHA_FORMAT_LATTICE
    newCONSTSUB(stash, "CABOCHA_FORMAT_LATTICE", newSViv(CABOCHA_FORMAT_LATTICE));
#endif
#if HAVE_CABOCHA_FORMAT_TREE_LATTICE
    newCONSTSUB(stash, "CABOCHA_FORMAT_TREE_LATTICE", newSViv(CABOCHA_FORMAT_TREE_LATTICE));
#endif
#if HAVE_CABOCHA_FORMAT_XML
    newCONSTSUB(stash, "CABOCHA_FORMAT_XML", newSViv(CABOCHA_FORMAT_XML));
#endif
#if HAVE_CABOCHA_FORMAT_CONLL
    newCONSTSUB(stash, "CABOCHA_FORMAT_CONLL", newSViv(CABOCHA_FORMAT_CONLL));
#endif
#if HAVE_CABOCHA_FORMAT_NONE
    newCONSTSUB(stash, "CABOCHA_FORMAT_NONE", newSViv(CABOCHA_FORMAT_NONE));
#endif

}

MODULE = Text::CaboCha    PACKAGE = Text::CaboCha    PREFIX = TextCaboCha_

PROTOTYPES: DISABLE

BOOT:
    TextCaboCha_bootstrap();
    register_constants();

TextCaboCha *
TextCaboCha__xs_create(SV *class_sv, AV *args = NULL)
    CODE:
        RETVAL = TextCaboCha_create_from_av(args);
    OUTPUT:
        RETVAL

TextCaboCha_Tree *
TextCaboCha_parse(TextCaboCha *cabocha, char *string)

TextCaboCha_Tree *
TextCaboCha_parse_from_node(TextCaboCha *cabocha, const TextMeCab_Node *node)

const char *
TextCaboCha_version()
    CODE:
        RETVAL = CaboCha::Parser::version();
    OUTPUT:
        RETVAL

MODULE = Text::CaboCha    PACKAGE = Text::CaboCha::Tree    PREFIX = TextCaboCha_Tree_

PROTOTYPES: DISABLE

size_t
TextCaboCha_Tree_size(TextCaboCha_Tree *tree)

size_t
TextCaboCha_Tree_token_size(TextCaboCha_Tree *tree)

SV *
TextCaboCha_Tree_tokens(TextCaboCha_Tree *tree)

SV *
TextCaboCha_Tree_chunks(TextCaboCha_Tree *tree)

const TextCaboCha_Token *
TextCaboCha_Tree_token(TextCaboCha_Tree *tree, size_t size)

size_t
TextCaboCha_Tree_chunk_size(TextCaboCha_Tree *tree)

const TextCaboCha_Chunk *
TextCaboCha_Tree_chunk(TextCaboCha_Tree *tree, size_t size)

const char *
TextCaboCha_Tree_tostr(TextCaboCha_Tree *tree, unsigned int format)

MODULE = Text::CaboCha    PACKAGE = Text::CaboCha::Token    PREFIX = TextCaboCha_Token_

PROTOTYPES: DISABLE

const char *
TextCaboCha_Token_surface(TextCaboCha_Token *token)

const char *
TextCaboCha_Token_normalized_surface(TextCaboCha_Token *token)

const char *
TextCaboCha_Token_feature(TextCaboCha_Token *token)

SV *
TextCaboCha_Token_feature_list(TextCaboCha_Token *token)

unsigned short
TextCaboCha_Token_feature_list_size(TextCaboCha_Token *token)

const char *
TextCaboCha_Token_ne(TextCaboCha_Token *token)

const char *
TextCaboCha_Token_additional_info(TextCaboCha_Token *token)

TextCaboCha_Chunk *
TextCaboCha_Token_chunk(TextCaboCha_Token *token)

MODULE = Text::CaboCha    PACKAGE = Text::CaboCha::Chunk    PREFIX = TextCaboCha_Chunk_

PROTOTYPES: DISABLE

int
TextCaboCha_Chunk_link(TextCaboCha_Chunk *chunk)

size_t
TextCaboCha_Chunk_head_pos(TextCaboCha_Chunk *chunk)

size_t
TextCaboCha_Chunk_func_pos(TextCaboCha_Chunk *chunk)

size_t
TextCaboCha_Chunk_token_size(TextCaboCha_Chunk *chunk)

size_t
TextCaboCha_Chunk_token_pos(TextCaboCha_Chunk *chunk)

float
TextCaboCha_Chunk_score(TextCaboCha_Chunk *chunk)

SV *
TextCaboCha_Chunk_feature_list(TextCaboCha_Chunk *chunk)

const char *
TextCaboCha_Chunk_additional_info(TextCaboCha_Chunk *chunk)

unsigned short
TextCaboCha_Chunk_list_size(TextCaboCha_Chunk *chunk)