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
     CMS__ALL CMS__BUG CMS__EOF */
  /* Offset 5 gives the best switch position.  */
  switch (name[5]) {
  case 'A':
    if (memEQ(name, "CMS__ALL", 8)) {
    /*                    ^        */
#ifdef CMS$_ALL
      *iv_return = CMS$_ALL;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'B':
    if (memEQ(name, "CMS__BUG", 8)) {
    /*                    ^        */
#ifdef CMS$_BUG
      *iv_return = CMS$_BUG;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'E':
    if (memEQ(name, "CMS__EOF", 8)) {
    /*                    ^        */
#ifdef CMS$_EOF
      *iv_return = CMS$_EOF;
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
constant_10 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     CMS_K_MARK CMS_M_BYTE CMS_M_WORD CMS__INUSE CMS__LIBIS CMS__MARKS
     CMS__NOACE CMS__NOCLS CMS__NOCMD CMS__NOELE CMS__NOGRP CMS__NOHIS
     CMS__NOOBJ CMS__NOREF CMS__NORES CMS__NOREV */
  /* Offset 8 gives the best switch position.  */
  switch (name[8]) {
  case 'B':
    if (memEQ(name, "CMS__NOOBJ", 10)) {
    /*                       ^        */
#ifdef CMS$_NOOBJ
      *iv_return = CMS$_NOOBJ;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'C':
    if (memEQ(name, "CMS__NOACE", 10)) {
    /*                       ^        */
#ifdef CMS$_NOACE
      *iv_return = CMS$_NOACE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'E':
    if (memEQ(name, "CMS__NOREF", 10)) {
    /*                       ^        */
#ifdef CMS$_NOREF
      *iv_return = CMS$_NOREF;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "CMS__NORES", 10)) {
    /*                       ^        */
#ifdef CMS$_NORES
      *iv_return = CMS$_NORES;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "CMS__NOREV", 10)) {
    /*                       ^        */
#ifdef CMS$_NOREV
      *iv_return = CMS$_NOREV;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'I':
    if (memEQ(name, "CMS__LIBIS", 10)) {
    /*                       ^        */
#ifdef CMS$_LIBIS
      *iv_return = CMS$_LIBIS;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "CMS__NOHIS", 10)) {
    /*                       ^        */
#ifdef CMS$_NOHIS
      *iv_return = CMS$_NOHIS;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'K':
    if (memEQ(name, "CMS__MARKS", 10)) {
    /*                       ^        */
#ifdef CMS$_MARKS
      *iv_return = CMS$_MARKS;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'L':
    if (memEQ(name, "CMS__NOCLS", 10)) {
    /*                       ^        */
#ifdef CMS$_NOCLS
      *iv_return = CMS$_NOCLS;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "CMS__NOELE", 10)) {
    /*                       ^        */
#ifdef CMS$_NOELE
      *iv_return = CMS$_NOELE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'M':
    if (memEQ(name, "CMS__NOCMD", 10)) {
    /*                       ^        */
#ifdef CMS$_NOCMD
      *iv_return = CMS$_NOCMD;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'R':
    if (memEQ(name, "CMS_K_MARK", 10)) {
    /*                       ^        */
#ifdef CMS$K_MARK
      *iv_return = CMS$K_MARK;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "CMS_M_WORD", 10)) {
    /*                       ^        */
#ifdef CMS$K_WORD
      *iv_return = CMS$K_WORD;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "CMS__NOGRP", 10)) {
    /*                       ^        */
#ifdef CMS$_NOGRP
      *iv_return = CMS$_NOGRP;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'S':
    if (memEQ(name, "CMS__INUSE", 10)) {
    /*                       ^        */
#ifdef CMS$_INUSE
      *iv_return = CMS$_INUSE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'T':
    if (memEQ(name, "CMS_M_BYTE", 10)) {
    /*                       ^        */
#ifdef CMS$K_BYTE
      *iv_return = CMS$K_BYTE;
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
     CMS_K_AFTER CMS_M_ASCII CMS_M_OCTAL CMS__ABSTIM CMS__BADBUG CMS__BADCRC
     CMS__BADLIB CMS__BADLST CMS__BADPTR CMS__BADREF CMS__CNTSTR CMS__CONCLS
     CMS__CONELE CMS__CONGRP CMS__CONHIS CMS__CONRES CMS__COPIED CMS__COPIES
     CMS__DUPEDF CMS__DUPREF CMS__ELEEXP CMS__FIXCRC CMS__FIXHDR CMS__ILLACT
     CMS__ILLGEN CMS__ILLPAR CMS__ILLRMK CMS__ILLSEQ CMS__ILLVAR CMS__LIBSET
     CMS__MARKED CMS__MAXARG CMS__MERGED CMS__MINARG CMS__MODACL CMS__MUTEXC
     CMS__NOCOPY CMS__NOFILE CMS__NOGENS CMS__NOMARK CMS__NORMAL CMS__NOTSET
     CMS__OPENIN CMS__READIN CMS__RECGRP CMS__REMARK CMS__REPCMD CMS__REPDEL
     CMS__REPEDF CMS__REPREF CMS__UNFOUT CMS__VERARC CMS__VERCLS CMS__VERCMD
     CMS__VERCON CMS__VEREDF CMS__VERELE CMS__VERFRE CMS__VERGRP CMS__VERREF
     CMS__VERRES CMS__VERSTR */
  /* Offset 8 gives the best switch position.  */
  switch (name[8]) {
  case 'A':
    if (memEQ(name, "CMS__ILLACT", 11)) {
    /*                       ^         */
#ifdef CMS$_ILLACT
      *iv_return = CMS$_ILLACT;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "CMS__MAXARG", 11)) {
    /*                       ^         */
#ifdef CMS$_MAXARG
      *iv_return = CMS$_MAXARG;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "CMS__MINARG", 11)) {
    /*                       ^         */
#ifdef CMS$_MINARG
      *iv_return = CMS$_MINARG;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "CMS__MODACL", 11)) {
    /*                       ^         */
#ifdef CMS$_MODACL
      *iv_return = CMS$_MODACL;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "CMS__NOMARK", 11)) {
    /*                       ^         */
#ifdef CMS$_NOMARK
      *iv_return = CMS$_NOMARK;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "CMS__REMARK", 11)) {
    /*                       ^         */
#ifdef CMS$_REMARK
      *iv_return = CMS$_REMARK;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "CMS__VERARC", 11)) {
    /*                       ^         */
#ifdef CMS$_VERARC
      *iv_return = CMS$_VERARC;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'B':
    if (memEQ(name, "CMS__BADBUG", 11)) {
    /*                       ^         */
#ifdef CMS$_BADBUG
      *iv_return = CMS$_BADBUG;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'C':
    if (memEQ(name, "CMS_M_ASCII", 11)) {
    /*                       ^         */
#ifdef CMS$K_ASCII
      *iv_return = CMS$K_ASCII;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "CMS__BADCRC", 11)) {
    /*                       ^         */
#ifdef CMS$_BADCRC
      *iv_return = CMS$_BADCRC;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "CMS__CONCLS", 11)) {
    /*                       ^         */
#ifdef CMS$_CONCLS
      *iv_return = CMS$_CONCLS;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "CMS__FIXCRC", 11)) {
    /*                       ^         */
#ifdef CMS$_FIXCRC
      *iv_return = CMS$_FIXCRC;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "CMS__REPCMD", 11)) {
    /*                       ^         */
#ifdef CMS$_REPCMD
      *iv_return = CMS$_REPCMD;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "CMS__VERCLS", 11)) {
    /*                       ^         */
#ifdef CMS$_VERCLS
      *iv_return = CMS$_VERCLS;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "CMS__VERCMD", 11)) {
    /*                       ^         */
#ifdef CMS$_VERCMD
      *iv_return = CMS$_VERCMD;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "CMS__VERCON", 11)) {
    /*                       ^         */
#ifdef CMS$_VERCON
      *iv_return = CMS$_VERCON;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'D':
    if (memEQ(name, "CMS__READIN", 11)) {
    /*                       ^         */
#ifdef CMS$_READIN
      *iv_return = CMS$_READIN;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "CMS__REPDEL", 11)) {
    /*                       ^         */
#ifdef CMS$_REPDEL
      *iv_return = CMS$_REPDEL;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'E':
    if (memEQ(name, "CMS__CONELE", 11)) {
    /*                       ^         */
#ifdef CMS$_CONELE
      *iv_return = CMS$_CONELE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "CMS__DUPEDF", 11)) {
    /*                       ^         */
#ifdef CMS$_DUPEDF
      *iv_return = CMS$_DUPEDF;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "CMS__ELEEXP", 11)) {
    /*                       ^         */
#ifdef CMS$_ELEEXP
      *iv_return = CMS$_ELEEXP;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "CMS__MUTEXC", 11)) {
    /*                       ^         */
#ifdef CMS$_MUTEXC
      *iv_return = CMS$_MUTEXC;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "CMS__NOGENS", 11)) {
    /*                       ^         */
#ifdef CMS$_NOGENS
      *iv_return = CMS$_NOGENS;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "CMS__REPEDF", 11)) {
    /*                       ^         */
#ifdef CMS$_REPEDF
      *iv_return = CMS$_REPEDF;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "CMS__VEREDF", 11)) {
    /*                       ^         */
#ifdef CMS$_VEREDF
      *iv_return = CMS$_VEREDF;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "CMS__VERELE", 11)) {
    /*                       ^         */
#ifdef CMS$_VERELE
      *iv_return = CMS$_VERELE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'F':
    if (memEQ(name, "CMS__VERFRE", 11)) {
    /*                       ^         */
#ifdef CMS$_VERFRE
      *iv_return = CMS$_VERFRE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'G':
    if (memEQ(name, "CMS__CONGRP", 11)) {
    /*                       ^         */
#ifdef CMS$_CONGRP
      *iv_return = CMS$_CONGRP;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "CMS__ILLGEN", 11)) {
    /*                       ^         */
#ifdef CMS$_ILLGEN
      *iv_return = CMS$_ILLGEN;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "CMS__MERGED", 11)) {
    /*                       ^         */
#ifdef CMS$_MERGED
      *iv_return = CMS$_MERGED;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "CMS__RECGRP", 11)) {
    /*                       ^         */
#ifdef CMS$_RECGRP
      *iv_return = CMS$_RECGRP;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "CMS__VERGRP", 11)) {
    /*                       ^         */
#ifdef CMS$_VERGRP
      *iv_return = CMS$_VERGRP;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'H':
    if (memEQ(name, "CMS__CONHIS", 11)) {
    /*                       ^         */
#ifdef CMS$_CONHIS
      *iv_return = CMS$_CONHIS;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "CMS__FIXHDR", 11)) {
    /*                       ^         */
#ifdef CMS$_FIXHDR
      *iv_return = CMS$_FIXHDR;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'I':
    if (memEQ(name, "CMS__COPIED", 11)) {
    /*                       ^         */
#ifdef CMS$_COPIED
      *iv_return = CMS$_COPIED;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "CMS__COPIES", 11)) {
    /*                       ^         */
#ifdef CMS$_COPIES
      *iv_return = CMS$_COPIES;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "CMS__NOFILE", 11)) {
    /*                       ^         */
#ifdef CMS$_NOFILE
      *iv_return = CMS$_NOFILE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'K':
    if (memEQ(name, "CMS__MARKED", 11)) {
    /*                       ^         */
#ifdef CMS$_MARKED
      *iv_return = CMS$_MARKED;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'L':
    if (memEQ(name, "CMS__BADLIB", 11)) {
    /*                       ^         */
#ifdef CMS$_BADLIB
      *iv_return = CMS$_BADLIB;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "CMS__BADLST", 11)) {
    /*                       ^         */
#ifdef CMS$_BADLST
      *iv_return = CMS$_BADLST;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'M':
    if (memEQ(name, "CMS__NORMAL", 11)) {
    /*                       ^         */
#ifdef CMS$_NORMAL
      *iv_return = CMS$_NORMAL;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'N':
    if (memEQ(name, "CMS__OPENIN", 11)) {
    /*                       ^         */
#ifdef CMS$_OPENIN
      *iv_return = CMS$_OPENIN;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'O':
    if (memEQ(name, "CMS__NOCOPY", 11)) {
    /*                       ^         */
#ifdef CMS$_NOCOPY
      *iv_return = CMS$_NOCOPY;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "CMS__UNFOUT", 11)) {
    /*                       ^         */
#ifdef CMS$_UNFOUT
      *iv_return = CMS$_UNFOUT;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'P':
    if (memEQ(name, "CMS__BADPTR", 11)) {
    /*                       ^         */
#ifdef CMS$_BADPTR
      *iv_return = CMS$_BADPTR;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "CMS__ILLPAR", 11)) {
    /*                       ^         */
#ifdef CMS$_ILLPAR
      *iv_return = CMS$_ILLPAR;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'R':
    if (memEQ(name, "CMS__BADREF", 11)) {
    /*                       ^         */
#ifdef CMS$_BADREF
      *iv_return = CMS$_BADREF;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "CMS__CONRES", 11)) {
    /*                       ^         */
#ifdef CMS$_CONRES
      *iv_return = CMS$_CONRES;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "CMS__DUPREF", 11)) {
    /*                       ^         */
#ifdef CMS$_DUPREF
      *iv_return = CMS$_DUPREF;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "CMS__ILLRMK", 11)) {
    /*                       ^         */
#ifdef CMS$_ILLRMK
      *iv_return = CMS$_ILLRMK;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "CMS__REPREF", 11)) {
    /*                       ^         */
#ifdef CMS$_REPREF
      *iv_return = CMS$_REPREF;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "CMS__VERREF", 11)) {
    /*                       ^         */
#ifdef CMS$_VERREF
      *iv_return = CMS$_VERREF;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "CMS__VERRES", 11)) {
    /*                       ^         */
#ifdef CMS$_VERRES
      *iv_return = CMS$_VERRES;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'S':
    if (memEQ(name, "CMS__CNTSTR", 11)) {
    /*                       ^         */
#ifdef CMS$_CNTSTR
      *iv_return = CMS$_CNTSTR;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "CMS__ILLSEQ", 11)) {
    /*                       ^         */
#ifdef CMS$_ILLSEQ
      *iv_return = CMS$_ILLSEQ;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "CMS__LIBSET", 11)) {
    /*                       ^         */
#ifdef CMS$_LIBSET
      *iv_return = CMS$_LIBSET;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "CMS__NOTSET", 11)) {
    /*                       ^         */
#ifdef CMS$_NOTSET
      *iv_return = CMS$_NOTSET;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "CMS__VERSTR", 11)) {
    /*                       ^         */
#ifdef CMS$_VERSTR
      *iv_return = CMS$_VERSTR;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'T':
    if (memEQ(name, "CMS_K_AFTER", 11)) {
    /*                       ^         */
#ifdef CMS$K_AFTER
      *iv_return = CMS$K_AFTER;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "CMS_M_OCTAL", 11)) {
    /*                       ^         */
#ifdef CMS$K_OCTAL
      *iv_return = CMS$K_OCTAL;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "CMS__ABSTIM", 11)) {
    /*                       ^         */
#ifdef CMS$_ABSTIM
      *iv_return = CMS$_ABSTIM;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'V':
    if (memEQ(name, "CMS__ILLVAR", 11)) {
    /*                       ^         */
#ifdef CMS$_ILLVAR
      *iv_return = CMS$_ILLVAR;
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
constant_12 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     CMS_K_ACCEPT CMS_K_BEFORE CMS_K_CANCEL CMS_K_REJECT CMS_K_REVIEW
     CMS__AUTOREC CMS__BADCALL CMS__CONFIRM CMS__CREATED CMS__CREATES
     CMS__DELETED CMS__EDFMISS CMS__ERRVER2 CMS__EXCLUDE CMS__FETCHED
     CMS__FETCHES CMS__HISTDEL CMS__ILLCHAR CMS__ILLHIST CMS__ILLNAME
     CMS__ILLNOTE CMS__MODACLS CMS__MSGPOST CMS__MULTPAR CMS__NOCLOSE
     CMS__NOFETCH CMS__NOINPUT CMS__NOMATCH CMS__NOREPRO CMS__NORESRO
     CMS__NOSINCE CMS__NOTWILD CMS__NULLARG CMS__NULLSTR CMS__OPENARC
     CMS__OPENIN1 CMS__OPENIN2 CMS__OPENOUT CMS__READERR CMS__REFMISS
     CMS__REMOVED CMS__REVIEWS CMS__SEQFAIL CMS__STOPPED CMS__TOODEEP
     CMS__TOOLONG CMS__USERERR CMS__VEREDFS CMS__VERREFS CMS__WAITING
     CMS__WILDVER CMS__ZEROADD CMS__ZLENBLK */
  /* Offset 5 gives the best switch position.  */
  switch (name[5]) {
  case 'A':
    if (memEQ(name, "CMS__AUTOREC", 12)) {
    /*                    ^             */
#ifdef CMS$_AUTOREC
      *iv_return = CMS$_AUTOREC;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'B':
    if (memEQ(name, "CMS__BADCALL", 12)) {
    /*                    ^             */
#ifdef CMS$_BADCALL
      *iv_return = CMS$_BADCALL;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'C':
    if (memEQ(name, "CMS__CONFIRM", 12)) {
    /*                    ^             */
#ifdef CMS$_CONFIRM
      *iv_return = CMS$_CONFIRM;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "CMS__CREATED", 12)) {
    /*                    ^             */
#ifdef CMS$_CREATED
      *iv_return = CMS$_CREATED;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "CMS__CREATES", 12)) {
    /*                    ^             */
#ifdef CMS$_CREATES
      *iv_return = CMS$_CREATES;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'D':
    if (memEQ(name, "CMS__DELETED", 12)) {
    /*                    ^             */
#ifdef CMS$_DELETED
      *iv_return = CMS$_DELETED;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'E':
    if (memEQ(name, "CMS__EDFMISS", 12)) {
    /*                    ^             */
#ifdef CMS$_EDFMISS
      *iv_return = CMS$_EDFMISS;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "CMS__ERRVER2", 12)) {
    /*                    ^             */
#ifdef CMS$_ERRVER2
      *iv_return = CMS$_ERRVER2;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "CMS__EXCLUDE", 12)) {
    /*                    ^             */
#ifdef CMS$_EXCLUDE
      *iv_return = CMS$_EXCLUDE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'F':
    if (memEQ(name, "CMS__FETCHED", 12)) {
    /*                    ^             */
#ifdef CMS$_FETCHED
      *iv_return = CMS$_FETCHED;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "CMS__FETCHES", 12)) {
    /*                    ^             */
#ifdef CMS$_FETCHES
      *iv_return = CMS$_FETCHES;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'H':
    if (memEQ(name, "CMS__HISTDEL", 12)) {
    /*                    ^             */
#ifdef CMS$_HISTDEL
      *iv_return = CMS$_HISTDEL;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'I':
    if (memEQ(name, "CMS__ILLCHAR", 12)) {
    /*                    ^             */
#ifdef CMS$_ILLCHAR
      *iv_return = CMS$_ILLCHAR;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "CMS__ILLHIST", 12)) {
    /*                    ^             */
#ifdef CMS$_ILLHIST
      *iv_return = CMS$_ILLHIST;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "CMS__ILLNAME", 12)) {
    /*                    ^             */
#ifdef CMS$_ILLNAME
      *iv_return = CMS$_ILLNAME;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "CMS__ILLNOTE", 12)) {
    /*                    ^             */
#ifdef CMS$_ILLNOTE
      *iv_return = CMS$_ILLNOTE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'M':
    if (memEQ(name, "CMS__MODACLS", 12)) {
    /*                    ^             */
#ifdef CMS$_MODACLS
      *iv_return = CMS$_MODACLS;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "CMS__MSGPOST", 12)) {
    /*                    ^             */
#ifdef CMS$_MSGPOST
      *iv_return = CMS$_MSGPOST;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "CMS__MULTPAR", 12)) {
    /*                    ^             */
#ifdef CMS$_MULTPAR
      *iv_return = CMS$_MULTPAR;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'N':
    if (memEQ(name, "CMS__NOCLOSE", 12)) {
    /*                    ^             */
#ifdef CMS$_NOCLOSE
      *iv_return = CMS$_NOCLOSE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "CMS__NOFETCH", 12)) {
    /*                    ^             */
#ifdef CMS$_NOFETCH
      *iv_return = CMS$_NOFETCH;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "CMS__NOINPUT", 12)) {
    /*                    ^             */
#ifdef CMS$_NOINPUT
      *iv_return = CMS$_NOINPUT;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "CMS__NOMATCH", 12)) {
    /*                    ^             */
#ifdef CMS$_NOMATCH
      *iv_return = CMS$_NOMATCH;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "CMS__NOREPRO", 12)) {
    /*                    ^             */
#ifdef CMS$_NOREPRO
      *iv_return = CMS$_NOREPRO;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "CMS__NORESRO", 12)) {
    /*                    ^             */
#ifdef CMS$_NORESRO
      *iv_return = CMS$_NORESRO;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "CMS__NOSINCE", 12)) {
    /*                    ^             */
#ifdef CMS$_NOSINCE
      *iv_return = CMS$_NOSINCE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "CMS__NOTWILD", 12)) {
    /*                    ^             */
#ifdef CMS$_NOTWILD
      *iv_return = CMS$_NOTWILD;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "CMS__NULLARG", 12)) {
    /*                    ^             */
#ifdef CMS$_NULLARG
      *iv_return = CMS$_NULLARG;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "CMS__NULLSTR", 12)) {
    /*                    ^             */
#ifdef CMS$_NULLSTR
      *iv_return = CMS$_NULLSTR;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'O':
    if (memEQ(name, "CMS__OPENARC", 12)) {
    /*                    ^             */
#ifdef CMS$_OPENARC
      *iv_return = CMS$_OPENARC;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "CMS__OPENIN1", 12)) {
    /*                    ^             */
#ifdef CMS$_OPENIN1
      *iv_return = CMS$_OPENIN1;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "CMS__OPENIN2", 12)) {
    /*                    ^             */
#ifdef CMS$_OPENIN2
      *iv_return = CMS$_OPENIN2;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "CMS__OPENOUT", 12)) {
    /*                    ^             */
#ifdef CMS$_OPENOUT
      *iv_return = CMS$_OPENOUT;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'R':
    if (memEQ(name, "CMS__READERR", 12)) {
    /*                    ^             */
#ifdef CMS$_READERR
      *iv_return = CMS$_READERR;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "CMS__REFMISS", 12)) {
    /*                    ^             */
#ifdef CMS$_REFMISS
      *iv_return = CMS$_REFMISS;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "CMS__REMOVED", 12)) {
    /*                    ^             */
#ifdef CMS$_REMOVED
      *iv_return = CMS$_REMOVED;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "CMS__REVIEWS", 12)) {
    /*                    ^             */
#ifdef CMS$_REVIEWS
      *iv_return = CMS$_REVIEWS;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'S':
    if (memEQ(name, "CMS__SEQFAIL", 12)) {
    /*                    ^             */
#ifdef CMS$_SEQFAIL
      *iv_return = CMS$_SEQFAIL;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "CMS__STOPPED", 12)) {
    /*                    ^             */
#ifdef CMS$_STOPPED
      *iv_return = CMS$_STOPPED;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'T':
    if (memEQ(name, "CMS__TOODEEP", 12)) {
    /*                    ^             */
#ifdef CMS$_TOODEEP
      *iv_return = CMS$_TOODEEP;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "CMS__TOOLONG", 12)) {
    /*                    ^             */
#ifdef CMS$_TOOLONG
      *iv_return = CMS$_TOOLONG;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'U':
    if (memEQ(name, "CMS__USERERR", 12)) {
    /*                    ^             */
#ifdef CMS$_USERERR
      *iv_return = CMS$_USERERR;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'V':
    if (memEQ(name, "CMS__VEREDFS", 12)) {
    /*                    ^             */
#ifdef CMS$_VEREDFS
      *iv_return = CMS$_VEREDFS;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "CMS__VERREFS", 12)) {
    /*                    ^             */
#ifdef CMS$_VERREFS
      *iv_return = CMS$_VERREFS;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'W':
    if (memEQ(name, "CMS__WAITING", 12)) {
    /*                    ^             */
#ifdef CMS$_WAITING
      *iv_return = CMS$_WAITING;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "CMS__WILDVER", 12)) {
    /*                    ^             */
#ifdef CMS$_WILDVER
      *iv_return = CMS$_WILDVER;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'Z':
    if (memEQ(name, "CMS__ZEROADD", 12)) {
    /*                    ^             */
#ifdef CMS$_ZEROADD
      *iv_return = CMS$_ZEROADD;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "CMS__ZLENBLK", 12)) {
    /*                    ^             */
#ifdef CMS$_ZLENBLK
      *iv_return = CMS$_ZLENBLK;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case '_':
    if (memEQ(name, "CMS_K_ACCEPT", 12)) {
    /*                    ^             */
#ifdef CMS$K_ACCEPT
      *iv_return = CMS$K_ACCEPT;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "CMS_K_BEFORE", 12)) {
    /*                    ^             */
#ifdef CMS$K_BEFORE
      *iv_return = CMS$K_BEFORE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "CMS_K_CANCEL", 12)) {
    /*                    ^             */
#ifdef CMS$K_CANCEL
      *iv_return = CMS$K_CANCEL;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "CMS_K_REJECT", 12)) {
    /*                    ^             */
#ifdef CMS$K_REJECT
      *iv_return = CMS$K_REJECT;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "CMS_K_REVIEW", 12)) {
    /*                    ^             */
#ifdef CMS$K_REVIEW
      *iv_return = CMS$K_REVIEW;
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
constant_13 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     CMS_M_CMD_SET CMS_M_DECIMAL CMS_M_RECORDS CMS__ACCEPTED CMS__ACCVIORD
     CMS__ACCVIOWT CMS__CANCELED CMS__COMPARED CMS__CONTROLC CMS__ELEXPIGN
     CMS__ERRCLOSE CMS__ERRMARKS CMS__EXTFOUND CMS__FACILITY CMS__FILINUSE
     CMS__GROUPEXP CMS__HASFILES CMS__ILLELEXP CMS__INSERTED CMS__INVFETDB
     CMS__INVLIBDB CMS__ISMEMBER CMS__MODIFIED CMS__MSGBUILD CMS__MULTCALL
     CMS__NOACCEPT CMS__NOACCESS CMS__NOBACKUP CMS__NOBCKPTR CMS__NOCANCEL
     CMS__NOCONCUR CMS__NOCONRES CMS__NOCREATE CMS__NODEFACL CMS__NODELETE
     CMS__NOELEENT CMS__NOERRLOG CMS__NOHISPAR CMS__NOINSERT CMS__NOMODACL
     CMS__NOMODARG CMS__NOMODIFY CMS__NOOBJTYP CMS__NOREFDIR CMS__NOREFELE
     CMS__NOREJECT CMS__NOREMARK CMS__NOREPAIR CMS__NOREPCMD CMS__NOREPEDF
     CMS__NOREPREF CMS__NOREVIEW CMS__NOTBYCMS CMS__NOTFOUND CMS__NOTNOREF
     CMS__NOTTHERE CMS__NOVERIFY CMS__READONLY CMS__REJECTED CMS__REMOVALS
     CMS__REPAIRED CMS__RESERVED CMS__REVIEWED CMS__SAMELINE CMS__STARTHIS
     CMS__TRUNCLST CMS__UNDEFLIB CMS__VERIFIED CMS__WRITEERR */
  /* Offset 9 gives the best switch position.  */
  switch (name[9]) {
  case 'A':
    if (memEQ(name, "CMS__COMPARED", 13)) {
    /*                        ^          */
#ifdef CMS$_COMPARED
      *iv_return = CMS$_COMPARED;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "CMS__ERRMARKS", 13)) {
    /*                        ^          */
#ifdef CMS$_ERRMARKS
      *iv_return = CMS$_ERRMARKS;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'C':
    if (memEQ(name, "CMS__MULTCALL", 13)) {
    /*                        ^          */
#ifdef CMS$_MULTCALL
      *iv_return = CMS$_MULTCALL;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "CMS__NOACCEPT", 13)) {
    /*                        ^          */
#ifdef CMS$_NOACCEPT
      *iv_return = CMS$_NOACCEPT;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "CMS__NOACCESS", 13)) {
    /*                        ^          */
#ifdef CMS$_NOACCESS
      *iv_return = CMS$_NOACCESS;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "CMS__NOBACKUP", 13)) {
    /*                        ^          */
#ifdef CMS$_NOBACKUP
      *iv_return = CMS$_NOBACKUP;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "CMS__REJECTED", 13)) {
    /*                        ^          */
#ifdef CMS$_REJECTED
      *iv_return = CMS$_REJECTED;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "CMS__TRUNCLST", 13)) {
    /*                        ^          */
#ifdef CMS$_TRUNCLST
      *iv_return = CMS$_TRUNCLST;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'D':
    if (memEQ(name, "CMS__NOMODACL", 13)) {
    /*                        ^          */
#ifdef CMS$_NOMODACL
      *iv_return = CMS$_NOMODACL;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "CMS__NOMODARG", 13)) {
    /*                        ^          */
#ifdef CMS$_NOMODARG
      *iv_return = CMS$_NOMODARG;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "CMS__NOMODIFY", 13)) {
    /*                        ^          */
#ifdef CMS$_NOMODIFY
      *iv_return = CMS$_NOMODIFY;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'E':
    if (memEQ(name, "CMS__CANCELED", 13)) {
    /*                        ^          */
#ifdef CMS$_CANCELED
      *iv_return = CMS$_CANCELED;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "CMS__INVFETDB", 13)) {
    /*                        ^          */
#ifdef CMS$_INVFETDB
      *iv_return = CMS$_INVFETDB;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "CMS__NOCREATE", 13)) {
    /*                        ^          */
#ifdef CMS$_NOCREATE
      *iv_return = CMS$_NOCREATE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "CMS__NOELEENT", 13)) {
    /*                        ^          */
#ifdef CMS$_NOELEENT
      *iv_return = CMS$_NOELEENT;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "CMS__REVIEWED", 13)) {
    /*                        ^          */
#ifdef CMS$_REVIEWED
      *iv_return = CMS$_REVIEWED;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "CMS__WRITEERR", 13)) {
    /*                        ^          */
#ifdef CMS$_WRITEERR
      *iv_return = CMS$_WRITEERR;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'F':
    if (memEQ(name, "CMS__MODIFIED", 13)) {
    /*                        ^          */
#ifdef CMS$_MODIFIED
      *iv_return = CMS$_MODIFIED;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "CMS__NODEFACL", 13)) {
    /*                        ^          */
#ifdef CMS$_NODEFACL
      *iv_return = CMS$_NODEFACL;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "CMS__NOREFDIR", 13)) {
    /*                        ^          */
#ifdef CMS$_NOREFDIR
      *iv_return = CMS$_NOREFDIR;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "CMS__NOREFELE", 13)) {
    /*                        ^          */
#ifdef CMS$_NOREFELE
      *iv_return = CMS$_NOREFELE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "CMS__UNDEFLIB", 13)) {
    /*                        ^          */
#ifdef CMS$_UNDEFLIB
      *iv_return = CMS$_UNDEFLIB;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "CMS__VERIFIED", 13)) {
    /*                        ^          */
#ifdef CMS$_VERIFIED
      *iv_return = CMS$_VERIFIED;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'H':
    if (memEQ(name, "CMS__NOTTHERE", 13)) {
    /*                        ^          */
#ifdef CMS$_NOTTHERE
      *iv_return = CMS$_NOTTHERE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'I':
    if (memEQ(name, "CMS_M_DECIMAL", 13)) {
    /*                        ^          */
#ifdef CMS$K_DECIMAL
      *iv_return = CMS$K_DECIMAL;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "CMS__ACCVIORD", 13)) {
    /*                        ^          */
#ifdef CMS$_ACCVIORD
      *iv_return = CMS$_ACCVIORD;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "CMS__ACCVIOWT", 13)) {
    /*                        ^          */
#ifdef CMS$_ACCVIOWT
      *iv_return = CMS$_ACCVIOWT;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "CMS__HASFILES", 13)) {
    /*                        ^          */
#ifdef CMS$_HASFILES
      *iv_return = CMS$_HASFILES;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "CMS__INVLIBDB", 13)) {
    /*                        ^          */
#ifdef CMS$_INVLIBDB
      *iv_return = CMS$_INVLIBDB;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "CMS__REPAIRED", 13)) {
    /*                        ^          */
#ifdef CMS$_REPAIRED
      *iv_return = CMS$_REPAIRED;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'J':
    if (memEQ(name, "CMS__NOOBJTYP", 13)) {
    /*                        ^          */
#ifdef CMS$_NOOBJTYP
      *iv_return = CMS$_NOOBJTYP;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "CMS__NOREJECT", 13)) {
    /*                        ^          */
#ifdef CMS$_NOREJECT
      *iv_return = CMS$_NOREJECT;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'K':
    if (memEQ(name, "CMS__NOBCKPTR", 13)) {
    /*                        ^          */
#ifdef CMS$_NOBCKPTR
      *iv_return = CMS$_NOBCKPTR;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'L':
    if (memEQ(name, "CMS__ERRCLOSE", 13)) {
    /*                        ^          */
#ifdef CMS$_ERRCLOSE
      *iv_return = CMS$_ERRCLOSE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "CMS__FACILITY", 13)) {
    /*                        ^          */
#ifdef CMS$_FACILITY
      *iv_return = CMS$_FACILITY;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "CMS__ILLELEXP", 13)) {
    /*                        ^          */
#ifdef CMS$_ILLELEXP
      *iv_return = CMS$_ILLELEXP;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "CMS__NODELETE", 13)) {
    /*                        ^          */
#ifdef CMS$_NODELETE
      *iv_return = CMS$_NODELETE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "CMS__SAMELINE", 13)) {
    /*                        ^          */
#ifdef CMS$_SAMELINE
      *iv_return = CMS$_SAMELINE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'M':
    if (memEQ(name, "CMS__ISMEMBER", 13)) {
    /*                        ^          */
#ifdef CMS$_ISMEMBER
      *iv_return = CMS$_ISMEMBER;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "CMS__NOREMARK", 13)) {
    /*                        ^          */
#ifdef CMS$_NOREMARK
      *iv_return = CMS$_NOREMARK;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'N':
    if (memEQ(name, "CMS__FILINUSE", 13)) {
    /*                        ^          */
#ifdef CMS$_FILINUSE
      *iv_return = CMS$_FILINUSE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "CMS__NOCANCEL", 13)) {
    /*                        ^          */
#ifdef CMS$_NOCANCEL
      *iv_return = CMS$_NOCANCEL;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "CMS__NOCONCUR", 13)) {
    /*                        ^          */
#ifdef CMS$_NOCONCUR
      *iv_return = CMS$_NOCONCUR;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "CMS__NOCONRES", 13)) {
    /*                        ^          */
#ifdef CMS$_NOCONRES
      *iv_return = CMS$_NOCONRES;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'O':
    if (memEQ(name, "CMS_M_RECORDS", 13)) {
    /*                        ^          */
#ifdef CMS$K_RECORDS
      *iv_return = CMS$K_RECORDS;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "CMS__EXTFOUND", 13)) {
    /*                        ^          */
#ifdef CMS$_EXTFOUND
      *iv_return = CMS$_EXTFOUND;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "CMS__NOTFOUND", 13)) {
    /*                        ^          */
#ifdef CMS$_NOTFOUND
      *iv_return = CMS$_NOTFOUND;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "CMS__NOTNOREF", 13)) {
    /*                        ^          */
#ifdef CMS$_NOTNOREF
      *iv_return = CMS$_NOTNOREF;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "CMS__READONLY", 13)) {
    /*                        ^          */
#ifdef CMS$_READONLY
      *iv_return = CMS$_READONLY;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'P':
    if (memEQ(name, "CMS__ACCEPTED", 13)) {
    /*                        ^          */
#ifdef CMS$_ACCEPTED
      *iv_return = CMS$_ACCEPTED;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "CMS__ELEXPIGN", 13)) {
    /*                        ^          */
#ifdef CMS$_ELEXPIGN
      *iv_return = CMS$_ELEXPIGN;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "CMS__GROUPEXP", 13)) {
    /*                        ^          */
#ifdef CMS$_GROUPEXP
      *iv_return = CMS$_GROUPEXP;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "CMS__NOREPAIR", 13)) {
    /*                        ^          */
#ifdef CMS$_NOREPAIR
      *iv_return = CMS$_NOREPAIR;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "CMS__NOREPCMD", 13)) {
    /*                        ^          */
#ifdef CMS$_NOREPCMD
      *iv_return = CMS$_NOREPCMD;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "CMS__NOREPEDF", 13)) {
    /*                        ^          */
#ifdef CMS$_NOREPEDF
      *iv_return = CMS$_NOREPEDF;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "CMS__NOREPREF", 13)) {
    /*                        ^          */
#ifdef CMS$_NOREPREF
      *iv_return = CMS$_NOREPREF;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'R':
    if (memEQ(name, "CMS__CONTROLC", 13)) {
    /*                        ^          */
#ifdef CMS$_CONTROLC
      *iv_return = CMS$_CONTROLC;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "CMS__INSERTED", 13)) {
    /*                        ^          */
#ifdef CMS$_INSERTED
      *iv_return = CMS$_INSERTED;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "CMS__NOERRLOG", 13)) {
    /*                        ^          */
#ifdef CMS$_NOERRLOG
      *iv_return = CMS$_NOERRLOG;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "CMS__NOVERIFY", 13)) {
    /*                        ^          */
#ifdef CMS$_NOVERIFY
      *iv_return = CMS$_NOVERIFY;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "CMS__RESERVED", 13)) {
    /*                        ^          */
#ifdef CMS$_RESERVED
      *iv_return = CMS$_RESERVED;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'S':
    if (memEQ(name, "CMS__NOHISPAR", 13)) {
    /*                        ^          */
#ifdef CMS$_NOHISPAR
      *iv_return = CMS$_NOHISPAR;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "CMS__NOINSERT", 13)) {
    /*                        ^          */
#ifdef CMS$_NOINSERT
      *iv_return = CMS$_NOINSERT;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'T':
    if (memEQ(name, "CMS__STARTHIS", 13)) {
    /*                        ^          */
#ifdef CMS$_STARTHIS
      *iv_return = CMS$_STARTHIS;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'U':
    if (memEQ(name, "CMS__MSGBUILD", 13)) {
    /*                        ^          */
#ifdef CMS$_MSGBUILD
      *iv_return = CMS$_MSGBUILD;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'V':
    if (memEQ(name, "CMS__NOREVIEW", 13)) {
    /*                        ^          */
#ifdef CMS$_NOREVIEW
      *iv_return = CMS$_NOREVIEW;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "CMS__REMOVALS", 13)) {
    /*                        ^          */
#ifdef CMS$_REMOVALS
      *iv_return = CMS$_REMOVALS;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'Y':
    if (memEQ(name, "CMS__NOTBYCMS", 13)) {
    /*                        ^          */
#ifdef CMS$_NOTBYCMS
      *iv_return = CMS$_NOTBYCMS;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case '_':
    if (memEQ(name, "CMS_M_CMD_SET", 13)) {
    /*                        ^          */
#ifdef CMS$K_CMD_SET
      *iv_return = CMS$K_CMD_SET;
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
constant_14 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     CMS_M_CMD_COPY CMS_M_CMD_MARK CMS_M_LONGWORD CMS__ALPHACHAR CMS__ANNOTATED
     CMS__ANNSIGNAL CMS__BADFORMAT CMS__BADLENSTR CMS__BADLSTSTR CMS__BADORDSTR
     CMS__BADREFHDR CMS__BADSTRING CMS__BADTYPSTR CMS__BADVERSTR CMS__BCKPTRSTR
     CMS__CMPSIGNAL CMS__CONFLICTS CMS__CONVERTED CMS__DELETIONS CMS__DIFFCLASS
     CMS__DIFFERENT CMS__ELEEXISTS CMS__ENDOFLIST CMS__ENDPTRSTR CMS__ERRCOPIES
     CMS__ERRELEHIS CMS__ERRPAREXP CMS__ERRVERARC CMS__ERRVERCLS CMS__ERRVERCMD
     CMS__ERRVERCON CMS__ERRVERELE CMS__ERRVERFRE CMS__ERRVERGEN CMS__ERRVERGRP
     CMS__ERRVERRES CMS__ERRVERSTR CMS__FILEXISTS CMS__FREBLKCON CMS__GENEXISTS
     CMS__GENNOTANC CMS__GENNOTRES CMS__GENRESREV CMS__HISNOTSTM CMS__IDENTICAL
     CMS__ILLARCREC CMS__ILLCLSNAM CMS__ILLCONREC CMS__ILLDATREC CMS__ILLELENAM
     CMS__ILLFORMAT CMS__ILLGRPNAM CMS__ILLOBJTYP CMS__ILLPOSVAL CMS__ILLREFDIR
     CMS__ILLSUBTYP CMS__INCLIBVER CMS__INVFIXMRS CMS__INVGENLRL CMS__INVLENGTH
     CMS__INVOKERBK CMS__INVSTRDES CMS__LIBINSLIS CMS__LIBLISMOD CMS__LIBREMLIS
     CMS__MANCONLIB CMS__MISBLKSTR CMS__MISMATCON CMS__MSGCANCEL CMS__MSGUPDATE
     CMS__MSSBLKSTR CMS__MUSTBEDIR CMS__MUSTBEFIL CMS__MUSTBEPOS CMS__NETNOTALL
     CMS__NOCHANGES CMS__NOCOMPARE CMS__NOCONFIRM CMS__NOCONVERT CMS__NODELGEN1
     CMS__NORECOVER CMS__NOREMOVAL CMS__NOREPLACE CMS__NOREVPEND CMS__NOSRCHLST
     CMS__NOTCMSLIB CMS__NOTCRELIB CMS__NOTDIRDES CMS__NOTLOGGED CMS__NOWLDCARD
     CMS__NUMGENEXP CMS__OLDSYNTAX CMS__ONEPERIOD CMS__OVERDRAFT CMS__POSVALREQ
     CMS__RECNOTNEC CMS__RECOVERED CMS__REFMISMAT CMS__REFREPAIR CMS__REPBADLST
     CMS__REPBADTYP CMS__REPBCKPTR CMS__REPCNTSTR CMS__REPENDPTR CMS__REPGENLRL
     CMS__REPGENMRS CMS__REPMISBLK CMS__RETRIEVED CMS__SEQMISMAT CMS__SEQUENCED
     CMS__SUPERSEDE CMS__SYSTIMDIF CMS__SYSTIMERR CMS__TIMEORDER CMS__TRYAGNLAT
     CMS__UNRECTYPE CMS__UNSUPFRMT CMS__USEREPAIR CMS__USESETLIB CMS__VARLETTER
     CMS__VEREDFERR CMS__VERLMTERR CMS__VERREFERR CMS__WILDMATCH */
  /* Offset 8 gives the best switch position.  */
  switch (name[8]) {
  case 'A':
    if (memEQ(name, "CMS__ILLARCREC", 14)) {
    /*                       ^            */
#ifdef CMS$_ILLARCREC
      *iv_return = CMS$_ILLARCREC;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "CMS__TRYAGNLAT", 14)) {
    /*                       ^            */
#ifdef CMS$_TRYAGNLAT
      *iv_return = CMS$_TRYAGNLAT;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'B':
    if (memEQ(name, "CMS__FREBLKCON", 14)) {
    /*                       ^            */
#ifdef CMS$_FREBLKCON
      *iv_return = CMS$_FREBLKCON;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "CMS__MISBLKSTR", 14)) {
    /*                       ^            */
#ifdef CMS$_MISBLKSTR
      *iv_return = CMS$_MISBLKSTR;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "CMS__MSSBLKSTR", 14)) {
    /*                       ^            */
#ifdef CMS$_MSSBLKSTR
      *iv_return = CMS$_MSSBLKSTR;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "CMS__REPBADLST", 14)) {
    /*                       ^            */
#ifdef CMS$_REPBADLST
      *iv_return = CMS$_REPBADLST;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "CMS__REPBADTYP", 14)) {
    /*                       ^            */
#ifdef CMS$_REPBADTYP
      *iv_return = CMS$_REPBADTYP;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "CMS__REPBCKPTR", 14)) {
    /*                       ^            */
#ifdef CMS$_REPBCKPTR
      *iv_return = CMS$_REPBCKPTR;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'C':
    if (memEQ(name, "CMS__ERRCOPIES", 14)) {
    /*                       ^            */
#ifdef CMS$_ERRCOPIES
      *iv_return = CMS$_ERRCOPIES;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "CMS__ILLCLSNAM", 14)) {
    /*                       ^            */
#ifdef CMS$_ILLCLSNAM
      *iv_return = CMS$_ILLCLSNAM;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "CMS__ILLCONREC", 14)) {
    /*                       ^            */
#ifdef CMS$_ILLCONREC
      *iv_return = CMS$_ILLCONREC;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "CMS__MANCONLIB", 14)) {
    /*                       ^            */
#ifdef CMS$_MANCONLIB
      *iv_return = CMS$_MANCONLIB;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "CMS__MSGCANCEL", 14)) {
    /*                       ^            */
#ifdef CMS$_MSGCANCEL
      *iv_return = CMS$_MSGCANCEL;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "CMS__NOTCMSLIB", 14)) {
    /*                       ^            */
#ifdef CMS$_NOTCMSLIB
      *iv_return = CMS$_NOTCMSLIB;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "CMS__NOTCRELIB", 14)) {
    /*                       ^            */
#ifdef CMS$_NOTCRELIB
      *iv_return = CMS$_NOTCRELIB;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "CMS__REPCNTSTR", 14)) {
    /*                       ^            */
#ifdef CMS$_REPCNTSTR
      *iv_return = CMS$_REPCNTSTR;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'D':
    if (memEQ(name, "CMS_M_CMD_COPY", 14)) {
    /*                       ^            */
#ifdef CMS$K_CMD_COPY
      *iv_return = CMS$K_CMD_COPY;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "CMS_M_CMD_MARK", 14)) {
    /*                       ^            */
#ifdef CMS$K_CMD_MARK
      *iv_return = CMS$K_CMD_MARK;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "CMS__ILLDATREC", 14)) {
    /*                       ^            */
#ifdef CMS$_ILLDATREC
      *iv_return = CMS$_ILLDATREC;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "CMS__NOTDIRDES", 14)) {
    /*                       ^            */
#ifdef CMS$_NOTDIRDES
      *iv_return = CMS$_NOTDIRDES;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "CMS__WILDMATCH", 14)) {
    /*                       ^            */
#ifdef CMS$_WILDMATCH
      *iv_return = CMS$_WILDMATCH;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'E':
    if (memEQ(name, "CMS__DELETIONS", 14)) {
    /*                       ^            */
#ifdef CMS$_DELETIONS
      *iv_return = CMS$_DELETIONS;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "CMS__ELEEXISTS", 14)) {
    /*                       ^            */
#ifdef CMS$_ELEEXISTS
      *iv_return = CMS$_ELEEXISTS;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "CMS__ERRELEHIS", 14)) {
    /*                       ^            */
#ifdef CMS$_ERRELEHIS
      *iv_return = CMS$_ERRELEHIS;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "CMS__FILEXISTS", 14)) {
    /*                       ^            */
#ifdef CMS$_FILEXISTS
      *iv_return = CMS$_FILEXISTS;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "CMS__GENEXISTS", 14)) {
    /*                       ^            */
#ifdef CMS$_GENEXISTS
      *iv_return = CMS$_GENEXISTS;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "CMS__ILLELENAM", 14)) {
    /*                       ^            */
#ifdef CMS$_ILLELENAM
      *iv_return = CMS$_ILLELENAM;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "CMS__NODELGEN1", 14)) {
    /*                       ^            */
#ifdef CMS$_NODELGEN1
      *iv_return = CMS$_NODELGEN1;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "CMS__NORECOVER", 14)) {
    /*                       ^            */
#ifdef CMS$_NORECOVER
      *iv_return = CMS$_NORECOVER;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "CMS__NOREMOVAL", 14)) {
    /*                       ^            */
#ifdef CMS$_NOREMOVAL
      *iv_return = CMS$_NOREMOVAL;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "CMS__NOREPLACE", 14)) {
    /*                       ^            */
#ifdef CMS$_NOREPLACE
      *iv_return = CMS$_NOREPLACE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "CMS__NOREVPEND", 14)) {
    /*                       ^            */
#ifdef CMS$_NOREVPEND
      *iv_return = CMS$_NOREVPEND;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "CMS__REPENDPTR", 14)) {
    /*                       ^            */
#ifdef CMS$_REPENDPTR
      *iv_return = CMS$_REPENDPTR;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "CMS__SUPERSEDE", 14)) {
    /*                       ^            */
#ifdef CMS$_SUPERSEDE
      *iv_return = CMS$_SUPERSEDE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "CMS__TIMEORDER", 14)) {
    /*                       ^            */
#ifdef CMS$_TIMEORDER
      *iv_return = CMS$_TIMEORDER;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "CMS__UNRECTYPE", 14)) {
    /*                       ^            */
#ifdef CMS$_UNRECTYPE
      *iv_return = CMS$_UNRECTYPE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "CMS__VEREDFERR", 14)) {
    /*                       ^            */
#ifdef CMS$_VEREDFERR
      *iv_return = CMS$_VEREDFERR;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'F':
    if (memEQ(name, "CMS__BADFORMAT", 14)) {
    /*                       ^            */
#ifdef CMS$_BADFORMAT
      *iv_return = CMS$_BADFORMAT;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "CMS__CONFLICTS", 14)) {
    /*                       ^            */
#ifdef CMS$_CONFLICTS
      *iv_return = CMS$_CONFLICTS;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "CMS__DIFFCLASS", 14)) {
    /*                       ^            */
#ifdef CMS$_DIFFCLASS
      *iv_return = CMS$_DIFFCLASS;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "CMS__DIFFERENT", 14)) {
    /*                       ^            */
#ifdef CMS$_DIFFERENT
      *iv_return = CMS$_DIFFERENT;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "CMS__ILLFORMAT", 14)) {
    /*                       ^            */
#ifdef CMS$_ILLFORMAT
      *iv_return = CMS$_ILLFORMAT;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "CMS__INVFIXMRS", 14)) {
    /*                       ^            */
#ifdef CMS$_INVFIXMRS
      *iv_return = CMS$_INVFIXMRS;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'G':
    if (memEQ(name, "CMS__ILLGRPNAM", 14)) {
    /*                       ^            */
#ifdef CMS$_ILLGRPNAM
      *iv_return = CMS$_ILLGRPNAM;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "CMS__INVGENLRL", 14)) {
    /*                       ^            */
#ifdef CMS$_INVGENLRL
      *iv_return = CMS$_INVGENLRL;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "CMS__NUMGENEXP", 14)) {
    /*                       ^            */
#ifdef CMS$_NUMGENEXP
      *iv_return = CMS$_NUMGENEXP;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "CMS__REPGENLRL", 14)) {
    /*                       ^            */
#ifdef CMS$_REPGENLRL
      *iv_return = CMS$_REPGENLRL;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "CMS__REPGENMRS", 14)) {
    /*                       ^            */
#ifdef CMS$_REPGENMRS
      *iv_return = CMS$_REPGENMRS;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'H':
    if (memEQ(name, "CMS__ALPHACHAR", 14)) {
    /*                       ^            */
#ifdef CMS$_ALPHACHAR
      *iv_return = CMS$_ALPHACHAR;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "CMS__NOCHANGES", 14)) {
    /*                       ^            */
#ifdef CMS$_NOCHANGES
      *iv_return = CMS$_NOCHANGES;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'I':
    if (memEQ(name, "CMS__LIBINSLIS", 14)) {
    /*                       ^            */
#ifdef CMS$_LIBINSLIS
      *iv_return = CMS$_LIBINSLIS;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'L':
    if (memEQ(name, "CMS__BADLENSTR", 14)) {
    /*                       ^            */
#ifdef CMS$_BADLENSTR
      *iv_return = CMS$_BADLENSTR;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "CMS__BADLSTSTR", 14)) {
    /*                       ^            */
#ifdef CMS$_BADLSTSTR
      *iv_return = CMS$_BADLSTSTR;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "CMS__INCLIBVER", 14)) {
    /*                       ^            */
#ifdef CMS$_INCLIBVER
      *iv_return = CMS$_INCLIBVER;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "CMS__INVLENGTH", 14)) {
    /*                       ^            */
#ifdef CMS$_INVLENGTH
      *iv_return = CMS$_INVLENGTH;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "CMS__LIBLISMOD", 14)) {
    /*                       ^            */
#ifdef CMS$_LIBLISMOD
      *iv_return = CMS$_LIBLISMOD;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "CMS__NOTLOGGED", 14)) {
    /*                       ^            */
#ifdef CMS$_NOTLOGGED
      *iv_return = CMS$_NOTLOGGED;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "CMS__NOWLDCARD", 14)) {
    /*                       ^            */
#ifdef CMS$_NOWLDCARD
      *iv_return = CMS$_NOWLDCARD;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "CMS__VARLETTER", 14)) {
    /*                       ^            */
#ifdef CMS$_VARLETTER
      *iv_return = CMS$_VARLETTER;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "CMS__VERLMTERR", 14)) {
    /*                       ^            */
#ifdef CMS$_VERLMTERR
      *iv_return = CMS$_VERLMTERR;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'M':
    if (memEQ(name, "CMS__MISMATCON", 14)) {
    /*                       ^            */
#ifdef CMS$_MISMATCON
      *iv_return = CMS$_MISMATCON;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "CMS__REFMISMAT", 14)) {
    /*                       ^            */
#ifdef CMS$_REFMISMAT
      *iv_return = CMS$_REFMISMAT;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "CMS__REPMISBLK", 14)) {
    /*                       ^            */
#ifdef CMS$_REPMISBLK
      *iv_return = CMS$_REPMISBLK;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "CMS__SEQMISMAT", 14)) {
    /*                       ^            */
#ifdef CMS$_SEQMISMAT
      *iv_return = CMS$_SEQMISMAT;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'N':
    if (memEQ(name, "CMS_M_LONGWORD", 14)) {
    /*                       ^            */
#ifdef CMS$K_LONGWORD
      *iv_return = CMS$K_LONGWORD;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "CMS__GENNOTANC", 14)) {
    /*                       ^            */
#ifdef CMS$_GENNOTANC
      *iv_return = CMS$_GENNOTANC;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "CMS__GENNOTRES", 14)) {
    /*                       ^            */
#ifdef CMS$_GENNOTRES
      *iv_return = CMS$_GENNOTRES;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "CMS__HISNOTSTM", 14)) {
    /*                       ^            */
#ifdef CMS$_HISNOTSTM
      *iv_return = CMS$_HISNOTSTM;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "CMS__IDENTICAL", 14)) {
    /*                       ^            */
#ifdef CMS$_IDENTICAL
      *iv_return = CMS$_IDENTICAL;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "CMS__NETNOTALL", 14)) {
    /*                       ^            */
#ifdef CMS$_NETNOTALL
      *iv_return = CMS$_NETNOTALL;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "CMS__RECNOTNEC", 14)) {
    /*                       ^            */
#ifdef CMS$_RECNOTNEC
      *iv_return = CMS$_RECNOTNEC;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'O':
    if (memEQ(name, "CMS__ANNOTATED", 14)) {
    /*                       ^            */
#ifdef CMS$_ANNOTATED
      *iv_return = CMS$_ANNOTATED;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "CMS__BADORDSTR", 14)) {
    /*                       ^            */
#ifdef CMS$_BADORDSTR
      *iv_return = CMS$_BADORDSTR;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "CMS__ENDOFLIST", 14)) {
    /*                       ^            */
#ifdef CMS$_ENDOFLIST
      *iv_return = CMS$_ENDOFLIST;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "CMS__ILLOBJTYP", 14)) {
    /*                       ^            */
#ifdef CMS$_ILLOBJTYP
      *iv_return = CMS$_ILLOBJTYP;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "CMS__INVOKERBK", 14)) {
    /*                       ^            */
#ifdef CMS$_INVOKERBK
      *iv_return = CMS$_INVOKERBK;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "CMS__NOCOMPARE", 14)) {
    /*                       ^            */
#ifdef CMS$_NOCOMPARE
      *iv_return = CMS$_NOCOMPARE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "CMS__NOCONFIRM", 14)) {
    /*                       ^            */
#ifdef CMS$_NOCONFIRM
      *iv_return = CMS$_NOCONFIRM;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "CMS__NOCONVERT", 14)) {
    /*                       ^            */
#ifdef CMS$_NOCONVERT
      *iv_return = CMS$_NOCONVERT;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "CMS__RECOVERED", 14)) {
    /*                       ^            */
#ifdef CMS$_RECOVERED
      *iv_return = CMS$_RECOVERED;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'P':
    if (memEQ(name, "CMS__BCKPTRSTR", 14)) {
    /*                       ^            */
#ifdef CMS$_BCKPTRSTR
      *iv_return = CMS$_BCKPTRSTR;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "CMS__ENDPTRSTR", 14)) {
    /*                       ^            */
#ifdef CMS$_ENDPTRSTR
      *iv_return = CMS$_ENDPTRSTR;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "CMS__ERRPAREXP", 14)) {
    /*                       ^            */
#ifdef CMS$_ERRPAREXP
      *iv_return = CMS$_ERRPAREXP;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "CMS__ILLPOSVAL", 14)) {
    /*                       ^            */
#ifdef CMS$_ILLPOSVAL
      *iv_return = CMS$_ILLPOSVAL;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "CMS__ONEPERIOD", 14)) {
    /*                       ^            */
#ifdef CMS$_ONEPERIOD
      *iv_return = CMS$_ONEPERIOD;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'R':
    if (memEQ(name, "CMS__BADREFHDR", 14)) {
    /*                       ^            */
#ifdef CMS$_BADREFHDR
      *iv_return = CMS$_BADREFHDR;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "CMS__GENRESREV", 14)) {
    /*                       ^            */
#ifdef CMS$_GENRESREV
      *iv_return = CMS$_GENRESREV;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "CMS__ILLREFDIR", 14)) {
    /*                       ^            */
#ifdef CMS$_ILLREFDIR
      *iv_return = CMS$_ILLREFDIR;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "CMS__LIBREMLIS", 14)) {
    /*                       ^            */
#ifdef CMS$_LIBREMLIS
      *iv_return = CMS$_LIBREMLIS;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "CMS__NOSRCHLST", 14)) {
    /*                       ^            */
#ifdef CMS$_NOSRCHLST
      *iv_return = CMS$_NOSRCHLST;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "CMS__OVERDRAFT", 14)) {
    /*                       ^            */
#ifdef CMS$_OVERDRAFT
      *iv_return = CMS$_OVERDRAFT;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "CMS__REFREPAIR", 14)) {
    /*                       ^            */
#ifdef CMS$_REFREPAIR
      *iv_return = CMS$_REFREPAIR;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "CMS__RETRIEVED", 14)) {
    /*                       ^            */
#ifdef CMS$_RETRIEVED
      *iv_return = CMS$_RETRIEVED;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "CMS__USEREPAIR", 14)) {
    /*                       ^            */
#ifdef CMS$_USEREPAIR
      *iv_return = CMS$_USEREPAIR;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "CMS__VERREFERR", 14)) {
    /*                       ^            */
#ifdef CMS$_VERREFERR
      *iv_return = CMS$_VERREFERR;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'S':
    if (memEQ(name, "CMS__ANNSIGNAL", 14)) {
    /*                       ^            */
#ifdef CMS$_ANNSIGNAL
      *iv_return = CMS$_ANNSIGNAL;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "CMS__BADSTRING", 14)) {
    /*                       ^            */
#ifdef CMS$_BADSTRING
      *iv_return = CMS$_BADSTRING;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "CMS__CMPSIGNAL", 14)) {
    /*                       ^            */
#ifdef CMS$_CMPSIGNAL
      *iv_return = CMS$_CMPSIGNAL;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "CMS__ILLSUBTYP", 14)) {
    /*                       ^            */
#ifdef CMS$_ILLSUBTYP
      *iv_return = CMS$_ILLSUBTYP;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "CMS__INVSTRDES", 14)) {
    /*                       ^            */
#ifdef CMS$_INVSTRDES
      *iv_return = CMS$_INVSTRDES;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "CMS__OLDSYNTAX", 14)) {
    /*                       ^            */
#ifdef CMS$_OLDSYNTAX
      *iv_return = CMS$_OLDSYNTAX;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "CMS__USESETLIB", 14)) {
    /*                       ^            */
#ifdef CMS$_USESETLIB
      *iv_return = CMS$_USESETLIB;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'T':
    if (memEQ(name, "CMS__BADTYPSTR", 14)) {
    /*                       ^            */
#ifdef CMS$_BADTYPSTR
      *iv_return = CMS$_BADTYPSTR;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "CMS__MUSTBEDIR", 14)) {
    /*                       ^            */
#ifdef CMS$_MUSTBEDIR
      *iv_return = CMS$_MUSTBEDIR;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "CMS__MUSTBEFIL", 14)) {
    /*                       ^            */
#ifdef CMS$_MUSTBEFIL
      *iv_return = CMS$_MUSTBEFIL;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "CMS__MUSTBEPOS", 14)) {
    /*                       ^            */
#ifdef CMS$_MUSTBEPOS
      *iv_return = CMS$_MUSTBEPOS;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "CMS__SYSTIMDIF", 14)) {
    /*                       ^            */
#ifdef CMS$_SYSTIMDIF
      *iv_return = CMS$_SYSTIMDIF;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "CMS__SYSTIMERR", 14)) {
    /*                       ^            */
#ifdef CMS$_SYSTIMERR
      *iv_return = CMS$_SYSTIMERR;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'U':
    if (memEQ(name, "CMS__MSGUPDATE", 14)) {
    /*                       ^            */
#ifdef CMS$_MSGUPDATE
      *iv_return = CMS$_MSGUPDATE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "CMS__SEQUENCED", 14)) {
    /*                       ^            */
#ifdef CMS$_SEQUENCED
      *iv_return = CMS$_SEQUENCED;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "CMS__UNSUPFRMT", 14)) {
    /*                       ^            */
#ifdef CMS$_UNSUPFRMT
      *iv_return = CMS$_UNSUPFRMT;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'V':
    if (memEQ(name, "CMS__BADVERSTR", 14)) {
    /*                       ^            */
#ifdef CMS$_BADVERSTR
      *iv_return = CMS$_BADVERSTR;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "CMS__CONVERTED", 14)) {
    /*                       ^            */
#ifdef CMS$_CONVERTED
      *iv_return = CMS$_CONVERTED;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "CMS__ERRVERARC", 14)) {
    /*                       ^            */
#ifdef CMS$_ERRVERARC
      *iv_return = CMS$_ERRVERARC;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "CMS__ERRVERCLS", 14)) {
    /*                       ^            */
#ifdef CMS$_ERRVERCLS
      *iv_return = CMS$_ERRVERCLS;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "CMS__ERRVERCMD", 14)) {
    /*                       ^            */
#ifdef CMS$_ERRVERCMD
      *iv_return = CMS$_ERRVERCMD;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "CMS__ERRVERCON", 14)) {
    /*                       ^            */
#ifdef CMS$_ERRVERCON
      *iv_return = CMS$_ERRVERCON;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "CMS__ERRVERELE", 14)) {
    /*                       ^            */
#ifdef CMS$_ERRVERELE
      *iv_return = CMS$_ERRVERELE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "CMS__ERRVERFRE", 14)) {
    /*                       ^            */
#ifdef CMS$_ERRVERFRE
      *iv_return = CMS$_ERRVERFRE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "CMS__ERRVERGEN", 14)) {
    /*                       ^            */
#ifdef CMS$_ERRVERGEN
      *iv_return = CMS$_ERRVERGEN;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "CMS__ERRVERGRP", 14)) {
    /*                       ^            */
#ifdef CMS$_ERRVERGRP
      *iv_return = CMS$_ERRVERGRP;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "CMS__ERRVERRES", 14)) {
    /*                       ^            */
#ifdef CMS$_ERRVERRES
      *iv_return = CMS$_ERRVERRES;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "CMS__ERRVERSTR", 14)) {
    /*                       ^            */
#ifdef CMS$_ERRVERSTR
      *iv_return = CMS$_ERRVERSTR;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "CMS__POSVALREQ", 14)) {
    /*                       ^            */
#ifdef CMS$_POSVALREQ
      *iv_return = CMS$_POSVALREQ;
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
constant_15 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     CMS_K_ACL_CLASS CMS_K_ACL_GROUP CMS_K_SUPERSEDE CMS_M_CMD_FETCH
     CMS__ALRDYINCLS CMS__ALRDYINGRP CMS__AUTORECSUC CMS__BADCRETIME
     CMS__BADVERSION CMS__CONCURRENT CMS__CONVERTLIB CMS__CONVNOTNEC
     CMS__DEFAULTDIR CMS__ELEMULTRES CMS__ERRCREATES CMS__ERREMOVALS
     CMS__ERRFETCHES CMS__ERRHISLINE CMS__ERRMODACLS CMS__ERRREVIEWS
     CMS__ERRVEREDFS CMS__ERRVERREFS CMS__GENCREATED CMS__GENDELETED
     CMS__GENMULTRES CMS__GENRECSIZE CMS__GENREMOVED CMS__GENTOODEEP
     CMS__HASMEMBERS CMS__IDENTCLASS CMS__ILLEGALDEV CMS__INSERTIONS
     CMS__ISRESERVED CMS__MERGECOUNT CMS__NEEDNUMBER CMS__NEEDPERIOD
     CMS__NOANNOTATE CMS__NOEXTENDED CMS__NOHISNOTES CMS__NORESNOCON
     CMS__NORETRIEVE CMS__NOREVSPEND CMS__NOTRESBYOU CMS__PROCEEDING
     CMS__REJECTIONS CMS__RETRIEVALS CMS__REVPENDING CMS__SIZEMISMAT
     CMS__UNRESERVED CMS__UNRESERVES CMS__USERECOVER CMS__VARINRANGE
     CMS__VERREFERRW CMS__WILDNEEDED */
  /* Offset 12 gives the best switch position.  */
  switch (name[12]) {
  case 'A':
    if (memEQ(name, "CMS_K_ACL_CLASS", 15)) {
    /*                           ^         */
#ifdef CMS$K_ACL_CLASS
      *iv_return = CMS$K_ACL_CLASS;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "CMS__ERREMOVALS", 15)) {
    /*                           ^         */
#ifdef CMS$_ERREMOVALS
      *iv_return = CMS$_ERREMOVALS;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "CMS__IDENTCLASS", 15)) {
    /*                           ^         */
#ifdef CMS$_IDENTCLASS
      *iv_return = CMS$_IDENTCLASS;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "CMS__NOANNOTATE", 15)) {
    /*                           ^         */
#ifdef CMS$_NOANNOTATE
      *iv_return = CMS$_NOANNOTATE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "CMS__RETRIEVALS", 15)) {
    /*                           ^         */
#ifdef CMS$_RETRIEVALS
      *iv_return = CMS$_RETRIEVALS;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'B':
    if (memEQ(name, "CMS__NEEDNUMBER", 15)) {
    /*                           ^         */
#ifdef CMS$_NEEDNUMBER
      *iv_return = CMS$_NEEDNUMBER;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'C':
    if (memEQ(name, "CMS__ALRDYINCLS", 15)) {
    /*                           ^         */
#ifdef CMS$_ALRDYINCLS
      *iv_return = CMS$_ALRDYINCLS;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "CMS__ERRMODACLS", 15)) {
    /*                           ^         */
#ifdef CMS$_ERRMODACLS
      *iv_return = CMS$_ERRMODACLS;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "CMS__NORESNOCON", 15)) {
    /*                           ^         */
#ifdef CMS$_NORESNOCON
      *iv_return = CMS$_NORESNOCON;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'D':
    if (memEQ(name, "CMS__DEFAULTDIR", 15)) {
    /*                           ^         */
#ifdef CMS$_DEFAULTDIR
      *iv_return = CMS$_DEFAULTDIR;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "CMS__ERRVEREDFS", 15)) {
    /*                           ^         */
#ifdef CMS$_ERRVEREDFS
      *iv_return = CMS$_ERRVEREDFS;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "CMS__ILLEGALDEV", 15)) {
    /*                           ^         */
#ifdef CMS$_ILLEGALDEV
      *iv_return = CMS$_ILLEGALDEV;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "CMS__NOEXTENDED", 15)) {
    /*                           ^         */
#ifdef CMS$_NOEXTENDED
      *iv_return = CMS$_NOEXTENDED;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "CMS__WILDNEEDED", 15)) {
    /*                           ^         */
#ifdef CMS$_WILDNEEDED
      *iv_return = CMS$_WILDNEEDED;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'E':
    if (memEQ(name, "CMS_K_SUPERSEDE", 15)) {
    /*                           ^         */
#ifdef CMS$K_SUPERSEDE
      *iv_return = CMS$K_SUPERSEDE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "CMS__CONCURRENT", 15)) {
    /*                           ^         */
#ifdef CMS$_CONCURRENT
      *iv_return = CMS$_CONCURRENT;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "CMS__ERRREVIEWS", 15)) {
    /*                           ^         */
#ifdef CMS$_ERRREVIEWS
      *iv_return = CMS$_ERRREVIEWS;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "CMS__ERRVERREFS", 15)) {
    /*                           ^         */
#ifdef CMS$_ERRVERREFS
      *iv_return = CMS$_ERRVERREFS;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "CMS__GENTOODEEP", 15)) {
    /*                           ^         */
#ifdef CMS$_GENTOODEEP
      *iv_return = CMS$_GENTOODEEP;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "CMS__HASMEMBERS", 15)) {
    /*                           ^         */
#ifdef CMS$_HASMEMBERS
      *iv_return = CMS$_HASMEMBERS;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "CMS__NORETRIEVE", 15)) {
    /*                           ^         */
#ifdef CMS$_NORETRIEVE
      *iv_return = CMS$_NORETRIEVE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "CMS__NOREVSPEND", 15)) {
    /*                           ^         */
#ifdef CMS$_NOREVSPEND
      *iv_return = CMS$_NOREVSPEND;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'G':
    if (memEQ(name, "CMS__ALRDYINGRP", 15)) {
    /*                           ^         */
#ifdef CMS$_ALRDYINGRP
      *iv_return = CMS$_ALRDYINGRP;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'H':
    if (memEQ(name, "CMS__ERRFETCHES", 15)) {
    /*                           ^         */
#ifdef CMS$_ERRFETCHES
      *iv_return = CMS$_ERRFETCHES;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'I':
    if (memEQ(name, "CMS__BADCRETIME", 15)) {
    /*                           ^         */
#ifdef CMS$_BADCRETIME
      *iv_return = CMS$_BADCRETIME;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "CMS__BADVERSION", 15)) {
    /*                           ^         */
#ifdef CMS$_BADVERSION
      *iv_return = CMS$_BADVERSION;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "CMS__ERRHISLINE", 15)) {
    /*                           ^         */
#ifdef CMS$_ERRHISLINE
      *iv_return = CMS$_ERRHISLINE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "CMS__GENRECSIZE", 15)) {
    /*                           ^         */
#ifdef CMS$_GENRECSIZE
      *iv_return = CMS$_GENRECSIZE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "CMS__NEEDPERIOD", 15)) {
    /*                           ^         */
#ifdef CMS$_NEEDPERIOD
      *iv_return = CMS$_NEEDPERIOD;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "CMS__PROCEEDING", 15)) {
    /*                           ^         */
#ifdef CMS$_PROCEEDING
      *iv_return = CMS$_PROCEEDING;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "CMS__REVPENDING", 15)) {
    /*                           ^         */
#ifdef CMS$_REVPENDING
      *iv_return = CMS$_REVPENDING;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'L':
    if (memEQ(name, "CMS__CONVERTLIB", 15)) {
    /*                           ^         */
#ifdef CMS$_CONVERTLIB
      *iv_return = CMS$_CONVERTLIB;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'M':
    if (memEQ(name, "CMS__SIZEMISMAT", 15)) {
    /*                           ^         */
#ifdef CMS$_SIZEMISMAT
      *iv_return = CMS$_SIZEMISMAT;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'N':
    if (memEQ(name, "CMS__CONVNOTNEC", 15)) {
    /*                           ^         */
#ifdef CMS$_CONVNOTNEC
      *iv_return = CMS$_CONVNOTNEC;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "CMS__VARINRANGE", 15)) {
    /*                           ^         */
#ifdef CMS$_VARINRANGE
      *iv_return = CMS$_VARINRANGE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'O':
    if (memEQ(name, "CMS_K_ACL_GROUP", 15)) {
    /*                           ^         */
#ifdef CMS$K_ACL_GROUP
      *iv_return = CMS$K_ACL_GROUP;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "CMS__INSERTIONS", 15)) {
    /*                           ^         */
#ifdef CMS$_INSERTIONS
      *iv_return = CMS$_INSERTIONS;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "CMS__REJECTIONS", 15)) {
    /*                           ^         */
#ifdef CMS$_REJECTIONS
      *iv_return = CMS$_REJECTIONS;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'R':
    if (memEQ(name, "CMS__ELEMULTRES", 15)) {
    /*                           ^         */
#ifdef CMS$_ELEMULTRES
      *iv_return = CMS$_ELEMULTRES;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "CMS__GENMULTRES", 15)) {
    /*                           ^         */
#ifdef CMS$_GENMULTRES
      *iv_return = CMS$_GENMULTRES;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "CMS__VERREFERRW", 15)) {
    /*                           ^         */
#ifdef CMS$_VERREFERRW
      *iv_return = CMS$_VERREFERRW;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'S':
    if (memEQ(name, "CMS__AUTORECSUC", 15)) {
    /*                           ^         */
#ifdef CMS$_AUTORECSUC
      *iv_return = CMS$_AUTORECSUC;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'T':
    if (memEQ(name, "CMS_M_CMD_FETCH", 15)) {
    /*                           ^         */
#ifdef CMS$K_CMD_FETCH
      *iv_return = CMS$K_CMD_FETCH;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "CMS__ERRCREATES", 15)) {
    /*                           ^         */
#ifdef CMS$_ERRCREATES
      *iv_return = CMS$_ERRCREATES;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "CMS__GENCREATED", 15)) {
    /*                           ^         */
#ifdef CMS$_GENCREATED
      *iv_return = CMS$_GENCREATED;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "CMS__GENDELETED", 15)) {
    /*                           ^         */
#ifdef CMS$_GENDELETED
      *iv_return = CMS$_GENDELETED;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "CMS__NOHISNOTES", 15)) {
    /*                           ^         */
#ifdef CMS$_NOHISNOTES
      *iv_return = CMS$_NOHISNOTES;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'U':
    if (memEQ(name, "CMS__MERGECOUNT", 15)) {
    /*                           ^         */
#ifdef CMS$_MERGECOUNT
      *iv_return = CMS$_MERGECOUNT;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'V':
    if (memEQ(name, "CMS__GENREMOVED", 15)) {
    /*                           ^         */
#ifdef CMS$_GENREMOVED
      *iv_return = CMS$_GENREMOVED;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "CMS__ISRESERVED", 15)) {
    /*                           ^         */
#ifdef CMS$_ISRESERVED
      *iv_return = CMS$_ISRESERVED;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "CMS__UNRESERVED", 15)) {
    /*                           ^         */
#ifdef CMS$_UNRESERVED
      *iv_return = CMS$_UNRESERVED;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "CMS__UNRESERVES", 15)) {
    /*                           ^         */
#ifdef CMS$_UNRESERVES
      *iv_return = CMS$_UNRESERVES;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "CMS__USERECOVER", 15)) {
    /*                           ^         */
#ifdef CMS$_USERECOVER
      *iv_return = CMS$_USERECOVER;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'Y':
    if (memEQ(name, "CMS__NOTRESBYOU", 15)) {
    /*                           ^         */
#ifdef CMS$_NOTRESBYOU
      *iv_return = CMS$_NOTRESBYOU;
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
constant_16 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     CMS_M_CMD_ACCEPT CMS_M_CMD_CANCEL CMS_M_CMD_CREATE CMS_M_CMD_DELETE
     CMS_M_CMD_INSERT CMS_M_CMD_MODIFY CMS_M_CMD_REJECT CMS_M_CMD_REMARK
     CMS_M_CMD_REMOVE CMS_M_CMD_VERIFY CMS__ACCEPTANCES CMS__ALRDYEXISTS
     CMS__ALRDYMARKED CMS__ANNOTATIONS CMS__ARGCONFLICT CMS__ARGCOUNTERR
     CMS__CLASSGENEXP CMS__ERRMODIFIES CMS__EXTENDEDLIB CMS__GENINSERTED
     CMS__GENNOINSERT CMS__GENNOREMOVE CMS__GENNOTFOUND CMS__IDENTNOTRES
     CMS__INCRANGSPEC CMS__LIBALRINLIS CMS__LIBNOTINLIS CMS__MSGCONTINUE
     CMS__NOALTDELETE CMS__NOCOMMALIST CMS__NODELACCESS CMS__NODELETIONS
     CMS__NODELFUTURE CMS__NOGENBEFORE CMS__NOMOREPARAM CMS__NOREPBCKPTR
     CMS__NOREPGENLRL CMS__NOREPGENMRS CMS__NOSUPERSEDE CMS__NOTESVALREQ
     CMS__NOUNRESERVE CMS__TOOMANYLIBS CMS__WILDNOMATCH */
  /* Offset 10 gives the best switch position.  */
  switch (name[10]) {
  case 'A':
    if (memEQ(name, "CMS_M_CMD_ACCEPT", 16)) {
    /*                         ^            */
#ifdef CMS$K_CMD_ACCEPT
      *iv_return = CMS$K_CMD_ACCEPT;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "CMS__ANNOTATIONS", 16)) {
    /*                         ^            */
#ifdef CMS$_ANNOTATIONS
      *iv_return = CMS$_ANNOTATIONS;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "CMS__NODELACCESS", 16)) {
    /*                         ^            */
#ifdef CMS$_NODELACCESS
      *iv_return = CMS$_NODELACCESS;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'B':
    if (memEQ(name, "CMS__NOGENBEFORE", 16)) {
    /*                         ^            */
#ifdef CMS$_NOGENBEFORE
      *iv_return = CMS$_NOGENBEFORE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "CMS__NOREPBCKPTR", 16)) {
    /*                         ^            */
#ifdef CMS$_NOREPBCKPTR
      *iv_return = CMS$_NOREPBCKPTR;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'C':
    if (memEQ(name, "CMS_M_CMD_CANCEL", 16)) {
    /*                         ^            */
#ifdef CMS$K_CMD_CANCEL
      *iv_return = CMS$K_CMD_CANCEL;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "CMS_M_CMD_CREATE", 16)) {
    /*                         ^            */
#ifdef CMS$K_CMD_CREATE
      *iv_return = CMS$K_CMD_CREATE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'D':
    if (memEQ(name, "CMS_M_CMD_DELETE", 16)) {
    /*                         ^            */
#ifdef CMS$K_CMD_DELETE
      *iv_return = CMS$K_CMD_DELETE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "CMS__ERRMODIFIES", 16)) {
    /*                         ^            */
#ifdef CMS$_ERRMODIFIES
      *iv_return = CMS$_ERRMODIFIES;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "CMS__EXTENDEDLIB", 16)) {
    /*                         ^            */
#ifdef CMS$_EXTENDEDLIB
      *iv_return = CMS$_EXTENDEDLIB;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "CMS__NOALTDELETE", 16)) {
    /*                         ^            */
#ifdef CMS$_NOALTDELETE
      *iv_return = CMS$_NOALTDELETE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'E':
    if (memEQ(name, "CMS__ALRDYEXISTS", 16)) {
    /*                         ^            */
#ifdef CMS$_ALRDYEXISTS
      *iv_return = CMS$_ALRDYEXISTS;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "CMS__NODELETIONS", 16)) {
    /*                         ^            */
#ifdef CMS$_NODELETIONS
      *iv_return = CMS$_NODELETIONS;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "CMS__NOMOREPARAM", 16)) {
    /*                         ^            */
#ifdef CMS$_NOMOREPARAM
      *iv_return = CMS$_NOMOREPARAM;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "CMS__NOSUPERSEDE", 16)) {
    /*                         ^            */
#ifdef CMS$_NOSUPERSEDE
      *iv_return = CMS$_NOSUPERSEDE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "CMS__NOUNRESERVE", 16)) {
    /*                         ^            */
#ifdef CMS$_NOUNRESERVE
      *iv_return = CMS$_NOUNRESERVE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'F':
    if (memEQ(name, "CMS__NODELFUTURE", 16)) {
    /*                         ^            */
#ifdef CMS$_NODELFUTURE
      *iv_return = CMS$_NODELFUTURE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'G':
    if (memEQ(name, "CMS__CLASSGENEXP", 16)) {
    /*                         ^            */
#ifdef CMS$_CLASSGENEXP
      *iv_return = CMS$_CLASSGENEXP;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "CMS__NOREPGENLRL", 16)) {
    /*                         ^            */
#ifdef CMS$_NOREPGENLRL
      *iv_return = CMS$_NOREPGENLRL;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "CMS__NOREPGENMRS", 16)) {
    /*                         ^            */
#ifdef CMS$_NOREPGENMRS
      *iv_return = CMS$_NOREPGENMRS;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'I':
    if (memEQ(name, "CMS_M_CMD_INSERT", 16)) {
    /*                         ^            */
#ifdef CMS$K_CMD_INSERT
      *iv_return = CMS$K_CMD_INSERT;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "CMS__GENNOINSERT", 16)) {
    /*                         ^            */
#ifdef CMS$_GENNOINSERT
      *iv_return = CMS$_GENNOINSERT;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'M':
    if (memEQ(name, "CMS_M_CMD_MODIFY", 16)) {
    /*                         ^            */
#ifdef CMS$K_CMD_MODIFY
      *iv_return = CMS$K_CMD_MODIFY;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "CMS__ALRDYMARKED", 16)) {
    /*                         ^            */
#ifdef CMS$_ALRDYMARKED
      *iv_return = CMS$_ALRDYMARKED;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "CMS__NOCOMMALIST", 16)) {
    /*                         ^            */
#ifdef CMS$_NOCOMMALIST
      *iv_return = CMS$_NOCOMMALIST;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'N':
    if (memEQ(name, "CMS__ARGCONFLICT", 16)) {
    /*                         ^            */
#ifdef CMS$_ARGCONFLICT
      *iv_return = CMS$_ARGCONFLICT;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "CMS__IDENTNOTRES", 16)) {
    /*                         ^            */
#ifdef CMS$_IDENTNOTRES
      *iv_return = CMS$_IDENTNOTRES;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "CMS__INCRANGSPEC", 16)) {
    /*                         ^            */
#ifdef CMS$_INCRANGSPEC
      *iv_return = CMS$_INCRANGSPEC;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "CMS__MSGCONTINUE", 16)) {
    /*                         ^            */
#ifdef CMS$_MSGCONTINUE
      *iv_return = CMS$_MSGCONTINUE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "CMS__TOOMANYLIBS", 16)) {
    /*                         ^            */
#ifdef CMS$_TOOMANYLIBS
      *iv_return = CMS$_TOOMANYLIBS;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'O':
    if (memEQ(name, "CMS__WILDNOMATCH", 16)) {
    /*                         ^            */
#ifdef CMS$_WILDNOMATCH
      *iv_return = CMS$_WILDNOMATCH;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'R':
    if (memEQ(name, "CMS_M_CMD_REJECT", 16)) {
    /*                         ^            */
#ifdef CMS$K_CMD_REJECT
      *iv_return = CMS$K_CMD_REJECT;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "CMS_M_CMD_REMARK", 16)) {
    /*                         ^            */
#ifdef CMS$K_CMD_REMARK
      *iv_return = CMS$K_CMD_REMARK;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "CMS_M_CMD_REMOVE", 16)) {
    /*                         ^            */
#ifdef CMS$K_CMD_REMOVE
      *iv_return = CMS$K_CMD_REMOVE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "CMS__GENNOREMOVE", 16)) {
    /*                         ^            */
#ifdef CMS$_GENNOREMOVE
      *iv_return = CMS$_GENNOREMOVE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "CMS__LIBALRINLIS", 16)) {
    /*                         ^            */
#ifdef CMS$_LIBALRINLIS
      *iv_return = CMS$_LIBALRINLIS;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'S':
    if (memEQ(name, "CMS__GENINSERTED", 16)) {
    /*                         ^            */
#ifdef CMS$_GENINSERTED
      *iv_return = CMS$_GENINSERTED;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'T':
    if (memEQ(name, "CMS__ACCEPTANCES", 16)) {
    /*                         ^            */
#ifdef CMS$_ACCEPTANCES
      *iv_return = CMS$_ACCEPTANCES;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "CMS__GENNOTFOUND", 16)) {
    /*                         ^            */
#ifdef CMS$_GENNOTFOUND
      *iv_return = CMS$_GENNOTFOUND;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "CMS__LIBNOTINLIS", 16)) {
    /*                         ^            */
#ifdef CMS$_LIBNOTINLIS
      *iv_return = CMS$_LIBNOTINLIS;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'U':
    if (memEQ(name, "CMS__ARGCOUNTERR", 16)) {
    /*                         ^            */
#ifdef CMS$_ARGCOUNTERR
      *iv_return = CMS$_ARGCOUNTERR;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'V':
    if (memEQ(name, "CMS_M_CMD_VERIFY", 16)) {
    /*                         ^            */
#ifdef CMS$K_CMD_VERIFY
      *iv_return = CMS$K_CMD_VERIFY;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "CMS__NOTESVALREQ", 16)) {
    /*                         ^            */
#ifdef CMS$_NOTESVALREQ
      *iv_return = CMS$_NOTESVALREQ;
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
constant_17 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     CMS_K_ACL_COMMAND CMS_K_ACL_ELEMENT CMS_K_ACL_LIBRARY CMS_M_CMD_REPLACE
     CMS_M_CMD_RESERVE CMS_M_CMD_REVIEW_ CMS_M_ELEMENT_DIF CMS_M_HEXADECIMAL
     CMS_M_IGNORE_CASE CMS_M_IGNORE_FORM CMS_M_IGNORE_LEAD CMS_M_VARIANT_DIF
     CMS__CANCELATIONS CMS__ERRDELETIONS CMS__ERRETRIEVALS CMS__GENDELETIONS
     CMS__LIBLISNOTMOD CMS__LONGVARFOUND CMS__NOGENDELETED CMS__NOREPSEQDATA
     CMS__NOTCOMPLETED CMS__QUALCONFLICT CMS__REPILLDATREC CMS__REPLACEMENTS
     CMS__RESERVATIONS CMS__VERILLDATREC CMS__WILDCONFLICT */
  /* Offset 12 gives the best switch position.  */
  switch (name[12]) {
  case 'A':
    if (memEQ(name, "CMS__REPILLDATREC", 17)) {
    /*                           ^           */
#ifdef CMS$_REPILLDATREC
      *iv_return = CMS$_REPILLDATREC;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "CMS__VERILLDATREC", 17)) {
    /*                           ^           */
#ifdef CMS$_VERILLDATREC
      *iv_return = CMS$_VERILLDATREC;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'B':
    if (memEQ(name, "CMS_K_ACL_LIBRARY", 17)) {
    /*                           ^           */
#ifdef CMS$K_ACL_LIBRARY
      *iv_return = CMS$K_ACL_LIBRARY;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'C':
    if (memEQ(name, "CMS_M_HEXADECIMAL", 17)) {
    /*                           ^           */
#ifdef CMS$K_HEXADECIMAL
      *iv_return = CMS$K_HEXADECIMAL;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'E':
    if (memEQ(name, "CMS_K_ACL_ELEMENT", 17)) {
    /*                           ^           */
#ifdef CMS$K_ACL_ELEMENT
      *iv_return = CMS$K_ACL_ELEMENT;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "CMS__ERRETRIEVALS", 17)) {
    /*                           ^           */
#ifdef CMS$_ERRETRIEVALS
      *iv_return = CMS$_ERRETRIEVALS;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'F':
    if (memEQ(name, "CMS__LONGVARFOUND", 17)) {
    /*                           ^           */
#ifdef CMS$_LONGVARFOUND
      *iv_return = CMS$_LONGVARFOUND;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "CMS__QUALCONFLICT", 17)) {
    /*                           ^           */
#ifdef CMS$_QUALCONFLICT
      *iv_return = CMS$_QUALCONFLICT;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "CMS__WILDCONFLICT", 17)) {
    /*                           ^           */
#ifdef CMS$_WILDCONFLICT
      *iv_return = CMS$_WILDCONFLICT;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'L':
    if (memEQ(name, "CMS__NOGENDELETED", 17)) {
    /*                           ^           */
#ifdef CMS$_NOGENDELETED
      *iv_return = CMS$_NOGENDELETED;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "CMS__NOTCOMPLETED", 17)) {
    /*                           ^           */
#ifdef CMS$_NOTCOMPLETED
      *iv_return = CMS$_NOTCOMPLETED;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'M':
    if (memEQ(name, "CMS_K_ACL_COMMAND", 17)) {
    /*                           ^           */
#ifdef CMS$K_ACL_COMMAND
      *iv_return = CMS$K_ACL_COMMAND;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "CMS__REPLACEMENTS", 17)) {
    /*                           ^           */
#ifdef CMS$_REPLACEMENTS
      *iv_return = CMS$_REPLACEMENTS;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'O':
    if (memEQ(name, "CMS__LIBLISNOTMOD", 17)) {
    /*                           ^           */
#ifdef CMS$_LIBLISNOTMOD
      *iv_return = CMS$_LIBLISNOTMOD;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'P':
    if (memEQ(name, "CMS_M_CMD_REPLACE", 17)) {
    /*                           ^           */
#ifdef CMS$K_CMD_REPLACE
      *iv_return = CMS$K_CMD_REPLACE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'Q':
    if (memEQ(name, "CMS__NOREPSEQDATA", 17)) {
    /*                           ^           */
#ifdef CMS$_NOREPSEQDATA
      *iv_return = CMS$_NOREPSEQDATA;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'S':
    if (memEQ(name, "CMS_M_CMD_RESERVE", 17)) {
    /*                           ^           */
#ifdef CMS$K_CMD_RESERVE
      *iv_return = CMS$K_CMD_RESERVE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'T':
    if (memEQ(name, "CMS_M_ELEMENT_DIF", 17)) {
    /*                           ^           */
#ifdef CMS$M_ELEMENT_DIF
      *iv_return = CMS$M_ELEMENT_DIF;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "CMS_M_VARIANT_DIF", 17)) {
    /*                           ^           */
#ifdef CMS$M_VARIANT_DIF
      *iv_return = CMS$M_VARIANT_DIF;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "CMS__CANCELATIONS", 17)) {
    /*                           ^           */
#ifdef CMS$_CANCELATIONS
      *iv_return = CMS$_CANCELATIONS;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "CMS__ERRDELETIONS", 17)) {
    /*                           ^           */
#ifdef CMS$_ERRDELETIONS
      *iv_return = CMS$_ERRDELETIONS;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "CMS__GENDELETIONS", 17)) {
    /*                           ^           */
#ifdef CMS$_GENDELETIONS
      *iv_return = CMS$_GENDELETIONS;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "CMS__RESERVATIONS", 17)) {
    /*                           ^           */
#ifdef CMS$_RESERVATIONS
      *iv_return = CMS$_RESERVATIONS;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'V':
    if (memEQ(name, "CMS_M_CMD_REVIEW_", 17)) {
    /*                           ^           */
#ifdef CMS$K_CMD_REVIEW
      *iv_return = CMS$K_CMD_REVIEW;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case '_':
    if (memEQ(name, "CMS_M_IGNORE_CASE", 17)) {
    /*                           ^           */
#ifdef CMS$M_IGNORE_CASE
      *iv_return = CMS$M_IGNORE_CASE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "CMS_M_IGNORE_FORM", 17)) {
    /*                           ^           */
#ifdef CMS$M_IGNORE_FORM
      *iv_return = CMS$M_IGNORE_FORM;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "CMS_M_IGNORE_LEAD", 17)) {
    /*                           ^           */
#ifdef CMS$M_IGNORE_LEAD
      *iv_return = CMS$M_IGNORE_LEAD;
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
     CMS_M_IGNORE_NOTES CMS_M_IGNORE_SPACE CMS_M_IGNORE_TRAIL
     CMS__EDFINWRONGDIR CMS__ERRINSERTIONS CMS__ERRREJECTIONS
     CMS__ERRUNRESERVES CMS__MERGECONFLICT CMS__MODIFICATIONS
     CMS__NOEXTENDEDREF CMS__NORESERVATION CMS__RESERVEDBYYOU */
  /* Offset 14 gives the best switch position.  */
  switch (name[14]) {
  case 'D':
    if (memEQ(name, "CMS__NOEXTENDEDREF", 18)) {
    /*                             ^          */
#ifdef CMS$_NOEXTENDEDREF
      *iv_return = CMS$_NOEXTENDEDREF;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'G':
    if (memEQ(name, "CMS__EDFINWRONGDIR", 18)) {
    /*                             ^          */
#ifdef CMS$_EDFINWRONGDIR
      *iv_return = CMS$_EDFINWRONGDIR;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'I':
    if (memEQ(name, "CMS__ERRINSERTIONS", 18)) {
    /*                             ^          */
#ifdef CMS$_ERRINSERTIONS
      *iv_return = CMS$_ERRINSERTIONS;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "CMS__ERRREJECTIONS", 18)) {
    /*                             ^          */
#ifdef CMS$_ERRREJECTIONS
      *iv_return = CMS$_ERRREJECTIONS;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "CMS__MODIFICATIONS", 18)) {
    /*                             ^          */
#ifdef CMS$_MODIFICATIONS
      *iv_return = CMS$_MODIFICATIONS;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'L':
    if (memEQ(name, "CMS__MERGECONFLICT", 18)) {
    /*                             ^          */
#ifdef CMS$_MERGECONFLICT
      *iv_return = CMS$_MERGECONFLICT;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'O':
    if (memEQ(name, "CMS_M_IGNORE_NOTES", 18)) {
    /*                             ^          */
#ifdef CMS$M_IGNORE_NOTES
      *iv_return = CMS$M_IGNORE_NOTES;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'P':
    if (memEQ(name, "CMS_M_IGNORE_SPACE", 18)) {
    /*                             ^          */
#ifdef CMS$M_IGNORE_SPACE
      *iv_return = CMS$M_IGNORE_SPACE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'R':
    if (memEQ(name, "CMS_M_IGNORE_TRAIL", 18)) {
    /*                             ^          */
#ifdef CMS$M_IGNORE_TRAIL
      *iv_return = CMS$M_IGNORE_TRAIL;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "CMS__ERRUNRESERVES", 18)) {
    /*                             ^          */
#ifdef CMS$_ERRUNRESERVES
      *iv_return = CMS$_ERRUNRESERVES;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'T':
    if (memEQ(name, "CMS__NORESERVATION", 18)) {
    /*                             ^          */
#ifdef CMS$_NORESERVATION
      *iv_return = CMS$_NORESERVATION;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'Y':
    if (memEQ(name, "CMS__RESERVEDBYYOU", 18)) {
    /*                             ^          */
#ifdef CMS$_RESERVEDBYYOU
      *iv_return = CMS$_RESERVEDBYYOU;
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
constant_19 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     CMS_M_CMD_UNRESERVE CMS__ERRACCEPTANCES CMS__ERRANNOTATIONS
     CMS__ERREPLACEMENTS CMS__ERRESERVATIONS CMS__NOEDFIWDREPAIR */
  /* Offset 10 gives the best switch position.  */
  switch (name[10]) {
  case 'C':
    if (memEQ(name, "CMS__ERRACCEPTANCES", 19)) {
    /*                         ^               */
#ifdef CMS$_ERRACCEPTANCES
      *iv_return = CMS$_ERRACCEPTANCES;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'E':
    if (memEQ(name, "CMS__ERRESERVATIONS", 19)) {
    /*                         ^               */
#ifdef CMS$_ERRESERVATIONS
      *iv_return = CMS$_ERRESERVATIONS;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'I':
    if (memEQ(name, "CMS__NOEDFIWDREPAIR", 19)) {
    /*                         ^               */
#ifdef CMS$_NOEDFIWDREPAIR
      *iv_return = CMS$_NOEDFIWDREPAIR;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'L':
    if (memEQ(name, "CMS__ERREPLACEMENTS", 19)) {
    /*                         ^               */
#ifdef CMS$_ERREPLACEMENTS
      *iv_return = CMS$_ERREPLACEMENTS;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'N':
    if (memEQ(name, "CMS__ERRANNOTATIONS", 19)) {
    /*                         ^               */
#ifdef CMS$_ERRANNOTATIONS
      *iv_return = CMS$_ERRANNOTATIONS;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'U':
    if (memEQ(name, "CMS_M_CMD_UNRESERVE", 19)) {
    /*                         ^               */
#ifdef CMS$K_CMD_UNRESERVE
      *iv_return = CMS$K_CMD_UNRESERVE;
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
constant_20 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     CMS_M_GENERATION_DIF CMS_M_IGNORE_HISTORY CMS__ERRCANCELATIONS
     CMS__ERRGENDELETIONS */
  /* Offset 11 gives the best switch position.  */
  switch (name[11]) {
  case 'A':
    if (memEQ(name, "CMS_M_GENERATION_DIF", 20)) {
    /*                          ^               */
#ifdef CMS$K_GENERATION_DIF
      *iv_return = CMS$K_GENERATION_DIF;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'C':
    if (memEQ(name, "CMS__ERRCANCELATIONS", 20)) {
    /*                          ^               */
#ifdef CMS$_ERRCANCELATIONS
      *iv_return = CMS$_ERRCANCELATIONS;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'D':
    if (memEQ(name, "CMS__ERRGENDELETIONS", 20)) {
    /*                          ^               */
#ifdef CMS$_ERRGENDELETIONS
      *iv_return = CMS$_ERRGENDELETIONS;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'E':
    if (memEQ(name, "CMS_M_IGNORE_HISTORY", 20)) {
    /*                          ^               */
#ifdef CMS$M_IGNORE_HISTORY
      *iv_return = CMS$M_IGNORE_HISTORY;
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

#!dka0:[perl-5_8_8_root.][000000]perl.exe;2 -w
use ExtUtils::Constant qw (constant_types C_constant XS_constant);

my $types = {map {($_, 1)} qw(IV)};
my @names = (qw(),
            {name=>"CMS_K_ACCEPT", type=>"IV", macro=>"CMS$K_ACCEPT", value=>"CMS$K_ACCEPT"},
            {name=>"CMS_K_ACL_CLASS", type=>"IV", macro=>"CMS$K_ACL_CLASS", value=>"CMS$K_ACL_CLASS"},
            {name=>"CMS_K_ACL_COMMAND", type=>"IV", macro=>"CMS$K_ACL_COMMAND", value=>"CMS$K_ACL_COMMAND"},
            {name=>"CMS_K_ACL_ELEMENT", type=>"IV", macro=>"CMS$K_ACL_ELEMENT", value=>"CMS$K_ACL_ELEMENT"},
            {name=>"CMS_K_ACL_GROUP", type=>"IV", macro=>"CMS$K_ACL_GROUP", value=>"CMS$K_ACL_GROUP"},
            {name=>"CMS_K_ACL_LIBRARY", type=>"IV", macro=>"CMS$K_ACL_LIBRARY", value=>"CMS$K_ACL_LIBRARY"},
            {name=>"CMS_K_AFTER", type=>"IV", macro=>"CMS$K_AFTER", value=>"CMS$K_AFTER"},
            {name=>"CMS_K_BEFORE", type=>"IV", macro=>"CMS$K_BEFORE", value=>"CMS$K_BEFORE"},
            {name=>"CMS_K_CANCEL", type=>"IV", macro=>"CMS$K_CANCEL", value=>"CMS$K_CANCEL"},
            {name=>"CMS_K_MARK", type=>"IV", macro=>"CMS$K_MARK", value=>"CMS$K_MARK"},
            {name=>"CMS_K_REJECT", type=>"IV", macro=>"CMS$K_REJECT", value=>"CMS$K_REJECT"},
            {name=>"CMS_K_REVIEW", type=>"IV", macro=>"CMS$K_REVIEW", value=>"CMS$K_REVIEW"},
            {name=>"CMS_K_SUPERSEDE", type=>"IV", macro=>"CMS$K_SUPERSEDE", value=>"CMS$K_SUPERSEDE"},
            {name=>"CMS_M_ASCII", type=>"IV", macro=>"CMS$K_ASCII", value=>"CMS$K_ASCII"},
            {name=>"CMS_M_BYTE", type=>"IV", macro=>"CMS$K_BYTE", value=>"CMS$K_BYTE"},
            {name=>"CMS_M_CMD_ACCEPT", type=>"IV", macro=>"CMS$K_CMD_ACCEPT", value=>"CMS$K_CMD_ACCEPT"},
            {name=>"CMS_M_CMD_CANCEL", type=>"IV", macro=>"CMS$K_CMD_CANCEL", value=>"CMS$K_CMD_CANCEL"},
            {name=>"CMS_M_CMD_COPY", type=>"IV", macro=>"CMS$K_CMD_COPY", value=>"CMS$K_CMD_COPY"},
            {name=>"CMS_M_CMD_CREATE", type=>"IV", macro=>"CMS$K_CMD_CREATE", value=>"CMS$K_CMD_CREATE"},
            {name=>"CMS_M_CMD_DELETE", type=>"IV", macro=>"CMS$K_CMD_DELETE", value=>"CMS$K_CMD_DELETE"},
            {name=>"CMS_M_CMD_FETCH", type=>"IV", macro=>"CMS$K_CMD_FETCH", value=>"CMS$K_CMD_FETCH"},
            {name=>"CMS_M_CMD_INSERT", type=>"IV", macro=>"CMS$K_CMD_INSERT", value=>"CMS$K_CMD_INSERT"},
            {name=>"CMS_M_CMD_MARK", type=>"IV", macro=>"CMS$K_CMD_MARK", value=>"CMS$K_CMD_MARK"},
            {name=>"CMS_M_CMD_MODIFY", type=>"IV", macro=>"CMS$K_CMD_MODIFY", value=>"CMS$K_CMD_MODIFY"},
            {name=>"CMS_M_CMD_REJECT", type=>"IV", macro=>"CMS$K_CMD_REJECT", value=>"CMS$K_CMD_REJECT"},
            {name=>"CMS_M_CMD_REMARK", type=>"IV", macro=>"CMS$K_CMD_REMARK", value=>"CMS$K_CMD_REMARK"},
            {name=>"CMS_M_CMD_REMOVE", type=>"IV", macro=>"CMS$K_CMD_REMOVE", value=>"CMS$K_CMD_REMOVE"},
            {name=>"CMS_M_CMD_REPLACE", type=>"IV", macro=>"CMS$K_CMD_REPLACE", value=>"CMS$K_CMD_REPLACE"},
            {name=>"CMS_M_CMD_RESERVE", type=>"IV", macro=>"CMS$K_CMD_RESERVE", value=>"CMS$K_CMD_RESERVE"},
            {name=>"CMS_M_CMD_REVIEW_", type=>"IV", macro=>"CMS$K_CMD_REVIEW", value=>"CMS$K_CMD_REVIEW"},
            {name=>"CMS_M_CMD_SET", type=>"IV", macro=>"CMS$K_CMD_SET", value=>"CMS$K_CMD_SET"},
            {name=>"CMS_M_CMD_UNRESERVE", type=>"IV", macro=>"CMS$K_CMD_UNRESERVE", value=>"CMS$K_CMD_UNRESERVE"},
            {name=>"CMS_M_CMD_VERIFY", type=>"IV", macro=>"CMS$K_CMD_VERIFY", value=>"CMS$K_CMD_VERIFY"},
            {name=>"CMS_M_DECIMAL", type=>"IV", macro=>"CMS$K_DECIMAL", value=>"CMS$K_DECIMAL"},
            {name=>"CMS_M_ELEMENT_DIF", type=>"IV", macro=>"CMS$M_ELEMENT_DIF", value=>"CMS$M_ELEMENT_DIF"},
            {name=>"CMS_M_GENERATIONAL_DIF", type=>"IV", macro=>"CMS$M_GENERATIONAL_DIF", value=>"CMS$M_GENERATIONAL_DIF"},
            {name=>"CMS_M_GENERATION_DIF", type=>"IV", macro=>"CMS$K_GENERATION_DIF", value=>"CMS$K_GENERATION_DIF"},
            {name=>"CMS_M_HEXADECIMAL", type=>"IV", macro=>"CMS$K_HEXADECIMAL", value=>"CMS$K_HEXADECIMAL"},
            {name=>"CMS_M_IGNORE_CASE", type=>"IV", macro=>"CMS$M_IGNORE_CASE", value=>"CMS$M_IGNORE_CASE"},
            {name=>"CMS_M_IGNORE_FIRST_VARIANT", type=>"IV", macro=>"CMS$M_IGNORE_FIRST_VARIANT", value=>"CMS$M_IGNORE_FIRST_VARIANT"},
            {name=>"CMS_M_IGNORE_FORM", type=>"IV", macro=>"CMS$M_IGNORE_FORM", value=>"CMS$M_IGNORE_FORM"},
            {name=>"CMS_M_IGNORE_HISTORY", type=>"IV", macro=>"CMS$M_IGNORE_HISTORY", value=>"CMS$M_IGNORE_HISTORY"},
            {name=>"CMS_M_IGNORE_LEAD", type=>"IV", macro=>"CMS$M_IGNORE_LEAD", value=>"CMS$M_IGNORE_LEAD"},
            {name=>"CMS_M_IGNORE_NOTES", type=>"IV", macro=>"CMS$M_IGNORE_NOTES", value=>"CMS$M_IGNORE_NOTES"},
            {name=>"CMS_M_IGNORE_SPACE", type=>"IV", macro=>"CMS$M_IGNORE_SPACE", value=>"CMS$M_IGNORE_SPACE"},
            {name=>"CMS_M_IGNORE_TRAIL", type=>"IV", macro=>"CMS$M_IGNORE_TRAIL", value=>"CMS$M_IGNORE_TRAIL"},
            {name=>"CMS_M_LONGWORD", type=>"IV", macro=>"CMS$K_LONGWORD", value=>"CMS$K_LONGWORD"},
            {name=>"CMS_M_OCTAL", type=>"IV", macro=>"CMS$K_OCTAL", value=>"CMS$K_OCTAL"},
            {name=>"CMS_M_RECORDS", type=>"IV", macro=>"CMS$K_RECORDS", value=>"CMS$K_RECORDS"},
            {name=>"CMS_M_VARIANT_DIF", type=>"IV", macro=>"CMS$M_VARIANT_DIF", value=>"CMS$M_VARIANT_DIF"},
            {name=>"CMS_M_WORD", type=>"IV", macro=>"CMS$K_WORD", value=>"CMS$K_WORD"},
            {name=>"CMS__ABSTIM", type=>"IV", macro=>"CMS$_ABSTIM", value=>"CMS$_ABSTIM"},
            {name=>"CMS__ACCEPTANCES", type=>"IV", macro=>"CMS$_ACCEPTANCES", value=>"CMS$_ACCEPTANCES"},
            {name=>"CMS__ACCEPTED", type=>"IV", macro=>"CMS$_ACCEPTED", value=>"CMS$_ACCEPTED"},
            {name=>"CMS__ACCVIORD", type=>"IV", macro=>"CMS$_ACCVIORD", value=>"CMS$_ACCVIORD"},
            {name=>"CMS__ACCVIOWT", type=>"IV", macro=>"CMS$_ACCVIOWT", value=>"CMS$_ACCVIOWT"},
            {name=>"CMS__ALL", type=>"IV", macro=>"CMS$_ALL", value=>"CMS$_ALL"},
            {name=>"CMS__ALPHACHAR", type=>"IV", macro=>"CMS$_ALPHACHAR", value=>"CMS$_ALPHACHAR"},
            {name=>"CMS__ALRDYEXISTS", type=>"IV", macro=>"CMS$_ALRDYEXISTS", value=>"CMS$_ALRDYEXISTS"},
            {name=>"CMS__ALRDYINCLS", type=>"IV", macro=>"CMS$_ALRDYINCLS", value=>"CMS$_ALRDYINCLS"},
            {name=>"CMS__ALRDYINGRP", type=>"IV", macro=>"CMS$_ALRDYINGRP", value=>"CMS$_ALRDYINGRP"},
            {name=>"CMS__ALRDYMARKED", type=>"IV", macro=>"CMS$_ALRDYMARKED", value=>"CMS$_ALRDYMARKED"},
            {name=>"CMS__ANNOTATED", type=>"IV", macro=>"CMS$_ANNOTATED", value=>"CMS$_ANNOTATED"},
            {name=>"CMS__ANNOTATIONS", type=>"IV", macro=>"CMS$_ANNOTATIONS", value=>"CMS$_ANNOTATIONS"},
            {name=>"CMS__ANNSIGNAL", type=>"IV", macro=>"CMS$_ANNSIGNAL", value=>"CMS$_ANNSIGNAL"},
            {name=>"CMS__ARGCONFLICT", type=>"IV", macro=>"CMS$_ARGCONFLICT", value=>"CMS$_ARGCONFLICT"},
            {name=>"CMS__ARGCOUNTERR", type=>"IV", macro=>"CMS$_ARGCOUNTERR", value=>"CMS$_ARGCOUNTERR"},
            {name=>"CMS__AUTOREC", type=>"IV", macro=>"CMS$_AUTOREC", value=>"CMS$_AUTOREC"},
            {name=>"CMS__AUTORECSUC", type=>"IV", macro=>"CMS$_AUTORECSUC", value=>"CMS$_AUTORECSUC"},
            {name=>"CMS__BADBUG", type=>"IV", macro=>"CMS$_BADBUG", value=>"CMS$_BADBUG"},
            {name=>"CMS__BADCALL", type=>"IV", macro=>"CMS$_BADCALL", value=>"CMS$_BADCALL"},
            {name=>"CMS__BADCRC", type=>"IV", macro=>"CMS$_BADCRC", value=>"CMS$_BADCRC"},
            {name=>"CMS__BADCRETIME", type=>"IV", macro=>"CMS$_BADCRETIME", value=>"CMS$_BADCRETIME"},
            {name=>"CMS__BADFORMAT", type=>"IV", macro=>"CMS$_BADFORMAT", value=>"CMS$_BADFORMAT"},
            {name=>"CMS__BADLENSTR", type=>"IV", macro=>"CMS$_BADLENSTR", value=>"CMS$_BADLENSTR"},
            {name=>"CMS__BADLIB", type=>"IV", macro=>"CMS$_BADLIB", value=>"CMS$_BADLIB"},
            {name=>"CMS__BADLST", type=>"IV", macro=>"CMS$_BADLST", value=>"CMS$_BADLST"},
            {name=>"CMS__BADLSTSTR", type=>"IV", macro=>"CMS$_BADLSTSTR", value=>"CMS$_BADLSTSTR"},
            {name=>"CMS__BADORDSTR", type=>"IV", macro=>"CMS$_BADORDSTR", value=>"CMS$_BADORDSTR"},
            {name=>"CMS__BADPTR", type=>"IV", macro=>"CMS$_BADPTR", value=>"CMS$_BADPTR"},
            {name=>"CMS__BADREF", type=>"IV", macro=>"CMS$_BADREF", value=>"CMS$_BADREF"},
            {name=>"CMS__BADREFHDR", type=>"IV", macro=>"CMS$_BADREFHDR", value=>"CMS$_BADREFHDR"},
            {name=>"CMS__BADSTRING", type=>"IV", macro=>"CMS$_BADSTRING", value=>"CMS$_BADSTRING"},
            {name=>"CMS__BADTYPSTR", type=>"IV", macro=>"CMS$_BADTYPSTR", value=>"CMS$_BADTYPSTR"},
            {name=>"CMS__BADVERSION", type=>"IV", macro=>"CMS$_BADVERSION", value=>"CMS$_BADVERSION"},
            {name=>"CMS__BADVERSTR", type=>"IV", macro=>"CMS$_BADVERSTR", value=>"CMS$_BADVERSTR"},
            {name=>"CMS__BCKPTRSTR", type=>"IV", macro=>"CMS$_BCKPTRSTR", value=>"CMS$_BCKPTRSTR"},
            {name=>"CMS__BUG", type=>"IV", macro=>"CMS$_BUG", value=>"CMS$_BUG"},
            {name=>"CMS__CANCELATIONS", type=>"IV", macro=>"CMS$_CANCELATIONS", value=>"CMS$_CANCELATIONS"},
            {name=>"CMS__CANCELED", type=>"IV", macro=>"CMS$_CANCELED", value=>"CMS$_CANCELED"},
            {name=>"CMS__CLASSGENEXP", type=>"IV", macro=>"CMS$_CLASSGENEXP", value=>"CMS$_CLASSGENEXP"},
            {name=>"CMS__CMPSIGNAL", type=>"IV", macro=>"CMS$_CMPSIGNAL", value=>"CMS$_CMPSIGNAL"},
            {name=>"CMS__CNTSTR", type=>"IV", macro=>"CMS$_CNTSTR", value=>"CMS$_CNTSTR"},
            {name=>"CMS__COMPARED", type=>"IV", macro=>"CMS$_COMPARED", value=>"CMS$_COMPARED"},
            {name=>"CMS__CONCLS", type=>"IV", macro=>"CMS$_CONCLS", value=>"CMS$_CONCLS"},
            {name=>"CMS__CONCURRENT", type=>"IV", macro=>"CMS$_CONCURRENT", value=>"CMS$_CONCURRENT"},
            {name=>"CMS__CONELE", type=>"IV", macro=>"CMS$_CONELE", value=>"CMS$_CONELE"},
            {name=>"CMS__CONFIRM", type=>"IV", macro=>"CMS$_CONFIRM", value=>"CMS$_CONFIRM"},
            {name=>"CMS__CONFLICTS", type=>"IV", macro=>"CMS$_CONFLICTS", value=>"CMS$_CONFLICTS"},
            {name=>"CMS__CONGRP", type=>"IV", macro=>"CMS$_CONGRP", value=>"CMS$_CONGRP"},
            {name=>"CMS__CONHIS", type=>"IV", macro=>"CMS$_CONHIS", value=>"CMS$_CONHIS"},
            {name=>"CMS__CONRES", type=>"IV", macro=>"CMS$_CONRES", value=>"CMS$_CONRES"},
            {name=>"CMS__CONTROLC", type=>"IV", macro=>"CMS$_CONTROLC", value=>"CMS$_CONTROLC"},
            {name=>"CMS__CONVERTED", type=>"IV", macro=>"CMS$_CONVERTED", value=>"CMS$_CONVERTED"},
            {name=>"CMS__CONVERTLIB", type=>"IV", macro=>"CMS$_CONVERTLIB", value=>"CMS$_CONVERTLIB"},
            {name=>"CMS__CONVNOTNEC", type=>"IV", macro=>"CMS$_CONVNOTNEC", value=>"CMS$_CONVNOTNEC"},
            {name=>"CMS__COPIED", type=>"IV", macro=>"CMS$_COPIED", value=>"CMS$_COPIED"},
            {name=>"CMS__COPIES", type=>"IV", macro=>"CMS$_COPIES", value=>"CMS$_COPIES"},
            {name=>"CMS__CREATED", type=>"IV", macro=>"CMS$_CREATED", value=>"CMS$_CREATED"},
            {name=>"CMS__CREATES", type=>"IV", macro=>"CMS$_CREATES", value=>"CMS$_CREATES"},
            {name=>"CMS__DEFAULTDIR", type=>"IV", macro=>"CMS$_DEFAULTDIR", value=>"CMS$_DEFAULTDIR"},
            {name=>"CMS__DELETED", type=>"IV", macro=>"CMS$_DELETED", value=>"CMS$_DELETED"},
            {name=>"CMS__DELETIONS", type=>"IV", macro=>"CMS$_DELETIONS", value=>"CMS$_DELETIONS"},
            {name=>"CMS__DIFFCLASS", type=>"IV", macro=>"CMS$_DIFFCLASS", value=>"CMS$_DIFFCLASS"},
            {name=>"CMS__DIFFERENT", type=>"IV", macro=>"CMS$_DIFFERENT", value=>"CMS$_DIFFERENT"},
            {name=>"CMS__DUPEDF", type=>"IV", macro=>"CMS$_DUPEDF", value=>"CMS$_DUPEDF"},
            {name=>"CMS__DUPREF", type=>"IV", macro=>"CMS$_DUPREF", value=>"CMS$_DUPREF"},
            {name=>"CMS__EDFINWRONGDIR", type=>"IV", macro=>"CMS$_EDFINWRONGDIR", value=>"CMS$_EDFINWRONGDIR"},
            {name=>"CMS__EDFMISS", type=>"IV", macro=>"CMS$_EDFMISS", value=>"CMS$_EDFMISS"},
            {name=>"CMS__ELEEXISTS", type=>"IV", macro=>"CMS$_ELEEXISTS", value=>"CMS$_ELEEXISTS"},
            {name=>"CMS__ELEEXP", type=>"IV", macro=>"CMS$_ELEEXP", value=>"CMS$_ELEEXP"},
            {name=>"CMS__ELEMULTRES", type=>"IV", macro=>"CMS$_ELEMULTRES", value=>"CMS$_ELEMULTRES"},
            {name=>"CMS__ELEXPIGN", type=>"IV", macro=>"CMS$_ELEXPIGN", value=>"CMS$_ELEXPIGN"},
            {name=>"CMS__ENDOFLIST", type=>"IV", macro=>"CMS$_ENDOFLIST", value=>"CMS$_ENDOFLIST"},
            {name=>"CMS__ENDPTRSTR", type=>"IV", macro=>"CMS$_ENDPTRSTR", value=>"CMS$_ENDPTRSTR"},
            {name=>"CMS__EOF", type=>"IV", macro=>"CMS$_EOF", value=>"CMS$_EOF"},
            {name=>"CMS__ERRACCEPTANCES", type=>"IV", macro=>"CMS$_ERRACCEPTANCES", value=>"CMS$_ERRACCEPTANCES"},
            {name=>"CMS__ERRANNOTATIONS", type=>"IV", macro=>"CMS$_ERRANNOTATIONS", value=>"CMS$_ERRANNOTATIONS"},
            {name=>"CMS__ERRCANCELATIONS", type=>"IV", macro=>"CMS$_ERRCANCELATIONS", value=>"CMS$_ERRCANCELATIONS"},
            {name=>"CMS__ERRCLOSE", type=>"IV", macro=>"CMS$_ERRCLOSE", value=>"CMS$_ERRCLOSE"},
            {name=>"CMS__ERRCOPIES", type=>"IV", macro=>"CMS$_ERRCOPIES", value=>"CMS$_ERRCOPIES"},
            {name=>"CMS__ERRCREATES", type=>"IV", macro=>"CMS$_ERRCREATES", value=>"CMS$_ERRCREATES"},
            {name=>"CMS__ERRDELETIONS", type=>"IV", macro=>"CMS$_ERRDELETIONS", value=>"CMS$_ERRDELETIONS"},
            {name=>"CMS__ERRELEHIS", type=>"IV", macro=>"CMS$_ERRELEHIS", value=>"CMS$_ERRELEHIS"},
            {name=>"CMS__ERREMOVALS", type=>"IV", macro=>"CMS$_ERREMOVALS", value=>"CMS$_ERREMOVALS"},
            {name=>"CMS__ERREPLACEMENTS", type=>"IV", macro=>"CMS$_ERREPLACEMENTS", value=>"CMS$_ERREPLACEMENTS"},
            {name=>"CMS__ERRESERVATIONS", type=>"IV", macro=>"CMS$_ERRESERVATIONS", value=>"CMS$_ERRESERVATIONS"},
            {name=>"CMS__ERRETRIEVALS", type=>"IV", macro=>"CMS$_ERRETRIEVALS", value=>"CMS$_ERRETRIEVALS"},
            {name=>"CMS__ERRFETCHES", type=>"IV", macro=>"CMS$_ERRFETCHES", value=>"CMS$_ERRFETCHES"},
            {name=>"CMS__ERRGENDELETIONS", type=>"IV", macro=>"CMS$_ERRGENDELETIONS", value=>"CMS$_ERRGENDELETIONS"},
            {name=>"CMS__ERRHISLINE", type=>"IV", macro=>"CMS$_ERRHISLINE", value=>"CMS$_ERRHISLINE"},
            {name=>"CMS__ERRINSERTIONS", type=>"IV", macro=>"CMS$_ERRINSERTIONS", value=>"CMS$_ERRINSERTIONS"},
            {name=>"CMS__ERRMARKS", type=>"IV", macro=>"CMS$_ERRMARKS", value=>"CMS$_ERRMARKS"},
            {name=>"CMS__ERRMODACLS", type=>"IV", macro=>"CMS$_ERRMODACLS", value=>"CMS$_ERRMODACLS"},
            {name=>"CMS__ERRMODIFIES", type=>"IV", macro=>"CMS$_ERRMODIFIES", value=>"CMS$_ERRMODIFIES"},
            {name=>"CMS__ERRPAREXP", type=>"IV", macro=>"CMS$_ERRPAREXP", value=>"CMS$_ERRPAREXP"},
            {name=>"CMS__ERRREJECTIONS", type=>"IV", macro=>"CMS$_ERRREJECTIONS", value=>"CMS$_ERRREJECTIONS"},
            {name=>"CMS__ERRREVIEWS", type=>"IV", macro=>"CMS$_ERRREVIEWS", value=>"CMS$_ERRREVIEWS"},
            {name=>"CMS__ERRUNRESERVES", type=>"IV", macro=>"CMS$_ERRUNRESERVES", value=>"CMS$_ERRUNRESERVES"},
            {name=>"CMS__ERRVER2", type=>"IV", macro=>"CMS$_ERRVER2", value=>"CMS$_ERRVER2"},
            {name=>"CMS__ERRVERARC", type=>"IV", macro=>"CMS$_ERRVERARC", value=>"CMS$_ERRVERARC"},
            {name=>"CMS__ERRVERCLS", type=>"IV", macro=>"CMS$_ERRVERCLS", value=>"CMS$_ERRVERCLS"},
            {name=>"CMS__ERRVERCMD", type=>"IV", macro=>"CMS$_ERRVERCMD", value=>"CMS$_ERRVERCMD"},
            {name=>"CMS__ERRVERCON", type=>"IV", macro=>"CMS$_ERRVERCON", value=>"CMS$_ERRVERCON"},
            {name=>"CMS__ERRVEREDFS", type=>"IV", macro=>"CMS$_ERRVEREDFS", value=>"CMS$_ERRVEREDFS"},
            {name=>"CMS__ERRVERELE", type=>"IV", macro=>"CMS$_ERRVERELE", value=>"CMS$_ERRVERELE"},
            {name=>"CMS__ERRVERFRE", type=>"IV", macro=>"CMS$_ERRVERFRE", value=>"CMS$_ERRVERFRE"},
            {name=>"CMS__ERRVERGEN", type=>"IV", macro=>"CMS$_ERRVERGEN", value=>"CMS$_ERRVERGEN"},
            {name=>"CMS__ERRVERGRP", type=>"IV", macro=>"CMS$_ERRVERGRP", value=>"CMS$_ERRVERGRP"},
            {name=>"CMS__ERRVERREFS", type=>"IV", macro=>"CMS$_ERRVERREFS", value=>"CMS$_ERRVERREFS"},
            {name=>"CMS__ERRVERRES", type=>"IV", macro=>"CMS$_ERRVERRES", value=>"CMS$_ERRVERRES"},
            {name=>"CMS__ERRVERSTR", type=>"IV", macro=>"CMS$_ERRVERSTR", value=>"CMS$_ERRVERSTR"},
            {name=>"CMS__EXCLUDE", type=>"IV", macro=>"CMS$_EXCLUDE", value=>"CMS$_EXCLUDE"},
            {name=>"CMS__EXIT", type=>"IV", macro=>"CMS$_EXIT", value=>"CMS$_EXIT"},
            {name=>"CMS__EXTENDEDLIB", type=>"IV", macro=>"CMS$_EXTENDEDLIB", value=>"CMS$_EXTENDEDLIB"},
            {name=>"CMS__EXTFOUND", type=>"IV", macro=>"CMS$_EXTFOUND", value=>"CMS$_EXTFOUND"},
            {name=>"CMS__FACILITY", type=>"IV", macro=>"CMS$_FACILITY", value=>"CMS$_FACILITY"},
            {name=>"CMS__FETCHED", type=>"IV", macro=>"CMS$_FETCHED", value=>"CMS$_FETCHED"},
            {name=>"CMS__FETCHES", type=>"IV", macro=>"CMS$_FETCHES", value=>"CMS$_FETCHES"},
            {name=>"CMS__FILEXISTS", type=>"IV", macro=>"CMS$_FILEXISTS", value=>"CMS$_FILEXISTS"},
            {name=>"CMS__FILINUSE", type=>"IV", macro=>"CMS$_FILINUSE", value=>"CMS$_FILINUSE"},
            {name=>"CMS__FIXCRC", type=>"IV", macro=>"CMS$_FIXCRC", value=>"CMS$_FIXCRC"},
            {name=>"CMS__FIXHDR", type=>"IV", macro=>"CMS$_FIXHDR", value=>"CMS$_FIXHDR"},
            {name=>"CMS__FREBLKCON", type=>"IV", macro=>"CMS$_FREBLKCON", value=>"CMS$_FREBLKCON"},
            {name=>"CMS__GENCREATED", type=>"IV", macro=>"CMS$_GENCREATED", value=>"CMS$_GENCREATED"},
            {name=>"CMS__GENDELETED", type=>"IV", macro=>"CMS$_GENDELETED", value=>"CMS$_GENDELETED"},
            {name=>"CMS__GENDELETIONS", type=>"IV", macro=>"CMS$_GENDELETIONS", value=>"CMS$_GENDELETIONS"},
            {name=>"CMS__GENEXISTS", type=>"IV", macro=>"CMS$_GENEXISTS", value=>"CMS$_GENEXISTS"},
            {name=>"CMS__GENINSERTED", type=>"IV", macro=>"CMS$_GENINSERTED", value=>"CMS$_GENINSERTED"},
            {name=>"CMS__GENMULTRES", type=>"IV", macro=>"CMS$_GENMULTRES", value=>"CMS$_GENMULTRES"},
            {name=>"CMS__GENNOINSERT", type=>"IV", macro=>"CMS$_GENNOINSERT", value=>"CMS$_GENNOINSERT"},
            {name=>"CMS__GENNOREMOVE", type=>"IV", macro=>"CMS$_GENNOREMOVE", value=>"CMS$_GENNOREMOVE"},
            {name=>"CMS__GENNOTANC", type=>"IV", macro=>"CMS$_GENNOTANC", value=>"CMS$_GENNOTANC"},
            {name=>"CMS__GENNOTFOUND", type=>"IV", macro=>"CMS$_GENNOTFOUND", value=>"CMS$_GENNOTFOUND"},
            {name=>"CMS__GENNOTRES", type=>"IV", macro=>"CMS$_GENNOTRES", value=>"CMS$_GENNOTRES"},
            {name=>"CMS__GENRECSIZE", type=>"IV", macro=>"CMS$_GENRECSIZE", value=>"CMS$_GENRECSIZE"},
            {name=>"CMS__GENREMOVED", type=>"IV", macro=>"CMS$_GENREMOVED", value=>"CMS$_GENREMOVED"},
            {name=>"CMS__GENRESREV", type=>"IV", macro=>"CMS$_GENRESREV", value=>"CMS$_GENRESREV"},
            {name=>"CMS__GENTOODEEP", type=>"IV", macro=>"CMS$_GENTOODEEP", value=>"CMS$_GENTOODEEP"},
            {name=>"CMS__GROUPEXP", type=>"IV", macro=>"CMS$_GROUPEXP", value=>"CMS$_GROUPEXP"},
            {name=>"CMS__HASFILES", type=>"IV", macro=>"CMS$_HASFILES", value=>"CMS$_HASFILES"},
            {name=>"CMS__HASMEMBERS", type=>"IV", macro=>"CMS$_HASMEMBERS", value=>"CMS$_HASMEMBERS"},
            {name=>"CMS__HISNOTSTM", type=>"IV", macro=>"CMS$_HISNOTSTM", value=>"CMS$_HISNOTSTM"},
            {name=>"CMS__HISTDEL", type=>"IV", macro=>"CMS$_HISTDEL", value=>"CMS$_HISTDEL"},
            {name=>"CMS__IDENTCLASS", type=>"IV", macro=>"CMS$_IDENTCLASS", value=>"CMS$_IDENTCLASS"},
            {name=>"CMS__IDENTICAL", type=>"IV", macro=>"CMS$_IDENTICAL", value=>"CMS$_IDENTICAL"},
            {name=>"CMS__IDENTNOTRES", type=>"IV", macro=>"CMS$_IDENTNOTRES", value=>"CMS$_IDENTNOTRES"},
            {name=>"CMS__ILLACT", type=>"IV", macro=>"CMS$_ILLACT", value=>"CMS$_ILLACT"},
            {name=>"CMS__ILLARCREC", type=>"IV", macro=>"CMS$_ILLARCREC", value=>"CMS$_ILLARCREC"},
            {name=>"CMS__ILLCHAR", type=>"IV", macro=>"CMS$_ILLCHAR", value=>"CMS$_ILLCHAR"},
            {name=>"CMS__ILLCLSNAM", type=>"IV", macro=>"CMS$_ILLCLSNAM", value=>"CMS$_ILLCLSNAM"},
            {name=>"CMS__ILLCONREC", type=>"IV", macro=>"CMS$_ILLCONREC", value=>"CMS$_ILLCONREC"},
            {name=>"CMS__ILLDATREC", type=>"IV", macro=>"CMS$_ILLDATREC", value=>"CMS$_ILLDATREC"},
            {name=>"CMS__ILLEGALDEV", type=>"IV", macro=>"CMS$_ILLEGALDEV", value=>"CMS$_ILLEGALDEV"},
            {name=>"CMS__ILLELENAM", type=>"IV", macro=>"CMS$_ILLELENAM", value=>"CMS$_ILLELENAM"},
            {name=>"CMS__ILLELEXP", type=>"IV", macro=>"CMS$_ILLELEXP", value=>"CMS$_ILLELEXP"},
            {name=>"CMS__ILLFORMAT", type=>"IV", macro=>"CMS$_ILLFORMAT", value=>"CMS$_ILLFORMAT"},
            {name=>"CMS__ILLGEN", type=>"IV", macro=>"CMS$_ILLGEN", value=>"CMS$_ILLGEN"},
            {name=>"CMS__ILLGRPNAM", type=>"IV", macro=>"CMS$_ILLGRPNAM", value=>"CMS$_ILLGRPNAM"},
            {name=>"CMS__ILLHIST", type=>"IV", macro=>"CMS$_ILLHIST", value=>"CMS$_ILLHIST"},
            {name=>"CMS__ILLNAME", type=>"IV", macro=>"CMS$_ILLNAME", value=>"CMS$_ILLNAME"},
            {name=>"CMS__ILLNOTE", type=>"IV", macro=>"CMS$_ILLNOTE", value=>"CMS$_ILLNOTE"},
            {name=>"CMS__ILLOBJTYP", type=>"IV", macro=>"CMS$_ILLOBJTYP", value=>"CMS$_ILLOBJTYP"},
            {name=>"CMS__ILLPAR", type=>"IV", macro=>"CMS$_ILLPAR", value=>"CMS$_ILLPAR"},
            {name=>"CMS__ILLPOSVAL", type=>"IV", macro=>"CMS$_ILLPOSVAL", value=>"CMS$_ILLPOSVAL"},
            {name=>"CMS__ILLREFDIR", type=>"IV", macro=>"CMS$_ILLREFDIR", value=>"CMS$_ILLREFDIR"},
            {name=>"CMS__ILLRMK", type=>"IV", macro=>"CMS$_ILLRMK", value=>"CMS$_ILLRMK"},
            {name=>"CMS__ILLSEQ", type=>"IV", macro=>"CMS$_ILLSEQ", value=>"CMS$_ILLSEQ"},
            {name=>"CMS__ILLSUBTYP", type=>"IV", macro=>"CMS$_ILLSUBTYP", value=>"CMS$_ILLSUBTYP"},
            {name=>"CMS__ILLVAR", type=>"IV", macro=>"CMS$_ILLVAR", value=>"CMS$_ILLVAR"},
            {name=>"CMS__INCLIBVER", type=>"IV", macro=>"CMS$_INCLIBVER", value=>"CMS$_INCLIBVER"},
            {name=>"CMS__INCRANGSPEC", type=>"IV", macro=>"CMS$_INCRANGSPEC", value=>"CMS$_INCRANGSPEC"},
            {name=>"CMS__INSERTED", type=>"IV", macro=>"CMS$_INSERTED", value=>"CMS$_INSERTED"},
            {name=>"CMS__INSERTIONS", type=>"IV", macro=>"CMS$_INSERTIONS", value=>"CMS$_INSERTIONS"},
            {name=>"CMS__INUSE", type=>"IV", macro=>"CMS$_INUSE", value=>"CMS$_INUSE"},
            {name=>"CMS__INVFETDB", type=>"IV", macro=>"CMS$_INVFETDB", value=>"CMS$_INVFETDB"},
            {name=>"CMS__INVFIXMRS", type=>"IV", macro=>"CMS$_INVFIXMRS", value=>"CMS$_INVFIXMRS"},
            {name=>"CMS__INVGENLRL", type=>"IV", macro=>"CMS$_INVGENLRL", value=>"CMS$_INVGENLRL"},
            {name=>"CMS__INVLENGTH", type=>"IV", macro=>"CMS$_INVLENGTH", value=>"CMS$_INVLENGTH"},
            {name=>"CMS__INVLIBDB", type=>"IV", macro=>"CMS$_INVLIBDB", value=>"CMS$_INVLIBDB"},
            {name=>"CMS__INVOKERBK", type=>"IV", macro=>"CMS$_INVOKERBK", value=>"CMS$_INVOKERBK"},
            {name=>"CMS__INVSTRDES", type=>"IV", macro=>"CMS$_INVSTRDES", value=>"CMS$_INVSTRDES"},
            {name=>"CMS__ISMEMBER", type=>"IV", macro=>"CMS$_ISMEMBER", value=>"CMS$_ISMEMBER"},
            {name=>"CMS__ISRESERVED", type=>"IV", macro=>"CMS$_ISRESERVED", value=>"CMS$_ISRESERVED"},
            {name=>"CMS__LIBALRINLIS", type=>"IV", macro=>"CMS$_LIBALRINLIS", value=>"CMS$_LIBALRINLIS"},
            {name=>"CMS__LIBINSLIS", type=>"IV", macro=>"CMS$_LIBINSLIS", value=>"CMS$_LIBINSLIS"},
            {name=>"CMS__LIBIS", type=>"IV", macro=>"CMS$_LIBIS", value=>"CMS$_LIBIS"},
            {name=>"CMS__LIBLISMOD", type=>"IV", macro=>"CMS$_LIBLISMOD", value=>"CMS$_LIBLISMOD"},
            {name=>"CMS__LIBLISNOTMOD", type=>"IV", macro=>"CMS$_LIBLISNOTMOD", value=>"CMS$_LIBLISNOTMOD"},
            {name=>"CMS__LIBNOTINLIS", type=>"IV", macro=>"CMS$_LIBNOTINLIS", value=>"CMS$_LIBNOTINLIS"},
            {name=>"CMS__LIBREMLIS", type=>"IV", macro=>"CMS$_LIBREMLIS", value=>"CMS$_LIBREMLIS"},
            {name=>"CMS__LIBSET", type=>"IV", macro=>"CMS$_LIBSET", value=>"CMS$_LIBSET"},
            {name=>"CMS__LONGVARFOUND", type=>"IV", macro=>"CMS$_LONGVARFOUND", value=>"CMS$_LONGVARFOUND"},
            {name=>"CMS__MANCONLIB", type=>"IV", macro=>"CMS$_MANCONLIB", value=>"CMS$_MANCONLIB"},
            {name=>"CMS__MARKED", type=>"IV", macro=>"CMS$_MARKED", value=>"CMS$_MARKED"},
            {name=>"CMS__MARKS", type=>"IV", macro=>"CMS$_MARKS", value=>"CMS$_MARKS"},
            {name=>"CMS__MAXARG", type=>"IV", macro=>"CMS$_MAXARG", value=>"CMS$_MAXARG"},
            {name=>"CMS__MERGECONFLICT", type=>"IV", macro=>"CMS$_MERGECONFLICT", value=>"CMS$_MERGECONFLICT"},
            {name=>"CMS__MERGECOUNT", type=>"IV", macro=>"CMS$_MERGECOUNT", value=>"CMS$_MERGECOUNT"},
            {name=>"CMS__MERGED", type=>"IV", macro=>"CMS$_MERGED", value=>"CMS$_MERGED"},
            {name=>"CMS__MINARG", type=>"IV", macro=>"CMS$_MINARG", value=>"CMS$_MINARG"},
            {name=>"CMS__MISBLKSTR", type=>"IV", macro=>"CMS$_MISBLKSTR", value=>"CMS$_MISBLKSTR"},
            {name=>"CMS__MISMATCON", type=>"IV", macro=>"CMS$_MISMATCON", value=>"CMS$_MISMATCON"},
            {name=>"CMS__MODACL", type=>"IV", macro=>"CMS$_MODACL", value=>"CMS$_MODACL"},
            {name=>"CMS__MODACLS", type=>"IV", macro=>"CMS$_MODACLS", value=>"CMS$_MODACLS"},
            {name=>"CMS__MODIFICATIONS", type=>"IV", macro=>"CMS$_MODIFICATIONS", value=>"CMS$_MODIFICATIONS"},
            {name=>"CMS__MODIFIED", type=>"IV", macro=>"CMS$_MODIFIED", value=>"CMS$_MODIFIED"},
            {name=>"CMS__MSGBUILD", type=>"IV", macro=>"CMS$_MSGBUILD", value=>"CMS$_MSGBUILD"},
            {name=>"CMS__MSGCANCEL", type=>"IV", macro=>"CMS$_MSGCANCEL", value=>"CMS$_MSGCANCEL"},
            {name=>"CMS__MSGCONTINUE", type=>"IV", macro=>"CMS$_MSGCONTINUE", value=>"CMS$_MSGCONTINUE"},
            {name=>"CMS__MSGPOST", type=>"IV", macro=>"CMS$_MSGPOST", value=>"CMS$_MSGPOST"},
            {name=>"CMS__MSGUPDATE", type=>"IV", macro=>"CMS$_MSGUPDATE", value=>"CMS$_MSGUPDATE"},
            {name=>"CMS__MSSBLKSTR", type=>"IV", macro=>"CMS$_MSSBLKSTR", value=>"CMS$_MSSBLKSTR"},
            {name=>"CMS__MULTCALL", type=>"IV", macro=>"CMS$_MULTCALL", value=>"CMS$_MULTCALL"},
            {name=>"CMS__MULTPAR", type=>"IV", macro=>"CMS$_MULTPAR", value=>"CMS$_MULTPAR"},
            {name=>"CMS__MUSTBEDIR", type=>"IV", macro=>"CMS$_MUSTBEDIR", value=>"CMS$_MUSTBEDIR"},
            {name=>"CMS__MUSTBEFIL", type=>"IV", macro=>"CMS$_MUSTBEFIL", value=>"CMS$_MUSTBEFIL"},
            {name=>"CMS__MUSTBEPOS", type=>"IV", macro=>"CMS$_MUSTBEPOS", value=>"CMS$_MUSTBEPOS"},
            {name=>"CMS__MUTEXC", type=>"IV", macro=>"CMS$_MUTEXC", value=>"CMS$_MUTEXC"},
            {name=>"CMS__NEEDNUMBER", type=>"IV", macro=>"CMS$_NEEDNUMBER", value=>"CMS$_NEEDNUMBER"},
            {name=>"CMS__NEEDPERIOD", type=>"IV", macro=>"CMS$_NEEDPERIOD", value=>"CMS$_NEEDPERIOD"},
            {name=>"CMS__NETNOTALL", type=>"IV", macro=>"CMS$_NETNOTALL", value=>"CMS$_NETNOTALL"},
            {name=>"CMS__NOACCEPT", type=>"IV", macro=>"CMS$_NOACCEPT", value=>"CMS$_NOACCEPT"},
            {name=>"CMS__NOACCESS", type=>"IV", macro=>"CMS$_NOACCESS", value=>"CMS$_NOACCESS"},
            {name=>"CMS__NOACE", type=>"IV", macro=>"CMS$_NOACE", value=>"CMS$_NOACE"},
            {name=>"CMS__NOALTDELETE", type=>"IV", macro=>"CMS$_NOALTDELETE", value=>"CMS$_NOALTDELETE"},
            {name=>"CMS__NOANNOTATE", type=>"IV", macro=>"CMS$_NOANNOTATE", value=>"CMS$_NOANNOTATE"},
            {name=>"CMS__NOBACKUP", type=>"IV", macro=>"CMS$_NOBACKUP", value=>"CMS$_NOBACKUP"},
            {name=>"CMS__NOBCKPTR", type=>"IV", macro=>"CMS$_NOBCKPTR", value=>"CMS$_NOBCKPTR"},
            {name=>"CMS__NOCANCEL", type=>"IV", macro=>"CMS$_NOCANCEL", value=>"CMS$_NOCANCEL"},
            {name=>"CMS__NOCHANGES", type=>"IV", macro=>"CMS$_NOCHANGES", value=>"CMS$_NOCHANGES"},
            {name=>"CMS__NOCLOSE", type=>"IV", macro=>"CMS$_NOCLOSE", value=>"CMS$_NOCLOSE"},
            {name=>"CMS__NOCLS", type=>"IV", macro=>"CMS$_NOCLS", value=>"CMS$_NOCLS"},
            {name=>"CMS__NOCMD", type=>"IV", macro=>"CMS$_NOCMD", value=>"CMS$_NOCMD"},
            {name=>"CMS__NOCOMMALIST", type=>"IV", macro=>"CMS$_NOCOMMALIST", value=>"CMS$_NOCOMMALIST"},
            {name=>"CMS__NOCOMPARE", type=>"IV", macro=>"CMS$_NOCOMPARE", value=>"CMS$_NOCOMPARE"},
            {name=>"CMS__NOCONCUR", type=>"IV", macro=>"CMS$_NOCONCUR", value=>"CMS$_NOCONCUR"},
            {name=>"CMS__NOCONFIRM", type=>"IV", macro=>"CMS$_NOCONFIRM", value=>"CMS$_NOCONFIRM"},
            {name=>"CMS__NOCONRES", type=>"IV", macro=>"CMS$_NOCONRES", value=>"CMS$_NOCONRES"},
            {name=>"CMS__NOCONVERT", type=>"IV", macro=>"CMS$_NOCONVERT", value=>"CMS$_NOCONVERT"},
            {name=>"CMS__NOCOPY", type=>"IV", macro=>"CMS$_NOCOPY", value=>"CMS$_NOCOPY"},
            {name=>"CMS__NOCREATE", type=>"IV", macro=>"CMS$_NOCREATE", value=>"CMS$_NOCREATE"},
            {name=>"CMS__NODEFACL", type=>"IV", macro=>"CMS$_NODEFACL", value=>"CMS$_NODEFACL"},
            {name=>"CMS__NODELACCESS", type=>"IV", macro=>"CMS$_NODELACCESS", value=>"CMS$_NODELACCESS"},
            {name=>"CMS__NODELETE", type=>"IV", macro=>"CMS$_NODELETE", value=>"CMS$_NODELETE"},
            {name=>"CMS__NODELETIONS", type=>"IV", macro=>"CMS$_NODELETIONS", value=>"CMS$_NODELETIONS"},
            {name=>"CMS__NODELFUTURE", type=>"IV", macro=>"CMS$_NODELFUTURE", value=>"CMS$_NODELFUTURE"},
            {name=>"CMS__NODELGEN1", type=>"IV", macro=>"CMS$_NODELGEN1", value=>"CMS$_NODELGEN1"},
            {name=>"CMS__NOEDFIWDREPAIR", type=>"IV", macro=>"CMS$_NOEDFIWDREPAIR", value=>"CMS$_NOEDFIWDREPAIR"},
            {name=>"CMS__NOELE", type=>"IV", macro=>"CMS$_NOELE", value=>"CMS$_NOELE"},
            {name=>"CMS__NOELEENT", type=>"IV", macro=>"CMS$_NOELEENT", value=>"CMS$_NOELEENT"},
            {name=>"CMS__NOERRLOG", type=>"IV", macro=>"CMS$_NOERRLOG", value=>"CMS$_NOERRLOG"},
            {name=>"CMS__NOEXTENDED", type=>"IV", macro=>"CMS$_NOEXTENDED", value=>"CMS$_NOEXTENDED"},
            {name=>"CMS__NOEXTENDEDREF", type=>"IV", macro=>"CMS$_NOEXTENDEDREF", value=>"CMS$_NOEXTENDEDREF"},
            {name=>"CMS__NOFETCH", type=>"IV", macro=>"CMS$_NOFETCH", value=>"CMS$_NOFETCH"},
            {name=>"CMS__NOFILE", type=>"IV", macro=>"CMS$_NOFILE", value=>"CMS$_NOFILE"},
            {name=>"CMS__NOGENBEFORE", type=>"IV", macro=>"CMS$_NOGENBEFORE", value=>"CMS$_NOGENBEFORE"},
            {name=>"CMS__NOGENDELETED", type=>"IV", macro=>"CMS$_NOGENDELETED", value=>"CMS$_NOGENDELETED"},
            {name=>"CMS__NOGENS", type=>"IV", macro=>"CMS$_NOGENS", value=>"CMS$_NOGENS"},
            {name=>"CMS__NOGRP", type=>"IV", macro=>"CMS$_NOGRP", value=>"CMS$_NOGRP"},
            {name=>"CMS__NOHIS", type=>"IV", macro=>"CMS$_NOHIS", value=>"CMS$_NOHIS"},
            {name=>"CMS__NOHISNOTES", type=>"IV", macro=>"CMS$_NOHISNOTES", value=>"CMS$_NOHISNOTES"},
            {name=>"CMS__NOHISPAR", type=>"IV", macro=>"CMS$_NOHISPAR", value=>"CMS$_NOHISPAR"},
            {name=>"CMS__NOINPUT", type=>"IV", macro=>"CMS$_NOINPUT", value=>"CMS$_NOINPUT"},
            {name=>"CMS__NOINSERT", type=>"IV", macro=>"CMS$_NOINSERT", value=>"CMS$_NOINSERT"},
            {name=>"CMS__NOMARK", type=>"IV", macro=>"CMS$_NOMARK", value=>"CMS$_NOMARK"},
            {name=>"CMS__NOMATCH", type=>"IV", macro=>"CMS$_NOMATCH", value=>"CMS$_NOMATCH"},
            {name=>"CMS__NOMODACL", type=>"IV", macro=>"CMS$_NOMODACL", value=>"CMS$_NOMODACL"},
            {name=>"CMS__NOMODARG", type=>"IV", macro=>"CMS$_NOMODARG", value=>"CMS$_NOMODARG"},
            {name=>"CMS__NOMODIFY", type=>"IV", macro=>"CMS$_NOMODIFY", value=>"CMS$_NOMODIFY"},
            {name=>"CMS__NOMOREPARAM", type=>"IV", macro=>"CMS$_NOMOREPARAM", value=>"CMS$_NOMOREPARAM"},
            {name=>"CMS__NOOBJ", type=>"IV", macro=>"CMS$_NOOBJ", value=>"CMS$_NOOBJ"},
            {name=>"CMS__NOOBJTYP", type=>"IV", macro=>"CMS$_NOOBJTYP", value=>"CMS$_NOOBJTYP"},
            {name=>"CMS__NORECOVER", type=>"IV", macro=>"CMS$_NORECOVER", value=>"CMS$_NORECOVER"},
            {name=>"CMS__NOREF", type=>"IV", macro=>"CMS$_NOREF", value=>"CMS$_NOREF"},
            {name=>"CMS__NOREFDIR", type=>"IV", macro=>"CMS$_NOREFDIR", value=>"CMS$_NOREFDIR"},
            {name=>"CMS__NOREFELE", type=>"IV", macro=>"CMS$_NOREFELE", value=>"CMS$_NOREFELE"},
            {name=>"CMS__NOREJECT", type=>"IV", macro=>"CMS$_NOREJECT", value=>"CMS$_NOREJECT"},
            {name=>"CMS__NOREMARK", type=>"IV", macro=>"CMS$_NOREMARK", value=>"CMS$_NOREMARK"},
            {name=>"CMS__NOREMOVAL", type=>"IV", macro=>"CMS$_NOREMOVAL", value=>"CMS$_NOREMOVAL"},
            {name=>"CMS__NOREPAIR", type=>"IV", macro=>"CMS$_NOREPAIR", value=>"CMS$_NOREPAIR"},
            {name=>"CMS__NOREPBCKPTR", type=>"IV", macro=>"CMS$_NOREPBCKPTR", value=>"CMS$_NOREPBCKPTR"},
            {name=>"CMS__NOREPCMD", type=>"IV", macro=>"CMS$_NOREPCMD", value=>"CMS$_NOREPCMD"},
            {name=>"CMS__NOREPEDF", type=>"IV", macro=>"CMS$_NOREPEDF", value=>"CMS$_NOREPEDF"},
            {name=>"CMS__NOREPGENLRL", type=>"IV", macro=>"CMS$_NOREPGENLRL", value=>"CMS$_NOREPGENLRL"},
            {name=>"CMS__NOREPGENMRS", type=>"IV", macro=>"CMS$_NOREPGENMRS", value=>"CMS$_NOREPGENMRS"},
            {name=>"CMS__NOREPLACE", type=>"IV", macro=>"CMS$_NOREPLACE", value=>"CMS$_NOREPLACE"},
            {name=>"CMS__NOREPREF", type=>"IV", macro=>"CMS$_NOREPREF", value=>"CMS$_NOREPREF"},
            {name=>"CMS__NOREPRO", type=>"IV", macro=>"CMS$_NOREPRO", value=>"CMS$_NOREPRO"},
            {name=>"CMS__NOREPSEQDATA", type=>"IV", macro=>"CMS$_NOREPSEQDATA", value=>"CMS$_NOREPSEQDATA"},
            {name=>"CMS__NORES", type=>"IV", macro=>"CMS$_NORES", value=>"CMS$_NORES"},
            {name=>"CMS__NORESERVATION", type=>"IV", macro=>"CMS$_NORESERVATION", value=>"CMS$_NORESERVATION"},
            {name=>"CMS__NORESNOCON", type=>"IV", macro=>"CMS$_NORESNOCON", value=>"CMS$_NORESNOCON"},
            {name=>"CMS__NORESRO", type=>"IV", macro=>"CMS$_NORESRO", value=>"CMS$_NORESRO"},
            {name=>"CMS__NORETRIEVE", type=>"IV", macro=>"CMS$_NORETRIEVE", value=>"CMS$_NORETRIEVE"},
            {name=>"CMS__NOREV", type=>"IV", macro=>"CMS$_NOREV", value=>"CMS$_NOREV"},
            {name=>"CMS__NOREVIEW", type=>"IV", macro=>"CMS$_NOREVIEW", value=>"CMS$_NOREVIEW"},
            {name=>"CMS__NOREVPEND", type=>"IV", macro=>"CMS$_NOREVPEND", value=>"CMS$_NOREVPEND"},
            {name=>"CMS__NOREVSPEND", type=>"IV", macro=>"CMS$_NOREVSPEND", value=>"CMS$_NOREVSPEND"},
            {name=>"CMS__NORMAL", type=>"IV", macro=>"CMS$_NORMAL", value=>"CMS$_NORMAL"},
            {name=>"CMS__NOSINCE", type=>"IV", macro=>"CMS$_NOSINCE", value=>"CMS$_NOSINCE"},
            {name=>"CMS__NOSRCHLST", type=>"IV", macro=>"CMS$_NOSRCHLST", value=>"CMS$_NOSRCHLST"},
            {name=>"CMS__NOSUPERSEDE", type=>"IV", macro=>"CMS$_NOSUPERSEDE", value=>"CMS$_NOSUPERSEDE"},
            {name=>"CMS__NOTBYCMS", type=>"IV", macro=>"CMS$_NOTBYCMS", value=>"CMS$_NOTBYCMS"},
            {name=>"CMS__NOTCMSLIB", type=>"IV", macro=>"CMS$_NOTCMSLIB", value=>"CMS$_NOTCMSLIB"},
            {name=>"CMS__NOTCOMPLETED", type=>"IV", macro=>"CMS$_NOTCOMPLETED", value=>"CMS$_NOTCOMPLETED"},
            {name=>"CMS__NOTCRELIB", type=>"IV", macro=>"CMS$_NOTCRELIB", value=>"CMS$_NOTCRELIB"},
            {name=>"CMS__NOTDIRDES", type=>"IV", macro=>"CMS$_NOTDIRDES", value=>"CMS$_NOTDIRDES"},
            {name=>"CMS__NOTESVALREQ", type=>"IV", macro=>"CMS$_NOTESVALREQ", value=>"CMS$_NOTESVALREQ"},
            {name=>"CMS__NOTFOUND", type=>"IV", macro=>"CMS$_NOTFOUND", value=>"CMS$_NOTFOUND"},
            {name=>"CMS__NOTLOGGED", type=>"IV", macro=>"CMS$_NOTLOGGED", value=>"CMS$_NOTLOGGED"},
            {name=>"CMS__NOTNOREF", type=>"IV", macro=>"CMS$_NOTNOREF", value=>"CMS$_NOTNOREF"},
            {name=>"CMS__NOTRESBYOU", type=>"IV", macro=>"CMS$_NOTRESBYOU", value=>"CMS$_NOTRESBYOU"},
            {name=>"CMS__NOTSET", type=>"IV", macro=>"CMS$_NOTSET", value=>"CMS$_NOTSET"},
            {name=>"CMS__NOTTHERE", type=>"IV", macro=>"CMS$_NOTTHERE", value=>"CMS$_NOTTHERE"},
            {name=>"CMS__NOTWILD", type=>"IV", macro=>"CMS$_NOTWILD", value=>"CMS$_NOTWILD"},
            {name=>"CMS__NOUNRESERVE", type=>"IV", macro=>"CMS$_NOUNRESERVE", value=>"CMS$_NOUNRESERVE"},
            {name=>"CMS__NOVERIFY", type=>"IV", macro=>"CMS$_NOVERIFY", value=>"CMS$_NOVERIFY"},
            {name=>"CMS__NOWLDCARD", type=>"IV", macro=>"CMS$_NOWLDCARD", value=>"CMS$_NOWLDCARD"},
            {name=>"CMS__NULLARG", type=>"IV", macro=>"CMS$_NULLARG", value=>"CMS$_NULLARG"},
            {name=>"CMS__NULLSTR", type=>"IV", macro=>"CMS$_NULLSTR", value=>"CMS$_NULLSTR"},
            {name=>"CMS__NUMGENEXP", type=>"IV", macro=>"CMS$_NUMGENEXP", value=>"CMS$_NUMGENEXP"},
            {name=>"CMS__OLDSYNTAX", type=>"IV", macro=>"CMS$_OLDSYNTAX", value=>"CMS$_OLDSYNTAX"},
            {name=>"CMS__ONEPERIOD", type=>"IV", macro=>"CMS$_ONEPERIOD", value=>"CMS$_ONEPERIOD"},
            {name=>"CMS__OPENARC", type=>"IV", macro=>"CMS$_OPENARC", value=>"CMS$_OPENARC"},
            {name=>"CMS__OPENIN", type=>"IV", macro=>"CMS$_OPENIN", value=>"CMS$_OPENIN"},
            {name=>"CMS__OPENIN1", type=>"IV", macro=>"CMS$_OPENIN1", value=>"CMS$_OPENIN1"},
            {name=>"CMS__OPENIN2", type=>"IV", macro=>"CMS$_OPENIN2", value=>"CMS$_OPENIN2"},
            {name=>"CMS__OPENOUT", type=>"IV", macro=>"CMS$_OPENOUT", value=>"CMS$_OPENOUT"},
            {name=>"CMS__OVERDRAFT", type=>"IV", macro=>"CMS$_OVERDRAFT", value=>"CMS$_OVERDRAFT"},
            {name=>"CMS__POSVALREQ", type=>"IV", macro=>"CMS$_POSVALREQ", value=>"CMS$_POSVALREQ"},
            {name=>"CMS__PROCEEDING", type=>"IV", macro=>"CMS$_PROCEEDING", value=>"CMS$_PROCEEDING"},
            {name=>"CMS__QUALCONFLICT", type=>"IV", macro=>"CMS$_QUALCONFLICT", value=>"CMS$_QUALCONFLICT"},
            {name=>"CMS__READERR", type=>"IV", macro=>"CMS$_READERR", value=>"CMS$_READERR"},
            {name=>"CMS__READIN", type=>"IV", macro=>"CMS$_READIN", value=>"CMS$_READIN"},
            {name=>"CMS__READONLY", type=>"IV", macro=>"CMS$_READONLY", value=>"CMS$_READONLY"},
            {name=>"CMS__RECGRP", type=>"IV", macro=>"CMS$_RECGRP", value=>"CMS$_RECGRP"},
            {name=>"CMS__RECNOTNEC", type=>"IV", macro=>"CMS$_RECNOTNEC", value=>"CMS$_RECNOTNEC"},
            {name=>"CMS__RECOVERED", type=>"IV", macro=>"CMS$_RECOVERED", value=>"CMS$_RECOVERED"},
            {name=>"CMS__REFMISMAT", type=>"IV", macro=>"CMS$_REFMISMAT", value=>"CMS$_REFMISMAT"},
            {name=>"CMS__REFMISS", type=>"IV", macro=>"CMS$_REFMISS", value=>"CMS$_REFMISS"},
            {name=>"CMS__REFREPAIR", type=>"IV", macro=>"CMS$_REFREPAIR", value=>"CMS$_REFREPAIR"},
            {name=>"CMS__REJECTED", type=>"IV", macro=>"CMS$_REJECTED", value=>"CMS$_REJECTED"},
            {name=>"CMS__REJECTIONS", type=>"IV", macro=>"CMS$_REJECTIONS", value=>"CMS$_REJECTIONS"},
            {name=>"CMS__REMARK", type=>"IV", macro=>"CMS$_REMARK", value=>"CMS$_REMARK"},
            {name=>"CMS__REMOVALS", type=>"IV", macro=>"CMS$_REMOVALS", value=>"CMS$_REMOVALS"},
            {name=>"CMS__REMOVED", type=>"IV", macro=>"CMS$_REMOVED", value=>"CMS$_REMOVED"},
            {name=>"CMS__REPAIRED", type=>"IV", macro=>"CMS$_REPAIRED", value=>"CMS$_REPAIRED"},
            {name=>"CMS__REPBADLST", type=>"IV", macro=>"CMS$_REPBADLST", value=>"CMS$_REPBADLST"},
            {name=>"CMS__REPBADTYP", type=>"IV", macro=>"CMS$_REPBADTYP", value=>"CMS$_REPBADTYP"},
            {name=>"CMS__REPBCKPTR", type=>"IV", macro=>"CMS$_REPBCKPTR", value=>"CMS$_REPBCKPTR"},
            {name=>"CMS__REPCMD", type=>"IV", macro=>"CMS$_REPCMD", value=>"CMS$_REPCMD"},
            {name=>"CMS__REPCNTSTR", type=>"IV", macro=>"CMS$_REPCNTSTR", value=>"CMS$_REPCNTSTR"},
            {name=>"CMS__REPDEL", type=>"IV", macro=>"CMS$_REPDEL", value=>"CMS$_REPDEL"},
            {name=>"CMS__REPEDF", type=>"IV", macro=>"CMS$_REPEDF", value=>"CMS$_REPEDF"},
            {name=>"CMS__REPENDPTR", type=>"IV", macro=>"CMS$_REPENDPTR", value=>"CMS$_REPENDPTR"},
            {name=>"CMS__REPGENLRL", type=>"IV", macro=>"CMS$_REPGENLRL", value=>"CMS$_REPGENLRL"},
            {name=>"CMS__REPGENMRS", type=>"IV", macro=>"CMS$_REPGENMRS", value=>"CMS$_REPGENMRS"},
            {name=>"CMS__REPILLDATREC", type=>"IV", macro=>"CMS$_REPILLDATREC", value=>"CMS$_REPILLDATREC"},
            {name=>"CMS__REPLACEMENTS", type=>"IV", macro=>"CMS$_REPLACEMENTS", value=>"CMS$_REPLACEMENTS"},
            {name=>"CMS__REPMISBLK", type=>"IV", macro=>"CMS$_REPMISBLK", value=>"CMS$_REPMISBLK"},
            {name=>"CMS__REPREF", type=>"IV", macro=>"CMS$_REPREF", value=>"CMS$_REPREF"},
            {name=>"CMS__RESERVATIONS", type=>"IV", macro=>"CMS$_RESERVATIONS", value=>"CMS$_RESERVATIONS"},
            {name=>"CMS__RESERVED", type=>"IV", macro=>"CMS$_RESERVED", value=>"CMS$_RESERVED"},
            {name=>"CMS__RESERVEDBYYOU", type=>"IV", macro=>"CMS$_RESERVEDBYYOU", value=>"CMS$_RESERVEDBYYOU"},
            {name=>"CMS__RETRIEVALS", type=>"IV", macro=>"CMS$_RETRIEVALS", value=>"CMS$_RETRIEVALS"},
            {name=>"CMS__RETRIEVED", type=>"IV", macro=>"CMS$_RETRIEVED", value=>"CMS$_RETRIEVED"},
            {name=>"CMS__REVIEWED", type=>"IV", macro=>"CMS$_REVIEWED", value=>"CMS$_REVIEWED"},
            {name=>"CMS__REVIEWS", type=>"IV", macro=>"CMS$_REVIEWS", value=>"CMS$_REVIEWS"},
            {name=>"CMS__REVPENDING", type=>"IV", macro=>"CMS$_REVPENDING", value=>"CMS$_REVPENDING"},
            {name=>"CMS__SAMELINE", type=>"IV", macro=>"CMS$_SAMELINE", value=>"CMS$_SAMELINE"},
            {name=>"CMS__SEQFAIL", type=>"IV", macro=>"CMS$_SEQFAIL", value=>"CMS$_SEQFAIL"},
            {name=>"CMS__SEQMISMAT", type=>"IV", macro=>"CMS$_SEQMISMAT", value=>"CMS$_SEQMISMAT"},
            {name=>"CMS__SEQUENCED", type=>"IV", macro=>"CMS$_SEQUENCED", value=>"CMS$_SEQUENCED"},
            {name=>"CMS__SIZEMISMAT", type=>"IV", macro=>"CMS$_SIZEMISMAT", value=>"CMS$_SIZEMISMAT"},
            {name=>"CMS__STARTHIS", type=>"IV", macro=>"CMS$_STARTHIS", value=>"CMS$_STARTHIS"},
            {name=>"CMS__STOPPED", type=>"IV", macro=>"CMS$_STOPPED", value=>"CMS$_STOPPED"},
            {name=>"CMS__SUPERSEDE", type=>"IV", macro=>"CMS$_SUPERSEDE", value=>"CMS$_SUPERSEDE"},
            {name=>"CMS__SYSTIMDIF", type=>"IV", macro=>"CMS$_SYSTIMDIF", value=>"CMS$_SYSTIMDIF"},
            {name=>"CMS__SYSTIMERR", type=>"IV", macro=>"CMS$_SYSTIMERR", value=>"CMS$_SYSTIMERR"},
            {name=>"CMS__TIMEORDER", type=>"IV", macro=>"CMS$_TIMEORDER", value=>"CMS$_TIMEORDER"},
            {name=>"CMS__TOODEEP", type=>"IV", macro=>"CMS$_TOODEEP", value=>"CMS$_TOODEEP"},
            {name=>"CMS__TOOLONG", type=>"IV", macro=>"CMS$_TOOLONG", value=>"CMS$_TOOLONG"},
            {name=>"CMS__TOOMANYLIBS", type=>"IV", macro=>"CMS$_TOOMANYLIBS", value=>"CMS$_TOOMANYLIBS"},
            {name=>"CMS__TRUNCLST", type=>"IV", macro=>"CMS$_TRUNCLST", value=>"CMS$_TRUNCLST"},
            {name=>"CMS__TRYAGNLAT", type=>"IV", macro=>"CMS$_TRYAGNLAT", value=>"CMS$_TRYAGNLAT"},
            {name=>"CMS__UNDEFLIB", type=>"IV", macro=>"CMS$_UNDEFLIB", value=>"CMS$_UNDEFLIB"},
            {name=>"CMS__UNFOUT", type=>"IV", macro=>"CMS$_UNFOUT", value=>"CMS$_UNFOUT"},
            {name=>"CMS__UNRECTYPE", type=>"IV", macro=>"CMS$_UNRECTYPE", value=>"CMS$_UNRECTYPE"},
            {name=>"CMS__UNRESERVED", type=>"IV", macro=>"CMS$_UNRESERVED", value=>"CMS$_UNRESERVED"},
            {name=>"CMS__UNRESERVES", type=>"IV", macro=>"CMS$_UNRESERVES", value=>"CMS$_UNRESERVES"},
            {name=>"CMS__UNSUPFRMT", type=>"IV", macro=>"CMS$_UNSUPFRMT", value=>"CMS$_UNSUPFRMT"},
            {name=>"CMS__USERECOVER", type=>"IV", macro=>"CMS$_USERECOVER", value=>"CMS$_USERECOVER"},
            {name=>"CMS__USEREPAIR", type=>"IV", macro=>"CMS$_USEREPAIR", value=>"CMS$_USEREPAIR"},
            {name=>"CMS__USERERR", type=>"IV", macro=>"CMS$_USERERR", value=>"CMS$_USERERR"},
            {name=>"CMS__USESETLIB", type=>"IV", macro=>"CMS$_USESETLIB", value=>"CMS$_USESETLIB"},
            {name=>"CMS__VARINRANGE", type=>"IV", macro=>"CMS$_VARINRANGE", value=>"CMS$_VARINRANGE"},
            {name=>"CMS__VARLETTER", type=>"IV", macro=>"CMS$_VARLETTER", value=>"CMS$_VARLETTER"},
            {name=>"CMS__VER2", type=>"IV", macro=>"CMS$_VER2", value=>"CMS$_VER2"},
            {name=>"CMS__VERARC", type=>"IV", macro=>"CMS$_VERARC", value=>"CMS$_VERARC"},
            {name=>"CMS__VERCLS", type=>"IV", macro=>"CMS$_VERCLS", value=>"CMS$_VERCLS"},
            {name=>"CMS__VERCMD", type=>"IV", macro=>"CMS$_VERCMD", value=>"CMS$_VERCMD"},
            {name=>"CMS__VERCON", type=>"IV", macro=>"CMS$_VERCON", value=>"CMS$_VERCON"},
            {name=>"CMS__VEREDF", type=>"IV", macro=>"CMS$_VEREDF", value=>"CMS$_VEREDF"},
            {name=>"CMS__VEREDFERR", type=>"IV", macro=>"CMS$_VEREDFERR", value=>"CMS$_VEREDFERR"},
            {name=>"CMS__VEREDFS", type=>"IV", macro=>"CMS$_VEREDFS", value=>"CMS$_VEREDFS"},
            {name=>"CMS__VERELE", type=>"IV", macro=>"CMS$_VERELE", value=>"CMS$_VERELE"},
            {name=>"CMS__VERFRE", type=>"IV", macro=>"CMS$_VERFRE", value=>"CMS$_VERFRE"},
            {name=>"CMS__VERGRP", type=>"IV", macro=>"CMS$_VERGRP", value=>"CMS$_VERGRP"},
            {name=>"CMS__VERIFIED", type=>"IV", macro=>"CMS$_VERIFIED", value=>"CMS$_VERIFIED"},
            {name=>"CMS__VERILLDATREC", type=>"IV", macro=>"CMS$_VERILLDATREC", value=>"CMS$_VERILLDATREC"},
            {name=>"CMS__VERLMTERR", type=>"IV", macro=>"CMS$_VERLMTERR", value=>"CMS$_VERLMTERR"},
            {name=>"CMS__VERREF", type=>"IV", macro=>"CMS$_VERREF", value=>"CMS$_VERREF"},
            {name=>"CMS__VERREFERR", type=>"IV", macro=>"CMS$_VERREFERR", value=>"CMS$_VERREFERR"},
            {name=>"CMS__VERREFERRW", type=>"IV", macro=>"CMS$_VERREFERRW", value=>"CMS$_VERREFERRW"},
            {name=>"CMS__VERREFS", type=>"IV", macro=>"CMS$_VERREFS", value=>"CMS$_VERREFS"},
            {name=>"CMS__VERRES", type=>"IV", macro=>"CMS$_VERRES", value=>"CMS$_VERRES"},
            {name=>"CMS__VERSTR", type=>"IV", macro=>"CMS$_VERSTR", value=>"CMS$_VERSTR"},
            {name=>"CMS__WAITING", type=>"IV", macro=>"CMS$_WAITING", value=>"CMS$_WAITING"},
            {name=>"CMS__WILDCONFLICT", type=>"IV", macro=>"CMS$_WILDCONFLICT", value=>"CMS$_WILDCONFLICT"},
            {name=>"CMS__WILDMATCH", type=>"IV", macro=>"CMS$_WILDMATCH", value=>"CMS$_WILDMATCH"},
            {name=>"CMS__WILDNEEDED", type=>"IV", macro=>"CMS$_WILDNEEDED", value=>"CMS$_WILDNEEDED"},
            {name=>"CMS__WILDNOMATCH", type=>"IV", macro=>"CMS$_WILDNOMATCH", value=>"CMS$_WILDNOMATCH"},
            {name=>"CMS__WILDVER", type=>"IV", macro=>"CMS$_WILDVER", value=>"CMS$_WILDVER"},
            {name=>"CMS__WRITEERR", type=>"IV", macro=>"CMS$_WRITEERR", value=>"CMS$_WRITEERR"},
            {name=>"CMS__ZEROADD", type=>"IV", macro=>"CMS$_ZEROADD", value=>"CMS$_ZEROADD"},
            {name=>"CMS__ZLENBLK", type=>"IV", macro=>"CMS$_ZLENBLK", value=>"CMS$_ZLENBLK"});

print constant_types(); # macro defs
foreach (C_constant ("VMS::CMS", 'constant', 'IV', $types, undef, 3, @names) ) {
    print $_, "\n"; # C constant subs
}
print "#### XS Section:\n";
print XS_constant ("VMS::CMS", $types);
__END__
   */

  switch (len) {
  case 8:
    return constant_8 (aTHX_ name, iv_return);
    break;
  case 9:
    /* Names all of length 9.  */
    /* CMS__EXIT CMS__VER2 */
    /* Offset 7 gives the best switch position.  */
    switch (name[7]) {
    case 'I':
      if (memEQ(name, "CMS__EXIT", 9)) {
      /*                      ^       */
#ifdef CMS$_EXIT
        *iv_return = CMS$_EXIT;
        return PERL_constant_ISIV;
#else
        return PERL_constant_NOTDEF;
#endif
      }
      break;
    case 'R':
      if (memEQ(name, "CMS__VER2", 9)) {
      /*                      ^       */
#ifdef CMS$_VER2
        *iv_return = CMS$_VER2;
        return PERL_constant_ISIV;
#else
        return PERL_constant_NOTDEF;
#endif
      }
      break;
    }
    break;
  case 10:
    return constant_10 (aTHX_ name, iv_return);
    break;
  case 11:
    return constant_11 (aTHX_ name, iv_return);
    break;
  case 12:
    return constant_12 (aTHX_ name, iv_return);
    break;
  case 13:
    return constant_13 (aTHX_ name, iv_return);
    break;
  case 14:
    return constant_14 (aTHX_ name, iv_return);
    break;
  case 15:
    return constant_15 (aTHX_ name, iv_return);
    break;
  case 16:
    return constant_16 (aTHX_ name, iv_return);
    break;
  case 17:
    return constant_17 (aTHX_ name, iv_return);
    break;
  case 18:
    return constant_18 (aTHX_ name, iv_return);
    break;
  case 19:
    return constant_19 (aTHX_ name, iv_return);
    break;
  case 20:
    return constant_20 (aTHX_ name, iv_return);
    break;
  case 22:
    if (memEQ(name, "CMS_M_GENERATIONAL_DIF", 22)) {
#ifdef CMS$M_GENERATIONAL_DIF
      *iv_return = CMS$M_GENERATIONAL_DIF;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 26:
    if (memEQ(name, "CMS_M_IGNORE_FIRST_VARIANT", 26)) {
#ifdef CMS$M_IGNORE_FIRST_VARIANT
      *iv_return = CMS$M_IGNORE_FIRST_VARIANT;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

