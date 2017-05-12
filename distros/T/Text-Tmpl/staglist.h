#ifndef  __STAGLIST_H
#define  __STAGLIST_H

typedef struct staglist_struct staglist;
typedef struct staglist_struct *staglist_p;
struct staglist_struct
{
    /* name of this tag */
    char *name;

    /* pointer to the function which handles it */
    void (*function) (context_p, char **, int, char**);
    
    /* pointer to the next simple stag */
    staglist_p next;
};

#ifdef __cplusplus
extern "C" {
#endif /* __cplusplus */

staglist_p staglist_init();
void       staglist_destroy(staglist_p simple_tag_list);
int        staglist_alias(staglist_p *simple_tag_list, char *old_name,
                          char *new_name);
int        staglist_register(staglist_p *simple_tag_list, char *name,
                             void (*function)(context_p, char **, int, char**));
void       staglist_remove(staglist_p *simple_tag_list, char *name);
int        staglist_exists(staglist_p simple_tag_list, char *name);
int        staglist_exec(staglist_p simple_tag_list, char *name, context_p ctx,
                         char **output, int argc, char **argv);

#ifdef __cplusplus
}
#endif /* __cplusplus */

#endif /* __STAGLIST_H */
