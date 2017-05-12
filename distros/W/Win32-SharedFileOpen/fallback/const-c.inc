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
constant_6 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     O_EXCL O_RDWR O_TEXT */
  /* Offset 5 gives the best switch position.  */
  switch (name[5]) {
  case 'L':
    if (memEQ(name, "O_EXC", 5)) {
    /*                    L     */
#ifdef O_EXCL
      *iv_return = O_EXCL;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'R':
    if (memEQ(name, "O_RDW", 5)) {
    /*                    R     */
#ifdef O_RDWR
      *iv_return = O_RDWR;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'T':
    if (memEQ(name, "O_TEX", 5)) {
    /*                    T     */
#ifdef O_TEXT
      *iv_return = O_TEXT;
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
constant_7 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     O_CREAT O_TRUNC S_IREAD */
  /* Offset 6 gives the best switch position.  */
  switch (name[6]) {
  case 'C':
    if (memEQ(name, "O_TRUN", 6)) {
    /*                     C     */
#ifdef O_TRUNC
      *iv_return = O_TRUNC;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'D':
    if (memEQ(name, "S_IREA", 6)) {
    /*                     D     */
#ifdef S_IREAD
      *iv_return = S_IREAD;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'T':
    if (memEQ(name, "O_CREA", 6)) {
    /*                     T     */
#ifdef O_CREAT
      *iv_return = O_CREAT;
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
constant_8 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     INFINITE O_APPEND O_BINARY O_RANDOM O_RDONLY O_WRONLY S_IWRITE */
  /* Offset 2 gives the best switch position.  */
  switch (name[2]) {
  case 'A':
    if (memEQ(name, "O_APPEND", 8)) {
    /*                 ^           */
#ifdef O_APPEND
      *iv_return = O_APPEND;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'B':
    if (memEQ(name, "O_BINARY", 8)) {
    /*                 ^           */
#ifdef O_BINARY
      *iv_return = O_BINARY;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'F':
    if (memEQ(name, "INFINITE", 8)) {
    /*                 ^           */
#ifdef INFINITE
      *iv_return = (IV)INFINITE;
      return PERL_constant_ISUV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'I':
    if (memEQ(name, "S_IWRITE", 8)) {
    /*                 ^           */
#ifdef S_IWRITE
      *iv_return = S_IWRITE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'R':
    if (memEQ(name, "O_RANDOM", 8)) {
    /*                 ^           */
#ifdef O_RANDOM
      *iv_return = O_RANDOM;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "O_RDONLY", 8)) {
    /*                 ^           */
#ifdef O_RDONLY
      *iv_return = O_RDONLY;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'W':
    if (memEQ(name, "O_WRONLY", 8)) {
    /*                 ^           */
#ifdef O_WRONLY
      *iv_return = O_WRONLY;
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
     SH_DENYNO SH_DENYRD SH_DENYRW SH_DENYWR */
  /* Offset 8 gives the best switch position.  */
  switch (name[8]) {
  case 'D':
    if (memEQ(name, "SH_DENYR", 8)) {
    /*                       D     */
#ifdef SH_DENYRD
      *iv_return = SH_DENYRD;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'O':
    if (memEQ(name, "SH_DENYN", 8)) {
    /*                       O     */
#ifdef SH_DENYNO
      *iv_return = SH_DENYNO;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'R':
    if (memEQ(name, "SH_DENYW", 8)) {
    /*                       R     */
#ifdef SH_DENYWR
      *iv_return = SH_DENYWR;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'W':
    if (memEQ(name, "SH_DENYR", 8)) {
    /*                       W     */
#ifdef SH_DENYRW
      *iv_return = SH_DENYRW;
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

#!C:\perl5\bin\perl.exe -w
use ExtUtils::Constant qw (constant_types C_constant XS_constant);

my $types = {map {($_, 1)} qw(IV UV)};
my @names = (qw(O_APPEND O_BINARY O_CREAT O_EXCL O_NOINHERIT O_RANDOM O_RAW
	       O_RDONLY O_RDWR O_SEQUENTIAL O_SHORT_LIVED O_TEMPORARY O_TEXT
	       O_TRUNC O_WRONLY SH_DENYNO SH_DENYRD SH_DENYRW SH_DENYWR S_IREAD
	       S_IWRITE),
            {name=>"INFINITE", type=>"UV"});

print constant_types(); # macro defs
foreach (C_constant ("Win32::SharedFileOpen", 'constant', 'IV', $types, undef, 3, @names) ) {
    print $_, "\n"; # C constant subs
}
print "#### XS Section:\n";
print XS_constant ("Win32::SharedFileOpen", $types);
__END__
   */

  switch (len) {
  case 5:
    if (memEQ(name, "O_RAW", 5)) {
#ifdef O_RAW
      *iv_return = O_RAW;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 6:
    return constant_6 (aTHX_ name, iv_return);
    break;
  case 7:
    return constant_7 (aTHX_ name, iv_return);
    break;
  case 8:
    return constant_8 (aTHX_ name, iv_return);
    break;
  case 9:
    return constant_9 (aTHX_ name, iv_return);
    break;
  case 11:
    /* Names all of length 11.  */
    /* O_NOINHERIT O_TEMPORARY */
    /* Offset 5 gives the best switch position.  */
    switch (name[5]) {
    case 'N':
      if (memEQ(name, "O_NOINHERIT", 11)) {
      /*                    ^            */
#ifdef O_NOINHERIT
        *iv_return = O_NOINHERIT;
        return PERL_constant_ISIV;
#else
        return PERL_constant_NOTDEF;
#endif
      }
      break;
    case 'P':
      if (memEQ(name, "O_TEMPORARY", 11)) {
      /*                    ^            */
#ifdef O_TEMPORARY
        *iv_return = O_TEMPORARY;
        return PERL_constant_ISIV;
#else
        return PERL_constant_NOTDEF;
#endif
      }
      break;
    }
    break;
  case 12:
    if (memEQ(name, "O_SEQUENTIAL", 12)) {
#ifdef O_SEQUENTIAL
      *iv_return = O_SEQUENTIAL;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 13:
    if (memEQ(name, "O_SHORT_LIVED", 13)) {
#ifdef O_SHORT_LIVED
      *iv_return = O_SHORT_LIVED;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

