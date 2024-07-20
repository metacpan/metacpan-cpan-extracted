/* vi: set ft=c : */

/* Perls before 5.18 lack isIDCONT_uni, but baring minor differences of weird
 * Unicode characters, isALNUM_uni is close enough
 */
#ifndef isIDCONT_uni
#define isIDCONT_uni(c)       isALNUM_uni(c)
#endif

#define sv_cat_c(sv, c)  MY_sv_cat_c(aTHX_ sv, c)
static void MY_sv_cat_c(pTHX_ SV *sv, U32 c)
{
  char ds[UTF8_MAXBYTES + 1], *d;
  d = (char *)uvchr_to_utf8((U8 *)ds, c);
  if (d - ds > 1) {
    sv_utf8_upgrade(sv);
  }
  sv_catpvn(sv, ds, d - ds);
}

#define lex_consume(s)  MY_lex_consume(aTHX_ s)
static int MY_lex_consume(pTHX_ char *s)
{
  /* I want strprefix() */
  size_t i;
  for(i = 0; s[i]; i++) {
    if(s[i] != PL_parser->bufptr[i])
      return 0;
  }

  lex_read_to(PL_parser->bufptr + i);
  return i;
}

enum {
  LEX_IDENT_PACKAGENAME = (1<<0),
};

#define lex_scan_ident(      )  MY_lex_scan_ident(aTHX_ 0)
#define lex_scan_packagename()  MY_lex_scan_ident(aTHX_ LEX_IDENT_PACKAGENAME)
static SV *MY_lex_scan_ident(pTHX_ int flags)
{
  I32 c;
  bool at_start = TRUE;

  char *ident = PL_parser->bufptr;

  /* Don't get confused by things that look like attrs */
  if((flags & LEX_IDENT_PACKAGENAME) && (ident[0] == ':' && ident[1] != ':'))
    return FALSE;

  while((c = lex_peek_unichar(0))) {
    if(at_start ? isIDFIRST_uni(c) : isALNUM_uni(c))
      at_start = FALSE;
    /* TODO: This sucks in the case of a false Foo:Bar match */
    else if((flags & LEX_IDENT_PACKAGENAME) && (c == ':')) {
      lex_read_unichar(0);
      if(lex_read_unichar(0) != ':')
        croak("Expected colon to be followed by another in package name");
    }
    else
      break;

    lex_read_unichar(0);
  }

  STRLEN len = PL_parser->bufptr - ident;
  if(!len)
    return NULL;

  SV *ret = newSVpvn(ident, len);
  if(lex_bufutf8())
    SvUTF8_on(ret);

  return ret;
}

#define lex_scan_attrval_into(name, val)  MY_lex_scan_attrval_into(aTHX_ name, val)
static bool MY_lex_scan_attrval_into(pTHX_ SV *name, SV *val)
{
  /* TODO: really want  lex_scan_ident_into() */
  SV *n = lex_scan_ident();
  if(!n)
    return FALSE;

  sv_setsv(name, n);
  SvREFCNT_dec(n);

  if(name != val)
    SvPOK_off(val);

  /* Do not read space here as space is not allowed between NAME(ARGS) */

  if(lex_peek_unichar(0) != '(')
    return TRUE;

  lex_read_unichar(0);
  if(name == val)
    sv_cat_c(val, '(');
  else
    sv_setpvs(val, "");

  int count = 1;
  I32 c = lex_peek_unichar(0);
  while(count && c != -1) {
    if(c == '(')
      count++;
    if(c == ')')
      count--;
    if(c == '\\') {
      /* The next char does not bump count even if it is ( or );
       * the \\ is still captured
       */
      sv_cat_c(val, lex_read_unichar(0));
      c = lex_peek_unichar(0);
      if(c == -1)
        goto unterminated;
    }

    /* Don't append final closing ')' on split name/val */
    if(count || (name == val))
      sv_cat_c(val, c);
    lex_read_unichar(0);

    c = lex_peek_unichar(0);
  }

  if(c == -1)
    return FALSE;

  return TRUE;

unterminated:
  croak("Unterminated attribute parameter in attribute list");
}

#define lex_scan_attr()  MY_lex_scan_attr(aTHX)
static SV *MY_lex_scan_attr(pTHX)
{
  SV *ret = newSV(0);
  if(MY_lex_scan_attrval_into(aTHX_ ret, ret))
    return ret;

  SvREFCNT_dec(ret);
  return NULL;
}

