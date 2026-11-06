/* ------------------------------------------------------------------------
@NAME       : ast.c
@DESCRIPTION: Creating, freeing and traversing the AST for a single entry.
-------------------------------------------------------------------------- */

#include <stdlib.h>
#include "bt_internal.h"

AST *
bt_new_ast (bt_nodetype nodetype, const char *text, size_t len,
            const char *filename, int line, long offset)
{
   AST * node = bt_xcalloc (1, sizeof (AST));

   node->nodetype = nodetype;
   node->metatype = BTE_UNKNOWN;
   node->text = text ? bt_xstrndup (text, len) : NULL;
   node->filename = filename;
   node->line = line;
   node->offset = offset;
   return node;
}

void
bt_free_ast (AST *ast)
{
   /* iterate along siblings, recurse into children */
   while (ast)
   {
      AST * next = ast->right;
      bt_free_ast (ast->down);
      free (ast->text);
      free (ast);
      ast = next;
   }
}


AST *
bt_next_entry (AST *entry_list, AST *prev_entry)
{
   if (entry_list == NULL || entry_list->nodetype != BTAST_ENTRY)
      return NULL;
   if (prev_entry)
      return prev_entry->nodetype == BTAST_ENTRY ? prev_entry->right : NULL;
   return entry_list;
}

bt_metatype
bt_entry_metatype (AST *entry)
{
   if (!entry || entry->nodetype != BTAST_ENTRY)
      return BTE_UNKNOWN;
   return entry->metatype;
}

char *
bt_entry_type (AST *entry)
{
   if (!entry || entry->nodetype != BTAST_ENTRY)
      return NULL;
   return entry->text;
}

char *
bt_entry_key (AST *entry)
{
   if (entry && entry->metatype == BTE_REGULAR &&
       entry->down && entry->down->nodetype == BTAST_KEY)
      return entry->down->text;
   return NULL;
}

AST *
bt_next_field (AST *entry, AST *prev, char **name)
{
   AST * field;

   if (name) *name = NULL;
   if (!entry || !entry->down)
      return NULL;
   if (entry->metatype != BTE_MACRODEF && entry->metatype != BTE_REGULAR)
      return NULL;

   if (prev == NULL)                    /* they want the first one */
   {
      field = entry->down;
      if (field->nodetype == BTAST_KEY) /* skip over citation key */
         field = field->right;
   }
   else
      field = prev->right;

   if (!field)
      return NULL;
   if (name) *name = field->text;
   return field;
}

/* Walk the simple values of a field, or of a comment/preamble entry */
AST *
bt_next_value (AST *top, AST *prev, bt_nodetype *nodetype, char **text)
{
   AST * value = NULL;

   if (nodetype) *nodetype = BTAST_BOGUS;
   if (text) *text = NULL;
   if (!top)
      return NULL;

   if (top->nodetype == BTAST_FIELD ||
       (top->nodetype == BTAST_ENTRY &&
        (top->metatype == BTE_COMMENT || top->metatype == BTE_PREAMBLE)))
      value = prev ? prev->right : top->down;

   if (value)
   {
      if (nodetype) *nodetype = value->nodetype;
      if (text) *text = value->text;
   }
   return value;
}
