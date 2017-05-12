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
constant_13 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     FOF_ALLOWUNDO FOF_FILESONLY FOF_NOERRORUI */
  /* Offset 8 gives the best switch position.  */
  switch (name[8]) {
  case 'R':
    if (memEQ(name, "FOF_NOERRORUI", 13)) {
    /*                       ^           */
#ifdef FOF_NOERRORUI
      *iv_return = FOF_NOERRORUI;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'S':
    if (memEQ(name, "FOF_FILESONLY", 13)) {
    /*                       ^           */
#ifdef FOF_FILESONLY
      *iv_return = FOF_FILESONLY;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'W':
    if (memEQ(name, "FOF_ALLOWUNDO", 13)) {
    /*                       ^           */
#ifdef FOF_ALLOWUNDO
      *iv_return = FOF_ALLOWUNDO;
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
constant_18 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     FOF_MULTIDESTFILES FOF_NOCONFIRMATION FOF_NOCONFIRMMKDIR
     FOF_RECURSEREPARSE FOF_SIMPLEPROGRESS */
  /* Offset 15 gives the best switch position.  */
  switch (name[15]) {
  case 'D':
    if (memEQ(name, "FOF_NOCONFIRMMKDIR", 18)) {
    /*                              ^         */
#ifdef FOF_NOCONFIRMMKDIR
      *iv_return = FOF_NOCONFIRMMKDIR;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'E':
    if (memEQ(name, "FOF_SIMPLEPROGRESS", 18)) {
    /*                              ^         */
#ifdef FOF_SIMPLEPROGRESS
      *iv_return = FOF_SIMPLEPROGRESS;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'I':
    if (memEQ(name, "FOF_NOCONFIRMATION", 18)) {
    /*                              ^         */
#ifdef FOF_NOCONFIRMATION
      *iv_return = FOF_NOCONFIRMATION;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'L':
    if (memEQ(name, "FOF_MULTIDESTFILES", 18)) {
    /*                              ^         */
#ifdef FOF_MULTIDESTFILES
      *iv_return = FOF_MULTIDESTFILES;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'R':
    if (memEQ(name, "FOF_RECURSEREPARSE", 18)) {
    /*                              ^         */
#ifdef FOF_RECURSEREPARSE
      *iv_return = FOF_RECURSEREPARSE;
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
constant (pTHX_ const char *name, STRLEN len, IV *iv_return, const char **pv_return) {
  /* Initially switch on the length of the name.  */
  /* When generated this function returned values for the list of names given
     in this section of perl code.  Rather than manually editing these functions
     to add or remove constants, which would result in this comment and section
     of code becoming inaccurate, we recommend that you edit this section of
     code, and use it to regenerate a new set of constant functions which you
     then use to replace the originals.

     Regenerate these constant functions by feeding this entire source file to
     perl -x

#!C:\Perl\bin\perl.exe -w
use ExtUtils::Constant qw (constant_types C_constant XS_constant);

my $types = {map {($_, 1)} qw(IV PV)};
my @names = (qw(FOF_ALLOWUNDO FOF_CONFIRMMOUSE FOF_FILESONLY FOF_MULTIDESTFILES
	       FOF_NOCONFIRMATION FOF_NOCONFIRMMKDIR FOF_NOCOPYSECURITYATTRIBS
	       FOF_NOERRORUI FOF_NORECURSEREPARSE FOF_NORECURSION
	       FOF_NO_CONNECTED_ELEMENTS FOF_RECURSEREPARSE
	       FOF_RENAMEONCOLLISION FOF_SILENT FOF_SIMPLEPROGRESS
	       FOF_WANTMAPPINGHANDLE FOF_WANTNUKEWARNING FO_COPY FO_DELETE
	       FO_MOVE FO_RENAME IDCANCEL IDNO IDYES));

print constant_types(); # macro defs
foreach (C_constant ("CopyHook", 'constant', 'IV', $types, undef, 3, @names) ) {
    print $_, "\n"; # C constant subs
}
print "#### XS Section:\n";
print XS_constant ("CopyHook", $types);
__END__
   */

  switch (len) {
  case 4:
    if (memEQ(name, "IDNO", 4)) {
#ifdef IDNO
      *iv_return = IDNO;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 5:
    if (memEQ(name, "IDYES", 5)) {
#ifdef IDYES
      *iv_return = IDYES;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 7:
    /* Names all of length 7.  */
    /* FO_COPY FO_MOVE */
    /* Offset 5 gives the best switch position.  */
    switch (name[5]) {
    case 'P':
      if (memEQ(name, "FO_COPY", 7)) {
      /*                    ^       */
#ifdef FO_COPY
        *iv_return = FO_COPY;
        return PERL_constant_ISIV;
#else
        return PERL_constant_NOTDEF;
#endif
      }
      break;
    case 'V':
      if (memEQ(name, "FO_MOVE", 7)) {
      /*                    ^       */
#ifdef FO_MOVE
        *iv_return = FO_MOVE;
        return PERL_constant_ISIV;
#else
        return PERL_constant_NOTDEF;
#endif
      }
      break;
    }
    break;
  case 8:
    if (memEQ(name, "IDCANCEL", 8)) {
#ifdef IDCANCEL
      *iv_return = IDCANCEL;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 9:
    /* Names all of length 9.  */
    /* FO_DELETE FO_RENAME */
    /* Offset 5 gives the best switch position.  */
    switch (name[5]) {
    case 'L':
      if (memEQ(name, "FO_DELETE", 9)) {
      /*                    ^         */
#ifdef FO_DELETE
        *iv_return = FO_DELETE;
        return PERL_constant_ISIV;
#else
        return PERL_constant_NOTDEF;
#endif
      }
      break;
    case 'N':
      if (memEQ(name, "FO_RENAME", 9)) {
      /*                    ^         */
#ifdef FO_RENAME
        *iv_return = FO_RENAME;
        return PERL_constant_ISIV;
#else
        return PERL_constant_NOTDEF;
#endif
      }
      break;
    }
    break;
  case 10:
    if (memEQ(name, "FOF_SILENT", 10)) {
#ifdef FOF_SILENT
      *iv_return = FOF_SILENT;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 13:
    return constant_13 (aTHX_ name, iv_return);
    break;
  case 15:
    if (memEQ(name, "FOF_NORECURSION", 15)) {
#ifdef FOF_NORECURSION
      *iv_return = FOF_NORECURSION;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 16:
    if (memEQ(name, "FOF_CONFIRMMOUSE", 16)) {
#ifdef FOF_CONFIRMMOUSE
      *iv_return = FOF_CONFIRMMOUSE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 18:
    return constant_18 (aTHX_ name, iv_return);
    break;
  case 19:
    if (memEQ(name, "FOF_WANTNUKEWARNING", 19)) {
#ifdef FOF_WANTNUKEWARNING
      *iv_return = FOF_WANTNUKEWARNING;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 20:
    if (memEQ(name, "FOF_NORECURSEREPARSE", 20)) {
#ifdef FOF_NORECURSEREPARSE
      *iv_return = FOF_NORECURSEREPARSE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 21:
    /* Names all of length 21.  */
    /* FOF_RENAMEONCOLLISION FOF_WANTMAPPINGHANDLE */
    /* Offset 10 gives the best switch position.  */
    switch (name[10]) {
    case 'O':
      if (memEQ(name, "FOF_RENAMEONCOLLISION", 21)) {
      /*                         ^                 */
#ifdef FOF_RENAMEONCOLLISION
        *iv_return = FOF_RENAMEONCOLLISION;
        return PERL_constant_ISIV;
#else
        return PERL_constant_NOTDEF;
#endif
      }
      break;
    case 'P':
      if (memEQ(name, "FOF_WANTMAPPINGHANDLE", 21)) {
      /*                         ^                 */
#ifdef FOF_WANTMAPPINGHANDLE
        *iv_return = FOF_WANTMAPPINGHANDLE;
        return PERL_constant_ISIV;
#else
        return PERL_constant_NOTDEF;
#endif
      }
      break;
    }
    break;
  case 25:
    /* Names all of length 25.  */
    /* FOF_NOCOPYSECURITYATTRIBS FOF_NO_CONNECTED_ELEMENTS */
    /* Offset 8 gives the best switch position.  */
    switch (name[8]) {
    case 'O':
      if (memEQ(name, "FOF_NO_CONNECTED_ELEMENTS", 25)) {
      /*                       ^                       */
#ifdef FOF_NO_CONNECTED_ELEMENTS
        *iv_return = FOF_NO_CONNECTED_ELEMENTS;
        return PERL_constant_ISIV;
#else
        return PERL_constant_NOTDEF;
#endif
      }
      break;
    case 'P':
      if (memEQ(name, "FOF_NOCOPYSECURITYATTRIBS", 25)) {
      /*                       ^                       */
#ifdef FOF_NOCOPYSECURITYATTRIBS
        *iv_return = FOF_NOCOPYSECURITYATTRIBS;
        return PERL_constant_ISIV;
#else
        return PERL_constant_NOTDEF;
#endif
      }
      break;
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}
