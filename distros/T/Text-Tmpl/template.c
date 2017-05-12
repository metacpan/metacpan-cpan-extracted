/* ====================================================================
 * Copyright 1999 Web Juice, LLC. All rights reserved.
 *
 * template.c
 *
 * The end-user API for the templating library.
 *
 * ==================================================================== */

#include <sys/types.h>
#include <sys/stat.h>
#include <stdlib.h>
#include <string.h>
#include <stdio.h>
#ifndef WIN32
#include <sys/param.h>
#include <unistd.h>
#endif

#include <template.h>
#include <default_tags.h>

#ifndef MAXPATHLEN
#define MAXPATHLEN 1024
#endif /* MAXPATHLEN */

int template_errno = TMPL_ENONE;

int parser(context_p ctx, int looping, token_group_p tokens, char **output);

char *template_errno_strings[] =
{
    "no error",
    "malloc() failed",
    "got NULL argument where pointer was expected",
    "got bogus argument value",
    "no such variable",
    "no such named context",
    "no such simple tag",
    "no such tag pair",
    "file not found",
    "unable to open file",
    "unable to parse",
    "this can't happen!",
    "no such token",
    NULL
};


/* ====================================================================
 * NAME:          template_init
 *
 * DESCRIPTION:   Initializes the templating library end-user API.  This
 *                includes initializing a context and global tag lists,
 *                and registering all the default tags.
 *
 * RETURN VALUES: If there's a problem, returns NULL; otherwise returns
 *                the main context.
 *
 * BUGS:          Hopefully none.
 * ==================================================================== */
context_p
template_init(void)
{
    context_p ctx = context_init();

    if (ctx == NULL)
    {
        return NULL;
    }

    ctx->simple_tags = staglist_init();
    if (ctx->simple_tags == NULL)
    {
        context_destroy(ctx);
        return NULL;
    }

    ctx->tag_pairs = tagplist_init();
    if (ctx->tag_pairs == NULL)
    {
        context_destroy(ctx);
        return NULL;
    }

    template_register_simple(ctx, "echo", simple_tag_echo);
    template_register_simple(ctx, "include", simple_tag_include);

    template_register_pair(ctx, 0, "comment", "endcomment", tag_pair_comment);
    template_register_pair(ctx, 1, "loop",    "endloop",    tag_pair_loop);
    template_register_pair(ctx, 0, "if",      "endif",      tag_pair_if);
    template_register_pair(ctx, 0, "ifn",     "endifn",     tag_pair_ifn);
    template_register_pair(ctx, 0, "debug",   "enddebug",   tag_pair_debug);

    ctx->bufsize = MAXPATHLEN;
    ctx->buffer = (char *)malloc(MAXPATHLEN);
    getcwd(ctx->buffer, MAXPATHLEN);

    template_set_value(ctx, TMPL_VARNAME_OTAG,  "<!--#");
    template_set_value(ctx, TMPL_VARNAME_CTAG,  "-->");
    template_set_value(ctx, TMPL_VARNAME_DIR,   ctx->buffer);

    template_set_debug(ctx, 0);
    template_set_strip(ctx, 1);

    return(ctx);
}




/* ====================================================================
 * NAME:          template_set_debug
 *
 * DESCRIPTION:   Change the debugging level of this context.
 *
 * RETURN VALUES: 0 if there's a problem; 1 on success.
 *               
 * BUGS:          Hopefully none.
 * ==================================================================== */
void
template_set_debug(context_p ctx, int debug)
{
    if (ctx == NULL)
    {
        return;
    }
    if (debug)
    {
        ctx_set_debug(ctx);
    }
    else
    {
        ctx_unset_debug(ctx);
    }
    return;
}



/* ====================================================================
 * NAME:          template_set_strip
 *
 * DESCRIPTION:   Modify the behavior of the parser - if strip is on,
 *                the parser will not output the first character after
 *                a tag *if* it is a newline.  If strip is off, the parser
 *                outputs all non-tag characters.
 *
 * RETURN VALUES: 0 if there's a problem; 1 on success.
 *               
 * BUGS:          Hopefully none.
 * ==================================================================== */
void
template_set_strip(context_p ctx, int strip)
{
    if (ctx == NULL)
    {
        return;
    }
    if (strip)
    {
        ctx_set_strip(ctx);
    }
    else
    {
        ctx_unset_strip(ctx);
    }
    return;
}



