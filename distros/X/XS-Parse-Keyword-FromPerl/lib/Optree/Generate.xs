/*  You may distribute under the terms of either the GNU General Public License
 *  or the Artistic License (the same terms as Perl itself)
 *
 *  (C) Paul Evans, 2023 -- leonerd@leonerd.org.uk
 */
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "perl-backcompat.c.inc"
#include "perl-additions.c.inc"

#include "newSVop.c.inc"

#define ENTER_and_setup_pad(name)  S_ENTER_and_setup_pad(aTHX_ name)
static void S_ENTER_and_setup_pad(pTHX_ const char *name)
{
  if(!PL_compcv)
    croak("Cannot call %s while not compiling a subroutine", name);

  ENTER;

  PAD_SET_CUR(CvPADLIST(PL_compcv), 1);

  SAVESPTR(PL_comppad_name);
  PL_comppad_name = PadlistNAMES(CvPADLIST(PL_compcv));
}

static void S_setup_constants(pTHX)
{
  HV *stash;
  AV *export;

#define DO_CONSTANT(c) \
  newCONSTSUB(stash, #c, newSViv(c)); \
  av_push(export, newSVpv(#c, 0))

  stash = gv_stashpvs("Optree::Generate", TRUE);
  export = get_av("Optree::Generate::EXPORT_OK", TRUE);

  DO_CONSTANT(G_SCALAR);
  DO_CONSTANT(G_LIST);
  DO_CONSTANT(G_VOID);

  DO_CONSTANT(OPf_WANT);
  DO_CONSTANT(OPf_WANT_VOID);
  DO_CONSTANT(OPf_WANT_SCALAR);
  DO_CONSTANT(OPf_WANT_LIST);
  DO_CONSTANT(OPf_KIDS);
  DO_CONSTANT(OPf_PARENS);
  DO_CONSTANT(OPf_REF);
  DO_CONSTANT(OPf_MOD);
  DO_CONSTANT(OPf_STACKED);
  DO_CONSTANT(OPf_SPECIAL);
}

MODULE = Optree::Generate    PACKAGE = Optree::Generate

I32 opcode(const char *opname)
  CODE:
    for(RETVAL = 0; RETVAL < OP_max; RETVAL++)
      if(strEQ(opname, PL_op_name[RETVAL]))
        goto found;
    croak("Unrecognised opcode(\"%s\")", opname);
found:
    ;
  OUTPUT:
    RETVAL

SV *
op_contextualize(SV *o, I32 context)
  CODE:
    ENTER_and_setup_pad("op_contextualize");
    RETVAL = newSVop(op_contextualize(SvOPo(o), context));
    LEAVE;
  OUTPUT:
    RETVAL

SV *
op_scope(SV *o)
  CODE:
    ENTER_and_setup_pad("op_scope");
    RETVAL = newSVop(op_scope(SvOPo(o)));
    LEAVE;
  OUTPUT:
    RETVAL

SV *
newOP(I32 type, I32 flags)
  CODE:
    ENTER_and_setup_pad("newOP");
    RETVAL = newSVop(newOP(type, flags));
    LEAVE;
  OUTPUT:
    RETVAL

SV *
newASSIGNOP(I32 flags, SV *left, I32 optype, SV *right)
  CODE:
    ENTER_and_setup_pad("newASSIGNOP");
    RETVAL = newSVop(newASSIGNOP(flags, SvOPo(left), optype, SvOPo(right)));
    LEAVE;
  OUTPUT:
    RETVAL

SV *
newBINOP(I32 type, I32 flags, SV *first, SV *last)
  CODE:
    ENTER_and_setup_pad("newBINOP");
    RETVAL = newSVop(newBINOP(type, flags, SvOPo(first), SvOPo(last)));
    LEAVE;
  OUTPUT:
    RETVAL

SV *
newCONDOP(I32 flags, SV *first, SV *trueop, SV *falseop)
  CODE:
    ENTER_and_setup_pad("newCONDOP");
    RETVAL = newSVop(newCONDOP(flags, SvOPo(first), SvOPo(trueop), SvOPo(falseop)));
    LEAVE;
  OUTPUT:
    RETVAL

SV *
newFOROP(I32 flags, SV *sv, SV *expr, SV *block, SV *cont)
  CODE:
    ENTER_and_setup_pad("newFOROP");
    RETVAL = newSVop(newFOROP(flags, maySvOPo(sv), SvOPo(expr), SvOPo(block), maySvOPo(cont)));
    LEAVE;
  OUTPUT:
    RETVAL

SV *
newGVOP(I32 type, I32 flags, SV *gv)
  CODE:
    if(!SvROK(gv) || SvTYPE(SvRV(gv)) != SVt_PVGV)
      croak("Expected a GLOB ref to newGVOP");
    ENTER_and_setup_pad("newGVOP");
    RETVAL = newSVop(newGVOP(type, flags, (GV *)SvRV(gv)));
    LEAVE;
  OUTPUT:
    RETVAL

SV *
newLISTOP(I32 type, I32 flags, ...)
  CODE:
    ENTER_and_setup_pad("newLISTOP");
    /* Can't use newLISTOPn() here because of a variable number of kid ops */
    OP *o = newLISTOP(OP_LIST, 0, NULL, NULL);
    for(U32 i = 2; i < items; i++)
      o = op_append_elem(OP_LIST, o, SvOPo(ST(i)));
    if(type != OP_LIST)
      o = op_convert_list(type, flags, o);
    RETVAL = newSVop(o);
    LEAVE;
  OUTPUT:
    RETVAL

SV *
newLOGOP(I32 type, I32 flags, SV *first, SV *other)
  CODE:
    ENTER_and_setup_pad("newLOGOP");
    RETVAL = newSVop(newLOGOP(type, flags, SvOPo(first), SvOPo(other)));
    LEAVE;
  OUTPUT:
    RETVAL

SV *
newPADxVOP(I32 type, I32 flags, U32 padoffset)
  CODE:
    ENTER_and_setup_pad("newPADxVOP");
    RETVAL = newSVop(newPADxVOP(type, flags, padoffset));
    LEAVE;
  OUTPUT:
    RETVAL

SV *
newSVOP(I32 type, I32 flags, SV *sv)
  CODE:
    ENTER_and_setup_pad("newSVOP");
    RETVAL = newSVop(newSVOP(type, flags, newSVsv(sv)));
    LEAVE;
  OUTPUT:
    RETVAL

SV *
newUNOP(I32 type, I32 flags, SV *first)
  CODE:
    ENTER_and_setup_pad("newUNOP");
    RETVAL = newSVop(newUNOP(type, flags, SvOPo(first)));
    LEAVE;
  OUTPUT:
    RETVAL

BOOT:
  S_setup_constants(aTHX);
