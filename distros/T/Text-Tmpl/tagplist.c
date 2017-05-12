/* ====================================================================
 * Copyright 1999 Web Juice, LLC. All rights reserved.
 *
 * tagplist.c
 *
 * Functions for manipulating the tag pair list structure in the template
 * library.
 *
 * ==================================================================== */

#include <stdlib.h>
#include <string.h>

#include <template.h>

/* ====================================================================
 * NAME:          tagplist_init
 *
 * DESCRIPTION:   Initializes and returns a pointer to a new tag pair
 *                list structure.
 *
 * RETURN VALUES: Returns NULL if the memory allocation fails; otherwise
 *                returns a pointer to a tag pair list structure.
 *
 * BUGS:          Hopefully none.
 * ==================================================================== */
tagplist_p
tagplist_init()
{
    tagplist_p tag_pair_list;

    tag_pair_list = (tagplist_p)malloc(sizeof(tagplist));
    if (tag_pair_list == NULL)
    { 
        template_errno = TMPL_EMALLOC;
        return NULL;
    }

    tag_pair_list->open_name     = NULL;
    tag_pair_list->close_name    = NULL;
    tag_pair_list->function      = NULL;
    tag_pair_list->next          = NULL;
    tag_pair_list->named_context = 0;

    return(tag_pair_list);
}



/* ====================================================================
 * NAME:          tagplist_destroy
 *
 * DESCRIPTION:   Frees up all memory associated with a tag pair list.
 *
 * RETURN VALUES: None.
 *
 * BUGS:          Because a free()d pointer still *looks* valid, it is
 *                difficult to protect against the problems that arise
 *                if the user calls this function too early.
 * ==================================================================== */
void
tagplist_destroy(tagplist_p tag_pair_list)
{
    tagplist_p next;

    if (tag_pair_list == NULL)
    {
        return;
    }

    next = tag_pair_list->next;

    tag_pair_list->next = NULL;
    if (tag_pair_list->open_name != NULL)
    {
        free(tag_pair_list->open_name);
    }
    if (tag_pair_list->close_name != NULL)
    {
        free(tag_pair_list->close_name);
    }
    free(tag_pair_list);

    tagplist_destroy(next);
}



/* ====================================================================
 * NAME:          tagplist_alias
 *
 * DESCRIPTION:   Copy an existing tag pair to a new tag pair name.
 *
 * RETURN VALUES: Returns 0 upon failure; 1 on success.
 *
 * BUGS:          Hopefully none.
 * ==================================================================== */
int
tagplist_alias(tagplist_p *tag_pair_list, char *old_open_name,
               char *old_close_name, char *new_open_name, char *new_close_name)
{
    tagplist_p current = *tag_pair_list;

    /* Make sure the names are not NULL */
    if ((old_open_name == NULL) || (old_close_name == NULL)
       || (new_open_name == NULL) || (new_close_name == NULL))
    {
        template_errno = TMPL_ENULLARG;
        return 0;
    }

    /* Walk through the contexts to find the old tag */
    while (current != NULL)
    {
        if ((current->open_name != NULL) && (current->close_name != NULL)
           && (strcmp(current->open_name, old_open_name) == 0)
           && (strcmp(current->close_name, old_close_name) == 0))
        {
            return tagplist_register(tag_pair_list, current->named_context,
                                     new_open_name, new_close_name,
                                     current->function);
        }
        current = current->next;
    }

    template_errno = TMPL_ENOTAGP;
    return 0;
}



/* ====================================================================
 * NAME:          tagplist_remove
 *
 * DESCRIPTION:   Remove a tag pair.
 *
 * RETURN VALUES: None.
 *
 * BUGS:          Hopefully none.
 * ==================================================================== */
void
tagplist_remove(tagplist_p *tag_pair_list, char *open_name)
{
    tagplist_p current  = *tag_pair_list;
    tagplist_p previous = NULL;

    /* Make sure the name isn't NULL */
    if (open_name == NULL)
    {
        template_errno = TMPL_ENULLARG;
        return;
    }

    /* Make sure the pointer passed in wasn't NULL */
    if (*tag_pair_list == NULL)
    {
        template_errno = TMPL_ENULLARG;
        return;
    }

    while (current != NULL)
    {
        if ((current->open_name != NULL)
         && (strcmp(current->open_name, open_name) == 0))
        {
            break;
        }
        previous = current;
        current  = current->next;
    }

    /* The tag wasn't found */
    if (current == NULL)
    {
        return;
    }

    /* Move a pointer to skip the found tag */
    if (previous == NULL)
    {
        *tag_pair_list = current->next;
    } else
    {
        previous->next = current->next;
    }

    /* Destroy the tag */
    current->next = NULL;
    if (current->open_name != NULL)
    {
        free(current->open_name);
    }
    if (current->close_name != NULL)
    {
        free(current->close_name);
    }
    free(current);
}



