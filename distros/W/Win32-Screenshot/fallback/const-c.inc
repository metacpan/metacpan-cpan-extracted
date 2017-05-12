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
constant_11 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     GW_HWNDLAST GW_HWNDNEXT GW_HWNDPREV SW_MAXIMIZE SW_MINIMIZE */
  /* Offset 7 gives the best switch position.  */
  switch (name[7]) {
  case 'L':
    if (memEQ(name, "GW_HWNDLAST", 11)) {
    /*                      ^          */
#ifdef GW_HWNDLAST
      *iv_return = GW_HWNDLAST;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'M':
    if (memEQ(name, "SW_MAXIMIZE", 11)) {
    /*                      ^          */
#ifdef SW_MAXIMIZE
      *iv_return = SW_MAXIMIZE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "SW_MINIMIZE", 11)) {
    /*                      ^          */
#ifdef SW_MINIMIZE
      *iv_return = SW_MINIMIZE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'N':
    if (memEQ(name, "GW_HWNDNEXT", 11)) {
    /*                      ^          */
#ifdef GW_HWNDNEXT
      *iv_return = GW_HWNDNEXT;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'P':
    if (memEQ(name, "GW_HWNDPREV", 11)) {
    /*                      ^          */
#ifdef GW_HWNDPREV
      *iv_return = GW_HWNDPREV;
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

#!C:\intraNet\Perl\bin\perl.exe -w
use ExtUtils::Constant qw (constant_types C_constant XS_constant);

my $types = {map {($_, 1)} qw(IV)};
my @names = (qw(GW_CHILD GW_HWNDFIRST GW_HWNDLAST GW_HWNDNEXT GW_HWNDPREV
	       GW_OWNER SW_HIDE SW_MAXIMIZE SW_MINIMIZE SW_RESTORE SW_SHOW
	       SW_SHOWDEFAULT SW_SHOWMAXIMIZED SW_SHOWMINIMIZED
	       SW_SHOWMINNOACTIVE SW_SHOWNA SW_SHOWNOACTIVATE SW_SHOWNORMAL));

print constant_types(); # macro defs
foreach (C_constant ("Win32::Screenshot", 'constant', 'IV', $types, undef, 3, @names) ) {
    print $_, "\n"; # C constant subs
}
print "#### XS Section:\n";
print XS_constant ("Win32::Screenshot", $types);
__END__
   */

  switch (len) {
  case 7:
    /* Names all of length 7.  */
    /* SW_HIDE SW_SHOW */
    /* Offset 4 gives the best switch position.  */
    switch (name[4]) {
    case 'H':
      if (memEQ(name, "SW_SHOW", 7)) {
      /*                   ^        */
#ifdef SW_SHOW
        *iv_return = SW_SHOW;
        return PERL_constant_ISIV;
#else
        return PERL_constant_NOTDEF;
#endif
      }
      break;
    case 'I':
      if (memEQ(name, "SW_HIDE", 7)) {
      /*                   ^        */
#ifdef SW_HIDE
        *iv_return = SW_HIDE;
        return PERL_constant_ISIV;
#else
        return PERL_constant_NOTDEF;
#endif
      }
      break;
    }
    break;
  case 8:
    /* Names all of length 8.  */
    /* GW_CHILD GW_OWNER */
    /* Offset 5 gives the best switch position.  */
    switch (name[5]) {
    case 'I':
      if (memEQ(name, "GW_CHILD", 8)) {
      /*                    ^        */
#ifdef GW_CHILD
        *iv_return = GW_CHILD;
        return PERL_constant_ISIV;
#else
        return PERL_constant_NOTDEF;
#endif
      }
      break;
    case 'N':
      if (memEQ(name, "GW_OWNER", 8)) {
      /*                    ^        */
#ifdef GW_OWNER
        *iv_return = GW_OWNER;
        return PERL_constant_ISIV;
#else
        return PERL_constant_NOTDEF;
#endif
      }
      break;
    }
    break;
  case 9:
    if (memEQ(name, "SW_SHOWNA", 9)) {
#ifdef SW_SHOWNA
      *iv_return = SW_SHOWNA;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 10:
    if (memEQ(name, "SW_RESTORE", 10)) {
#ifdef SW_RESTORE
      *iv_return = SW_RESTORE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 11:
    return constant_11 (aTHX_ name, iv_return);
    break;
  case 12:
    if (memEQ(name, "GW_HWNDFIRST", 12)) {
#ifdef GW_HWNDFIRST
      *iv_return = GW_HWNDFIRST;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 13:
    if (memEQ(name, "SW_SHOWNORMAL", 13)) {
#ifdef SW_SHOWNORMAL
      *iv_return = SW_SHOWNORMAL;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 14:
    if (memEQ(name, "SW_SHOWDEFAULT", 14)) {
#ifdef SW_SHOWDEFAULT
      *iv_return = SW_SHOWDEFAULT;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 16:
    /* Names all of length 16.  */
    /* SW_SHOWMAXIMIZED SW_SHOWMINIMIZED */
    /* Offset 8 gives the best switch position.  */
    switch (name[8]) {
    case 'A':
      if (memEQ(name, "SW_SHOWMAXIMIZED", 16)) {
      /*                       ^              */
#ifdef SW_SHOWMAXIMIZED
        *iv_return = SW_SHOWMAXIMIZED;
        return PERL_constant_ISIV;
#else
        return PERL_constant_NOTDEF;
#endif
      }
      break;
    case 'I':
      if (memEQ(name, "SW_SHOWMINIMIZED", 16)) {
      /*                       ^              */
#ifdef SW_SHOWMINIMIZED
        *iv_return = SW_SHOWMINIMIZED;
        return PERL_constant_ISIV;
#else
        return PERL_constant_NOTDEF;
#endif
      }
      break;
    }
    break;
  case 17:
    if (memEQ(name, "SW_SHOWNOACTIVATE", 17)) {
#ifdef SW_SHOWNOACTIVATE
      *iv_return = SW_SHOWNOACTIVATE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 18:
    if (memEQ(name, "SW_SHOWMINNOACTIVE", 18)) {
#ifdef SW_SHOWMINNOACTIVE
      *iv_return = SW_SHOWMINNOACTIVE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}
