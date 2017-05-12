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

#!dsa0:[perl-5_10_0_root.][000000]perl.exe;1 -w
use ExtUtils::Constant qw (constant_types C_constant XS_constant);

my $types = {map {($_, 1)} qw(IV)};
my @names = (qw(),
            {name=>"BIGINT", type=>"IV", macro=>"VMSTIME_BIGINT", value=>"4"},
            {name=>"FLOAT", type=>"IV", macro=>"VMSTIME_FLOAT", value=>"2"},
            {name=>"HEX", type=>"IV", macro=>"VMSTIME_HEX", value=>"3"},
            {name=>"LONGINT", type=>"IV", macro=>"VMSTIME_LONGINT", value=>"1"},
            {name=>"PACK", type=>"IV", macro=>"VMSTIME_PACK", value=>"0"});

print constant_types(), "\n"; # macro defs
foreach (C_constant ("VMS::Time", 'constant', 'IV', $types, undef, 3, @names) ) {
    print $_, "\n"; # C constant subs
}
print "\n#### XS Section:\n";
print XS_constant ("VMS::Time", $types);
__END__
   */

  switch (len) {
  case 3:
    if (memEQ(name, "HEX", 3)) {
#ifdef VMSTIME_HEX
      *iv_return = 3;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 4:
    if (memEQ(name, "PACK", 4)) {
#ifdef VMSTIME_PACK
      *iv_return = 0;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 5:
    if (memEQ(name, "FLOAT", 5)) {
#ifdef VMSTIME_FLOAT
      *iv_return = 2;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 6:
    if (memEQ(name, "BIGINT", 6)) {
#ifdef VMSTIME_BIGINT
      *iv_return = 4;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 7:
    if (memEQ(name, "LONGINT", 7)) {
#ifdef VMSTIME_LONGINT
      *iv_return = 1;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