/* ====================================================================
 * NAME:          template_set_delimiters
 *
 * DESCRIPTION:   Allows the user to set the opening and closing delimiters
 *                for template tags.
 *
 * RETURN VALUES: 0 if there's a problem; 1 on success.
 *
 * BUGS:          Hopefully none.
 * ==================================================================== */
int
template_set_delimiters(context_p ctx, char *opentag, char *closetag)
{
    if ((opentag == NULL) || (closetag == NULL))
    {
        template_errno = TMPL_ENULLARG;
        return 0;
    }

    if ((! template_set_value(ctx, TMPL_VARNAME_OTAG, opentag))
     || (! template_set_value(ctx, TMPL_VARNAME_CTAG, closetag)))
    {
        return 0;
    }

    return 1;
}



/* ====================================================================
 * NAME:          template_alias_simple
 *
 * DESCRIPTION:   Copy an existing simple tag to a new tag name.
 *
 * RETURN VALUES: The return of staglist_alias (true or false)
 *
 * BUGS:          Should it verify that the tag name isn't taken as a tag
 *                pair name?
 * ==================================================================== */
int
template_alias_simple(context_p ctx, char *old_name, char *new_name)
{
    context_p current;

    if (ctx == NULL)
    {
        template_errno = TMPL_ENULLARG;
        return 0;
    }

    current = context_root(ctx);
    return(staglist_alias(&(current->simple_tags), old_name, new_name));
}



/* ====================================================================
 * NAME:          template_register_simple
 *
 * DESCRIPTION:   Registers a new simple tag into the global simple tag list.
 *
 * RETURN VALUES: The return of staglist_register (true or false)
 *
 * BUGS:          Should it verify that the tag name isn't taken as a tag
 *                pair name?
 * ==================================================================== */
int
template_register_simple(context_p ctx, char *name,
                         void (*function)(context_p, char **, int, char**))
{
    context_p current;

    if (ctx == NULL)
    {
        template_errno = TMPL_ENULLARG;
        return 0;
    }

    current = context_root(ctx);
    return(staglist_register(&(current->simple_tags), name, function));
}



/* ====================================================================
 * NAME:          template_remove_simple
 *
 * DESCRIPTION:   Removes a simple tag from the simple tag list.
 *
 * RETURN VALUES: None.
 *
 * BUGS:          Hopefully none.
 * ==================================================================== */
void
template_remove_simple(context_p ctx, char *name)
{
    context_p current;

    if (ctx == NULL)
    {
        template_errno = TMPL_ENULLARG;
        return;
    }

    current = context_root(ctx);
    staglist_remove(&(current->simple_tags), name);
}



/* ====================================================================
 * NAME:          template_remove_pair
 *
 * DESCRIPTION:   Removes a tag pair from the tag pair list.
 *
 * RETURN VALUES: None.
 *
 * BUGS:          Hopefully none.
 * ==================================================================== */
void
template_remove_pair(context_p ctx, char *open_name)
{
    context_p current;

    if (ctx == NULL)
    {
        template_errno = TMPL_ENULLARG;
        return;
    }

    current = context_root(ctx);
    tagplist_remove(&(current->tag_pairs), open_name);
}





/* ====================================================================
 * NAME:          template_alias_simple
 *



/* ====================================================================
 * NAME:          template_alias_simple
 *
 * DESCRIPTION:   Copy an existing tag pair to a new tag pair name.
 *
 * RETURN VALUES: The return of tagplist_alias (true or false)
 *
 * BUGS:          Should it verify that the tag name isn't taken as a 
 *                simple tag name?
 * ==================================================================== */
int
template_alias_pair(context_p ctx, char *old_open_name, char *old_close_name,
                    char *new_open_name, char *new_close_name)
{
    context_p current;

    if (ctx == NULL)
    {
        template_errno = TMPL_ENULLARG;
        return 0;
    }

    current = context_root(ctx);
    return(tagplist_alias(&(current->tag_pairs), old_open_name, old_close_name,
                          new_open_name, new_close_name));
}



/* ====================================================================
 * NAME:          template_register_pair
 *
 * DESCRIPTION:   Registers a new tag pair into the global tag pair list.
 *
 * RETURN VALUES: The return of tagplist_register (true or false)
 *
 * BUGS:          Should it verify that the tag name isn't taken as a 
 *                simple tag name?
 * ==================================================================== */
