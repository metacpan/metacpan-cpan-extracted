/* ====================================================================
 * Copyright 1999 J. David Lowe. All rights reserved.
 *
 * tokens.c
 *
 * Functions for manipulating a token list.
 *
 * ==================================================================== */

#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <ctype.h>

#include <template.h>



/* ====================================================================
 * NAME:          token_group_init
 *
 * DESCRIPTION:   Initializes and returns a pointer to a new token_group
 *                structure.
 *
 * RETURN VALUES: Returns NULL if the memory allocation fails; otherwise
 *                returns a pointer to a token_group structure.
 *
 * BUGS:          Hopefully none.
 * ==================================================================== */
token_group_p
token_group_init(void)
{
    token_group_p tgroup;

    tgroup = (token_group_p)malloc(sizeof(token_group));
    if (tgroup == NULL)
    {
        template_errno = TMPL_EMALLOC;
        return NULL;
    }

    tgroup->tokens      = NULL;
    tgroup->max_token   = -1;
    tgroup->first       = 0;
    tgroup->last        = 0;
    tgroup->current     = 0;

    return(tgroup);
}



/* ====================================================================
 * NAME:          token_subgroup_init
 *
 * DESCRIPTION:   Initializes and returns a pointer to a new token_group
 *                structure, "inherited" from an existing token_group.
 *
 * RETURN VALUES: Returns NULL if the memory allocation fails; otherwise
 *                returns a pointer to a token_group structure.
 *
 * BUGS:          Hopefully none.
 * ==================================================================== */
token_group_p
token_subgroup_init(token_group_p tgroup, unsigned int first,
                    unsigned int last)
{
    token_group_p new;

    if (tgroup == NULL)
    {
        template_errno = TMPL_ENULLARG;
        return NULL;
    }

    new = token_group_init();
    if (new == NULL)
    {
         return NULL;
    }

    new->tokens      = tgroup->tokens;
    new->max_token   = tgroup->max_token;
    new->first       = first;
    new->last        = last;
    new->current     = 0;

    return(new);
}



/* ====================================================================
 * NAME:          token_group_destroy
 *
 * DESCRIPTION:   Frees up all memory associated with a token_group.
 *
 * RETURN VALUES: None.
 *
 * BUGS:          Because a free()d pointer still *looks* valid, it is
 *                difficult to protect against the problems that arise
 *                if the user calls this function too early.
 * ==================================================================== */
void
token_group_destroy(token_group_p tgroup)
{
    if (tgroup == NULL)
    {
        return;
    }

    if (tgroup->tokens != NULL)
    {
        int i;

        for (i = 0; i <= tgroup->max_token; i++)
        {
            if (tgroup->tokens[i].type == TOKEN_TYPE_TAG_PARSED)
            {
                int j;
    
                for (j = 0; j <= tgroup->tokens[i].tag_argc; j++)
                {
                    free(tgroup->tokens[i].tag_argv[j]);
                }
                free(tgroup->tokens[i].tag_argv);
    
                tgroup->tokens[i].type = TOKEN_TYPE_TAG;
            }
        }

        free(tgroup->tokens);
        tgroup->tokens = NULL;
    }

    free(tgroup);
}



/* ====================================================================
 * NAME:          token_subgroup_destroy
 *
 * DESCRIPTION:   Frees up all memory associated with a token_group
 *                created by token_subgroup_init()
 *
 * RETURN VALUES: None.
 *
 * BUGS:          Because a free()d pointer still *looks* valid, it is
 *                difficult to protect against the problems that arise
 *                if the user calls this function too early.
 * ==================================================================== */
void
token_subgroup_destroy(token_group_p tgroup)
{
    if (tgroup == NULL)
    {
        return;
    }

    tgroup->tokens = NULL;
    token_group_destroy(tgroup);
}



/* ====================================================================
 * NAME:          token_rewind
 *
 * DESCRIPTION:   Reets the token group's "current" index.
 *
 * RETURN VALUES: None.
 *
 * BUGS:          Hopefully none.
 * ==================================================================== */
void
token_rewind(token_group_p tgroup)
{
    if (tgroup != NULL)
    {
        tgroup->current = tgroup->first;
    }
}



/* ====================================================================
 * NAME:          token_next
 *
 * DESCRIPTION:   Returns the next token in a token group, and increments
 *                the token group's "current" index.
 *
 * RETURN VALUES: Returns NULL if there are no more tokens to return;
 *                otherwise returns a pointer to a token structure.
 *
 * BUGS:          Hopefully none.
 * ==================================================================== */
