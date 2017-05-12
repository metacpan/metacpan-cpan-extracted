#ifndef  __CONTEXT_H
#define  __CONTEXT_H

typedef struct context_struct context;
typedef struct context_struct *context_p;

#include <varlist.h>
#include <nclist.h>
#include <staglist.h>
#include <tagplist.h>

#define CTX_FLAG_NONE      0
#define CTX_FLAG_OUTPUT    (1 << 0)
#define CTX_FLAG_ANONYMOUS (1 << 1)
#define CTX_FLAG_STRIP     (1 << 2)
#define CTX_FLAG_DEBUG     (1 << 3)

#define ctx_is_output(x)    ((x)->flags & CTX_FLAG_OUTPUT)
#define ctx_is_anonymous(x) ((x)->flags & CTX_FLAG_ANONYMOUS)
#define ctx_is_strip(x)     ((x)->flags & CTX_FLAG_STRIP)
#define ctx_is_debug(x)     ((x)->flags & CTX_FLAG_DEBUG)

#define ctx_set_output(x)    ((x)->flags |= CTX_FLAG_OUTPUT)
#define ctx_set_anonymous(x) ((x)->flags |= CTX_FLAG_ANONYMOUS)
#define ctx_set_strip(x)     ((x)->flags |= CTX_FLAG_STRIP)
#define ctx_set_debug(x)     ((x)->flags |= CTX_FLAG_DEBUG)

#define ctx_unset_output(x)    ((x)->flags &= ~ CTX_FLAG_OUTPUT)
#define ctx_unset_anonymous(x) ((x)->flags &= ~ CTX_FLAG_ANONYMOUS)
#define ctx_unset_strip(x)     ((x)->flags &= ~ CTX_FLAG_STRIP)
#define ctx_unset_debug(x)     ((x)->flags &= ~ CTX_FLAG_DEBUG)

struct context_struct
{
    /* table of variables and values in this list */
    varlist_p variables;

    /* table of named child contexts */
    nclist_p  named_child_contexts;

    /* table of simple tags */
    staglist_p simple_tags;

    /* table of tag pairs */
    tagplist_p tag_pairs;

    /* pointer to parent context, or NULL if this is the top context */
    context_p parent_context;

    /* pointer to next context, or NULL if this is the last (or only) element
       in this loop */
    context_p next_context;

    /* to optimize adding loop iterations, this is a pointer to the last
       iteration of this loop */
    context_p last_context;

    /* flags can be CTX_FLAG_* */
    unsigned char flags;

    /* buffer for temporary string storage */
    char *buffer;

    /* buffer size */
    int bufsize;
};

#ifdef __cplusplus
extern "C" {
#endif /* __cplusplus */

context_p context_init(void);
void      context_destroy(context_p ctx);
char *    context_get_value(context_p ctx, char *name);
int       context_set_value(context_p ctx, char *name, char *value);
context_p context_get_anonymous_child(context_p ctx);
context_p context_get_named_child(context_p ctx, char *name);
int       context_set_named_child(context_p ctx, char *name);
context_p context_add_peer(context_p ctx);
void      context_output_contents(context_p ctx, char output_contents);
context_p context_root(context_p ctx);

#ifdef __cplusplus
}
#endif /* __cplusplus */

#endif /* __CONTEXT_H */