#define lex_scan_attrs(compcv)  MY_lex_scan_attrs(aTHX_ compcv)
static OP *MY_lex_scan_attrs(pTHX_ CV *compcv)
{
  /* Attributes are supplied to newATTRSUB() as an OP_LIST containing
   * OP_CONSTs, one attribute in each as a plain SV. Note that we don't have
   * to parse inside the contents of the parens; that is handled by the
   * attribute handlers themselves
   */
  OP *attrs = NULL;
  SV *attr;

  lex_read_space(0);
  while((attr = lex_scan_attr())) {
    lex_read_space(0);

    if(compcv && strEQ(SvPV_nolen(attr), "lvalue")) {
      CvLVALUE_on(compcv);
    }

    if(!attrs)
      attrs = newLISTOP(OP_LIST, 0, NULL, NULL);

    attrs = op_append_elem(OP_LIST, attrs, newSVOP(OP_CONST, 0, attr));

    /* Accept additional colons to prefix additional attrs */
    if(lex_peek_unichar(0) == ':') {
      lex_read_unichar(0);
      lex_read_space(0);
    }
  }

  return attrs;
}

#define lex_scan_lexvar()  MY_lex_scan_lexvar(aTHX)
static SV *MY_lex_scan_lexvar(pTHX)
{
  int sigil = lex_peek_unichar(0);
  switch(sigil) {
    case '$':
    case '@':
    case '%':
      lex_read_unichar(0);
      break;

    default:
      croak("Expected a lexical variable");
  }

  SV *ret = lex_scan_ident();
  if(!ret)
    return NULL;

  /* prepend sigil - which we know to be a single byte */
  SvGROW(ret, SvCUR(ret) + 1);
  Move(SvPVX(ret), SvPVX(ret) + 1, SvCUR(ret), char);
  SvPVX(ret)[0] = sigil;
  SvCUR(ret)++;

  SvPVX(ret)[SvCUR(ret)] = 0;

  return ret;
}

#define lex_scan_parenthesized()  MY_lex_scan_parenthesized(aTHX)
static SV *MY_lex_scan_parenthesized(pTHX)
{
  I32 c;
  int parencount = 0;
  SV *ret = newSVpvs("");
  if(lex_bufutf8())
    SvUTF8_on(ret);

  c = lex_peek_unichar(0);

  while(c != -1) {
    sv_cat_c(ret, lex_read_unichar(0));

    switch(c) {
      case '(': parencount++; break;
      case ')': parencount--; break;
    }
    if(!parencount)
      break;

    c = lex_peek_unichar(0);
  }

  if(SvCUR(ret))
    return ret;

  SvREFCNT_dec(ret);
  return NULL;
}

#define lex_scan_version(flags)  MY_lex_scan_version(aTHX_ flags)
static SV *MY_lex_scan_version(pTHX_ int flags)
{
  I32 c;
  SV *tmpsv = sv_2mortal(newSVpvs(""));

  /* scan_version() expects a version to end in linefeed, semicolon or
   * openbrace; gets confused if other keywords are fine. We'll have to
   * extract it first.
   *   https://rt.cpan.org/Ticket/Display.html?id=132903
   */

  while((c = lex_peek_unichar(0))) {
    /* Allow a single leading v before accepting only digits, dot, underscore */
    if((!SvCUR(tmpsv) && (c == 'v')) || strchr("0123456789._", c))
      sv_cat_c(tmpsv, lex_read_unichar(0));
    else
      break;
  }

  if(!SvCUR(tmpsv) && (flags & PARSE_OPTIONAL))
    return NULL;

  SV *ret = newSV(0);
  scan_version(SvPVX(tmpsv), ret, FALSE);

  return ret;
}

#define parse_lexvar()  MY_parse_lexvar(aTHX)
static PADOFFSET MY_parse_lexvar(pTHX)
{
  /* TODO: Rewrite this in terms of using lex_scan_lexvar()
  */
  char *lexname = PL_parser->bufptr;

  if(lex_read_unichar(0) != '$')
    croak("Expected a lexical scalar at %s", lexname);

  if(!isIDFIRST_uni(lex_peek_unichar(0)))
    croak("Expected a lexical scalar at %s", lexname);
  lex_read_unichar(0);
  while(isIDCONT_uni(lex_peek_unichar(0)))
    lex_read_unichar(0);

  /* Forbid $_ */
  if(PL_parser->bufptr - lexname == 2 && lexname[1] == '_')
    croak("Can't use global $_ in \"my\"");

  return pad_add_name_pvn(lexname, PL_parser->bufptr - lexname, 0, NULL, NULL);
}

#define parse_scoped_block(flags)  MY_parse_scoped_block(aTHX_ flags)
static OP *MY_parse_scoped_block(pTHX_ int flags)
{
  OP *ret;
  I32 save_ix = block_start(TRUE);
  ret = parse_block(flags);
  return block_end(save_ix, ret);
}
