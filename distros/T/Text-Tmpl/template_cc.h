#ifndef __TEMPLATE_CC_H
#define __TEMPLATE_CC_H

#ifdef __cplusplus

#include <stdio.h>
#include <template.h>

class tmpl
{
public:
    // this is our basic constructor
    tmpl() : t(template_init()), is_destroyable(1) { }

    // this constructor is used to make a context into a template object
    tmpl(context_p ctx) : t(ctx), is_destroyable(0) { }

    // destructor does nothing unless is_destroyable == 1
    ~tmpl()
    {
        if (is_destroyable)
        {
            template_destroy(t);
            t = NULL;
        }
    }

    // operator for casting to context_p
    operator context_p()
    {
        return t;
    }

    int
    set_delimiters(char *opentag, char *closetag)
    {
        return template_set_delimiters(t, opentag, closetag);
    }

    int
    register_simple(char *name,
                    void (*function)(context_p, char **, int, char**))
    {
        return template_register_simple(t, name, function);
    }

    int
    alias_simple(char *old_name, char *new_name)
    {
        return template_alias_simple(t, old_name, new_name);
    }

    int
    register_pair(char named_context, char *open_name, char *close_name,
                  void (*function)(context_p, int, char**))
    {
        return template_register_pair(t, named_context, open_name,
                                      close_name, function);
    }

    int
    alias_pair(char *old_open_name, char *old_close_name, char *new_open_name,
               char *new_close_name)
    {
        return template_alias_pair(t, old_open_name, old_close_name,
                                   new_open_name, new_close_name);
    }

    void
    remove_simple(char *name)
    {
        template_remove_simple(t, name);
    }

    void
    remove_pair(char *open_name)
    {
        template_remove_pair(t, open_name);
    }

    void
    set_debug(int debug_level)
    {
        template_set_debug(t, debug_level);
    }

    void
    set_strip(int strip)
    {
        template_set_strip(t, strip);
    }

    int
    set_dir(char *directory)
    {
        return template_set_dir(t, directory);
    }

    int
    set_value(char *name, char *value)
    {
        return template_set_value(t, name, value);
    }

    tmpl
    loop_iteration(char *loop_name)
    {
        return (tmpl)template_loop_iteration(t, loop_name);
    }

    tmpl
    fetch_loop_iteration(char *loop_name, int iteration)
    {
        return (tmpl)template_fetch_loop_iteration(t, loop_name, iteration);
    }

    int
    parse_string(char *tmpl, char **output)
    {
        return template_parse_string(t, tmpl, output);
    }

    int
    parse_file(char *template_filename, char **output)
    {
        return template_parse_file(t, template_filename, output);
    }
protected:
    context_p     t;
    unsigned char is_destroyable;
};

#endif /* __cplusplus */

#endif /* __TEMPLATE_CC_H */
