/* $Id$
 *
 * Copyright (c) 2006-2008 Daisuke Maki <disuke@endeworks.jp>
 * All rights reserved.
 */

#include "text-mecab.h"
#ifndef  __TEXT_MECAB_NODE_C__
#define  __TEXT_MECAB_NODE_C__

unsigned int
TextMeCab_Node_id(node)
        TextMeCab_Node *node;
{
    return MECAB_NODE_ID(node);
}

unsigned int
TextMeCab_Node_length(node)
        TextMeCab_Node *node;
{
    return MECAB_NODE_LENGTH(node);
}

unsigned int
TextMeCab_Node_rlength(node)
        TextMeCab_Node *node;
{
    return MECAB_NODE_RLENGTH(node);
}

TextMeCab_Node *
TextMeCab_Node_next(node)
        TextMeCab_Node *node;
{
    return MECAB_NODE_NEXT(node);
}

TextMeCab_Node *
TextMeCab_Node_prev(node)
        TextMeCab_Node *node;
{
    return MECAB_NODE_PREV(node);
}

SV *
TextMeCab_Node_surface(node)
        TextMeCab_Node *node;
{
    return (node->length > 0) ?
        newSVpvn(MECAB_NODE_SURFACE(node), MECAB_NODE_LENGTH(node)) :
        newSV(0)
    ;
}

const char *
TextMeCab_Node_feature(node)
        TextMeCab_Node *node;
{
    return MECAB_NODE_FEATURE(node);
}

unsigned short
TextMeCab_Node_rcattr(node)
        TextMeCab_Node *node;
{
    return MECAB_NODE_RCATTR(node);
}

unsigned short
TextMeCab_Node_lcattr(node)
        TextMeCab_Node *node;
{
    return MECAB_NODE_LCATTR(node);
}

unsigned short
TextMeCab_Node_posid(node)
        TextMeCab_Node *node;
{
    return MECAB_NODE_POSID(node);
}

unsigned char
TextMeCab_Node_char_type(node)
        TextMeCab_Node *node;
{
    return MECAB_NODE_CHAR_TYPE(node);
}

unsigned char
TextMeCab_Node_stat(node)
        TextMeCab_Node *node;
{
    return MECAB_NODE_STAT(node);
}

unsigned char
TextMeCab_Node_isbest(node)
        TextMeCab_Node *node;
{
    return MECAB_NODE_ISBEST(node);
}

float
TextMeCab_Node_alpha(node)
        TextMeCab_Node *node;
{
    return MECAB_NODE_ALPHA(node);
}

float
TextMeCab_Node_beta(node)
        TextMeCab_Node *node;
{
    return MECAB_NODE_BETA(node);
}

float
TextMeCab_Node_prob(node)
        TextMeCab_Node *node;
{
    return MECAB_NODE_PROB(node);
}

long
TextMeCab_Node_cost(node)
        TextMeCab_Node *node;
{
    return MECAB_NODE_COST(node);
}

short
TextMeCab_Node_wcost(node)
        TextMeCab_Node *node;
{
    return MECAB_NODE_WCOST(node);
}

const char *
TextMeCab_Node_format(node, mecab)
        TextMeCab_Node *node;
        TextMeCab      *mecab;
{
    return mecab_format_node(XS_2MECAB(mecab), node);
}

TextMeCab_Node_Cloned *
TextMeCab_Node_dclone(node)
        TextMeCab_Node *node;
{
    TextMeCab_Node_Cloned *prev_node   = NULL;
    TextMeCab_Node_Cloned *cloned_node = NULL;
    TextMeCab_Node        *head        = NULL;
    TextMeCab_Node        *current     = NULL;
    TextMeCab_Node_Cloned *tmp         = NULL;
    TextMeCab_Node_Cloned_Meta *meta;

    /* XXX - We clone the entire node list, to make management easier */
    head = node;
    while (head->prev != NULL) {
        head = head->prev;
    }

    Newz(1234, meta, 1, TextMeCab_Node_Cloned_Meta);

    current = head;
    while(current != NULL) {
        tmp = TextMeCab_Node_clone_single_node(current);
        if (current == node) {
            cloned_node = tmp;
        }
        tmp->meta = meta;
        tmp->prev = prev_node;
        if (prev_node != NULL) {
            prev_node->next = tmp;
        } else {
            meta->first = tmp;
        }

        prev_node = tmp;
        current = current->next;
    }

    meta->refcnt++;
    return cloned_node;
}

TextMeCab_Node_Cloned *
TextMeCab_Node_clone_single_node(node)
        TextMeCab_Node *node;
{
    TextMeCab_Node_Cloned *cloned;

    Newz(1234, cloned, 1, TextMeCab_Node_Cloned);
    Newz(1234, cloned->actual, 1, TextMeCab_Node);

    if (node->length <= 0) {
        cloned->actual->surface = NULL;
    } else {
        int len = node->length;
        /* node->length is actually unsigned short, but what the heck.
         * just cast it off to an int.
         */
        Newz(1234, cloned->actual->surface, len + 1, char);
        Copy(node->surface, cloned->actual->surface, len, char);
    }

    Newz(1234, cloned->actual->feature, strlen(node->feature), char);
    Copy(node->feature, cloned->actual->feature, strlen(node->feature), char);

    cloned->actual->id        = node->id;
    cloned->actual->length    = node->length;
    cloned->actual->stat      = node->stat;
    cloned->actual->cost      = node->cost;
    cloned->actual->rlength   = node->rlength;
    cloned->actual->rcAttr    = node->rcAttr;
    cloned->actual->lcAttr    = node->lcAttr;
    cloned->actual->posid     = node->posid;
    cloned->actual->char_type = node->char_type;
    cloned->actual->isbest    = node->isbest;
    cloned->actual->alpha     = node->alpha;
    cloned->actual->prob      = node->prob;
    cloned->actual->wcost     = node->wcost;
    cloned->actual->next      = NULL;
    cloned->actual->prev      = NULL;

    return cloned;
}

#endif /* __TEXT_MECAB_NODE_C__ */
