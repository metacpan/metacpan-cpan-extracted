/* ------------------------------------------------------------------------
@NAME       : macros.c
@DESCRIPTION: Macro (@string) tables.  A table is a hash keyed on the
              case-folded macro name (macro names are case-insensitive).
              A table may have a parent: lookups that fail in a table fall
              back to its parent, but definitions and deletions only ever
              touch the table itself.  This lets a file keep its @string
              definitions private while still seeing the globally defined
              macros (eg. month names).
-------------------------------------------------------------------------- */

#include <stdlib.h>
#include <string.h>
#include "bt_internal.h"

typedef struct macro
{
   char *         key;                  /* case-folded name */
   char *         text;                 /* may be NULL */
   unsigned long  hash;
   struct macro * next;
} macro;

struct bt_macros
{
   macro **    buckets;
   size_t      nbuckets;
   size_t      count;
   bt_macros * parent;
};

static unsigned long
hash_key (const char *s)
{
   unsigned long h = 5381;              /* djb2 */
   while (*s)
      h = h * 33 + (unsigned char) *s++;
   return h;
}

bt_macros *
bt_macros_new (bt_macros *parent)
{
   bt_macros * m = bt_xcalloc (1, sizeof (bt_macros));

   m->nbuckets = 64;
   m->buckets = bt_xcalloc (m->nbuckets, sizeof (macro *));
   m->parent = parent;
   return m;
}

void
bt_delete_all_macros (bt_macros *m)
{
   size_t i;

   for (i = 0; i < m->nbuckets; i++)
   {
      macro * cur = m->buckets[i];
      while (cur)
      {
         macro * next = cur->next;
         free (cur->key);
         free (cur->text);
         free (cur);
         cur = next;
      }
      m->buckets[i] = NULL;
   }
   m->count = 0;
}

void
bt_macros_free (bt_macros *m)
{
   if (!m)
      return;
   bt_delete_all_macros (m);
   free (m->buckets);
   free (m);
}

static void
insert (bt_macros *m, char *key, unsigned long hash, const char *text)
{
   macro * rec;
   size_t  b;

   if (m->count >= m->nbuckets * 2)     /* grow */
   {
      size_t   newn = m->nbuckets * 4;
      macro ** nb = bt_xcalloc (newn, sizeof (macro *));
      size_t   i;

      for (i = 0; i < m->nbuckets; i++)
      {
         macro * cur = m->buckets[i];
         while (cur)
         {
            macro * next = cur->next;
            cur->next = nb[cur->hash % newn];
            nb[cur->hash % newn] = cur;
            cur = next;
         }
      }
      free (m->buckets);
      m->buckets = nb;
      m->nbuckets = newn;
   }

   rec = bt_xmalloc (sizeof (macro));
   rec->key = key;
   rec->text = bt_xstrdup (text);
   rec->hash = hash;
   b = hash % m->nbuckets;
   rec->next = m->buckets[b];
   m->buckets[b] = rec;
   m->count++;
}

bt_macros *
bt_macros_clone (const bt_macros *m, bt_macros *parent)
{
   bt_macros * c = bt_macros_new (parent);
   size_t      i;

   for (i = 0; i < m->nbuckets; i++)
   {
      macro * cur;
      for (cur = m->buckets[i]; cur; cur = cur->next)
         insert (c, bt_xstrdup (cur->key), cur->hash, cur->text);
   }
   return c;
}

/* Find a macro in this table only; *prevp gets the link pointing to it */
static macro *
find_local (bt_macros *m, const char *key, unsigned long hash, macro ***prevp)
{
   macro ** link = &m->buckets[hash % m->nbuckets];

   while (*link)
   {
      if ((*link)->hash == hash && strcmp ((*link)->key, key) == 0)
      {
         if (prevp) *prevp = link;
         return *link;
      }
      link = &(*link)->next;
   }
   return NULL;
}

static macro *
find (bt_macros *m, const char *name)
{
   char *        key = bt_uni_map_string (name, BT_CASE_FOLD);
   unsigned long hash = hash_key (key);
   macro *       rec = NULL;

   for (; m && !rec; m = m->parent)
      rec = find_local (m, key, hash, NULL);
   free (key);
   return rec;
}

void
bt_add_macro_text (bt_macros *m, bt_errors *errs,
                   const char *name, const char *text,
                   const char *filename, int line)
{
   char *        key = bt_uni_map_string (name, BT_CASE_FOLD);
   unsigned long hash = hash_key (key);
   macro **      link;
   macro *       rec;

   if ((rec = find_local (m, key, hash, &link)))
   {
      bt_report (errs, BTERR_CONTENT, filename, line, NULL, -1,
                 "overriding existing definition of macro \"%s\"", name);
      free (rec->text);
      rec->text = bt_xstrdup (text);
      free (key);
      return;
   }
   insert (m, key, hash, text);
}

/* Define a macro from a "name = value" AST node (from an @string entry).
 * If the value has not already been post-processed as a macro value
 * (macros expanded, substrings pasted, whitespace not collapsed) that is
 * done here before the text is stored. */
void
bt_add_macro_value (bt_macros *m, bt_errors *errs,
                    AST *assignment, btshort options)
{
   AST *  value;
   char * text;
   boolean free_text;

   if (assignment == NULL || assignment->down == NULL)
      return;
   value = assignment->down;

   if ((options & BTO_STRINGMASK) != BTO_MACRO)
   {
      text = bt_postprocess_field (m, errs, assignment, BTO_MACRO, FALSE);
      free_text = TRUE;
   }
   else
   {
      if (value->nodetype != BTAST_STRING || value->right != NULL)
      {
         bt_report (errs, BTERR_INTERNAL, NULL, -1, NULL, -1,
                    "add_macro: macro value was not correctly preprocessed");
         return;
      }
      text = value->text;
      free_text = FALSE;
   }

   bt_add_macro_text (m, errs, assignment->text, text,
                      assignment->filename, assignment->line);
   if (free_text)
      free (text);
}

void
bt_delete_macro (bt_macros *m, const char *name)
{
   char *        key = bt_uni_map_string (name, BT_CASE_FOLD);
   unsigned long hash = hash_key (key);
   macro **      link;
   macro *       rec;

   if ((rec = find_local (m, key, hash, &link)))
   {
      *link = rec->next;
      free (rec->key);
      free (rec->text);
      free (rec);
      m->count--;
   }
   free (key);
}

int
bt_macro_length (bt_macros *m, const char *name)
{
   macro * rec = find (m, name);
   return (rec && rec->text) ? (int) strlen (rec->text) : 0;
}

const char *
bt_macro_text (bt_macros *m, bt_errors *errs, const char *name,
               const char *filename, int line)
{
   macro * rec = find (m, name);

   if (!rec)
   {
      bt_report (errs, BTERR_CONTENT, filename, line, NULL, -1,
                 "undefined macro \"%s\"", name);
      return NULL;
   }
   return rec->text;
}
