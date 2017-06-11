#ifndef __TEXT_CABOCHA_H__
#define __TEXT_CABOCHA_H__

#include <cabocha.h>
#include "config-const.h"

#ifdef __cplusplus
extern "C" {
#endif

#define PERL_NO_GET_CONTEXT /* we want efficiency */
#include <EXTERN.h>
#include <perl.h>
#include <XSUB.h>
#include "ppport.h"

#ifdef __cplusplus
} /* extern "C" */
#endif

#define NEED_newCONSTSUB
#define NEED_newRV_noinc
#define NEED_sv_2pv_nolen
#define NEED_sv_2pv_flags
#define NEED_newSVpvn_flags

#define TEXT_CABOCHA_TOKEN_KLASS "Text::CaboCha::Token"
#define TEXT_CABOCHA_CHUNK_KLASS "Text::CaboCha::Chunk"

#ifndef TEXT_CABOCHA_DEBUG
#define TEXT_CABOCHA_DEBUG 0
#endif

#define XS_STATE(type, x) \
    INT2PTR(type, SvROK(x) ? SvIV(SvRV(x)) : SvIV(x))

#define XS_STRUCT2OBJ(sv, class, obj) \
    if (obj == NULL) { \
        sv_setsv(sv, &PL_sv_undef); \
    } else { \
        sv_setref_pv(sv, class, (void *)obj); \
    }

typedef struct {
    CaboCha::Parser *cabocha;
    char **argv;
    unsigned int argc;
} TextCaboCha;

typedef CaboCha::Tree   TextCaboCha_Tree;
typedef cabocha_token_t TextCaboCha_Token;
typedef cabocha_chunk_t TextCaboCha_Chunk;

typedef mecab_node_t TextMeCab_Node;

#define XS_2CABOCHA(x) x->cabocha

/* Text::CaboCha */
void TextCaboCha_bootstrap();
TextCaboCha *TextCaboCha_create(char **argv, unsigned int argc);
TextCaboCha *TextCaboCha_create_from_av(AV *av);
TextCaboCha_Tree *TextCaboCha_parse(TextCaboCha *cabocha, char *string);
TextCaboCha_Tree *TextCaboCha_parse_from_node(TextCaboCha *cabocha, const TextMeCab_Node *node);

/* Text::CaboCha::Tree */
size_t TextCaboCha_Tree_size(TextCaboCha_Tree *tree);
size_t TextCaboCha_Tree_token_size(TextCaboCha_Tree *tree);
SV *TextCaboCha_Tree_tokens(TextCaboCha_Tree *tree);
SV *TextCaboCha_Tree_chunks(TextCaboCha_Tree *tree);
const TextCaboCha_Token *TextCaboCha_Tree_token(TextCaboCha_Tree *tree, size_t size);
size_t TextCaboCha_Tree_chunk_size(TextCaboCha_Tree *tree);
const TextCaboCha_Chunk *TextCaboCha_Tree_chunk(TextCaboCha_Tree *tree, size_t size);
const char *TextCaboCha_Tree_tostr(TextCaboCha_Tree *tree, unsigned int format);

/* Text::CaboCha::Token */

#define CABOCHA_TOKEN_SURFACE(x)            x ? x->surface            : NULL
#define CABOCHA_TOKEN_NORMALIZED_SURFACE(x) x ? x->normalized_surface : NULL
#define CABOCHA_TOKEN_FEATURE(x)            x ? x->feature            : NULL
#define CABOCHA_TOKEN_FEATURE_LIST(x)       x ? x->feature_list       : NULL
#define CABOCHA_TOKEN_FEATURE_LIST_SIZE(x)  x ? x->feature_list_size  : -1
#define CABOCHA_TOKEN_NE(x)                 x ? x->ne                 : NULL
#define CABOCHA_TOKEN_ADDITIONAL_INFO(x)    x ? x->additional_info    : NULL
#define CABOCHA_TOKEN_CHUNK(x)              x ? x->chunk              : NULL

const char *TextCaboCha_Token_surface(TextCaboCha_Token *token);
const char *TextCaboCha_Token_normalized_surface(TextCaboCha_Token *token);
const char *TextCaboCha_Token_feature(TextCaboCha_Token *token);
SV *TextCaboCha_Token_feature_list(TextCaboCha_Token *token);
unsigned short TextCaboCha_Token_feature_list_size(TextCaboCha_Token *token);
const char *TextCaboCha_Token_ne(TextCaboCha_Token *token);
const char *TextCaboCha_Token_additional_info(TextCaboCha_Token *token);
TextCaboCha_Chunk *TextCaboCha_Token_chunk(TextCaboCha_Token *token);

/* Text::CaboCha::Chunk */

#define CABOCHA_CHUNK_LINK(x)              x ? x->link              : -1
#define CABOCHA_CHUNK_HEAD_POS(x)          x ? x->head_pos          : -1
#define CABOCHA_CHUNK_FUNC_POS(x)          x ? x->func_pos          : -1
#define CABOCHA_CHUNK_TOKEN_SIZE(x)        x ? x->token_size        : -1
#define CABOCHA_CHUNK_TOKEN_POS(x)         x ? x->token_pos         : -1
#define CABOCHA_CHUNK_SCORE(x)             x ? x->score             : -1
#define CABOCHA_CHUNK_FEATURE_LIST(x)      x ? x->feature_list      : NULL
#define CABOCHA_CHUNK_ADDITIONAL_INFO(x)   x ? x->additional_info   : NULL
#define CABOCHA_CHUNK_FEATURE_LIST_SIZE(x) x ? x->feature_list_size : -1

int TextCaboCha_Chunk_link(TextCaboCha_Chunk *chunk);
size_t TextCaboCha_Chunk_head_pos(TextCaboCha_Chunk *chunk);
size_t TextCaboCha_Chunk_func_pos(TextCaboCha_Chunk *chunk);
size_t TextCaboCha_Chunk_token_size(TextCaboCha_Chunk *chunk);
size_t TextCaboCha_Chunk_token_pos(TextCaboCha_Chunk *chunk);
float TextCaboCha_Chunk_score(TextCaboCha_Chunk *chunk);
SV *TextCaboCha_Chunk_feature_list(TextCaboCha_Chunk *chunk);
const char *TextCaboCha_Chunk_additional_info(TextCaboCha_Chunk *chunk);
unsigned short int TextCaboCha_Chunk_list_size(TextCaboCha_Chunk *chunk);

#endif /* __TEXT_CABOCHA_H__ */