/*  You may distribute under the terms of either the GNU General Public License
 *  or the Artistic License (the same terms as Perl itself)
 *
 *  (C) Paul Evans, 2023 -- leonerd@leonerd.org.uk
 */
#define PERL_NO_GET_CONTEXT

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <tree_sitter/api.h>

#include <dlfcn.h>

typedef TSLanguage    *Text__Treesitter__Language;
typedef TSNode         Text__Treesitter___Node;
typedef TSParser      *Text__Treesitter__Parser;
typedef TSQuery       *Text__Treesitter__Query;
typedef TSQueryCursor *Text__Treesitter__QueryCursor;
typedef TSQueryMatch   Text__Treesitter__QueryMatch;
typedef TSTree        *Text__Treesitter___Tree;

static SV *S_newSVnode(pTHX_ TSNode node)
{
  SV *sv = newSV(0);
  sv_setref_pvn(sv, "Text::Treesitter::_Node", (void *)&node, sizeof(node));
  return sv;
}
#define newSVnode(node)  S_newSVnode(aTHX_ node)

static SV *S_newSVquerymatch(pTHX_ TSQueryMatch *match)
{
  return sv_setref_pvn(newSV(0), "Text::Treesitter::QueryMatch", (void *)match, sizeof(*match));
}
#define newSVquerymatch(match)  S_newSVquerymatch(aTHX_ match)

static void S_extract_line_col(pTHX_ const char *s, STRLEN len, STRLEN offset, int *line, int *col, SV *linebuf)
{
  (*line) = 0;
  (*col)  = 0;

  while(len && offset) {
    (*col)++;
    if(*s == '\n') {
      (*line)++;
      (*col) = 0;
      SvCUR(linebuf) = 0;
    }
    else
      sv_catpvn(linebuf, s, 1);

    offset--;

    s++, len--;
  }
  /* capture the rest of the line */
  while(len) {
    if(*s == '\n')
      break;
    sv_catpvn(linebuf, s, 1);

    s++, len--;
  }
}
#define extract_line_col(s, len, offset, line, col, linebuf)  S_extract_line_col(aTHX_ s, len, offset, line, col, linebuf)

MODULE = Text::Treesitter  PACKAGE = Text::Treesitter::Language  PREFIX = ts_language_

Text::Treesitter::Language load(const char *path, const char *name)
  CODE:
  {
    /* Maybe perl has some wrappings of these things we can use */
    void *langmod = dlopen(path, RTLD_LAZY|RTLD_LOCAL);
    if(!langmod)
      croak("Unable to load tree-sitter language from %s - %s",
        path, dlerror());

    SV *symnamesv = newSVpvf("tree_sitter_%s", name);
    SAVEFREESV(symnamesv);

    void *(*langfunc)(void) = dlsym(langmod, SvPVbyte_nolen(symnamesv));
    if(!langfunc)
      croak("Unable to use tree-sitter language library %s - no symbol named '%s'",
        path, SvPVbyte_nolen(symnamesv));

    RETVAL = (*langfunc)();
  }
  OUTPUT:
    RETVAL

U32 ts_language_symbol_count(Text::Treesitter::Language self)

const char *ts_language_symbol_name(Text::Treesitter::Language self, U16 symbol)

int ts_language_symbol_type(Text::Treesitter::Language self, U16 symbol)

U32 ts_language_field_count(Text::Treesitter::Language self)

const char *ts_language_field_name_for_id(Text::Treesitter::Language self, U16 field)

MODULE = Text::Treesitter  PACKAGE = Text::Treesitter::_Node  PREFIX = ts_node_

const char *ts_node_type(Text::Treesitter::_Node self)

U32 ts_node_start_byte(Text::Treesitter::_Node self)

U32 ts_node_end_byte(Text::Treesitter::_Node self)

void start_point(Text::Treesitter::_Node self)
  ALIAS:
    start_point = 0
    end_point   = 1
  PPCODE:
  {
    TSPoint point = ix == 0 ? ts_node_start_point(self) : ts_node_end_point(self);
    EXTEND(SP, 2);
    mPUSHu(point.row);
    mPUSHu(point.column);
    XSRETURN(2);
  }

bool ts_node_is_null(Text::Treesitter::_Node self)

bool ts_node_is_named(Text::Treesitter::_Node self)

bool ts_node_is_missing(Text::Treesitter::_Node self)

bool ts_node_is_extra(Text::Treesitter::_Node self)

bool ts_node_has_changes(Text::Treesitter::_Node self)

