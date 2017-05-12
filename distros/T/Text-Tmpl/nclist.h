#ifndef  __NCLIST_H
#define  __NCLIST_H

typedef struct nclist_struct nclist;
typedef struct nclist_struct *nclist_p;

#include <context.h>

struct nclist_struct
{
    /* name for this context */
    char           *name;

    /* context that it points to */
    context_p      context;

    /* next named context in the list, or NULL */
    nclist_p       next;
};

#ifdef __cplusplus
extern "C" {
#endif /* __cplusplus */

nclist_p         nclist_init(void);
void             nclist_destroy(nclist_p named_context_list);
context_p        nclist_get_context(nclist_p named_context_list, char *name);
int              nclist_new_context(nclist_p *named_context_list, char *name);

#ifdef __cplusplus
}
#endif /* __cplusplus */

#endif /* __NCLIST_H */
