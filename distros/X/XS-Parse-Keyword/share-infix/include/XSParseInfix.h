#ifndef __XS_PARSE_INFIX_H__
#define __XS_PARSE_INFIX_H__

#define XSPARSEINFIX_ABI_VERSION 2

/* Infix operator classifications */
/* No built-in operators use the _MISC categories, but they are provided for
 * custom infix operators to use so they are still found by selections */
enum XSParseInfixClassification {
  XPI_CLS_NONE = 0,
  XPI_CLS_PREDICATE,   /* any boolean-returning operator */
  XPI_CLS_RELATION,    /*  ... any predicate that is typewise symmetric */
  XPI_CLS_EQUALITY,    /*      ... any relation that is true for (x == x) and false otherwise */
  XPI_CLS_SMARTMATCH,  /*  ... the predicate smartmatch (~~) */
  XPI_CLS_MATCHRE,     /*  ... the predicate regexp match (=~) */
  XPI_CLS_ISA,         /*  ... the predicate instance of (isa) */
  XPI_CLS_MATCH_MISC,  /*  ... any other match-like predicate */
  XPI_CLS_ORDERING,    /* cmp or <=> */

  /* Since the _MISC categories never turn up in selections, put them at high
   * index so as to leave space for more */
  XPI_CLS_LOW_MISC = 0x80,  /* an operator at low precedence */
  XPI_CLS_LOGICAL_OR_LOW_MISC,
  XPI_CLS_LOGICAL_AND_LOW_MISC,
  XPI_CLS_ASSIGN_MISC,
  XPI_CLS_LOGICAL_OR_MISC,
  XPI_CLS_LOGICAL_AND_MISC,
  XPI_CLS_ADD_MISC,         /* an operator at addition-like precedence */
  XPI_CLS_MUL_MISC,         /* an operator at multiplication-like precedence */
  XPI_CLS_POW_MISC,         /* an operator at power exponentiation-like precedence */
  XPI_CLS_HIGH_MISC,        /* an operator at high precedence */
};

enum XSParseInfixSelection {
  XPI_SELECT_ANY,
  XPI_SELECT_PREDICATE, /* any predicate */
  XPI_SELECT_RELATION,  /* any relation */
  XPI_SELECT_EQUALITY,  /* any equality */
  XPI_SELECT_ORDERING,  /* any ordering */

  XPI_SELECT_MATCH_NOSMART, /* any equality or other match operator, including smartmatch */
  XPI_SELECT_MATCH_SMART,   /* any equality or other match operator, not including smartmatch */
};

/* flags */
enum {
  XPI_FLAG_LISTASSOC = (1<<0),
};

/* lhs_flags, rhs_flags */
enum {
  XPI_OPERAND_TERM_LIST = 6, /* term in list context */
  XPI_OPERAND_LIST      = 7, /* list in list context */

  /* Other bitflags */
  XPI_OPERAND_ONLY_LOOK = (1<<3),
};

struct XSParseInfixHooks {
  U16 flags;
  U8 lhs_flags, rhs_flags;
  enum XSParseInfixClassification cls;

  const char *wrapper_func_name;

  /* These two hooks are ANDed together; both must pass, if present */
  const char *permit_hintkey;
  bool (*permit) (pTHX_ void *hookdata);

  /* These hooks are alternatives; the first one defined is used */
  OP *(*new_op)(pTHX_ U32 flags, OP *lhs, OP *rhs, SV **parsedata, void *hookdata);
  OP *(*ppaddr)(pTHX); /* A pp func used directly in newBINOP_custom() */

  /* optional */
  void (*parse)(pTHX_ U32 flags, SV **parsedata, void *hookdata);
};

struct XSParseInfixInfo {
  const char *opname;
  OPCODE opcode;

  const struct XSParseInfixHooks *hooks;
  void *hookdata;

  enum XSParseInfixClassification cls;
};