int
template_register_pair(context_p ctx, char named_context, char *open_name,
                       char *close_name,
                       void (*function)(context_p, int, char**))
{
    context_p current;

    if (ctx == NULL)
    {
        template_errno = TMPL_ENULLARG;
        return 0;
    }

    current = context_root(ctx);
    return(tagplist_register(&(current->tag_pairs), named_context, open_name,
                             close_name, function));
}



/* ====================================================================
 * NAME:          template_parse_file
 *
 * DESCRIPTION:   Takes a filename and context as input - reads the file,
 *                runs it through parser(), and makes sure that everything
 *                goes okay.
 *
 * RETURN VALUES: Returns 0 if there are any problems with the file or parser,
 *                otherwise returns 1.
 *
 * BUGS:          Hopefully none.
 * ==================================================================== */
int
template_parse_file(context_p ctx, char *template_filename, char **output)
{
    struct stat finfo;
    FILE        *filehandle;
    char        *template;
    char        *real_filename;
    int         retval;
    token_group_p tokens = token_group_init();

    if ((template_filename == NULL) || (output == NULL))
    {
        template_errno = TMPL_ENULLARG;
        return 0;
    }

    *output = NULL;

    if (stat(template_filename, &finfo) != 0)
    {
        char *dir = context_get_value(ctx, TMPL_VARNAME_DIR);
        int size  = strlen(template_filename) + strlen(dir) + 2;

        real_filename = (char *)malloc(size);
        strcpy(real_filename, dir);
        strcat(real_filename, template_filename);
        real_filename[size - 1] = '\0';

        if (stat(real_filename, &finfo) != 0)
        {
            free(real_filename);
            template_errno = TMPL_ENOTFOUND;
            return 0;
        }
    }
    else
    {
        real_filename = (char *)malloc(strlen(template_filename) + 1);
        strcpy(real_filename, template_filename);
    }

    if ((filehandle = fopen(real_filename, "r")) == NULL)
    {
        free(real_filename);
        template_errno = TMPL_EFOPEN;
        return 0;
    }

    template = (char *)malloc(finfo.st_size + 1);
    if (template == NULL)
    {
        free(real_filename);
        fclose(filehandle);
        template_errno = TMPL_EMALLOC;
        return 0;
    }

    fread(template, 1, finfo.st_size, filehandle);
    template[finfo.st_size] = '\0';

    fclose(filehandle);

    if (tokenize(ctx, template, tokens))
    {
        retval = parser(ctx, 1, tokens, output);
    } else
    {
        retval = 0;
    }
    free(real_filename);
    free(template);
    token_group_destroy(tokens);

    if (retval < 0)
    {
        return(0);
    } else
    {
        return(1);
    }
}



/* ====================================================================
 * NAME:          template_parse_string
 *
 * DESCRIPTION:   Takes an input string and context as input - runs the
 *                input through parser().
 *
 * RETURN VALUES: Returns 0 if the parsing fails, 1 otherwise.
 *
 * BUGS:          Hopefully none.
 * ==================================================================== */
int
template_parse_string(context_p ctx, char *tmpl, char **output)
{
    token_group_p tokens = token_group_init();
    int retval;

    if (tokenize(ctx, tmpl, tokens))
    {
        retval = parser(ctx, 1, tokens, output);
    } else
    {
        retval = 0;
    }

    token_group_destroy(tokens);

    if (retval < 0)
    {
        return(0);
    }
    {
        return(1);
    }
}



/* ====================================================================
 * NAME:          template_strerror
 *
 * DESCRIPTION:   Returns a string describing the current error condition
 *                (if any)
 *
 * RETURN VALUES: A string describing the current error condition.
 *
 * BUGS:          Hopefully none.
 * ==================================================================== */
char *
template_strerror(void)
{
    if ((template_errno < TMPL_ERR_MIN) || (template_errno > TMPL_ERR_MAX)) {
        template_errno = TMPL_ESCREWY;
    }
    return(template_errno_strings[template_errno]);
}



/* ====================================================================
 * NAME:          template_free_output
 *
 * DESCRIPTION:   Frees a string.
 *
 * RETURN VALUES: None.
 *
 * BUGS:          The fact that it exists at all. DO NOT USE THIS FUNCTION!
 * ==================================================================== */
void
template_free_output(char *output)
{
    free(output);
}
