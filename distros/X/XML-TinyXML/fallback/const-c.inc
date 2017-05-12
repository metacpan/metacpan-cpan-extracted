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
my @names = (qw(XML_BADARGS XML_GENERIC_ERR XML_LINKLIST_ERR XML_MEMORY_ERR
	       XML_NOERR XML_OPEN_FILE_ERR XML_PARSER_GENERIC_ERR
	       XML_UPDATE_ERR));

print constant_types(); # macro defs
foreach (C_constant ("TinyXML", 'constant', 'IV', $types, undef, 3, @names) ) {
    print $_, "\n"; # C constant subs
}
print "#### XS Section:\n";
print XS_constant ("TinyXML", $types);
__END__
   */

  switch (len) {
  case 9:
    if (memEQ(name, "XML_NOERR", 9)) {
#ifdef XML_NOERR
      *iv_return = XML_NOERR;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 11:
    if (memEQ(name, "XML_BADARGS", 11)) {
#ifdef XML_BADARGS
      *iv_return = XML_BADARGS;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 14:
    /* Names all of length 14.  */
    /* XML_MEMORY_ERR XML_UPDATE_ERR */
    /* Offset 8 gives the best switch position.  */
    switch (name[8]) {
    case 'R':
      if (memEQ(name, "XML_MEMORY_ERR", 14)) {
      /*                       ^            */
#ifdef XML_MEMORY_ERR
        *iv_return = XML_MEMORY_ERR;
        return PERL_constant_ISIV;
#else
        return PERL_constant_NOTDEF;
#endif
      }
      break;
    case 'T':
      if (memEQ(name, "XML_UPDATE_ERR", 14)) {
      /*                       ^            */
#ifdef XML_UPDATE_ERR
        *iv_return = XML_UPDATE_ERR;
        return PERL_constant_ISIV;
#else
        return PERL_constant_NOTDEF;
#endif
      }
      break;
    }
    break;
  case 15:
    if (memEQ(name, "XML_GENERIC_ERR", 15)) {
#ifdef XML_GENERIC_ERR
      *iv_return = XML_GENERIC_ERR;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 16:
    if (memEQ(name, "XML_LINKLIST_ERR", 16)) {
#ifdef XML_LINKLIST_ERR
      *iv_return = XML_LINKLIST_ERR;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 17:
    if (memEQ(name, "XML_OPEN_FILE_ERR", 17)) {
#ifdef XML_OPEN_FILE_ERR
      *iv_return = XML_OPEN_FILE_ERR;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 22:
    if (memEQ(name, "XML_PARSER_GENERIC_ERR", 22)) {
#ifdef XML_PARSER_GENERIC_ERR
      *iv_return = XML_PARSER_GENERIC_ERR;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

