#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"
#include "uinteger_ppp.h"

enum uint_xop_index {
  xi_u_add,
  xi_u_subtract,
  xi_u_multiply,
  xi_u_negate,
  xi_op_count
};

#ifdef op_sibling_splice
#  define DO_TARGMY
#endif

static XOP xops[xi_op_count];

static void (*next_rpeepp)(pTHX_ OP *o);

typedef OP *(*checker_type)(pTHX_ OP *o);
typedef OP *(*ppfunc_type)(pTHX);

static checker_type next_add_checker;
static checker_type next_subtract_checker;
static checker_type next_multiply_checker;
static checker_type next_negate_checker;

static checker_type next_sassign_checker;

static bool
in_uinteger(pTHX) {
  SV **entry = hv_fetchs(GvHV(PL_hintgv), "uinteger", 0);
  return entry && SvTRUE(*entry);
}

static OP *
integer_checker(pTHX_ OP *op, checker_type next, OP* (*ppfunc)(pTHX)) {
  if (in_uinteger(aTHX)) {
    op->op_type = OP_CUSTOM;
    op->op_ppaddr = ppfunc;
    // newBINOP skips this if we change the opcode
    if (!op->op_targ)
      op->op_targ = pad_alloc(op->op_type, SVs_PADTMP);
    op = op_contextualize(op, G_SCALAR);
  }
  else {
    op = next(aTHX_ op);
  }
  return op;
}

static OP *
pp_u_add(pTHX) {
    SV *targ = (PL_op->op_flags & OPf_STACKED)
                    ? PL_stack_sp[-1]
                    : PAD_SV(PL_op->op_targ);

    if (rpp_try_AMAGIC_2(add_amg, AMGf_assign))
        return NORMAL;

    SV *leftsv = PL_stack_sp[-1];
    UV left    = USE_LEFT(leftsv) ? (UV)SvIV_nomg(leftsv) : 0;
    UV right   = (UV)SvIV_nomg(PL_stack_sp[0]);

    TARGu(left + right, 1);
    rpp_replace_2_1_NN(targ);
    return NORMAL;
  
}

static OP *
pp_u_subtract(pTHX) {
    SV *targ = (PL_op->op_flags & OPf_STACKED)
                    ? PL_stack_sp[-1]
                    : PAD_SV(PL_op->op_targ);

    if (rpp_try_AMAGIC_2(subtr_amg, AMGf_assign))
        return NORMAL;

    SV *leftsv = PL_stack_sp[-1];
    UV left    = USE_LEFT(leftsv) ? (UV)SvIV_nomg(leftsv) : 0;
    UV right   = (UV)SvIV_nomg(PL_stack_sp[0]);

    TARGu(left - right, 1);
    rpp_replace_2_1_NN(targ);
    return NORMAL;
  
}

static OP *
pp_u_multiply(pTHX) {
    SV *targ = (PL_op->op_flags & OPf_STACKED)
                    ? PL_stack_sp[-1]
                    : PAD_SV(PL_op->op_targ);

    if (rpp_try_AMAGIC_2(mult_amg, AMGf_assign))
        return NORMAL;

    SV *leftsv = PL_stack_sp[-1];
    UV left    = USE_LEFT(leftsv) ? (UV)SvIV_nomg(leftsv) : 0;
    UV right   = (UV)SvIV_nomg(PL_stack_sp[0]);

    TARGu(left * right, 1);
    rpp_replace_2_1_NN(targ);
    return NORMAL;  
}

static OP *
pp_u_negate(pTHX) {
    dTARGET;
    if (rpp_try_AMAGIC_1(neg_amg, 0))
        return NORMAL;

    SV * const sv = *PL_stack_sp;

    UV const i = SvIV_nomg(sv);
    TARGu(-(UV)i, 1);
    if (LIKELY(targ != sv))
        rpp_replace_1_1_NN(TARG);
    return NORMAL;
}

static ppfunc_type ppfuncs[] =
  {
    pp_u_add,
    pp_u_subtract,
    pp_u_multiply,
    pp_u_negate
  };

static OP *
add_checker(pTHX_ OP *op) {
  return integer_checker(aTHX_ op, next_add_checker, pp_u_add);
}