token_p
token_next(context_p ctx, token_group_p tgroup, unsigned int *position)
{
    token_p rtok;

    if (tgroup == NULL)
    {
        template_errno = TMPL_ENULLARG;
        return NULL;
    }

    if ((tgroup->max_token < 0) || (tgroup->tokens == NULL))
    {
        template_errno = TMPL_ENOTOKEN;
        return NULL;
    }

    /* If current > last, we're done, so return NULL, and wrap */
    if (tgroup->current > tgroup->last)
    {
        tgroup->current = tgroup->first;
        template_errno = TMPL_ENOTOKEN;
        return NULL;
    }

    /* Otherwise, increment and return the next token */
    *position = tgroup->current;
    ++(tgroup->current);
    rtok = &(tgroup->tokens[*position]);

    /* Side effect: parse tag if not already done */
    if (rtok->type == TOKEN_TYPE_TAG)
    {
        token_parsetag(ctx, rtok);
    } else if (rtok->type == TOKEN_TYPE_TAG_PARSED)
    {
        int j;

        for (j = 1; j <= rtok->tag_argc; j++)
        {
            free(rtok->tag_argv[j]);
            rtok->tag_argv[j] = NULL;
        }

        token_parsetag(ctx, rtok);
    }

    return(rtok);
}



/* ====================================================================
 * NAME:          token_parsetag
 *
 * DESCRIPTION:   Parses a tag's argument list in the current context.
 *
 * RETURN VALUES: None.
 *
 * BUGS:          Hopefully none.
 * ==================================================================== */
void
token_parsetag(context_p ctx, token_p token)
{
    int length = 0;
    int point  = 0;
    int total  = token->length;
    int argbegin;
    char *tag, *p, last, instring;
    int current_argc;

    tag = token->t;

    for (; (point < total) && isspace(tag[point]); point++);
    for (p = tag + point; (point + length < total) && (!isspace(*p)); p++, length++) ;

    current_argc = 0;
    if (token->tag_argc < current_argc)
    {
        token->tag_argv =
                      (char **)malloc((current_argc + 1) * sizeof(char **));
        token->tag_argc = current_argc;

        /* Copy the tag name into argv[0] only if it's not already done */
        token->tag_argv[0] = (char *)malloc(length + 1);
        strncpy(token->tag_argv[0], tag + point, length);
        (token->tag_argv[0])[length] = '\0';
    }

    last      = '\0';
    instring  = 0;
    argbegin  = 0;
    for (point += length + 1; point < total; point++)
    {
        last = *p;
        p = tag + point;

        if ((! isspace((int)*p)) && (current_argc == 0))
        {
            argbegin = point;
            ++current_argc;
            if (token->tag_argc < current_argc)
            {
                token->tag_argv = (char **)realloc(token->tag_argv,
                                        (current_argc + 1) * (sizeof(char *)));
                token->tag_argc = current_argc;
            }
        }
        if (*p == '"')
        {
            if ((instring) && (last != '\\'))
            {
                instring = 0;
            } else if (! instring)
            {
                instring = 1;
            }
        } else if (*p == ',')
        {
            if (! instring)
            {
                /* parse the current argument string into tag_argv */
                token_parsearg(ctx, tag + argbegin, point - argbegin,
                               &(token->tag_argv[current_argc]));

                /* point to the next argument string */
                argbegin = point + 1;
                ++current_argc;
                if (token->tag_argc < current_argc)
                {
                    token->tag_argv = (char **)realloc(token->tag_argv,
                                        (current_argc + 1) * (sizeof(char *)));
                    token->tag_argc = current_argc;
                }
            }
        }
    }
    if (current_argc > 0)
    {
        token_parsearg(ctx, tag + argbegin, total - argbegin,
                       &(token->tag_argv[current_argc]));
    }

    token->type = TOKEN_TYPE_TAG_PARSED;

    return;
}



/* ====================================================================
 * NAME:          token_push
 *
 * DESCRIPTION:   Adds a new token to a token group, extending the group's
 *                token list if necessary.
 *
 * RETURN VALUES: Returns 0 on failure, 1 on success.
 *
 * BUGS:          Hopefully none.
 * ==================================================================== */
int
token_push(token_group_p tgroup, char *t, unsigned long length,
           unsigned char type)
{
    if (tgroup == NULL)
    {
        template_errno = TMPL_ENULLARG;
        return 0;
    }

    if (tgroup->max_token < 0)
    {
        --(tgroup->last);
    }

    if ((tgroup->max_token < 0) || (tgroup->last >= tgroup->max_token)) {
        /* We have to allocate some new token space */
        unsigned int i;

        tgroup->max_token += TOKEN_GROWFACTOR;
        tgroup->tokens = (token_p)realloc((void *)tgroup->tokens,
                                      sizeof(token) * (tgroup->max_token + 1));

        for (i = tgroup->last + 1; i <= tgroup->max_token; i++)
        {
            (tgroup->tokens[i]).type = TOKEN_TYPE_NONE;
        }
    }

    ++(tgroup->last);

    tgroup->tokens[tgroup->last].t        = t;
    tgroup->tokens[tgroup->last].tag_argc = -1;
    tgroup->tokens[tgroup->last].tag_argv = NULL;
    tgroup->tokens[tgroup->last].length   = length;
    tgroup->tokens[tgroup->last].type     = type;

    return(1);
}



