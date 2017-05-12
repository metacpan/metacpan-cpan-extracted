/* $Id$
 *
 * Copyright (c) 2006-2008 Daisuke Maki <daisuke@endeworks.jp>
 * All rights reserved.
 */

#include "text-mecab.h"
#ifndef __TEXT_MECAB_CLONE_C__
#define __TEXT_MECAB_CLONE_C__

/* Deep Copy Memory Management Strategy:
 *
 * When we call dclone(), we actually clone the *entire* node list.
 * that is, we go back to the first node in the list, and start from
 * there.
 *
 * When ->next, ->prev is called, we update the node->head struct's
 * refcnt. When this refcnt is zero, we finally free the struct
 */

void
TextMeCab_Node_Cloned_free(TextMeCab_Node_Cloned *node)
{
    TextMeCab_Node_Cloned_Meta *meta;
    TextMeCab_Node_Cloned      *tmp;

    if (node == NULL || node->meta == NULL) { /* sanity */
        return;
    }

    meta = node->meta;
    if (meta->refcnt != 0)
        return;

    meta->refcnt--;
    node = meta->first;
    while (node != NULL) {
        tmp = node->next;
        Safefree(node->actual);
        Safefree(node);
        node = tmp;
    }
    Safefree(meta);
}

#if 0
pmecab_node_clone_t *
pmecab_deep_clone_node(mecab_node_t *node)
{
    pmecab_node_clone_head_t *xs_head;
    pmecab_node_clone_t *xs_node;
    pmecab_node_clone_t *cur_xs_node;
    pmecab_node_clone_t *tmp_xs;
    mecab_node_t *cur_node;
    mecab_node_t *tmp;
    if (node == NULL)
        return NULL;

    /* First, create the clone node list head. Then create the node that 
     * requested to be cloned.
     */
    Newz(1234, xs_head, 1, pmecab_node_clone_head_t);

    xs_node = pmecab_clone_node(node);
    xs_node->head = xs_head;

    cur_node = node->prev;
    cur_xs_node = xs_node;
    while (cur_node != NULL) {
        tmp = cur_node->prev;
        tmp_xs = pmecab_clone_node(cur_node);
        tmp_xs->head = xs_head;

        if (tmp == NULL) {
            xs_head->first = tmp_xs;
        }

        cur_xs_node->prev = tmp_xs;
        cur_xs_node->actual->prev = tmp_xs->actual;
        
        tmp_xs->next = cur_xs_node;
        tmp_xs->actual->next = cur_xs_node->actual;

        cur_node = tmp;
        cur_xs_node = tmp_xs;
    }

    cur_node    = node;
    cur_xs_node = xs_node;
    while (cur_node != NULL) {
        tmp = cur_node->next;
        tmp_xs = pmecab_clone_node(cur_node);
        tmp_xs->head = xs_head;

        cur_xs_node->next = tmp_xs;
        cur_xs_node->actual->next = tmp_xs->actual;
        tmp_xs->prev = cur_xs_node;
        tmp_xs->actual->prev = cur_xs_node->actual;

        cur_node = tmp;
        cur_xs_node = tmp_xs;
    }

    xs_head->refcnt++;

    return xs_node;
}
#endif

unsigned int
TextMeCab_Node_Cloned_id(node)
        TextMeCab_Node_Cloned *node;
{
    return MECAB_NODE_ID(node->actual);
}

unsigned int
TextMeCab_Node_Cloned_length(node)
        TextMeCab_Node_Cloned *node;
{
    return MECAB_NODE_LENGTH(node->actual);
}

unsigned int
TextMeCab_Node_Cloned_rlength(node)
        TextMeCab_Node_Cloned *node;
{
    return MECAB_NODE_RLENGTH(node->actual);
}

TextMeCab_Node_Cloned *
TextMeCab_Node_Cloned_next(node)
        TextMeCab_Node_Cloned *node;
{
    return MECAB_NODE_NEXT(node);
}

TextMeCab_Node_Cloned *
TextMeCab_Node_Cloned_prev(node)
        TextMeCab_Node_Cloned *node;
{
    return MECAB_NODE_PREV(node);
}

const char *
TextMeCab_Node_Cloned_surface(node)
        TextMeCab_Node_Cloned *node;
{
    return MECAB_NODE_SURFACE(node->actual);
}

const char *
TextMeCab_Node_Cloned_feature(node)
        TextMeCab_Node_Cloned *node;
{
    return MECAB_NODE_FEATURE(node->actual);
}

unsigned short
TextMeCab_Node_Cloned_rcattr(node)
        TextMeCab_Node_Cloned *node;
{
    return MECAB_NODE_RCATTR(node->actual);
}

unsigned short
TextMeCab_Node_Cloned_lcattr(node)
        TextMeCab_Node_Cloned *node;
{
    return MECAB_NODE_LCATTR(node->actual);
}

unsigned short
TextMeCab_Node_Cloned_posid(node)
        TextMeCab_Node_Cloned *node;
{
    return MECAB_NODE_POSID(node->actual);
}

unsigned char
TextMeCab_Node_Cloned_char_type(node)
        TextMeCab_Node_Cloned *node;
{
    return MECAB_NODE_CHAR_TYPE(node->actual);
}

unsigned char
TextMeCab_Node_Cloned_stat(node)
        TextMeCab_Node_Cloned *node;
{
    return MECAB_NODE_STAT(node->actual);
}

unsigned char
TextMeCab_Node_Cloned_isbest(node)
        TextMeCab_Node_Cloned *node;
{
    return MECAB_NODE_ISBEST(node->actual);
}

float
TextMeCab_Node_Cloned_alpha(node)
        TextMeCab_Node_Cloned *node;
{
    return MECAB_NODE_ALPHA(node->actual);
}

float
TextMeCab_Node_Cloned_beta(node)
        TextMeCab_Node_Cloned *node;
{
    return MECAB_NODE_BETA(node->actual);
}

float
TextMeCab_Node_Cloned_prob(node)
        TextMeCab_Node_Cloned *node;
{
    return MECAB_NODE_PROB(node->actual);
}

long
TextMeCab_Node_Cloned_cost(node)
        TextMeCab_Node_Cloned *node;
{
    return MECAB_NODE_COST(node->actual);
}

short
TextMeCab_Node_Cloned_wcost(node)
        TextMeCab_Node_Cloned *node;
{
    return MECAB_NODE_WCOST(node->actual);
}

const char *
TextMeCab_Node_Cloned_format(node, mecab)
        TextMeCab_Node_Cloned *node;
        TextMeCab             *mecab;
{
    return mecab_format_node(XS_2MECAB(mecab), node->actual);
}

#endif /* __TEXT_MECAB_CLONE_C__ */

