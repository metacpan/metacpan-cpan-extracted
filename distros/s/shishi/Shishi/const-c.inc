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
constant_17 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     SHISHI_MATCH_CHAR SHISHI_MATCH_CODE SHISHI_MATCH_SKIP SHISHI_MATCH_TEXT
     SHISHI_MATCH_TRUE */
  /* Offset 14 gives the best switch position.  */
  switch (name[14]) {
  case 'E':
    if (memEQ(name, "SHISHI_MATCH_TEXT", 17)) {
    /*                             ^         */
      *iv_return = SHISHI_MATCH_TEXT;
      return PERL_constant_ISIV;
    }
    break;
  case 'H':
    if (memEQ(name, "SHISHI_MATCH_CHAR", 17)) {
    /*                             ^         */
      *iv_return = SHISHI_MATCH_CHAR;
      return PERL_constant_ISIV;
    }
    break;
  case 'K':
    if (memEQ(name, "SHISHI_MATCH_SKIP", 17)) {
    /*                             ^         */
      *iv_return = SHISHI_MATCH_SKIP;
      return PERL_constant_ISIV;
    }
    break;
  case 'O':
    if (memEQ(name, "SHISHI_MATCH_CODE", 17)) {
    /*                             ^         */
      *iv_return = SHISHI_MATCH_CODE;
      return PERL_constant_ISIV;
    }
    break;
  case 'R':
    if (memEQ(name, "SHISHI_MATCH_TRUE", 17)) {
    /*                             ^         */
      *iv_return = SHISHI_MATCH_TRUE;
      return PERL_constant_ISIV;
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

#!perl -w
use ExtUtils::Constant qw (constant_types C_constant XS_constant);

my $types = {map {($_, 1)} qw(IV)};
my @names = (qw(),
            {name=>"SHISHI_ACTION_CONTINUE", type=>"IV", macro=>"1"},
            {name=>"SHISHI_ACTION_FAIL", type=>"IV", macro=>"1"},
            {name=>"SHISHI_ACTION_FINISH", type=>"IV", macro=>"1"},
            {name=>"SHISHI_AGAIN", type=>"IV", macro=>"1"},
            {name=>"SHISHI_FAILED", type=>"IV", macro=>"1"},
            {name=>"SHISHI_MATCHED", type=>"IV", macro=>"1"},
            {name=>"SHISHI_MATCH_ANY", type=>"IV", macro=>"1"},
            {name=>"SHISHI_MATCH_CHAR", type=>"IV", macro=>"1"},
            {name=>"SHISHI_MATCH_CODE", type=>"IV", macro=>"1"},
            {name=>"SHISHI_MATCH_END", type=>"IV", macro=>"1"},
            {name=>"SHISHI_MATCH_SKIP", type=>"IV", macro=>"1"},
            {name=>"SHISHI_MATCH_TEXT", type=>"IV", macro=>"1"},
            {name=>"SHISHI_MATCH_TOKEN", type=>"IV", macro=>"1"},
            {name=>"SHISHI_MATCH_TRUE", type=>"IV", macro=>"1"});

print constant_types(); # macro defs
foreach (C_constant ("Shishi", 'constant', 'IV', $types, undef, 3, @names) ) {
    print $_, "\n"; # C constant subs
}
print "#### XS Section:\n";
print XS_constant ("Shishi", $types);
__END__
   */

  switch (len) {
  case 12:
    if (memEQ(name, "SHISHI_AGAIN", 12)) {
      *iv_return = SHISHI_AGAIN;
      return PERL_constant_ISIV;
    }
    break;
  case 13:
    if (memEQ(name, "SHISHI_FAILED", 13)) {
      *iv_return = SHISHI_FAILED;
      return PERL_constant_ISIV;
    }
    break;
  case 14:
    if (memEQ(name, "SHISHI_MATCHED", 14)) {
      *iv_return = SHISHI_MATCHED;
      return PERL_constant_ISIV;
    }
    break;
  case 16:
    /* Names all of length 16.  */
    /* SHISHI_MATCH_ANY SHISHI_MATCH_END */
    /* Offset 13 gives the best switch position.  */
    switch (name[13]) {
    case 'A':
      if (memEQ(name, "SHISHI_MATCH_ANY", 16)) {
      /*                            ^         */
        *iv_return = SHISHI_MATCH_ANY;
        return PERL_constant_ISIV;
      }
      break;
    case 'E':
      if (memEQ(name, "SHISHI_MATCH_END", 16)) {
      /*                            ^         */
        *iv_return = SHISHI_MATCH_END;
        return PERL_constant_ISIV;
      }
      break;
    }
    break;
  case 17:
    return constant_17 (aTHX_ name, iv_return);
    break;
  case 18:
    /* Names all of length 18.  */
    /* SHISHI_ACTION_FAIL SHISHI_MATCH_TOKEN */
    /* Offset 8 gives the best switch position.  */
    switch (name[8]) {
    case 'A':
      if (memEQ(name, "SHISHI_MATCH_TOKEN", 18)) {
      /*                       ^                */
        *iv_return = SHISHI_MATCH_TOKEN;
        return PERL_constant_ISIV;
      }
      break;
    case 'C':
      if (memEQ(name, "SHISHI_ACTION_FAIL", 18)) {
      /*                       ^                */
        *iv_return = SHISHI_ACTION_FAIL;
        return PERL_constant_ISIV;
      }
      break;
    }
    break;
  case 20:
    if (memEQ(name, "SHISHI_ACTION_FINISH", 20)) {
      *iv_return = SHISHI_ACTION_FINISH;
      return PERL_constant_ISIV;
    }
    break;
  case 22:
    if (memEQ(name, "SHISHI_ACTION_CONTINUE", 22)) {
      *iv_return = SHISHI_ACTION_CONTINUE;
      return PERL_constant_ISIV;
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

