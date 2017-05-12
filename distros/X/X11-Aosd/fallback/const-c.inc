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
     COORDINATE_CENTER TRANSPARENCY_FAKE TRANSPARENCY_NONE */
  /* Offset 15 gives the best switch position.  */
  switch (name[15]) {
  case 'E':
    if (memEQ(name, "COORDINATE_CENTER", 17)) {
    /*                              ^        */
      *iv_return = COORDINATE_CENTER;
      return PERL_constant_ISIV;
    }
    break;
  case 'K':
    if (memEQ(name, "TRANSPARENCY_FAKE", 17)) {
    /*                              ^        */
      *iv_return = TRANSPARENCY_FAKE;
      return PERL_constant_ISIV;
    }
    break;
  case 'N':
    if (memEQ(name, "TRANSPARENCY_NONE", 17)) {
    /*                              ^        */
      *iv_return = TRANSPARENCY_NONE;
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

#!/usr/bin/perl -w
use ExtUtils::Constant qw (constant_types C_constant XS_constant);

my $types = {map {($_, 1)} qw(IV)};
my @names = (qw(),
            {name=>"COORDINATE_CENTER", type=>"IV", macro=>"1"},
            {name=>"COORDINATE_MAXIMUM", type=>"IV", macro=>"1"},
            {name=>"COORDINATE_MINIMUM", type=>"IV", macro=>"1"},
            {name=>"TRANSPARENCY_COMPOSITE", type=>"IV", macro=>"1"},
            {name=>"TRANSPARENCY_FAKE", type=>"IV", macro=>"1"},
            {name=>"TRANSPARENCY_NONE", type=>"IV", macro=>"1"});

print constant_types(); # macro defs
foreach (C_constant ("X11::Aosd", 'constant', 'IV', $types, undef, 3, @names) ) {
    print $_, "\n"; # C constant subs
}
print "#### XS Section:\n";
print XS_constant ("X11::Aosd", $types);
__END__
   */

  switch (len) {
  case 17:
    return constant_17 (aTHX_ name, iv_return);
    break;
  case 18:
    /* Names all of length 18.  */
    /* COORDINATE_MAXIMUM COORDINATE_MINIMUM */
    /* Offset 12 gives the best switch position.  */
    switch (name[12]) {
    case 'A':
      if (memEQ(name, "COORDINATE_MAXIMUM", 18)) {
      /*                           ^            */
        *iv_return = COORDINATE_MAXIMUM;
        return PERL_constant_ISIV;
      }
      break;
    case 'I':
      if (memEQ(name, "COORDINATE_MINIMUM", 18)) {
      /*                           ^            */
        *iv_return = COORDINATE_MINIMUM;
        return PERL_constant_ISIV;
      }
      break;
    }
    break;
  case 22:
    if (memEQ(name, "TRANSPARENCY_COMPOSITE", 22)) {
      *iv_return = TRANSPARENCY_COMPOSITE;
      return PERL_constant_ISIV;
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

