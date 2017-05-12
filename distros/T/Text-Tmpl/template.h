#include <varlist.h>
#include <nclist.h>
#include <context.h>
#include <staglist.h>
#include <tagplist.h>
#include <default_tags.h>
#include <tokens.h>

#ifdef WIN32
#define snprintf _snprintf
#endif

#ifndef __TEMPLATE_H
#define __TEMPLATE_H

#define TEMPLATE_TRUE           "1"
#define TEMPLATE_FALSE          "0"

#define TMPL_ENONE              0
#define TMPL_EMALLOC		1
#define TMPL_ENULLARG		2
#define TMPL_EBADARG		3
#define TMPL_ENOVALUE		4
#define TMPL_ENOCTX		5
#define TMPL_ENOSTAG		6
#define TMPL_ENOTAGP		7
#define TMPL_ENOTFOUND		8
#define TMPL_EFOPEN		9
#define TMPL_EPARSE		10
#define TMPL_ESCREWY		11
#define TMPL_ENOTOKEN		12

#define TMPL_ERR_MIN            0
#define TMPL_ERR_MAX            12

#define TMPL_VARNAME_DIR        "INTERNAL_dir"
#define TMPL_VARNAME_OTAG       "INTERNAL_otag"
#define TMPL_VARNAME_CTAG       "INTERNAL_ctag"

#define template_set_value(c, n, v)  context_set_value(c, n, v)
#define template_destroy(c)          context_destroy(c)
#define template_set_dir(c, d)       template_set_value(c, TMPL_VARNAME_DIR, d)

#ifdef __cplusplus
extern "C" {
#endif /* __cplusplus */

extern int template_errno;

extern char *template_errno_strings[];

context_p template_init(void);
int       template_set_delimiters(context_p ctx, char *opentag,
                                  char *closetag);
int       template_register_simple(context_p ctx, char *name,
                             void (*function)(context_p, char **, int, char**));
int       template_alias_simple(context_p ctx, char *old_name, char *new_name);
void      template_remove_simple(context_p ctx, char *name);
int       template_register_pair(context_p ctx, char named_context,
                                 char *open_name, char *close_name,
                                 void (*function)(context_p, int, char**));
int       template_alias_pair(context_p ctx, char *old_open_name,
                              char *old_close_name, char *new_open_name,
                              char *new_close_name);
void      template_remove_pair(context_p ctx, char *open_name);
void      template_set_debug(context_p ctx, int debug_level);
void      template_set_strip(context_p ctx, int strip);
context_p template_loop_iteration(context_p ctx, char *loop_name);
context_p template_fetch_loop_iteration(context_p ctx, char *loop_name,
                                        int iteration);
int       template_parse_string(context_p ctx, char *tmpl, char **output);
int       template_parse_file(context_p ctx, char *template_filename,
                              char **output);
char *    template_strerror(void);
void      template_free_output(char *output); /* XX: do not use! */

#ifdef __cplusplus
}
#endif /* __cplusplus */

#endif /* __TEMPLATE_H */