bool ts_node_has_error(Text::Treesitter::_Node self)

Text::Treesitter::_Node ts_node_parent(Text::Treesitter::_Node self)

U32 ts_node_child_count(Text::Treesitter::_Node self)

void child_nodes(Text::Treesitter::_Node self)
  ALIAS:
    child_nodes = 0
    field_names_with_child_nodes = 1
  PPCODE:
  {
    U32 nodecount = ts_node_child_count(self);
    U32 retcount = nodecount * (ix + 1);

    EXTEND(SP, retcount);
    for(U32 i = 0; i < nodecount; i++) {
      if(ix) {
        const char *field_name = ts_node_field_name_for_child(self, i);
        if(field_name)
          mPUSHp(field_name, strlen(field_name));
        else
          PUSHs(&PL_sv_undef);
      }

      mPUSHs(newSVnode(ts_node_child(self, i)));;
    }
    XSRETURN(retcount);
  }

MODULE = Text::Treesitter  PACKAGE = Text::Treesitter::Parser  PREFIX = ts_parser_

Text::Treesitter::Parser new(SV *cls)
  CODE:
    RETVAL = ts_parser_new();
  OUTPUT:
    RETVAL

void DESTROY(Text::Treesitter::Parser self)
  CODE:
    ts_parser_delete(self);

bool ts_parser_set_language(Text::Treesitter::Parser self, Text::Treesitter::Language lang)

Text::Treesitter::_Tree _parse_string(Text::Treesitter::Parser self, SV *str)
  CODE:
    SvGETMAGIC(str);

    STRLEN len;
    char *pv = SvPVutf8(str, len);

    RETVAL = ts_parser_parse_string(self, NULL, pv, len);
  OUTPUT:
    RETVAL

void ts_parser_reset(Text::Treesitter::Parser self)

MODULE = Text::Treesitter  PACKAGE = Text::Treesitter::Query  PREFIX = ts_query_

Text::Treesitter::Query new(SV *cls, Text::Treesitter::Language lang, SV *src)
  CODE:
  {
    SvGETMAGIC(src);

    STRLEN srclen;
    char *srcstr = SvPVutf8(src, srclen);

    uint32_t error_offset;
    TSQueryError error_type;

    RETVAL = ts_query_new(lang, srcstr, srclen, &error_offset, &error_type);
    if(!RETVAL) {
      const char *error_names[] = {
        "none",
        "Syntax",
        "NodeType",
        "Field",
        "Capture",
        "Structure",
        "Language",
      };
      const char *error_name =
        error_type < sizeof(error_names)/sizeof(error_names[0]) ? error_names[error_type] : "<unknown>";

      int line = 0, col = 0;
      SV *linebuf = newSVpvn("", 0);
      SAVEFREESV(linebuf);

      extract_line_col(srcstr, srclen, error_offset, &line, &col, linebuf);

      SV *heremark = newSVpvn("", 0);
      SAVEFREESV(heremark);
      for(int i = 0; i < col; i++)
        sv_catpvn(heremark, " ", 1);
      sv_catpvn(heremark, "^", 1);

      croak("ts_query_new: %s error at line=%d col=%d:\n: %" SVf "\n  %" SVf "\n",
        error_name, line + 1, col + 1,
        SVfARG(linebuf),
        SVfARG(heremark));
    }
  }
  OUTPUT:
    RETVAL

void DESTROY(Text::Treesitter::Query self)
  CODE:
    ts_query_delete(self);

U32 ts_query_pattern_count(Text::Treesitter::Query self)

U32 ts_query_capture_count(Text::Treesitter::Query self)

U32 ts_query_string_count(Text::Treesitter::Query self)

SV *capture_name_for_id(Text::Treesitter::Query self, U32 id)
  CODE:
  {
    uint32_t len;
    const char *pv = ts_query_capture_name_for_id(self, id, &len);
    RETVAL = newSVpvf(pv, len, SVf_UTF8);
  }
  OUTPUT:
    RETVAL

SV *string_value_for_id(Text::Treesitter::Query self, U32 id)
  CODE:
  {
    uint32_t len;
    const char *pv = ts_query_string_value_for_id(self, id, &len);
    RETVAL = newSVpvf(pv, len, SVf_UTF8);
  }
  OUTPUT:
    RETVAL

