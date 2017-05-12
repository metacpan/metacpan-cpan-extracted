/* ====================================================================
 * Copyright 1999 Web Juice, LLC. All rights reserved.
 *
 * context.c
 *
 * Functions for manipulating the context structure in the template
 * library.
 *
 * ==================================================================== */

#include <stdlib.h>

#include <template.h>

/* ====================================================================
 * NAME:          context_init
 *
 * DESCRIPTION:   Initializes and returns a pointer to a new context
 *                structure.
 *
 * RETURN VALUES: Returns NULL if the memory allocation fails; otherwise
 *                returns a pointer to a varlist structure.
 *
 * BUGS:          Hopefully none.
 * ==================================================================== */
context_p
context_init(void)
{
    context_p ctx;

    ctx = (context_p)malloc(sizeof(context));
    if (ctx == NULL)
    {
        template_errno = TMPL_EMALLOC;
        return NULL;
    }

    ctx->variables            = NULL;
    ctx->named_child_contexts = NULL;
    ctx->simple_tags          = NULL;
    ctx->tag_pairs            = NULL;
    ctx->parent_context       = NULL;
    ctx->next_context         = NULL;
    ctx->last_context         = ctx;
    ctx->flags                = CTX_FLAG_OUTPUT;
    ctx->buffer               = NULL;
    ctx->bufsize              = -1;

    return(ctx);
}



/* ====================================================================
 * NAME:          context_destroy
 *
 * DESCRIPTION:   Frees up all memory associated with a context.
 *
 * RETURN VALUES: None.
 *
 * BUGS:          Because a free()d pointer still *looks* valid, it is
 *                difficult to protect against the problems that arise
 *                if the user calls this function too early.
 * ==================================================================== */
void
context_destroy(context_p ctx)
{
    context_p next;

    if (ctx == NULL)
    {
        return;
    }

    next = ctx->next_context;

    if (ctx->named_child_contexts != NULL)
    {
        nclist_destroy(ctx->named_child_contexts);
    }
    if (ctx->variables != NULL)
    {
        varlist_destroy(ctx->variables);
    }
    if (ctx->simple_tags != NULL)
    {
        staglist_destroy(ctx->simple_tags);
    }
    if (ctx->tag_pairs != NULL)
    {
        tagplist_destroy(ctx->tag_pairs);
    }
    if (ctx->buffer != NULL)
    {
        free(ctx->buffer);
    }

    ctx->named_child_contexts = NULL;
    ctx->variables            = NULL;
    ctx->next_context         = NULL;
    ctx->last_context         = NULL;
    ctx->parent_context       = NULL;
    ctx->simple_tags          = NULL;
    ctx->tag_pairs            = NULL;
    ctx->buffer               = NULL;
    free(ctx);

    context_destroy(next);
}



/* ====================================================================
 * NAME:          context_get_value
 *
 * DESCRIPTION:   Returns the value of the variable stored under the given
 *                name in the current context or any parents' variable list.
 *
 * RETURN VALUES: This function will return NULL if there are any problems
 *                or if there is no value.  It returns a string containing
 *                the value on success.
 *
 * BUGS:          Hopefully none.
 * ==================================================================== */
char *
context_get_value(context_p ctx, char *name)
{
    char *result;

    if (ctx == NULL)
    {
        template_errno = TMPL_ENULLARG;
        return NULL;
    }

    result = varlist_get_value(ctx->variables, name);
    if (result != NULL)
    {
        return(result);
    }
    if (ctx->parent_context == NULL)
    {
        template_errno = TMPL_ENOVALUE;
        return NULL;
    }
    return(context_get_value(ctx->parent_context, name));
}



/* ====================================================================
 * NAME:          context_set_value
 *
 * DESCRIPTION:   Set a variable in the context's variable list.
 *
 * RETURN VALUES: Returns 0 if there's any trouble.  Returns 1 if the
 *                variable was successfully set.
 *
 * BUGS:          Hopefully none.
 * ==================================================================== */
int
context_set_value(context_p ctx, char *name, char *value)
{
    if (ctx == NULL)
    {
        template_errno = TMPL_ENULLARG;
        return 0;
    }
    return(varlist_set_value(&(ctx->variables), name, value));
}



/* ====================================================================
 * NAME:          context_get_anonymous_child
 *
 * DESCRIPTION:   Creates and returns an unnamed context with the parent
 *                set to the current context (i.e. a new context within
 *                the scope of the current context).
 *
 * RETURN VALUES: Returns NULL if there's a problem; returns a pointer to
 *                the new context otherwise.
 *
 * BUGS:          Hopefully none.
 * ==================================================================== */
