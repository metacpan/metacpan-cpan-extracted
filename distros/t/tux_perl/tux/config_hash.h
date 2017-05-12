/*
 * This code is a part of tux_perl, and is released under the GPL.
 * Copyright 2002 by Yale Huang<mailto:yale@sdf-eu.org>.
 * See README and COPYING for more information, or see
 *   http://tux-perl.sourceforge.net/.
 *
 * $Id: config_hash.h,v 1.2 2002/11/11 11:17:02 yaleh Exp $
 */

#ifndef __CONFIG_HASH_H
#define __CONFIG_HASH_H

#if defined (__cplusplus)
extern "C" {
#endif

#define HASH_NODE(x)        ((hash_node *)(x))
#define HASH_FOLDER(x)      ((hash_folder *)(x))
#define HASH_VARIABLE(x)    ((hash_variable *)(x))

#define NODE_PARENT(x) (((hash_node *)(x))->parent)
#define NODE_PREV(x)   (((hash_node *)(x))->prev)
#define NODE_NEXT(x)   (((hash_node *)(x))->next)
#define NODE_TYPE(x)   (((hash_node *)(x))->node_type)
#define NODE_NAME(x)   (((hash_node *)(x))->name)

#define IS_VARIABLE(x) (NODE_TYPE(x)==HASH_NODE_TYPE_VARIABLE)
#define IS_FOLDER(x)   (NODE_TYPE(x)==HASH_NODE_TYPE_FOLDER)

typedef enum hash_node_type_t{
  HASH_NODE_TYPE_VARIABLE,
  HASH_NODE_TYPE_FOLDER
}hash_node_type;

typedef struct hash_node_t hash_node;
struct hash_node_t{
  hash_node *parent,*prev,*next;
  hash_node_type node_type;
  char *name;
};

typedef struct hash_variable_t hash_variable;
struct hash_variable_t{
  hash_node node;
  char *value;
};

typedef struct hash_folder_t hash_folder;
struct hash_folder_t{
  hash_node node;
  hash_node* first_child;
};

hash_node * find_node(hash_node * first, const char *name);

hash_folder * read_hash(const char * filename);

void free_folder(hash_folder * folder);

int dump_node(hash_node * node);

char * get_value(hash_folder * folder, const char * name);

#if defined (__cplusplus)
}
#endif
 
#endif
