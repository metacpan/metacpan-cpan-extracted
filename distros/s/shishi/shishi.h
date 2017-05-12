/* Shishi dynamic lexer/parser system.  
   Copyright 2002, Simon Cozens 
   Provided to you under the terms of the Artistic License
*/

#ifndef _MALLOC_H /* Looks non-portable, but it has no effect on non-GNU */
#include <malloc.h> 
#endif 
#ifndef _STRING_H
#include <string.h>
#endif
#ifndef _STDLIB_H
#include <stdlib.h>
#endif
#ifndef _STDIO_H
#include <stdio.h>
#endif

#ifdef SHISHI_DEBUG
#define DEBUG(x) x
#include <signal.h>
#define BREAKPOINT kill(getpid(), SIGWINCH)
#else
#define DEBUG(x)
#define BREAKPOINT
#endif

#define SHISHI_DEC_ALLOC 2
#define SHISHI_NODE_ALLOC 2
#define SHISHI_MATCH_STACK_ALLOC 4

typedef int token_t;

typedef int(*shishi_comparison_t)(void*, char*, void*, void*, void*);

typedef enum {
    SHISHI_MATCH_TEXT,
    SHISHI_MATCH_CHAR,
    SHISHI_MATCH_TOKEN, 
    SHISHI_MATCH_ANY,
    SHISHI_MATCH_END,
    SHISHI_MATCH_SKIP,
    SHISHI_MATCH_TRUE,
    SHISHI_MATCH_CODE
} shishi_match_t;

#ifdef SHISHI_DEBUG

#ifdef SHISHI_INSHISHIC
const char* Shishi_debug_matchtypes[] = {
    "TEXT",
    "CHAR",
    "TOKEN",
    "ANY",
    "END",
    "SKIP",
    "TRUE",
    "CODE",
};
#else
extern const char* Shishi_debug_matchtypes[];
#endif
#endif

typedef enum {
    SHISHI_ACTION_CONTINUE,
    SHISHI_ACTION_FINISH,
    SHISHI_ACTION_FAIL
} shishi_action_t;

#ifdef SHISHI_DEBUG
#ifdef SHISHI_INSHISHIC
const char* Shishi_debug_actiontypes[] = {
    "CONTINUE",
    "FINISH",
    "FAIL"
};
#else
extern const char* Shishi_debug_actiontypes[];
#endif
#endif

struct _shishi_decision {
    union {
	token_t token; /* Characters are tokens, (token_t)'a' representing a, etc.*/
        struct {
            char* buffer;
            int   length;
        } string;
        struct {
            shishi_comparison_t* function;
            void* data; /* Always provide data with a callback */
        } comparison; 
    } target;
    shishi_match_t target_type;
    shishi_action_t action;
    struct _shishi_node * next_node;
};

typedef struct _shishi_decision ShishiDecision;

struct _shishi_node {
    char* creator; /* Where did this node come from? */
    int children;  /* How many decisions hang off me? */
    int alloc;     /* How many decisions do I have room for? */
    int parents;   /* How many decisions point to me? */
    struct _shishi_decision ** decisions; 
};


typedef struct _shishi_node ShishiNode;

typedef struct {
    char *ptr;
    ShishiNode* node;
    int doffset;
} ShishiMatchStack;

typedef struct {
    char *text;
    int offset;
    int end_of_match;
    ShishiMatchStack* stack_top;
    ShishiMatchStack* stack_alloc;
    ShishiMatchStack* stack;
} ShishiMatch;

typedef struct {
    ShishiNode** nodes;
    token_t* stack;
    int num_nodes;
    int alloc_nodes;
    char* creator; /* Who am I? */
} Shishi;

Shishi* Shishi_new(const char* creator);


enum {
    SHISHI_AGAIN,
    SHISHI_MATCHED,
    SHISHI_FAILED
};

#include "shishi_prot.h"