/* ====================================================================
 * NAME:          tagplist_register
 *
 * DESCRIPTION:   Register a new tag pair and associated function to call.
 *
 * RETURN VALUES: Returns 0 upon failure; 1 on success.
 *
 * BUGS:          Hopefully none.
 * ==================================================================== */
int
tagplist_register(tagplist_p *tag_pair_list, char named_context,
                  char *open_name, char *close_name,
                  void (*function) (context_p, int, char**))
{
    tagplist_p new = NULL;
    int length;

    /* Make sure the function isn't NULL */
    if (function == NULL)
    {
        template_errno = TMPL_ENULLARG;
        return 0;
    }

    if ((open_name == NULL) || (close_name == NULL))
    {
        template_errno = TMPL_ENULLARG;
        return 0;
    }

    if (*tag_pair_list == NULL)
    {
        template_errno = TMPL_ENULLARG;
        return 0;
    }

    new = tagplist_init();

    new->function      = function;
    new->named_context = named_context;

    length = strlen(open_name);
    new->open_name = (char *)malloc(length + 1);
    strncpy(new->open_name, open_name, length);
    new->open_name[length] = '\0';

    length = strlen(close_name);
    new->close_name = (char *)malloc(length + 1);
    strncpy(new->close_name, close_name, length);
    new->close_name[length] = '\0';

    new->next = *tag_pair_list;

    *tag_pair_list = new;

    return 1;
}



/* ====================================================================
 * NAME:          tagplist_is_opentag
 *
 * DESCRIPTION:   Find out whether a particular tag is a legitimate
 *                opening tag.
 *
 * RETURN VALUES: Returns 0 if there's a problem or if the name is not
 *                a valid opening tag, or 1 if the name is a valid tag.
 *
 * BUGS:          Hopefully none.
 * ==================================================================== */
int
tagplist_is_opentag(tagplist_p tag_pair_list, char *open_name)
{
    tagplist_p current  = tag_pair_list;

    while (current != NULL)
    {
        if ((current->open_name != NULL) && (current->function != NULL)
            && (strcmp(current->open_name, open_name) == 0))
        {
            return 1;
        }
        current = current->next;
    }

    template_errno = TMPL_ENOTAGP;
    return 0;
}



/* ====================================================================
 * NAME:          tagplist_is_closetag
 *
 * DESCRIPTION:   Find out whether a particular tag is a valid closing
 *                tag for another (i.e. whether you have a valid tag pair).
 *
 * RETURN VALUES: Returns 0 if there's a problem or if the names do not
 *                form a valid tag pair; otherwise returns 1.
 *
 * BUGS:          Hopefully none.
 * ==================================================================== */
int
tagplist_is_closetag(tagplist_p tag_pair_list, char *open_name,
                     char *close_name)
{
    tagplist_p current  = tag_pair_list;

    while (current != NULL)
    {
        if ((current->open_name != NULL) && (current->close_name != NULL)
            && (strcmp(current->open_name, open_name) == 0)
            && (strcmp(current->close_name, close_name) == 0))
        {
            return 1;
        }
        current = current->next;
    }

    template_errno = TMPL_ENOTAGP;
    return 0;
}



/* ====================================================================
 * NAME:          tagplist_exec
 *
 * DESCRIPTION:   Executes the function associated with a given tag pair.
 *
 * RETURN VALUES: Returns NULL if there's a problem or the context
 *                modified by the function otherwise.
 *
 * BUGS:          Hopefully none.
 * ==================================================================== */
context_p
tagplist_exec(tagplist_p tag_pair_list, char *open_name, context_p ctx,
              int argc, char **argv)
{
    tagplist_p current = tag_pair_list;

    while (current != NULL)
    {
        if ((current->open_name != NULL) && (current->function != NULL)
            && (strcmp(current->open_name, open_name) == 0))
        {
            if ((current->named_context) && (argc >= 0))
            {
                context_p named_context;

                named_context = context_get_named_child(ctx, argv[1]);
                if (named_context == NULL)
                {
                    named_context = context_get_anonymous_child(ctx);
                    if (named_context == NULL)
                    {
                        return NULL;
                    }

                    ctx_unset_output(named_context);
                    return(named_context);
                }

                current->function(named_context, argc, argv);

                return(named_context);
            } else {
                context_p anonymous_context;

                anonymous_context = context_get_anonymous_child(ctx);
                if (anonymous_context == NULL)
                {
                    return NULL;
                }

                current->function(anonymous_context, argc, argv);
                return(anonymous_context);
            }
        }
        current = current->next;
    }

    template_errno = TMPL_ENOTAGP;
    return NULL;
}