/* ====================================================================
 * NAME:          tokenize
 *
 * DESCRIPTION:   Breaks a string into a token group using the rules in
 *                the current context.
 *
 * RETURN VALUES: Returns 0 if the input string contains unrecoverable
 *                syntax errors, 1 otherwise.
 *
 * BUGS:          Hopefully none.
 * ==================================================================== */
int
tokenize(context_p ctx, char *input, token_group_p tokens)
{
    char strip = ctx_is_strip(ctx);
    char *otag = context_get_value(ctx, TMPL_VARNAME_OTAG);
    int  slo   = strlen(otag);
    char *ctag = context_get_value(ctx, TMPL_VARNAME_CTAG);
    int  slc   = strlen(ctag);

    char *position = input;
    char *tagstart, *tagend;

    while ((tagstart = strstr(position, otag)) != NULL)
    {
        /* everything before the open tag is one token */
        token_push(tokens, position, tagstart - position, TOKEN_TYPE_TEXT);

        /* find the end of the tag */
        tagend = strstr(tagstart, ctag);
        if (tagend == NULL)
        {
            /* tokens_destroy */
            template_errno = TMPL_EPARSE;
            return 0;
        }

        /* the tag is one token */
        token_push(tokens, tagstart + slo, tagend - tagstart - slo,
                   TOKEN_TYPE_TAG);

        /* move past the end of the tag */
        position = tagend + slc;
        if ((strip) && (*position == '\n')) position++;
    }

    /* everything after the last tag is one token */
    token_push(tokens, position, strlen(position), TOKEN_TYPE_TEXT);

    return 1;
}



/* ====================================================================
 * NAME:          token_parsearg
 *
 * DESCRIPTION:   Parses a string (inarg) as a single argument.  Does
 *                variable substitution and string concatentation, and
 *                outputs the result into outarg.
 *
 * RETURN VALUES: None - output is placed into outarg.
 *
 * BUGS:          Character by character parsing may be avoidable - not
 *                sure.
 * ==================================================================== */
void
token_parsearg(context_p ctx, char *inarg, int size, char **outarg)
{
    char *begin, *p, *varvalue, *b;
    char instring, last;
    int  index, cursize, i, length;
    context_p rootctx = NULL;

    i       = 0;
    index   = 0;
    cursize = 0;
    *outarg = NULL;

    /* move past leading whitespace */
    for (begin = inarg; isspace((int)*begin); ++begin, ++i) ;

    instring = 0;
    last     = '\0';
    for (p = begin; i < size; last = *p, p++, i++)
    {
        if (*p == '"')
        {
            if (instring)
            {
                if (last == '\\')
                {
                    --index;
                    append_output(outarg, "\"", 1, &cursize, &index);
                } else
                {
                    instring = 0;
                }
            } else if (! instring)
            {
                instring = 1;
            }
        } else if (*p == '$')
        {
            if (instring)
            {
                append_output(outarg, p, 1, &cursize, &index);
            } else
            {
                b = ++p;

                for (++i; ((i <= size) && (isalnum((int)*p) || (*p == '_') || (*p == '.'))); p++, i++) ;

                length = p - b;

                if (rootctx == NULL)
                {
                    rootctx = context_root(ctx);
                }

                if (rootctx->bufsize < (length + 1))
                {
                    if (rootctx->buffer != NULL)
                    {
                        free(rootctx->buffer);
                    }
                    rootctx->buffer  = (char *)malloc(length + 1);
                    rootctx->bufsize = length + 1;
                }
                strncpy(rootctx->buffer, b, length);
                (rootctx->buffer)[length] = '\0';

                varvalue = context_get_value(ctx, rootctx->buffer);
                if (varvalue != NULL)
                {
                    append_output(outarg, varvalue, strlen(varvalue),
                                  &cursize, &index);
                }
                --p;
                --i;
            }
        } else
        {
            if (instring)
            {
                append_output(outarg, p, 1, &cursize, &index);
            }
        }
    }

    /* ensure null termination even if append_output was never called */
    if (*outarg != NULL)
    {
        (*outarg)[index] = '\0';
    }
}



/* ====================================================================
 * NAME:          append_output
 *
 * DESCRIPTION:   Function used by parser to dynamically expand a string
 *                as needed.  This is really a glorified strncat which
 *                grows the destination string as needed.
 *
 * RETURN VALUES: None, but *output is modified.
 *
 * BUGS:          Hopefully none.
 * ==================================================================== */
void
append_output(char **output, char *append, int append_size, int *current_size,
              int *current_length)
{
    if (((*current_length) + append_size + 1) > *current_size) {
        char *temp;

        if (((*current_length) + append_size + 1) > ((*current_size) * 2))
        {
            *current_size = ((*current_length) + append_size + 1) * 2;
        } else
        {
            *current_size = (*current_size) * 2;
        }
        temp = (char *)malloc(*current_size);

        if (*output != NULL)
        {
            strncpy(temp, *output, *current_length);
            temp[*current_length] = '\0';

            free(*output);
        }
        *output = temp;
    }

    strncpy((*output) + (*current_length), append, append_size);
    (*output)[(*current_length) + append_size] = '\0';

    (*current_length) += append_size;
}
