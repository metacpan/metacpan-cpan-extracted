#define PERL_constant_NOTFOUND	1
#define PERL_constant_NOTDEF	2
#define PERL_constant_ISIV	3
#define PERL_constant_ISNO	4
#define PERL_constant_ISNV	5
#define PERL_constant_ISPV	6
#define PERL_constant_ISPVN	7
#define PERL_constant_ISSV	8
#define PERL_constant_ISUNDEF	9
#define PERL_constant_ISUV	10
#define PERL_constant_ISYES	11

#ifndef NVTYPE
typedef double NV; /* 5.6 and later define NVTYPE, and typedef NV to it.  */
#endif
#ifndef aTHX_
#define aTHX_ /* 5.6 or later define this for threading support.  */
#endif
#ifndef pTHX_
#define pTHX_ /* 5.6 or later define this for threading support.  */
#endif

static int
constant_9 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     NOCONTEXT TOK_BLANK TOK_ERROR TOK_UNDEF */
  /* Offset 5 gives the best switch position.  */
  switch (name[5]) {
  case 'L':
    if (memEQ(name, "TOK_BLANK", 9)) {
    /*                    ^         */
#ifdef TOK_BLANK
      *iv_return = TOK_BLANK;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'N':
    if (memEQ(name, "TOK_UNDEF", 9)) {
    /*                    ^         */
#ifdef TOK_UNDEF
      *iv_return = TOK_UNDEF;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'R':
    if (memEQ(name, "TOK_ERROR", 9)) {
    /*                    ^         */
#ifdef TOK_ERROR
      *iv_return = TOK_ERROR;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'T':
    if (memEQ(name, "NOCONTEXT", 9)) {
    /*                    ^         */
#ifdef NOCONTEXT
      *iv_return = NOCONTEXT;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

static int
constant_10 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     TOK_DQUOTE TOK_IQUOTE TOK_SQUOTE */
  /* Offset 4 gives the best switch position.  */
  switch (name[4]) {
  case 'D':
    if (memEQ(name, "TOK_DQUOTE", 10)) {
    /*                   ^            */
#ifdef TOK_DQUOTE
      *iv_return = TOK_DQUOTE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'I':
    if (memEQ(name, "TOK_IQUOTE", 10)) {
    /*                   ^            */
#ifdef TOK_IQUOTE
      *iv_return = TOK_IQUOTE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'S':
    if (memEQ(name, "TOK_SQUOTE", 10)) {
    /*                   ^            */
#ifdef TOK_SQUOTE
      *iv_return = TOK_SQUOTE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

static int
constant_15 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     TOK_OPT_DEFAULT TOK_OPT_SIQUOTE UNCLOSED_DQUOTE UNCLOSED_IQUOTE
     UNCLOSED_SQUOTE */
  /* Offset 9 gives the best switch position.  */
  switch (name[9]) {
  case 'D':
    if (memEQ(name, "UNCLOSED_DQUOTE", 15)) {
    /*                        ^            */
#ifdef UNCLOSED_DQUOTE
      *iv_return = UNCLOSED_DQUOTE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'E':
    if (memEQ(name, "TOK_OPT_DEFAULT", 15)) {
    /*                        ^            */
#ifdef TOK_OPT_DEFAULT
      *iv_return = TOK_OPT_DEFAULT;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'I':
    if (memEQ(name, "TOK_OPT_SIQUOTE", 15)) {
    /*                        ^            */
#ifdef TOK_OPT_SIQUOTE
      *iv_return = TOK_OPT_SIQUOTE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "UNCLOSED_IQUOTE", 15)) {
    /*                        ^            */
#ifdef UNCLOSED_IQUOTE
      *iv_return = UNCLOSED_IQUOTE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'S':
    if (memEQ(name, "UNCLOSED_SQUOTE", 15)) {
    /*                        ^            */
#ifdef UNCLOSED_SQUOTE
      *iv_return = UNCLOSED_SQUOTE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

static int
constant_18 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     TOK_OPT_CC_COMMENT TOK_OPT_NOUNESCAPE UNCLOSED_C_COMMENT */
  /* Offset 8 gives the best switch position.  */
  switch (name[8]) {
  case 'C':
    if (memEQ(name, "TOK_OPT_CC_COMMENT", 18)) {
    /*                       ^                */
#ifdef TOK_OPT_CC_COMMENT
      *iv_return = TOK_OPT_CC_COMMENT;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'N':
    if (memEQ(name, "TOK_OPT_NOUNESCAPE", 18)) {
    /*                       ^                */
#ifdef TOK_OPT_NOUNESCAPE
      *iv_return = TOK_OPT_NOUNESCAPE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case '_':
    if (memEQ(name, "UNCLOSED_C_COMMENT", 18)) {
    /*                       ^                */
#ifdef UNCLOSED_C_COMMENT
      *iv_return = UNCLOSED_C_COMMENT;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

static int
constant (pTHX_ const char *name, STRLEN len, IV *iv_return) {
  /* Initially switch on the length of the name.  */
  /* When generated this function returned values for the list of names given
     in this section of perl code.  Rather than manually editing these functions
     to add or remove constants, which would result in this comment and section
     of code becoming inaccurate, we recommend that you edit this section of
     code, and use it to regenerate a new set of constant functions which you
     then use to replace the originals.

     Regenerate these constant functions by feeding this entire source file to
     perl -x

#!/usr/bin/perl5.12.4 -w
use ExtUtils::Constant qw (constant_types C_constant XS_constant);

my $types = {map {($_, 1)} qw(IV)};
my @names = (qw(NOCONTEXT NOERR TOK_BASH_COMMENT TOK_BLANK TOK_CC_COMMENT
	       TOK_COMMENT TOK_C_COMMENT TOK_DQUOTE TOK_EOF TOK_EOL TOK_ERROR
	       TOK_IQUOTE TOK_OPT_CC_COMMENT TOK_OPT_C_COMMENT TOK_OPT_DEFAULT
	       TOK_OPT_NONE TOK_OPT_NOUNESCAPE TOK_OPT_NO_BASH_COMMENT
	       TOK_OPT_NO_IQUOTE TOK_OPT_PASSCOMMENT TOK_OPT_PASS_COMMENT
	       TOK_OPT_SIQUOTE TOK_OPT_UNESCAPE TOK_OPT_UNESCAPE_CHARS
	       TOK_OPT_UNESCAPE_LINES TOK_OPT_UNESCAPE_NQ_LINES TOK_SIQUOTE
	       TOK_SQUOTE TOK_TEXT TOK_UNDEF UNCLOSED_C_COMMENT UNCLOSED_DQUOTE
	       UNCLOSED_IQUOTE UNCLOSED_SQUOTE));

print constant_types(), "\n"; # macro defs
foreach (C_constant ("Tokenizer", 'constant', 'IV', $types, undef, 3, @names) ) {
    print $_, "\n"; # C constant subs
}
print "\n#### XS Section:\n";
print XS_constant ("Tokenizer", $types);
__END__
   */

  switch (len) {
  case 5:
    if (memEQ(name, "NOERR", 5)) {
#ifdef NOERR
      *iv_return = NOERR;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 7:
    /* Names all of length 7.  */
    /* TOK_EOF TOK_EOL */
    /* Offset 6 gives the best switch position.  */
    switch (name[6]) {
    case 'F':
      if (memEQ(name, "TOK_EO", 6)) {
      /*                     F     */
#ifdef TOK_EOF
        *iv_return = TOK_EOF;
        return PERL_constant_ISIV;
#else
        return PERL_constant_NOTDEF;
#endif
      }
      break;
    case 'L':
      if (memEQ(name, "TOK_EO", 6)) {
      /*                     L     */
#ifdef TOK_EOL
        *iv_return = TOK_EOL;
        return PERL_constant_ISIV;
#else
        return PERL_constant_NOTDEF;
#endif
      }
      break;
    }
    break;
  case 8:
    if (memEQ(name, "TOK_TEXT", 8)) {
#ifdef TOK_TEXT
      *iv_return = TOK_TEXT;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 9:
    return constant_9 (aTHX_ name, iv_return);
    break;
  case 10:
    return constant_10 (aTHX_ name, iv_return);
    break;
  case 11:
    /* Names all of length 11.  */
    /* TOK_COMMENT TOK_SIQUOTE */
    /* Offset 6 gives the best switch position.  */
    switch (name[6]) {
    case 'M':
      if (memEQ(name, "TOK_COMMENT", 11)) {
      /*                     ^           */
#ifdef TOK_COMMENT
        *iv_return = TOK_COMMENT;
        return PERL_constant_ISIV;
#else
        return PERL_constant_NOTDEF;
#endif
      }
      break;
    case 'Q':
      if (memEQ(name, "TOK_SIQUOTE", 11)) {
      /*                     ^           */
#ifdef TOK_SIQUOTE
        *iv_return = TOK_SIQUOTE;
        return PERL_constant_ISIV;
#else
        return PERL_constant_NOTDEF;
#endif
      }
      break;
    }
    break;
  case 12:
    if (memEQ(name, "TOK_OPT_NONE", 12)) {
#ifdef TOK_OPT_NONE
      *iv_return = TOK_OPT_NONE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 13:
    if (memEQ(name, "TOK_C_COMMENT", 13)) {
#ifdef TOK_C_COMMENT
      *iv_return = TOK_C_COMMENT;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 14:
    if (memEQ(name, "TOK_CC_COMMENT", 14)) {
#ifdef TOK_CC_COMMENT
      *iv_return = TOK_CC_COMMENT;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 15:
    return constant_15 (aTHX_ name, iv_return);
    break;
  case 16:
    /* Names all of length 16.  */
    /* TOK_BASH_COMMENT TOK_OPT_UNESCAPE */
    /* Offset 6 gives the best switch position.  */
    switch (name[6]) {
    case 'S':
      if (memEQ(name, "TOK_BASH_COMMENT", 16)) {
      /*                     ^                */
#ifdef TOK_BASH_COMMENT
        *iv_return = TOK_BASH_COMMENT;
        return PERL_constant_ISIV;
#else
        return PERL_constant_NOTDEF;
#endif
      }
      break;
    case 'T':
      if (memEQ(name, "TOK_OPT_UNESCAPE", 16)) {
      /*                     ^                */
#ifdef TOK_OPT_UNESCAPE
        *iv_return = TOK_OPT_UNESCAPE;
        return PERL_constant_ISIV;
#else
        return PERL_constant_NOTDEF;
#endif
      }
      break;
    }
    break;
  case 17:
    /* Names all of length 17.  */
    /* TOK_OPT_C_COMMENT TOK_OPT_NO_IQUOTE */
    /* Offset 12 gives the best switch position.  */
    switch (name[12]) {
    case 'M':
      if (memEQ(name, "TOK_OPT_C_COMMENT", 17)) {
      /*                           ^           */
#ifdef TOK_OPT_C_COMMENT
        *iv_return = TOK_OPT_C_COMMENT;
        return PERL_constant_ISIV;
#else
        return PERL_constant_NOTDEF;
#endif
      }
      break;
    case 'Q':
      if (memEQ(name, "TOK_OPT_NO_IQUOTE", 17)) {
      /*                           ^           */
#ifdef TOK_OPT_NO_IQUOTE
        *iv_return = TOK_OPT_NO_IQUOTE;
        return PERL_constant_ISIV;
#else
        return PERL_constant_NOTDEF;
#endif
      }
      break;
    }
    break;
  case 18:
    return constant_18 (aTHX_ name, iv_return);
    break;
  case 19:
    if (memEQ(name, "TOK_OPT_PASSCOMMENT", 19)) {
#ifdef TOK_OPT_PASSCOMMENT
      *iv_return = TOK_OPT_PASSCOMMENT;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 20:
    if (memEQ(name, "TOK_OPT_PASS_COMMENT", 20)) {
#ifdef TOK_OPT_PASS_COMMENT
      *iv_return = TOK_OPT_PASS_COMMENT;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 22:
    /* Names all of length 22.  */
    /* TOK_OPT_UNESCAPE_CHARS TOK_OPT_UNESCAPE_LINES */
    /* Offset 18 gives the best switch position.  */
    switch (name[18]) {
    case 'H':
      if (memEQ(name, "TOK_OPT_UNESCAPE_CHARS", 22)) {
      /*                                 ^          */
#ifdef TOK_OPT_UNESCAPE_CHARS
        *iv_return = TOK_OPT_UNESCAPE_CHARS;
        return PERL_constant_ISIV;
#else
        return PERL_constant_NOTDEF;
#endif
      }
      break;
    case 'I':
      if (memEQ(name, "TOK_OPT_UNESCAPE_LINES", 22)) {
      /*                                 ^          */
#ifdef TOK_OPT_UNESCAPE_LINES
        *iv_return = TOK_OPT_UNESCAPE_LINES;
        return PERL_constant_ISIV;
#else
        return PERL_constant_NOTDEF;
#endif
      }
      break;
    }
    break;
  case 23:
    if (memEQ(name, "TOK_OPT_NO_BASH_COMMENT", 23)) {
#ifdef TOK_OPT_NO_BASH_COMMENT
      *iv_return = TOK_OPT_NO_BASH_COMMENT;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 25:
    if (memEQ(name, "TOK_OPT_UNESCAPE_NQ_LINES", 25)) {
#ifdef TOK_OPT_UNESCAPE_NQ_LINES
      *iv_return = TOK_OPT_UNESCAPE_NQ_LINES;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

