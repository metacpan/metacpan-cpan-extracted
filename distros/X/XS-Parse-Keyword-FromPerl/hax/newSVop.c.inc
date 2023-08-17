/* vi: set ft=c : */

/* Wrappers between OP * and B::OP-blessed SVs */

#define newSVop(o)  S_newSVop(aTHX_ o)
static SV *S_newSVop(pTHX_ OP *o)
{
  SV *ret = newSV(0);

  const char *opclassname;
  switch(op_class(o)) {
    case OPclass_BASEOP:   opclassname = "B::OP";       break;
    case OPclass_UNOP:     opclassname = "B::UNOP";     break;
    case OPclass_BINOP:    opclassname = "B::BINOP";    break;
    case OPclass_LOGOP:    opclassname = "B::LOGOP";    break;
    case OPclass_LISTOP:   opclassname = "B::LISTOP";   break;
    case OPclass_PMOP:     opclassname = "B::PMOP";     break;
    case OPclass_SVOP:     opclassname = "B::SVOP";     break;
    case OPclass_PADOP:    opclassname = "B::PADOP";    break;
    case OPclass_PVOP:     opclassname = "B::PVOP";     break;
    case OPclass_LOOP:     opclassname = "B::LOOP";     break;
    case OPclass_COP:      opclassname = "B::COP";      break;
    case OPclass_METHOP:   opclassname = "B::METHOP";   break;
    case OPclass_UNOP_AUX: opclassname = "B::UNOP_AUX"; break;
    default:
      croak("TODO: handle opclass=%d\n", op_class(o));
  }

  sv_setiv(newSVrv(ret, opclassname), PTR2IV(o));
  return ret;
}

#define SvOPo(sv)  S_SvOPo(aTHX_ sv)
static OP *S_SvOPo(pTHX_ SV *sv)
{
  if(!SvOK(sv))
    croak("Expected a B::OP instance, found <undef>");
  if(!SvROK(sv) || !sv_derived_from(sv, "B::OP"))
    croak("Expected a B::OP instance, found %" SVf, SVfARG(sv));

  return NUM2PTR(OP *, SvIV(SvRV(sv)));
}

#define maySvOPo(sv)  (sv && SvOK(sv) ? SvOPo(sv) : NULL)
