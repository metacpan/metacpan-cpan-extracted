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
constant_8 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     EX_IOERR EX_OSERR EX_USAGE EX__BASE */
  /* Offset 3 gives the best switch position.  */
  switch (name[3]) {
  case 'I':
    if (memEQ(name, "EX_IOERR", 8)) {
    /*                  ^          */
#ifdef EX_IOERR
      *iv_return = EX_IOERR;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'O':
    if (memEQ(name, "EX_OSERR", 8)) {
    /*                  ^          */
#ifdef EX_OSERR
      *iv_return = EX_OSERR;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'U':
    if (memEQ(name, "EX_USAGE", 8)) {
    /*                  ^          */
#ifdef EX_USAGE
      *iv_return = EX_USAGE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case '_':
    if (memEQ(name, "EX__BASE", 8)) {
    /*                  ^          */
#ifdef EX__BASE
      *iv_return = EX__BASE;
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
constant_9 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     EX_CONFIG EX_NOHOST EX_NOPERM EX_NOUSER EX_OSFILE */
  /* Offset 6 gives the best switch position.  */
  switch (name[6]) {
  case 'E':
    if (memEQ(name, "EX_NOPERM", 9)) {
    /*                     ^        */
#ifdef EX_NOPERM
      *iv_return = EX_NOPERM;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'F':
    if (memEQ(name, "EX_CONFIG", 9)) {
    /*                     ^        */
#ifdef EX_CONFIG
      *iv_return = EX_CONFIG;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'I':
    if (memEQ(name, "EX_OSFILE", 9)) {
    /*                     ^        */
#ifdef EX_OSFILE
      *iv_return = EX_OSFILE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'O':
    if (memEQ(name, "EX_NOHOST", 9)) {
    /*                     ^        */
#ifdef EX_NOHOST
      *iv_return = EX_NOHOST;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'S':
    if (memEQ(name, "EX_NOUSER", 9)) {
    /*                     ^        */
#ifdef EX_NOUSER
      *iv_return = EX_NOUSER;
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
constant_11 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     EX_PROTOCOL EX_SOFTWARE EX_TEMPFAIL */
  /* Offset 3 gives the best switch position.  */
  switch (name[3]) {
  case 'P':
    if (memEQ(name, "EX_PROTOCOL", 11)) {
    /*                  ^              */
#ifdef EX_PROTOCOL
      *iv_return = EX_PROTOCOL;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'S':
    if (memEQ(name, "EX_SOFTWARE", 11)) {
    /*                  ^              */
#ifdef EX_SOFTWARE
      *iv_return = EX_SOFTWARE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'T':
    if (memEQ(name, "EX_TEMPFAIL", 11)) {
    /*                  ^              */
#ifdef EX_TEMPFAIL
      *iv_return = EX_TEMPFAIL;
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

#!/home/jmates/perl5/perlbrew/perls/perl-5.14.1/bin/perl -w
use ExtUtils::Constant qw (constant_types C_constant XS_constant);

my $types = {map {($_, 1)} qw(IV)};
my @names = (qw(EX_CANTCREAT EX_CONFIG EX_DATAERR EX_IOERR EX_NOHOST EX_NOINPUT
	       EX_NOPERM EX_NOUSER EX_OK EX_OSERR EX_OSFILE EX_PROTOCOL
	       EX_SOFTWARE EX_TEMPFAIL EX_UNAVAILABLE EX_USAGE EX__BASE
	       EX__MAX));

print constant_types(), "\n"; # macro defs
foreach (C_constant ("Unix::Sysexits", 'constant', 'IV', $types, undef, 3, @names) ) {
    print $_, "\n"; # C constant subs
}
print "\n#### XS Section:\n";
print XS_constant ("Unix::Sysexits", $types);
__END__
   */

  switch (len) {
  case 5:
    if (memEQ(name, "EX_OK", 5)) {
#ifdef EX_OK
      *iv_return = EX_OK;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 7:
    if (memEQ(name, "EX__MAX", 7)) {
#ifdef EX__MAX
      *iv_return = EX__MAX;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 8:
    return constant_8 (aTHX_ name, iv_return);
    break;
  case 9:
    return constant_9 (aTHX_ name, iv_return);
    break;
  case 10:
    /* Names all of length 10.  */
    /* EX_DATAERR EX_NOINPUT */
    /* Offset 9 gives the best switch position.  */
    switch (name[9]) {
    case 'R':
      if (memEQ(name, "EX_DATAER", 9)) {
      /*                        R     */
#ifdef EX_DATAERR
        *iv_return = EX_DATAERR;
        return PERL_constant_ISIV;
#else
        return PERL_constant_NOTDEF;
#endif
      }
      break;
    case 'T':
      if (memEQ(name, "EX_NOINPU", 9)) {
      /*                        T     */
#ifdef EX_NOINPUT
        *iv_return = EX_NOINPUT;
        return PERL_constant_ISIV;
#else
        return PERL_constant_NOTDEF;
#endif
      }
      break;
    }
    break;
  case 11:
    return constant_11 (aTHX_ name, iv_return);
    break;
  case 12:
    if (memEQ(name, "EX_CANTCREAT", 12)) {
#ifdef EX_CANTCREAT
      *iv_return = EX_CANTCREAT;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 14:
    if (memEQ(name, "EX_UNAVAILABLE", 14)) {
#ifdef EX_UNAVAILABLE
      *iv_return = EX_UNAVAILABLE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