context_p
context_get_anonymous_child(context_p ctx)
{
    context_p anonymous_ctx;

    if (ctx == NULL)
    {
        template_errno = TMPL_ENULLARG;
        return NULL;
    }

    anonymous_ctx = context_init();
    if (anonymous_ctx == NULL)
    {
        return NULL;
    }

    anonymous_ctx->parent_context = ctx;
    anonymous_ctx->flags          = ctx->flags;
    ctx_set_anonymous(anonymous_ctx);

    return(anonymous_ctx);
}



/* ====================================================================
 * NAME:          context_get_named_child
 *
 * DESCRIPTION:   This function returns a named context within the scope
 *                of the current context, if it exists.
 *
 * RETURN VALUES: Returns NULL if there is any problem, or if the context
 *                doesn't exist; else returns a pointer to the context.
 *
 * BUGS:          Hopefully none.
 * ==================================================================== */
context_p
context_get_named_child(context_p ctx, char *name)
{
    context_p result;

    if ((ctx == NULL) || (name == NULL))
    { 
        template_errno = TMPL_ENULLARG;
        return NULL;
    }

    result = nclist_get_context(ctx->named_child_contexts, name);
    if (result != NULL)
    {
        return(result);
    }
    if (ctx->parent_context == NULL)
    {
        template_errno = TMPL_ENOCTX;
        return NULL;
    }
    return(context_get_named_child(ctx->parent_context, name));
}



/* ====================================================================
 * NAME:          context_set_named_child
 *
 * DESCRIPTION:   This function creates a new named context within the
 *                scope of the current context.
 *
 * RETURN VALUES: Returns 0 if there is any trouble; returns 1 on success.
 *
 * BUGS:          Hopefully none.
 * ==================================================================== */
int
context_set_named_child(context_p ctx, char *name)
{
    context_p named_ctx;
    if (ctx == NULL)
    {
        template_errno = TMPL_ENULLARG;
        return 0;
    }

    if (! nclist_new_context(&(ctx->named_child_contexts), name))
    {
        return 0;
    }

    named_ctx = context_get_named_child(ctx, name);
    if (named_ctx == NULL)
    {
        return 0;
    }

    named_ctx->parent_context = ctx;
    named_ctx->flags          = ctx->flags;
    ctx_unset_anonymous(named_ctx);

    return 1;
}



/* ====================================================================
 * NAME:          context_add_peer
 *
 * DESCRIPTION:   This function adds a peer context (a.k.a. loop iteration)
 *                to the context passed in, and initializes it.
 *
 * RETURN VALUES: Returns NULL if there is any trouble; returns a pointer to
 *                the new peer context otherwise.
 *
 * BUGS:          Hopefully none.
 * ==================================================================== */
context_p
context_add_peer(context_p ctx)
{
    context_p peer_ctx;

    if (ctx == NULL)
    {
        template_errno = TMPL_ENULLARG;
        return NULL;
    }

    if (ctx->last_context == NULL)
    {
        template_errno = TMPL_ESCREWY;
        return NULL;
    }

    peer_ctx = context_init();
    if (peer_ctx == NULL)
    {
        return NULL;
    }
    peer_ctx->parent_context = ctx->parent_context;
    peer_ctx->flags          = ctx->flags;
    ctx_unset_anonymous(peer_ctx);

    ctx->last_context->next_context = peer_ctx;
    ctx->last_context               = peer_ctx;

    return(peer_ctx);
}



/* ====================================================================
 * NAME:          context_output_contents
 *
 * DESCRIPTION:   This function sets or unsets the output flag in a context
 *
 * RETURN VALUES: None.
 *
 * BUGS:          Hopefully none.
 * ==================================================================== */
void
context_output_contents(context_p ctx, char output_contents)
{
    if (ctx == NULL)
    {
        return;
    }

    if (output_contents)
    {
        ctx_set_output(ctx);
    }
    else
    {
        ctx_unset_output(ctx);
    }
    return;
}



/* ====================================================================
 * NAME:          context_root
 *
 * DESCRIPTION:   This function returns the root context for a given context.
 *
 * RETURN VALUES: The root context.
 *
 * BUGS:          Hopefully none.
 * ==================================================================== */
context_p
context_root(context_p ctx)
{
     context_p root = ctx;

     while (root->parent_context != NULL)
     {
         root = root->parent_context;
     }

     return root;
}
