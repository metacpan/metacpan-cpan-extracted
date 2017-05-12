#ifndef  __VARLIST_H
#define  __VARLIST_H

typedef struct varlist_struct varlist;
typedef struct varlist_struct *varlist_p;
struct varlist_struct
{
    /* name for this variable */
    char      *name;

    /* value for this variable */
    char      *value;

    /* next variable in the list, or NULL */
    varlist_p next;
};

#ifdef __cplusplus
extern "C" {
#endif /* __cplusplus */

varlist_p varlist_init(void);
void      varlist_destroy(varlist_p variable_list);
char *    varlist_get_value(varlist_p variable_list, char *name);
int       varlist_set_value(varlist_p *variable_list, char *name, char *value);

#ifdef __cplusplus
}
#endif /* __cplusplus */

#endif /* __VARLIST_H */
