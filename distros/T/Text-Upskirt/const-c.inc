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
     MKDA_NOT_AUTOLINK MKD_TABLE_ALIGN_L MKD_TABLE_ALIGN_R UPSKIRT_VER_MAJOR
     UPSKIRT_VER_MINOR */
  /* Offset 13 gives the best switch position.  */
  switch (name[13]) {
  case 'A':
    if (memEQ(name, "UPSKIRT_VER_MAJOR", 17)) {
    /*                            ^          */
#ifdef UPSKIRT_VER_MAJOR
      *iv_return = UPSKIRT_VER_MAJOR;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'G':
    if (memEQ(name, "MKD_TABLE_ALIGN_L", 17)) {
    /*                            ^          */
#ifdef MKD_TABLE_ALIGN_L
      *iv_return = MKD_TABLE_ALIGN_L;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "MKD_TABLE_ALIGN_R", 17)) {
    /*                            ^          */
#ifdef MKD_TABLE_ALIGN_R
      *iv_return = MKD_TABLE_ALIGN_R;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'I':
    if (memEQ(name, "UPSKIRT_VER_MINOR", 17)) {
    /*                            ^          */
#ifdef UPSKIRT_VER_MINOR
      *iv_return = UPSKIRT_VER_MINOR;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'L':
    if (memEQ(name, "MKDA_NOT_AUTOLINK", 17)) {
    /*                            ^          */
      *iv_return = MKDA_NOT_AUTOLINK;
      return PERL_constant_ISIV;
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

static int
constant_20 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     MKDEXT_SPACE_HEADERS MKDEXT_STRIKETHROUGH UPSKIRT_VER_REVISION */
  /* Offset 8 gives the best switch position.  */
  switch (name[8]) {
  case 'P':
    if (memEQ(name, "MKDEXT_SPACE_HEADERS", 20)) {
    /*                       ^                  */
      *iv_return = MKDEXT_SPACE_HEADERS;
      return PERL_constant_ISIV;
    }
    break;
  case 'T':
    if (memEQ(name, "MKDEXT_STRIKETHROUGH", 20)) {
    /*                       ^                  */
      *iv_return = MKDEXT_STRIKETHROUGH;
      return PERL_constant_ISIV;
    }
    break;
  case 'V':
    if (memEQ(name, "UPSKIRT_VER_REVISION", 20)) {
    /*                       ^                  */
#ifdef UPSKIRT_VER_REVISION
      *iv_return = UPSKIRT_VER_REVISION;
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

#!/usr/bin/perl5.12.3 -w
use ExtUtils::Constant qw (constant_types C_constant XS_constant);

my $types = {map {($_, 1)} qw(IV)};
my @names = (qw(MKD_LIST_ORDERED MKD_LI_BLOCK MKD_TABLE_ALIGN_CENTER
	       MKD_TABLE_ALIGN_L MKD_TABLE_ALIGN_R UPSKIRT_VER_MAJOR
	       UPSKIRT_VER_MINOR UPSKIRT_VER_REVISION),
            {name=>"MKDA_EMAIL", type=>"IV", macro=>"1"},
            {name=>"MKDA_NORMAL", type=>"IV", macro=>"1"},
            {name=>"MKDA_NOT_AUTOLINK", type=>"IV", macro=>"1"},
            {name=>"MKDEXT_AUTOLINK", type=>"IV", macro=>"1"},
            {name=>"MKDEXT_FENCED_CODE", type=>"IV", macro=>"1"},
            {name=>"MKDEXT_LAX_HTML_BLOCKS", type=>"IV", macro=>"1"},
            {name=>"MKDEXT_NO_INTRA_EMPHASIS", type=>"IV", macro=>"1"},
            {name=>"MKDEXT_SPACE_HEADERS", type=>"IV", macro=>"1"},
            {name=>"MKDEXT_STRIKETHROUGH", type=>"IV", macro=>"1"},
            {name=>"MKDEXT_TABLES", type=>"IV", macro=>"1"});

print constant_types(), "\n"; # macro defs
foreach (C_constant ("Text::Upskirt::Markdown", 'constant', 'IV', $types, undef, 3, @names) ) {
    print $_, "\n"; # C constant subs
}
print "\n#### XS Section:\n";
print XS_constant ("Text::Upskirt::Markdown", $types);
__END__
   */

  switch (len) {
  case 10:
    if (memEQ(name, "MKDA_EMAIL", 10)) {
      *iv_return = MKDA_EMAIL;
      return PERL_constant_ISIV;
    }
    break;
  case 11:
    if (memEQ(name, "MKDA_NORMAL", 11)) {
      *iv_return = MKDA_NORMAL;
      return PERL_constant_ISIV;
    }
    break;
  case 12:
    if (memEQ(name, "MKD_LI_BLOCK", 12)) {
#ifdef MKD_LI_BLOCK
      *iv_return = MKD_LI_BLOCK;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 13:
    if (memEQ(name, "MKDEXT_TABLES", 13)) {
      *iv_return = MKDEXT_TABLES;
      return PERL_constant_ISIV;
    }
    break;
  case 15:
    if (memEQ(name, "MKDEXT_AUTOLINK", 15)) {
      *iv_return = MKDEXT_AUTOLINK;
      return PERL_constant_ISIV;
    }
    break;
  case 16:
    if (memEQ(name, "MKD_LIST_ORDERED", 16)) {
#ifdef MKD_LIST_ORDERED
      *iv_return = MKD_LIST_ORDERED;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 17:
    return constant_17 (aTHX_ name, iv_return);
    break;
  case 18:
    if (memEQ(name, "MKDEXT_FENCED_CODE", 18)) {
      *iv_return = MKDEXT_FENCED_CODE;
      return PERL_constant_ISIV;
    }
    break;
  case 20:
    return constant_20 (aTHX_ name, iv_return);
    break;
  case 22:
    /* Names all of length 22.  */
    /* MKDEXT_LAX_HTML_BLOCKS MKD_TABLE_ALIGN_CENTER */
    /* Offset 21 gives the best switch position.  */
    switch (name[21]) {
    case 'R':
      if (memEQ(name, "MKD_TABLE_ALIGN_CENTE", 21)) {
      /*                                    R      */
#ifdef MKD_TABLE_ALIGN_CENTER
        *iv_return = MKD_TABLE_ALIGN_CENTER;
        return PERL_constant_ISIV;
#else
        return PERL_constant_NOTDEF;
#endif
      }
      break;
    case 'S':
      if (memEQ(name, "MKDEXT_LAX_HTML_BLOCK", 21)) {
      /*                                    S      */
        *iv_return = MKDEXT_LAX_HTML_BLOCKS;
        return PERL_constant_ISIV;
      }
      break;
    }
    break;
  case 24:
    if (memEQ(name, "MKDEXT_NO_INTRA_EMPHASIS", 24)) {
      *iv_return = MKDEXT_NO_INTRA_EMPHASIS;
      return PERL_constant_ISIV;
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

