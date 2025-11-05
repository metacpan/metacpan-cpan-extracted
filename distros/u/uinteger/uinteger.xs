#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"
#include "uinteger_ppp.h"

static XOP xop_add;
static XOP xop_subtract;
static XOP xop_multiply;
static XOP xop_negate;

typedef OP *(*checker_type)(pTHX_ OP *o);
static checker_type next_add_checker;
static checker_type next_subtract_checker;
static checker_type next_multiply_checker;
static checker_type next_negate_checker;

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
    UV left    = USE_LEFT(leftsv) ? SvUV_nomg(leftsv) : 0;
    UV right   = SvUV_nomg(PL_stack_sp[0]);

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
    UV left    = USE_LEFT(leftsv) ? SvUV_nomg(leftsv) : 0;
    UV right   = SvUV_nomg(PL_stack_sp[0]);

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
    UV left    = USE_LEFT(leftsv) ? SvUV_nomg(leftsv) : 0;
    UV right   = SvUV_nomg(PL_stack_sp[0]);

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

inline void
xop_init(XOP *xop, const char *name, const char *desc, U32 cls) {
  XopENTRY_set(xop, xop_name, name);
  XopENTRY_set(xop, xop_desc, desc);
  XopENTRY_set(xop, xop_class, cls);  
}

static void
init_ops(pTHX) {
  xop_init(&xop_add, "u_add", "add unsigned integers", OA_BINOP);
  Perl_custom_op_register(aTHX_ pp_u_add, &xop_add);

  xop_init(&xop_subtract, "u_subtract", "subtract unsigned integers", OA_BINOP);
  Perl_custom_op_register(aTHX_ pp_u_subtract, &xop_subtract);

  xop_init(&xop_subtract, "u_multiply", "multiply unsigned integers", OA_BINOP);
  Perl_custom_op_register(aTHX_ pp_u_multiply, &xop_multiply);

  xop_init(&xop_negate, "u_negate", "negate unsigned integers", OA_UNOP);
  Perl_custom_op_register(aTHX_ pp_u_negate, &xop_negate);
  
  wrap_op_checker(OP_ADD, add_checker, &next_add_checker);
  wrap_op_checker(OP_SUBTRACT, subtract_checker, &next_subtract_checker);
  wrap_op_checker(OP_MULTIPLY, multiply_checker, &next_multiply_checker);
  wrap_op_checker(OP_NEGATE, negate_checker, &next_negate_checker);
}

MODULE = uinteger PACKAGE = uinteger

BOOT:
  init_ops(aTHX);
