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

#!C:\perl5\bin\perl.exe -w
use ExtUtils::Constant qw (constant_types C_constant XS_constant);

my $types = {map {($_, 1)} qw(IV)};
my @names = (qw(SEM_FAILCRITICALERRORS SEM_NOALIGNMENTFAULTEXCEPT
	       SEM_NOGPFAULTERRORBOX SEM_NOOPENFILEERRORBOX));

print constant_types(); # macro defs
foreach (C_constant ("Win32::UTCFileTime", 'constant', 'IV', $types, undef, 3, @names) ) {
    print $_, "\n"; # C constant subs
}
print "#### XS Section:\n";
print XS_constant ("Win32::UTCFileTime", $types);
__END__
   */

  switch (len) {
  case 21:
    if (memEQ(name, "SEM_NOGPFAULTERRORBOX", 21)) {
#ifdef SEM_NOGPFAULTERRORBOX
      *iv_return = SEM_NOGPFAULTERRORBOX;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 22:
    /* Names all of length 22.  */
    /* SEM_FAILCRITICALERRORS SEM_NOOPENFILEERRORBOX */
    /* Offset 8 gives the best switch position.  */
    switch (name[8]) {
    case 'C':
      if (memEQ(name, "SEM_FAILCRITICALERRORS", 22)) {
      /*                       ^                    */
#ifdef SEM_FAILCRITICALERRORS
        *iv_return = SEM_FAILCRITICALERRORS;
        return PERL_constant_ISIV;
#else
        return PERL_constant_NOTDEF;
#endif
      }
      break;
    case 'E':
      if (memEQ(name, "SEM_NOOPENFILEERRORBOX", 22)) {
      /*                       ^                    */
#ifdef SEM_NOOPENFILEERRORBOX
        *iv_return = SEM_NOOPENFILEERRORBOX;
        return PERL_constant_ISIV;
#else
        return PERL_constant_NOTDEF;
#endif
      }
      break;
    }
    break;
  case 26:
    if (memEQ(name, "SEM_NOALIGNMENTFAULTEXCEPT", 26)) {
#ifdef SEM_NOALIGNMENTFAULTEXCEPT
      *iv_return = SEM_NOALIGNMENTFAULTEXCEPT;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

