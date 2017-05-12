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
constant_19 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     CHM_ENUMERATE_FILES CHM_RESOLVE_FAILURE CHM_RESOLVE_SUCCESS */
  /* Offset 14 gives the best switch position.  */
  switch (name[14]) {
  case 'C':
    if (memEQ(name, "CHM_RESOLVE_SUCCESS", 19)) {
    /*                             ^           */
#ifdef CHM_RESOLVE_SUCCESS
      *iv_return = CHM_RESOLVE_SUCCESS;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'F':
    if (memEQ(name, "CHM_ENUMERATE_FILES", 19)) {
    /*                             ^           */
#ifdef CHM_ENUMERATE_FILES
      *iv_return = CHM_ENUMERATE_FILES;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'I':
    if (memEQ(name, "CHM_RESOLVE_FAILURE", 19)) {
    /*                             ^           */
#ifdef CHM_RESOLVE_FAILURE
      *iv_return = CHM_RESOLVE_FAILURE;
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

#!C:\strawberry-perl\perl\bin\perl.exe -w
use ExtUtils::Constant qw (constant_types C_constant XS_constant);

my $types = {map {($_, 1)} qw(IV)};
my @names = (qw(CHM_COMPRESSED CHM_ENUMERATE_ALL CHM_ENUMERATE_DIRS
	       CHM_ENUMERATE_FILES CHM_ENUMERATE_META CHM_ENUMERATE_NORMAL
	       CHM_ENUMERATE_SPECIAL CHM_ENUMERATOR_CONTINUE
	       CHM_ENUMERATOR_FAILURE CHM_ENUMERATOR_SUCCESS CHM_MAX_PATHLEN
	       CHM_PARAM_MAX_BLOCKS_CACHED CHM_RESOLVE_FAILURE
	       CHM_RESOLVE_SUCCESS CHM_UNCOMPRESSED));

print constant_types(); # macro defs
foreach (C_constant ("cmt::libchm", 'constant', 'IV', $types, undef, 3, @names) ) {
    print $_, "\n"; # C constant subs
}
print "#### XS Section:\n";
print XS_constant ("cmt::libchm", $types);
__END__
   */

  switch (len) {
  case 14:
    if (memEQ(name, "CHM_COMPRESSED", 14)) {
#ifdef CHM_COMPRESSED
      *iv_return = CHM_COMPRESSED;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 15:
    if (memEQ(name, "CHM_MAX_PATHLEN", 15)) {
#ifdef CHM_MAX_PATHLEN
      *iv_return = CHM_MAX_PATHLEN;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 16:
    if (memEQ(name, "CHM_UNCOMPRESSED", 16)) {
#ifdef CHM_UNCOMPRESSED
      *iv_return = CHM_UNCOMPRESSED;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 17:
    if (memEQ(name, "CHM_ENUMERATE_ALL", 17)) {
#ifdef CHM_ENUMERATE_ALL
      *iv_return = CHM_ENUMERATE_ALL;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 18:
    /* Names all of length 18.  */
    /* CHM_ENUMERATE_DIRS CHM_ENUMERATE_META */
    /* Offset 16 gives the best switch position.  */
    switch (name[16]) {
    case 'R':
      if (memEQ(name, "CHM_ENUMERATE_DIRS", 18)) {
      /*                               ^        */
#ifdef CHM_ENUMERATE_DIRS
        *iv_return = CHM_ENUMERATE_DIRS;
        return PERL_constant_ISIV;
#else
        return PERL_constant_NOTDEF;
#endif
      }
      break;
    case 'T':
      if (memEQ(name, "CHM_ENUMERATE_META", 18)) {
      /*                               ^        */
#ifdef CHM_ENUMERATE_META
        *iv_return = CHM_ENUMERATE_META;
        return PERL_constant_ISIV;
#else
        return PERL_constant_NOTDEF;
#endif
      }
      break;
    }
    break;
  case 19:
    return constant_19 (aTHX_ name, iv_return);
    break;
  case 20:
    if (memEQ(name, "CHM_ENUMERATE_NORMAL", 20)) {
#ifdef CHM_ENUMERATE_NORMAL
      *iv_return = CHM_ENUMERATE_NORMAL;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 21:
    if (memEQ(name, "CHM_ENUMERATE_SPECIAL", 21)) {
#ifdef CHM_ENUMERATE_SPECIAL
      *iv_return = CHM_ENUMERATE_SPECIAL;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 22:
    /* Names all of length 22.  */
    /* CHM_ENUMERATOR_FAILURE CHM_ENUMERATOR_SUCCESS */
    /* Offset 20 gives the best switch position.  */
    switch (name[20]) {
    case 'R':
      if (memEQ(name, "CHM_ENUMERATOR_FAILURE", 22)) {
      /*                                   ^        */
#ifdef CHM_ENUMERATOR_FAILURE
        *iv_return = CHM_ENUMERATOR_FAILURE;
        return PERL_constant_ISIV;
#else
        return PERL_constant_NOTDEF;
#endif
      }
      break;
    case 'S':
      if (memEQ(name, "CHM_ENUMERATOR_SUCCESS", 22)) {
      /*                                   ^        */
#ifdef CHM_ENUMERATOR_SUCCESS
        *iv_return = CHM_ENUMERATOR_SUCCESS;
        return PERL_constant_ISIV;
#else
        return PERL_constant_NOTDEF;
#endif
      }
      break;
    }
    break;
  case 23:
    if (memEQ(name, "CHM_ENUMERATOR_CONTINUE", 23)) {
#ifdef CHM_ENUMERATOR_CONTINUE
      *iv_return = CHM_ENUMERATOR_CONTINUE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 27:
    if (memEQ(name, "CHM_PARAM_MAX_BLOCKS_CACHED", 27)) {
#ifdef CHM_PARAM_MAX_BLOCKS_CACHED
      *iv_return = CHM_PARAM_MAX_BLOCKS_CACHED;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

