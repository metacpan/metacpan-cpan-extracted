#ifndef  __TAGPLIST_H
#define  __TAGPLIST_H

typedef struct tagplist_struct tagplist;
typedef struct tagplist_struct *tagplist_p;
struct tagplist_struct
{
    /* name of the opening tag */
    char *open_name;

    /* name of the closing tag */
    char *close_name;

    /* pointer to the function which handles this pair */
    void (*function) (context_p, int, char**);

    /* pointer to the next tag pair */
    tagplist_p next;

    /* if this tag pair has a pre-built named context set, this will be 1 */
    char named_context;
};

#ifdef __cplusplus
extern "C" {
#endif /* __cplusplus */

tagplist_p tagplist_init();
void       tagplist_destroy(tagplist_p tag_pair_list);
int        tagplist_alias(tagplist_p *tag_pair_list, char *old_open_name,
                          char *old_close_name, char *new_open_name,
                          char *new_close_name);
void       tagplist_remove(tagplist_p *tag_pair_list, char *open_name);
int        tagplist_register(tagplist_p *tag_pair_list, char named_context,
                             char *open_name, char *close_name,
                             void (*function) (context_p, int, char**));
int        tagplist_is_opentag(tagplist_p tag_pair_list, char *open_name);
int        tagplist_is_closetag(tagplist_p tag_pair_list, char *open_name,
                                char *close_name);
context_p  tagplist_exec(tagplist_p tag_pair_list, char *open_name,
                         context_p ctx, int argc, char **argv);

#ifdef __cplusplus
}
#endif /* __cplusplus */

#endif /* __TAGPLIST_H */