static bool (*parse_infix_func)(pTHX_ enum XSParseInfixSelection select, struct XSParseInfixInfo **infop);
#define parse_infix(select, infop) S_parse_infix(aTHX_ select, infop)
static bool S_parse_infix(pTHX_ enum XSParseInfixSelection select, struct XSParseInfixInfo **infop)
{
  if(!parse_infix_func)
    croak("Must call boot_xs_parse_infix() first");

  struct XSParseInfixInfo *infocopy;

  return (*parse_infix_func)(aTHX_ select, infop);
}

static OP *(*xs_parse_infix_new_op_func)(pTHX_ const struct XSParseInfixInfo *info, U32 flags, OP *lhs, OP *rhs);
#define xs_parse_infix_new_op(info, flags, lhs, rhs)  S_xs_parse_infix_new_op(aTHX_ info, flags, lhs, rhs)
static OP *S_xs_parse_infix_new_op(pTHX_ const struct XSParseInfixInfo *info, U32 flags, OP *lhs, OP *rhs)
{
  if(!xs_parse_infix_new_op_func)
    croak("Must call boot_xs_parse_infix() first");

  return (*xs_parse_infix_new_op_func)(aTHX_ info, flags, lhs, rhs);
}

static void (*register_xs_parse_infix_func)(pTHX_ const char *kw, const struct XSParseInfixHooks *hooks, void *hookdata);
#define register_xs_parse_infix(opname, hooks, hookdata)  S_register_xs_parse_infix(aTHX_ opname, hooks, hookdata)
static void S_register_xs_parse_infix(pTHX_ const char *opname, const struct XSParseInfixHooks *hooks, void *hookdata)
{
  if(!register_xs_parse_infix_func)
    croak("Must call boot_xs_parse_infix() first");

  return (*register_xs_parse_infix_func)(aTHX_ opname, hooks, hookdata);
}

#define boot_xs_parse_infix(ver) S_boot_xs_parse_infix(aTHX_ ver)
static void S_boot_xs_parse_infix(pTHX_ double ver) {
  SV **svp;
  SV *versv = ver ? newSVnv(ver) : NULL;

  load_module(PERL_LOADMOD_NOIMPORT, newSVpvs("XS::Parse::Infix"), versv, NULL);

  svp = hv_fetchs(PL_modglobal, "XS::Parse::Infix/ABIVERSION_MIN", 0);
  if(!svp)
    croak("XS::Parse::Infix ABI minimum version missing");
  int abi_ver = SvIV(*svp);
  if(abi_ver > XSPARSEINFIX_ABI_VERSION)
    croak("XS::Parse::Infix ABI version mismatch - library supports >= %d, compiled for %d",
        abi_ver, XSPARSEINFIX_ABI_VERSION);

  svp = hv_fetchs(PL_modglobal, "XS::Parse::Infix/ABIVERSION_MAX", 0);
  abi_ver = SvIV(*svp);
  if(abi_ver < XSPARSEINFIX_ABI_VERSION)
    croak("XS::Parse::Infix ABI version mismatch - library supports <= %d, compiled for %d",
        abi_ver, XSPARSEINFIX_ABI_VERSION);

  parse_infix_func = INT2PTR(bool (*)(pTHX_ enum XSParseInfixSelection, struct XSParseInfixInfo **),
      SvUV(*hv_fetchs(PL_modglobal, "XS::Parse::Infix/parse()@2", 0)));
  xs_parse_infix_new_op_func = INT2PTR(OP *(*)(pTHX_ const struct XSParseInfixInfo *, U32, OP *, OP *),
      SvUV(*hv_fetchs(PL_modglobal, "XS::Parse::Infix/new_op()@0", 0)));
  register_xs_parse_infix_func = INT2PTR(void (*)(pTHX_ const char *, const struct XSParseInfixHooks *, void *),
      SvUV(*hv_fetchs(PL_modglobal, "XS::Parse::Infix/register()@2", 0)));
}

#endif