static OP *
subtract_checker(pTHX_ OP *op) {
  return integer_checker(aTHX_ op, next_subtract_checker, pp_u_subtract);
}

static OP *
multiply_checker(pTHX_ OP *op) {
  return integer_checker(aTHX_ op, next_multiply_checker, pp_u_multiply);
}

static OP *
negate_checker(pTHX_ OP *op) {
  return integer_checker(aTHX_ op, next_negate_checker, pp_u_negate);
}

#ifdef XOPf_xop_dump
static void
my_xop_dump(pTHX_ const OP *o, struct Perl_OpDumpContext *ctx) {
  Perl_opdump_printf(aTHX_ ctx, "XOPPRIVATE = (%s0x%x)",
                     (o->op_private & OPpTARGET_MY) ? "TARGMY," : "",
                     (o->op_private & OPpARG4_MASK));
}
#endif

static inline void
xop_register(pTHX_ enum uint_xop_index xop_index, const char *name,
             const char *desc, U32 cls, ppfunc_type ppfunc) {
  XOP *const xop = xops + xop_index;
  XopENTRY_set(xop, xop_name, name);
  XopENTRY_set(xop, xop_desc, desc);
  XopENTRY_set(xop, xop_class, cls);  
#ifdef XOPf_xop_dump
  XopENTRY_set(xop, xop_dump, my_xop_dump);
#endif

  Perl_custom_op_register(aTHX_ ppfunc, xop);
}

#ifdef DO_TARGMY

static enum uint_xop_index
find_xop_index(ppfunc_type pp) {
  int i;
  for (i = 0; i < xi_op_count; ++i) {
    if (ppfuncs[i] == pp)
      break;
  }
  return (enum uint_xop_index)i;
}

/* do the targlex optimization for our ops */
static OP *
sassign_checker(pTHX_ OP *o) {
  o = next_sassign_checker(aTHX_ o);

  /* adapted from S_maybe_targlex() */
  OP *const kid = cLISTOPo->op_first;
  enum uint_xop_index i;
  if (kid->op_type == OP_CUSTOM
      && !(kid->op_flags & OPf_STACKED)
      && !(kid->op_private & OPpTARGET_MY)
      && (i = find_xop_index(kid->op_ppaddr)) != xi_op_count) {
    OP * const kkid = OpSIBLING(kid);
    if (kkid && kkid->op_type == OP_PADSV) {
      if (!(kkid->op_private & OPpLVAL_INTRO)
          || (kkid->op_private & OPpPAD_STATE)) {
        kid->op_private |= OPpTARGET_MY;
        kid->op_flags =
          (kid->op_flags & ~OPf_WANT)
          | (o->op_flags   &  OPf_WANT);
        kid->op_targ = kkid->op_targ;
        kkid->op_targ = 0;
        op_sibling_splice(o, NULL, 1, NULL);
        op_free(o);
        return kid;
      }
    }
  }

  return o;
}

#endif

static void
init_ops(pTHX) {
  xop_register(aTHX_ xi_u_add, "u_add", "add unsigned integers", OA_BINOP,
               pp_u_add);

  xop_register(aTHX_ xi_u_subtract, "u_subtract", "subtract unsigned integers",
               OA_BINOP, pp_u_subtract);

  xop_register(aTHX_ xi_u_multiply, "u_multiply", "multiply unsigned integers",
               OA_BINOP, pp_u_multiply);

  xop_register(aTHX_ xi_u_negate, "u_negate", "negate unsigned integers",
               OA_UNOP, pp_u_negate);
  
  wrap_op_checker(OP_ADD, add_checker, &next_add_checker);
  wrap_op_checker(OP_SUBTRACT, subtract_checker, &next_subtract_checker);
  wrap_op_checker(OP_MULTIPLY, multiply_checker, &next_multiply_checker);
  wrap_op_checker(OP_NEGATE, negate_checker, &next_negate_checker);

#ifdef DO_TARGMY
  wrap_op_checker(OP_SASSIGN, sassign_checker, &next_sassign_checker);
#endif
}

MODULE = uinteger PACKAGE = uinteger

BOOT:
  init_ops(aTHX);
