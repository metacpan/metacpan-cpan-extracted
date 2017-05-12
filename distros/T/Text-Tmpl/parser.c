/* ====================================================================
 * Copyright 1999 Web Juice, LLC. All rights reserved.
 *
 * parser.c
 *
 * The parsing bits of the template library.
 *
 * ==================================================================== */

#include <stdlib.h>
#include <stdio.h>
#include <ctype.h>
#include <string.h>

#include <template.h>



/* ====================================================================
 * NAME:          parser
 *
 * DESCRIPTION:   parses the given input using the current context, and
 *                outputs to a new string pointed to by the output
 *                parameter.
 *
 * RETURN VALUES: Returns -1 if there's a problem, and the length of the
 *                output string if the parsing was successful.  The real
 *                output goes into the output string (which the caller is
 *                responsible for freeing!)
 *
 * BUGS:          Hopefully none.
 * ==================================================================== */
int
parser(context_p ctx, int looping, token_group_p tokens, char **output)
{
    context_p    current       = ctx;
    int          output_size   = 0;
    int          output_length = 0;
    context_p    rootctx       = context_root(ctx);
    staglist_p   simple_tags   = NULL;
    tagplist_p   tag_pairs     = NULL;
    token_p      token         = NULL;
    unsigned int tokpos        = 0;

    if (ctx == NULL)
    {
        template_errno = TMPL_ENULLARG;
        return -1;
    }
    if (tokens == NULL)
    {
        template_errno = TMPL_ENULLARG;
        return -1;
    }

    simple_tags = rootctx->simple_tags;
    tag_pairs   = rootctx->tag_pairs;

    *output = NULL;

    do
    {
        /* let's avoid doing any work as long as we can */
        if (! ctx_is_output(current))
        {
            if (looping)
            {
                current = current->next_context;
            }
            continue;
        }

        /* rewind the token list */
        token_rewind(tokens);

        /* while we have a token */
        while ((token = token_next(current, tokens, &tokpos)) != NULL)
        {
            if (token->type == TOKEN_TYPE_TEXT)
            {
                append_output(output, token->t, token->length, &output_size,
                              &output_length);
                continue;
            } 
            if (token->type != TOKEN_TYPE_TAG_PARSED)
            { 
                template_errno = TMPL_ESCREWY;
                return -1;
            }

            /* deal with the simple tag case */
            if (staglist_exists(simple_tags, token->tag_argv[0]))
            {
                char *result;

                if ((staglist_exec(simple_tags, token->tag_argv[0], current,
                                   &result, token->tag_argc, token->tag_argv))
                    && (result != NULL))
                {
                    token_group_p subtokens = token_group_init();
                    char *parsed_result = NULL;
                    int  parsed_result_length = 0;

                    if (tokenize(current, result, subtokens))
                    {
                        parsed_result_length = parser(current, 0, subtokens,
                                                      &parsed_result);
                    } else
                    {
                        return -1;
                    }

                    token_group_destroy(subtokens);

                    if (parsed_result_length < 0)
                    {
                        free(result);
                        free(parsed_result);

                        return -1;
                    }

                    append_output(output, parsed_result, parsed_result_length,
                                  &output_size, &output_length);

                    free(result);
                    free(parsed_result);
                }
            /* deal with the tag pair case */
            } else if (tagplist_is_opentag(tag_pairs, token->tag_argv[0]))
            {
                int          depth     = 1;
                token_p      subtok    = NULL;
                unsigned int subtokpos = 0;

                while ((subtok = token_next(current, tokens, &subtokpos))!=NULL)
                {
                    if (subtok->type != TOKEN_TYPE_TAG_PARSED)
                    {
                        continue;
                    }

                    /* if the close tag is the same as the open tag, we're
                       nesting... */
                    if (strcmp(token->tag_argv[0], subtok->tag_argv[0]) == 0)
                    {
                        ++depth;
                    /* if the close tag and open tag form a pair, we're
                       un-nesting... */
                    } else if (tagplist_is_closetag(tag_pairs,
                                      token->tag_argv[0], subtok->tag_argv[0]))
                    {
                        --depth;
                    }

                    /* if depth is zero, this close tag is *the* close tag. */
                    if (depth == 0)
                    {
                        token_group_p newtokens;
                        context_p newcontext;

                        newcontext = tagplist_exec(tag_pairs,token->tag_argv[0],
                                                   current, token->tag_argc,
                                                   token->tag_argv);
                        newtokens  = token_subgroup_init(tokens, tokpos + 1,
                                                         subtokpos - 1);
                        if ((newcontext != NULL) && (newtokens != NULL))
                        {
                            char *parsed_result       = NULL;
                            int  parsed_result_length = 0;

                            parsed_result_length = parser(newcontext, 1,
                                                          newtokens,
                                                          &parsed_result);

                            token_subgroup_destroy(newtokens);

                            if (parsed_result_length < 0)
                            {
                                free(parsed_result);
                                if (ctx_is_anonymous(newcontext))
                                {
                                    context_destroy(newcontext);
                                }

                                return -1;
                            }

                            append_output(output, parsed_result,
                                          parsed_result_length, &output_size,
                                          &output_length);

                            free(parsed_result);

                            if (ctx_is_anonymous(newcontext))
                            {
                                context_destroy(newcontext);
                            }

                            break;
                        }
                    }
                }
                if (depth != 0) {
                    template_errno = TMPL_EPARSE;
                    return -1;
                }
            }
        }

        /* done this iteration - move to the next */
        if (looping)
        {
            current = current->next_context;
        }

    } while ((looping) && (current != NULL));

    return output_length;
}