void predicates_for_pattern(Text::Treesitter::Query self, U32 pattern_index)
  PPCODE:
  {
    U32 count;
    const TSQueryPredicateStep *predicates = ts_query_predicates_for_pattern(self, pattern_index, &count);

    /* predicates is a *flat* list of steps; each step being Capture, String
     * or Done. We need to turn this into a 2D list of arrayrefs storing each
     * predicate's strings and captures in a new arrayref
     */
    AV *predicate = NULL;
    U32 retcount = 0;

    const char *pv;
    uint32_t len;;

    for(U32 i = 0; i < count; i++) {
      const TSQueryPredicateStep *step = predicates + i;
      if(!predicate)
        predicate = newAV();

      switch(step->type) {
        case TSQueryPredicateStepTypeDone:
          mPUSHs(newRV_noinc((SV *)predicate));
          retcount++;

          predicate = NULL;
          break;

        case TSQueryPredicateStepTypeCapture:
          /* Indicate that it's a capture by pushing a SCALAR ref to IV */
          av_push(predicate, newRV_noinc(newSViv(step->value_id)));
          break;

        case TSQueryPredicateStepTypeString:
          pv = ts_query_string_value_for_id(self, step->value_id, &len);
          av_push(predicate, newSVpvf(pv, len, SVf_UTF8));
          break;
      }
    }

    XSRETURN(retcount);
  }

MODULE = Text::Treesitter  PACKAGE = Text::Treesitter::QueryCursor  PREFIX = ts_query_cursor_

Text::Treesitter::QueryCursor new(SV *cls)
  CODE:
    RETVAL = ts_query_cursor_new();
  OUTPUT:
    RETVAL

void DESTROY(Text::Treesitter::QueryCursor self)
  CODE:
    ts_query_cursor_delete(self);

void _exec(Text::Treesitter::QueryCursor self, Text::Treesitter::Query query, Text::Treesitter::_Node node)
  CODE:
    ts_query_cursor_exec(self, query, node);

SV *next_match(Text::Treesitter::QueryCursor self)
  CODE:
  {
    TSQueryMatch match;
    if(ts_query_cursor_next_match(self, &match))
      RETVAL = newSVquerymatch(&match);
    else
      RETVAL = &PL_sv_undef;
  }
  OUTPUT:
    RETVAL

MODULE = Text::Treesitter  PACKAGE = Text::Treesitter::QueryMatch

U32 id(Text::Treesitter::QueryMatch self)
  CODE:
    RETVAL = self.id;
  OUTPUT:
    RETVAL

U32 pattern_index(Text::Treesitter::QueryMatch self)
  CODE:
    RETVAL = self.pattern_index;
  OUTPUT:
    RETVAL

U32 capture_count(Text::Treesitter::QueryMatch self)
  CODE:
    RETVAL = self.capture_count;
  OUTPUT:
    RETVAL

Text::Treesitter::_Node node_for_capture(Text::Treesitter::QueryMatch self, U32 capture_index)
  CODE:
    if(capture_index >= self.capture_count)
      croak("index_for_capture: capture index out of bounds");
    RETVAL = self.captures[capture_index].node;
  OUTPUT:
    RETVAL

U32 index_for_capture(Text::Treesitter::QueryMatch self, U32 capture_index)
  CODE:
    if(capture_index >= self.capture_count)
      croak("index_for_capture: capture index out of bounds");
    RETVAL = self.captures[capture_index].index;
  OUTPUT:
    RETVAL

MODULE = Text::Treesitter  PACKAGE = Text::Treesitter::_Tree  PREFIX = ts_tree_

void DESTROY(Text::Treesitter::_Tree self)
  CODE:
    ts_tree_delete(self);

void print_dot_graph_stdout(Text::Treesitter::_Tree self)
  ALIAS:
    print_dot_graph_stdout = 1
    print_dot_graph_stderr = 2
  CODE:
    ts_tree_print_dot_graph(self, ix == 1 ? stdout : stderr);

Text::Treesitter::_Node _root_node(Text::Treesitter::_Tree self)
  CODE:
    RETVAL = ts_tree_root_node(self);
  OUTPUT:
    RETVAL

MODULE = Text::Treesitter  PACKAGE = Text::Treesitter

BOOT:
  HV *stash;
#define DO_CONSTANT(c) newCONSTSUB(stash, #c, newSViv(c))

  stash = Perl_gv_stashpvn(aTHX_ STR_WITH_LEN("Text::Treesitter::Language::_Symbol"), TRUE);

  DO_CONSTANT(TSSymbolTypeRegular);
  DO_CONSTANT(TSSymbolTypeAnonymous);
  DO_CONSTANT(TSSymbolTypeAuxiliary);
