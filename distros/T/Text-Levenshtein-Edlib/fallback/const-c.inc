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

#!/usr/bin/perl -w
use ExtUtils::Constant qw (constant_types C_constant XS_constant);

my $types = {map {($_, 1)} qw(IV)};
my @names = (qw(EDLIB_EDOP_DELETE EDLIB_EDOP_INSERT EDLIB_EDOP_MATCH
	       EDLIB_EDOP_MISMATCH EDLIB_STATUS_ERROR EDLIB_STATUS_OK),
            {name=>"EDLIB_CIGAR_EXTENDED", type=>"IV", macro=>"1"},
            {name=>"EDLIB_CIGAR_STANDARD", type=>"IV", macro=>"1"},
            {name=>"EDLIB_MODE_HW", type=>"IV", macro=>"1"},
            {name=>"EDLIB_MODE_NW", type=>"IV", macro=>"1"},
            {name=>"EDLIB_MODE_SHW", type=>"IV", macro=>"1"},
            {name=>"EDLIB_TASK_DISTANCE", type=>"IV", macro=>"1"},
            {name=>"EDLIB_TASK_LOC", type=>"IV", macro=>"1"},
            {name=>"EDLIB_TASK_PATH", type=>"IV", macro=>"1"});

print constant_types(), "\n"; # macro defs
foreach (C_constant ("Text::Levenshtein::Edlib", 'constant', 'IV', $types, undef, 3, @names) ) {
    print $_, "\n"; # C constant subs
}
print "\n#### XS Section:\n";
print XS_constant ("Text::Levenshtein::Edlib", $types);
__END__
   */

  switch (len) {
  case 13:
    /* Names all of length 13.  */
    /* EDLIB_MODE_HW EDLIB_MODE_NW */
    /* Offset 11 gives the best switch position.  */
    switch (name[11]) {
    case 'H':
      if (memEQ(name, "EDLIB_MODE_HW", 13)) {
      /*                          ^        */
        *iv_return = EDLIB_MODE_HW;
        return PERL_constant_ISIV;
      }
      break;
    case 'N':
      if (memEQ(name, "EDLIB_MODE_NW", 13)) {
      /*                          ^        */
        *iv_return = EDLIB_MODE_NW;
        return PERL_constant_ISIV;
      }
      break;
    }
    break;
  case 14:
    /* Names all of length 14.  */
    /* EDLIB_MODE_SHW EDLIB_TASK_LOC */
    /* Offset 9 gives the best switch position.  */
    switch (name[9]) {
    case 'E':
      if (memEQ(name, "EDLIB_MODE_SHW", 14)) {
      /*                        ^           */
        *iv_return = EDLIB_MODE_SHW;
        return PERL_constant_ISIV;
      }
      break;
    case 'K':
      if (memEQ(name, "EDLIB_TASK_LOC", 14)) {
      /*                        ^           */
        *iv_return = EDLIB_TASK_LOC;
        return PERL_constant_ISIV;
      }
      break;
    }
    break;
  case 15:
    /* Names all of length 15.  */
    /* EDLIB_STATUS_OK EDLIB_TASK_PATH */
    /* Offset 6 gives the best switch position.  */
    switch (name[6]) {
    case 'S':
      if (memEQ(name, "EDLIB_STATUS_OK", 15)) {
      /*                     ^               */
#ifdef EDLIB_STATUS_OK
        *iv_return = EDLIB_STATUS_OK;
        return PERL_constant_ISIV;
#else
        return PERL_constant_NOTDEF;
#endif
      }
      break;
    case 'T':
      if (memEQ(name, "EDLIB_TASK_PATH", 15)) {
      /*                     ^               */
        *iv_return = EDLIB_TASK_PATH;
        return PERL_constant_ISIV;
      }
      break;
    }
    break;
  case 16:
    if (memEQ(name, "EDLIB_EDOP_MATCH", 16)) {
#ifdef EDLIB_EDOP_MATCH
      *iv_return = EDLIB_EDOP_MATCH;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 17:
    /* Names all of length 17.  */
    /* EDLIB_EDOP_DELETE EDLIB_EDOP_INSERT */
    /* Offset 15 gives the best switch position.  */
    switch (name[15]) {
    case 'R':
      if (memEQ(name, "EDLIB_EDOP_INSERT", 17)) {
      /*                              ^        */
#ifdef EDLIB_EDOP_INSERT
        *iv_return = EDLIB_EDOP_INSERT;
        return PERL_constant_ISIV;
#else
        return PERL_constant_NOTDEF;
#endif
      }
      break;
    case 'T':
      if (memEQ(name, "EDLIB_EDOP_DELETE", 17)) {
      /*                              ^        */
#ifdef EDLIB_EDOP_DELETE
        *iv_return = EDLIB_EDOP_DELETE;
        return PERL_constant_ISIV;
#else
        return PERL_constant_NOTDEF;
#endif
      }
      break;
    }
    break;
  case 18:
    if (memEQ(name, "EDLIB_STATUS_ERROR", 18)) {
#ifdef EDLIB_STATUS_ERROR
      *iv_return = EDLIB_STATUS_ERROR;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 19:
    /* Names all of length 19.  */
    /* EDLIB_EDOP_MISMATCH EDLIB_TASK_DISTANCE */
    /* Offset 18 gives the best switch position.  */
    switch (name[18]) {
    case 'E':
      if (memEQ(name, "EDLIB_TASK_DISTANC", 18)) {
      /*                                 E      */
        *iv_return = EDLIB_TASK_DISTANCE;
        return PERL_constant_ISIV;
      }
      break;
    case 'H':
      if (memEQ(name, "EDLIB_EDOP_MISMATC", 18)) {
      /*                                 H      */
#ifdef EDLIB_EDOP_MISMATCH
        *iv_return = EDLIB_EDOP_MISMATCH;
        return PERL_constant_ISIV;
#else
        return PERL_constant_NOTDEF;
#endif
      }
      break;
    }
    break;
  case 20:
    /* Names all of length 20.  */
    /* EDLIB_CIGAR_EXTENDED EDLIB_CIGAR_STANDARD */
    /* Offset 17 gives the best switch position.  */
    switch (name[17]) {
    case 'A':
      if (memEQ(name, "EDLIB_CIGAR_STANDARD", 20)) {
      /*                                ^         */
        *iv_return = EDLIB_CIGAR_STANDARD;
        return PERL_constant_ISIV;
      }
      break;
    case 'D':
      if (memEQ(name, "EDLIB_CIGAR_EXTENDED", 20)) {
      /*                                ^         */
        *iv_return = EDLIB_CIGAR_EXTENDED;
        return PERL_constant_ISIV;
      }
      break;
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

