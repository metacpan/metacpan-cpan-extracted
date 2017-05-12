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

#!/usr/bin/perl5.8.1 -w
use ExtUtils::Constant qw (constant_types C_constant XS_constant);

my $types = {map {($_, 1)} qw(IV)};
my @names = (qw( TOKEN_STRUCT TOK_EOF TOK_OPT_DEFAULT TOK_OPT_NONE
	       TOK_OPT_NOUNESCAPE TOK_OPT_SIQUOTE TOK_OPT_UNESCAPE
	       TOK_OPT_UNESCAPE_CHARS TOK_OPT_UNESCAPE_LINES TOK_TEXT
	       TOK_UNDEF));

print constant_types(); # macro defs
foreach (C_constant ("Tokenizer", 'constant', 'IV', $types, undef, 3, @names) ) {
    print $_, "\n"; # C constant subs
}
print "#### XS Section:\n";
print XS_constant ("Tokenizer", $types);
__END__
   */

  switch (len) {
  case 0:
    if (name[0] == '') {
#ifdef 
      *iv_return = ;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 7:
    if (memEQ(name, "TOK_EOF", 7)) {
#ifdef TOK_EOF
      *iv_return = TOK_EOF;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
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
    if (memEQ(name, "TOK_UNDEF", 9)) {
#ifdef TOK_UNDEF
      *iv_return = TOK_UNDEF;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 12:
    /* Names all of length 12.  */
    /* TOKEN_STRUCT TOK_OPT_NONE */
    /* Offset 4 gives the best switch position.  */
    switch (name[4]) {
    case 'N':
      if (memEQ(name, "TOKEN_STRUCT", 12)) {
      /*                   ^              */
#ifdef TOKEN_STRUCT
        *iv_return = TOKEN_STRUCT;
        return PERL_constant_ISIV;
#else
        return PERL_constant_NOTDEF;
#endif
      }
      break;
    case 'O':
      if (memEQ(name, "TOK_OPT_NONE", 12)) {
      /*                   ^              */
#ifdef TOK_OPT_NONE
        *iv_return = TOK_OPT_NONE;
        return PERL_constant_ISIV;
#else
        return PERL_constant_NOTDEF;
#endif
      }
      break;
    }
    break;
  case 15:
    /* Names all of length 15.  */
    /* TOK_OPT_DEFAULT TOK_OPT_SIQUOTE */
    /* Offset 9 gives the best switch position.  */
    switch (name[9]) {
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
      break;
    }
    break;
  case 16:
    if (memEQ(name, "TOK_OPT_UNESCAPE", 16)) {
#ifdef TOK_OPT_UNESCAPE
      *iv_return = TOK_OPT_UNESCAPE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 18:
    if (memEQ(name, "TOK_OPT_NOUNESCAPE", 18)) {
#ifdef TOK_OPT_NOUNESCAPE
      *iv_return = TOK_OPT_NOUNESCAPE;
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
  }
  return PERL_constant_NOTFOUND;
}

