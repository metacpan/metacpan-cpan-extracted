#ifndef BIBTEX_AST_H
#define BIBTEX_AST_H

typedef enum 
{ 
   AST_BOGUS,                           /* to detect uninitialized nodes */
   AST_ECOMMENT, AST_EPREAMBLE, AST_EMACRODEF, AST_EALIAS, AST_EMODIFY,
   AST_ENTRY, AST_KEY, AST_FIELD, AST_STRING, AST_NUMBER, AST_MACRO
} nodetype_t;

#define AST_FIELDS int line, offset; nodetype_t nodetype; char *text;
#define zzcr_ast(ast,attr,tok,txt)              \
{                                               \
   (ast)->line = (attr)->line;                  \
   (ast)->offset = (attr)->offset;              \
   (ast)->text = strdup ((attr)->text);         \
}
#define zzd_ast(ast)                                                    \
   if ((ast)->text != NULL) free ((ast)->text);

#endif /* BIBTEX_AST_H */
