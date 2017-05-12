#ifndef __TEXT_MECAB_H__
#define __TEXT_MECAB_H__
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#define NEED_newCONSTSUB
#define NEED_newRV_noinc
#define NEED_sv_2pv_nolen
#define NEED_sv_2pv_flags
#include "ppport.h"
#include <mecab.h>

#ifndef TEXT_MECAB_DEBUG
#define TEXT_MECAB_DEBUG 0
#endif

#define XS_STATE(type, x) \
    INT2PTR(type, SvROK(x) ? SvIV(SvRV(x)) : SvIV(x))

#define XS_STRUCT2OBJ(sv, class, obj) \
    if (obj == NULL) { \
        sv_setsv(sv, &PL_sv_undef); \
    } else { \
        sv_setref_pv(sv, class, (void *) obj); \
    }

typedef struct {
    mecab_t *mecab;
    char **argv;
    unsigned int argc;
} TextMeCab;

typedef mecab_node_t TextMeCab_Node;

typedef struct TextMeCab_Node_Cloned_Meta {
    IV refcnt;
    struct TextMeCab_Node_Cloned *first;
} TextMeCab_Node_Cloned_Meta;

typedef struct TextMeCab_Node_Cloned {
    struct TextMeCab_Node_Cloned      *prev;
    struct TextMeCab_Node_Cloned      *next;
           TextMeCab_Node_Cloned_Meta *meta;
           TextMeCab_Node             *actual;
} TextMeCab_Node_Cloned;

#define XS_2MECAB(x) x->mecab

#define MECAB_NODE_ID(x) x ? x->id : 0 
#define MECAB_NODE_LENGTH(x) x ? x->length : -1
#define MECAB_NODE_RLENGTH(x) x ? x->rlength : -1
#define MECAB_NODE_NEXT(x) x ? x->next : NULL
#define MECAB_NODE_PREV(x) x ? x->prev : NULL
#define MECAB_NODE_SURFACE(x) x ? x->surface : NULL
#define MECAB_NODE_FEATURE(x) x ? x->feature : NULL
#define MECAB_NODE_RCATTR(x) x ? x->rcAttr : -1
#define MECAB_NODE_LCATTR(x) x ? x->lcAttr : -1
#define MECAB_NODE_POSID(x) x ? x->posid : -1
#define MECAB_NODE_CHAR_TYPE(x) x ? x->char_type : -1
#define MECAB_NODE_STAT(x) x ? x->stat : -1
#define MECAB_NODE_ISBEST(x) x ? x->isbest : -1
#define MECAB_NODE_ALPHA(x) x ? x->alpha : -1
#define MECAB_NODE_BETA(x) x ? x->beta : -1
#define MECAB_NODE_PROB(x) x ? x->prob : -1
#define MECAB_NODE_COST(x) x ? x->cost : -1
#define MECAB_NODE_WCOST(x) x ? x->wcost : -1

/* Text::MeCab */
void TextMeCab_bootstrap();
TextMeCab *TextMeCab_create(char **argv, unsigned int argc);
TextMeCab *TextMeCab_create_from_av(AV *av);
TextMeCab_Node *TextMeCab_parse(TextMeCab *mecab, char *string);

/* Text::MeCab::Node */
unsigned int TextMeCab_Node_id(TextMeCab_Node *node);
unsigned int TextMeCab_Node_length(TextMeCab_Node *node);
unsigned int TextMeCab_Node_rlength(TextMeCab_Node *node);
TextMeCab_Node *TextMeCab_Node_next(TextMeCab_Node *node);
TextMeCab_Node *TextMeCab_Node_prev(TextMeCab_Node *node);
SV *TextMeCab_Node_surface(TextMeCab_Node *node);
const char *TextMeCab_Node_feature(TextMeCab_Node *node);
unsigned short TextMeCab_Node_rcattr(TextMeCab_Node *node);
unsigned short TextMeCab_Node_lcattr(TextMeCab_Node *node);
unsigned short TextMeCab_Node_posid(TextMeCab_Node *node);
unsigned char TextMeCab_Node_char_type(TextMeCab_Node *node);
unsigned char TextMeCab_Node_stat(TextMeCab_Node *node);
unsigned char TextMeCab_Node_isbest(TextMeCab_Node *node);
float TextMeCab_Node_alpha(TextMeCab_Node *node);
float TextMeCab_Node_beta(TextMeCab_Node *node);
float TextMeCab_Node_prob(TextMeCab_Node *node);
long TextMeCab_Node_cost(TextMeCab_Node *node);
short TextMeCab_Node_wcost(TextMeCab_Node *node);
const char *TextMeCab_Node_format(TextMeCab_Node *node, TextMeCab *mecab);

TextMeCab_Node_Cloned *TextMeCab_Node_dclone(TextMeCab_Node *node);
TextMeCab_Node_Cloned *TextMeCab_Node_clone_single_node(TextMeCab_Node *node);

/* Text::MeCab::Node::Cloned */
void TextMeCab_Node_Cloned_free(TextMeCab_Node_Cloned *node);
unsigned int TextMeCab_Node_Cloned_id(TextMeCab_Node_Cloned *node);
unsigned int TextMeCab_Node_Cloned_length(TextMeCab_Node_Cloned *node);
unsigned int TextMeCab_Node_Cloned_rlength(TextMeCab_Node_Cloned *node);
TextMeCab_Node_Cloned *TextMeCab_Node_Cloned_next(TextMeCab_Node_Cloned *node);
TextMeCab_Node_Cloned *TextMeCab_Node_Cloned_prev(TextMeCab_Node_Cloned *node);
const char *TextMeCab_Node_Cloned_surface(TextMeCab_Node_Cloned *node);
const char *TextMeCab_Node_Cloned_feature(TextMeCab_Node_Cloned *node);
unsigned short TextMeCab_Node_Cloned_rcattr(TextMeCab_Node_Cloned *node);
unsigned short TextMeCab_Node_Cloned_lcattr(TextMeCab_Node_Cloned *node);
unsigned short TextMeCab_Node_Cloned_posid(TextMeCab_Node_Cloned *node);
unsigned char TextMeCab_Node_Cloned_char_type(TextMeCab_Node_Cloned *node);
unsigned char TextMeCab_Node_Cloned_stat(TextMeCab_Node_Cloned *node);
unsigned char TextMeCab_Node_Cloned_isbest(TextMeCab_Node_Cloned *node);
float TextMeCab_Node_Cloned_alpha(TextMeCab_Node_Cloned *node);
float TextMeCab_Node_Cloned_beta(TextMeCab_Node_Cloned *node);
float TextMeCab_Node_Cloned_prob(TextMeCab_Node_Cloned *node);
long TextMeCab_Node_Cloned_cost(TextMeCab_Node_Cloned *node);
short TextMeCab_Node_Cloned_wcost(TextMeCab_Node_Cloned *node);
const char *TextMeCab_Node_Cloned_format(TextMeCab_Node_Cloned *node, TextMeCab *mecab);

#endif /* __TEXT_MECAB_H__ */