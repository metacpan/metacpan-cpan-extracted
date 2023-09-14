/* vi: set ft=c : */

static int magic_free(pTHX_ SV *sv, MAGIC *mg)
{
  void (*freefunc)(pTHX_ SV *sv) = (void *)mg->mg_ptr;
  (*freefunc)(aTHX_ sv);
}

static const MGVTBL vtbl_sv_with_free = {
  .svt_free = magic_free,
};

#define newSV_with_free(size, freefunc)  S_newSV_with_free(aTHX_ size, freefunc)
static SV *S_newSV_with_free(pTHX_ STRLEN size, void (*freefunc)(pTHX_ SV *sv))
{
  SV *sv = newSV(size);
  sv_magicext(sv, NULL, PERL_MAGIC_ext, &vtbl_sv_with_free, (void *)freefunc, 0);
  return sv;
}
