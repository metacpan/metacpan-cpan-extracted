dnl -*- Mode: autoconf -*-
dnl AX_DOC_COMMON()
dnl  + common documentation stuff
dnl  + vars: doc_formats
dnl  + args: --with-docdir, --with-doc-formats
dnl  + AC_SUBST directory vars: pkgdocdir, pkgdocprogdir, pkgdoctutdir, pkgdoclibdir
dnl  + AC_SUBST:      CONFIG_DOC_WANT_(TXT|MAN|HTML|LATEX|DVI|PS|PDF)
dnl  + AM_CONDITIONAL:       DOC_WANT_(TXT|MAN|HTML|LATEX|DVI|PS|PDF), DOC_ENABLED
dnl
dnl AX_DOC_DOXYGEN()
dnl  + requires: AX_DOC_COMMON
dnl  + input vars: DOXYGEN_SOURCES, DOXY_DEFINES, DOXY_TAGPKGS
dnl  + AC_SUBST vars: DOXYGEN, DOXY_FILTER, DOXY_INPUT_FILTER, DOXYGEN_SOURCES, DOXY_DEFINES, DOXY_TAGFILES
dnl  + AM_CONDITIONAL: DOXY_WANT_(MAN|HTML|LATEX)
dnl
dnl AX_DOC_DOT()
dnl  + requires: (?)
dnl  + input vars: (?)
dnl  + AC_SUBST vars: DOT, HAVE_DOT, PS2PDF, HAVE_PS2PDF
dnl  + AM_CONDITIONAL: HAVE_DOT, HAVE_PS2PDF
dnl
dnl AX_DOC_POD()
dnl  + requires: AX_DOC_COMMON
dnl  + i/o AC_SUBST program vars: POD2TEXT, POD2MAN, POD2HTML, POD2LATEX
dnl  + i/o AC_SUBST target vars: DOC_MAN1_PODS, DOC_MAN5_PODS
dnl  + AM_CONDITIONAL: (none?)
dnl
dnl AX_DOC_GOG()
dnl  + requires: AX_CHECK_GOG()
dnl  + implies AX_DOC_POD
dnl  + input vars: DOC_MAN1_GOGS, DOC_GOGS, DOC_GOG_SKELS
dnl  + output vars: DOC_MAN1_PODS
dnl  + AM_CONDITIONAL: (none?)
dnl
dnl AX_DOC_GOG_LINKS([srcdir=src/programs [, dstdir=doc/programs]])
dnl  + input vars: DOC_MAN1_GOGS
dnl  + configures links dst -> src


dnl=============================================================================
AC_DEFUN([AX_DOC_COMMON],
[
##vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv
## Documentation: common
AC_ARG_WITH(docdir,
	AC_HELP_STRING([--with-docdir=DIR],
		[install documentation in DIR/AC_PACKAGE_NAME (default=DATADIR/doc)]),
	[docdir="$withval"],
	[docdir="\${datadir}/doc"])
pkgdocdir="\${docdir}/\${PACKAGE}"
pkgdocprogdir="\${docdir}/\${PACKAGE}/programs"
pkgdoctutdir="\${docdir}/\${PACKAGE}/tutorial"
pkgdoclibdir="\${docdir}/\${PACKAGE}/lib\${PACKAGE}"

AC_SUBST(docdir)
AC_SUBST(pkgdocdir)
AC_SUBST(pkgdocprogdir)
AC_SUBST(pkgdoctutdir)
AC_SUBST(pkgdoclibdir)

AC_ARG_WITH(doc-formats,
	AC_HELP_STRING([--with-doc-formats=LIST],
		       [Build documentation formats in LIST. \
                        Available formats: txt, man, html, dvi, ps, pdf, none.
	                Default='man html'. Requires Perl, pod2xxx.]),
	[ac_cv_doc_formats="$withval"])
AC_ARG_ENABLE(doc,
	AC_HELP_STRING([--disable-doc],[Synonym for --with-doc-formats="none"]),
	[enable_doc="$enableval"],[enable_doc="yes"])

if test "$enable_doc" != "yes" ; then
  ac_cv_doc_formats="none"
fi

AC_MSG_CHECKING([which documentation formats to build])
##
##-- set default doc formats if unspecified
if test -z "$ac_cv_doc_formats" ; then
  ac_cv_doc_formats="man html"
fi
##
##-- un-comma-tize the doc-formats
doc_formats=`echo "$ac_cv_doc_formats" | sed 's/\,/ /g'`

AC_MSG_RESULT($doc_formats)

  ##-- initialize "CONFIG_DOC_WANT_*" variables
  ##   + test with automake conditionals "DOC_WANT_*"

  ##-- docs: parse user request
  ##
  for fmt in "none" $doc_formats ; do
    case "$fmt" in
      txt)
        CONFIG_DOC_WANT_TXT="yes"
	;;
      man)
        CONFIG_DOC_WANT_MAN="yes"
	;;
      html)
        CONFIG_DOC_WANT_HTML="yes"
	;;
      dvi)
        CONFIG_DOC_WANT_LATEX="yes"
        CONFIG_DOC_WANT_DVI="yes"
	;;
      ps)
	CONFIG_DOC_WANT_LATEX="yes"
        CONFIG_DOC_WANT_PS="yes"
	;;
      pdf)
        CONFIG_DOC_WANT_LATEX="yes"
	CONFIG_DOC_WANT_PDF="yes"
	;;
      none)
	enable_doc="no"
        CONFIG_DOC_WANT_TXT="no"
	CONFIG_DOC_WANT_MAN="no"
  	CONFIG_DOC_WANT_HTML="no"
  	CONFIG_DOC_WANT_LATEX="no"
  	CONFIG_DOC_WANT_DVI="no"
  	CONFIG_DOC_WANT_PS="no"
  	CONFIG_DOC_WANT_PDF="no"
	;;
      *)
	AC_MSG_WARN(ignoring unknown documentation format: $fmt)
	;;
    esac; # case "$fmt" in ...
  done; # for fmt in $doc_formats ...
  ##
  ##--/docs: parse user request

  ##-- docs: requested: automake conditionals: indicator values
  AC_SUBST(CONFIG_DOC_WANT_TXT)
  AC_SUBST(CONFIG_DOC_WANT_MAN)
  AC_SUBST(CONFIG_DOC_WANT_HTML)
  AC_SUBST(CONFIG_DOC_WANT_LATEX)
  AC_SUBST(CONFIG_DOC_WANT_DVI)
  AC_SUBST(CONFIG_DOC_WANT_PS)
  AC_SUBST(CONFIG_DOC_WANT_PDF)

  ##-- automake conditionals: doc_want_x
  AM_CONDITIONAL(DOC_ENABLED,      [test -n "$doc_formats"           -a "$doc_formats" != "none"])
  AM_CONDITIONAL(DOC_WANT_TXT,     [test -n "$CONFIG_DOC_WANT_TXT"   -a "$CONFIG_DOC_WANT_TXT"   != "no"])
  AM_CONDITIONAL(DOC_WANT_MAN,     [test -n "$CONFIG_DOC_WANT_MAN"   -a "$CONFIG_DOC_WANT_MAN"   != "no"])
  AM_CONDITIONAL(DOC_WANT_HTML,    [test -n "$CONFIG_DOC_WANT_HTML"  -a "$CONFIG_DOC_WANT_HTML"  != "no"])
  AM_CONDITIONAL(DOC_WANT_LATEX,   [test -n "$CONFIG_DOC_WANT_LATEX" -a "$CONFIG_DOC_WANT_LATEX" != "no"])
  AM_CONDITIONAL(DOC_WANT_DVI,     [test -n "$CONFIG_DOC_WANT_DVI"   -a "$CONFIG_DOC_WANT_DVI"   != "no"])
  AM_CONDITIONAL(DOC_WANT_PS,      [test -n "$CONFIG_DOC_WANT_PS"    -a "$CONFIG_DOC_WANT_PS"    != "no"])
  AM_CONDITIONAL(DOC_WANT_PDF,     [test -n "$CONFIG_DOC_WANT_PDF"   -a "$CONFIG_DOC_WANT_PDF"   != "no"])
])

dnl=============================================================================
AC_DEFUN([AX_DOC_DOT],
[
##vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv
## Documentation: dot

  ##-- dot: prog
  ##
  AC_ARG_VAR(DOT,[Path to dot graph formatter; "no" to disable])
  if test -z "$DOT" ; then
    AC_PATH_PROG(DOT,dot,[no])
  fi
  ##
  if test -z "$DOT" -o "$DOT" = "no"; then
    AC_MSG_WARN([dot missing or disabled])
    AC_MSG_WARN([- graph generation disabled])
    DOT=no
    HAVE_DOT=no
  else
    HAVE_DOT=yes
  fi
  ##-- dot: output
  dnl AC_MSG_NOTICE([setting DOT=$DOT])
  AM_CONDITIONAL(HAVE_DOT,     [test -n "$DOT"     -a "$DOT"     != "no"])
  AC_SUBST(DOT)
  AC_SUBST(HAVE_DOT)
  ##
  ##--/dot

  ##-- ps2pdf : prog
  ##
  AC_ARG_VAR(PS2PDF,[Path to ps2pdf converter; "no" to disable])
  if test -z "$PS2PDF" ; then
    AC_PATH_PROG(PS2PDF,[ps2pdf],[no])
  fi
  ##
  if test -z "$PS2PDF" -o "$PS2PDF" = "no"; then
    AC_MSG_WARN([ps2pdf missing or disabled])
    AC_MSG_WARN([- dot-generated pdf files might look ugly])
    PS2PDF=no
    HAVE_PS2PDF=no
  else
    HAVE_PS2PDF=yes
  fi
  ##-- ps2pdf: output
  dnl AC_MSG_NOTICE([setting PS2PDF=$PS2PDF])
  AM_CONDITIONAL(HAVE_PS2PDF,     [test -n "$PS2PDF"     -a "$PS2PDF"     != "no"])
  AC_SUBST(PS2PDF)
  AC_SUBST(HAVE_PS2PDf)
  ##
  ##--/ps2pdf

  ##-- EPSTODF : prog
  ##
  AC_ARG_VAR(EPSTOPDF,[Path to epstopdf converter; "no" to disable])
  if test -z "$EPSTOPDF" ; then
    AC_PATH_PROG(EPSTOPDF,[epstopdf],[no])
  fi
  ##
  if test -z "$EPSTOPDF" -o "$EPSTOPDF" = "no"; then
    dnl AC_MSG_WARN([epstopdf missing or disabled])
    dnl AC_MSG_WARN([- dot-generated pdf files might look ugly])
    EPSTOPDF=no
    HAVE_EPSTOPDF=no
  else
    HAVE_EPSTOPDF=yes
  fi
  ##-- epstopdf: output
  dnl AC_MSG_NOTICE([setting EPSTOPDF=$EPSTOPDF])
  AM_CONDITIONAL(HAVE_EPSTOPDF,     [test -n "$EPSTOPDF"     -a "$EPSTOPDF"     != "no"])
  AC_SUBST(EPSTOPDF)
  AC_SUBST(HAVE_EPSTOPDF)
  ##
  ##--/epstopdf
])

dnl=============================================================================
AC_DEFUN([AX_DOC_DOXYGEN],
[
##vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv
## Documentation: doxygen

##-- doxygen: var
AC_ARG_VAR(DOXYGEN,[Path to doxygen documentation generator; "no" to disable])

if test "$doc_formats" != "none" ; then

  ##-- doxygen: prog
  ##
  if test -z "$DOXYGEN" ; then
    AC_PATH_PROG(DOXYGEN,doxygen,[no])
  fi
  AC_MSG_NOTICE([setting DOXYGEN=$DOXYGEN])
  ##
  if test -z "$DOXYGEN" -o "$DOXYGEN" = "no"; then
    AC_MSG_WARN([doxygen missing or disabled])
    AC_MSG_WARN([- generation of library documentation disabled])
    DOXYGEN=no
  fi
  ##
  ##--/doxygen:prog

  ##-- doxygen: filter: doc/lib*/'doxy-filter.perl'
  ##
  AC_ARG_VAR(DOXY_FILTER,[doxygen input filter; "no" to disable (default)])
  AC_MSG_CHECKING([for doxygen input filter])
  if test -z "$DOXY_FILTER"; then
    DOXY_FILTER="no"
    #DOXY_SRCDIR="`find ${srcdir}/doc/ -name 'lib*' -print | head -n1`"
    #if test -d "$DOXY_SRCDIR" -a -f "$DOXY_SRCDIR/doxy-filter.perl" -a "$PERL" != "no" ; then
    #  DOXY_SRCDIR=`cd "$DOXY_SRCDIR"; pwd`
    #  DOXY_FILTER="$PERL $DOXY_SRCDIR/doxy-filter.perl"
    #else
    #  DOXY_FILTER="no"
    #fi
  fi
  AC_MSG_RESULT([$DOXY_FILTER])
  ##
  if test "$DOXY_FILTER" != "no"; then
    AC_MSG_CHECKING([whether doxygen input filter works])
    if test -n "$DOXY_FILTER" && $DOXY_FILTER </dev/null 2>&1 >>config.log ; then
      AC_MSG_RESULT([yes])
    else
      AC_MSG_RESULT([no])
      DOXY_FILTER="no"
    fi
  fi
  AC_MSG_NOTICE([setting DOXY_FILTER=$DOXY_FILTER])
  ##
  if test "$DOXY_FILTER" != "no"; then
    DOXY_INPUT_FILTER="$DOXY_FILTER"
  else
    DOXY_INPUT_FILTER=""
  fi
  AC_SUBST(DOXY_FILTER)
  AC_SUBST(DOXY_INPUT_FILTER)
  ##
  ##--/doxygen:filter

  ##-- doxygen: sources
  AC_SUBST(DOXYGEN_SOURCES)

  ##-- docs: doxygen vars (compatibility)
  DOXY_WANT_MAN="$CONFIG_DOC_WANT_MAN"
  DOXY_WANT_HTML="$CONFIG_DOC_WANT_HTML"
  DOXY_WANT_LATEX="$CONFIG_DOC_WANT_LATEX"
  DOXY_WANT_HTMLHELP="NO"
  AC_SUBST(DOXY_WANT_HTML)
  AC_SUBST(DOXY_WANT_MAN)
  AC_SUBST(DOXY_WANT_LATEX)

  ##-- docs: doxygen: defines
  AC_SUBST(DOXY_DEFINES)

  ##-- doxygen: external tag-files (this needs an overhaul!)
  ##
  for ext in $DOXY_TAGPKGS; do
    extdocdir="`$PKG_CONFIG --variable=pkgdocdir ${ext}`"
    if test -n "$extdocdir" -a "$extdocdir" != "no" ; then
      exttagfiles="`find $extdocdir -name '*.tag'`"
      for exttag in $exttagfiles ; do
        exttagdir="`dirname $exttag`/html"
        if test -d "$exttagdir" ; then
          DOXY_TAGFILES="$DOXY_TAGFILES $exttag=$exttagdir"
        fi
      done
    fi
  done 
  AC_SUBST(DOXY_TAGPKGS)
  AC_SUBST(DOXY_TAGFILES)   
  ##
  ##--/doxyxgen: tag-files
  
fi; # if test "$doc_formats" != "none" ...

##-- automake conditionals: doyxgen
AM_CONDITIONAL(HAVE_DOXYGEN,     [test -n "$DOXYGEN"     -a "$DOXYGEN"     != "no"])
AM_CONDITIONAL(HAVE_DOXY_FILTER, [test -n "$DOXY_FILTER" -a "$DOXY_FILTER" != "no"])
])



dnl=============================================================================
AC_DEFUN([AX_DOC_POD],
[
  ##vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv
  ## Documentation: .pod
if test "$doc_formats" != "none" ; then
  ##-- docs: section 5 (static pods)
  AC_SUBST(DOC_MAN1_PODS)
  AC_SUBST(DOC_MAN5_PODS)

  ##-- docs: pods (all)
  DOC_PODS="$DOC_MAN1_PODS $DOC_MAN5_PODS"
  AC_SUBST(DOC_PODS)

  ##-- docs:pod2x
  ##
  AC_ARG_VAR(PODSELECT, [Path to perl 'podselect' script; "no" for none])
  AC_ARG_VAR(POD2TEXT, [Path to perl 'pod2text' script; "no" for none])
  AC_ARG_VAR(POD2MAN,  [Path to perl 'pod2man' script; "no" for none])
  AC_ARG_VAR(POD2HTML, [Path to perl 'pod2html' script; "no" for none])
  AC_ARG_VAR(POD2LATEX,[Path to perl 'pod2latex' script; "no" for none])
  if test -z "$PODSELECT" ; then
     AC_PATH_PROG(PODSELECT,podselect,[no])
  fi
  if test -z "$POD2TEXT" ; then
     AC_PATH_PROG(POD2TEXT,pod2text,[no])
  fi
  if test -z "$POD2MAN"  ; then
     AC_PATH_PROG(POD2MAN,pod2man,[no])
  fi
  if test -z "$POD2HTML" ; then
     AC_PATH_PROG(POD2HTML,pod2html,[no])
  fi
  if test -z "$POD2LATEX"; then
     AC_PATH_PROG(POD2LATEX,pod2latex,[no])
  fi
  ##
  ##--/docs:pod2x
fi; # if test "$doc_formats" != "none" ...

##-- programs: pod2x
AC_SUBST(PODSELECT)
AC_SUBST(POD2TEXT)
AC_SUBST(POD2MAN)
AC_SUBST(POD2HTML)
AC_SUBST(POD2LATEX)

##-- automake conditionals: pod2x
AM_CONDITIONAL(HAVE_PODSELECT,   [test -n "$PODSELECT" -a "$PODSELECT"  != "no"])
AM_CONDITIONAL(HAVE_POD2TEXT,    [test -n "$POD2TEXT"  -a "$POD2TEXT"  != "no"])
AM_CONDITIONAL(HAVE_POD2MAN,     [test -n "$POD2MAN"   -a "$POD2MAN"   != "no"]) 
AM_CONDITIONAL(HAVE_POD2HTML,    [test -n "$POD2HTML"  -a "$POD2HTML"  != "no"])
AM_CONDITIONAL(HAVE_POD2LATEX,   [test -n "$POD2LATEX" -a "$POD2LATEX" != "no"])
])

dnl=============================================================================
AC_DEFUN([AX_DOC_GOG],
[
  ##vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv
  ## documentation: .gog

  ##-- variables
  DOC_MAN1_PODS="$DOC_MAN1_PODS `echo \"$DOC_GOG_SKELS\" | sed 's/\.skel/\.pod/g'` `echo \"$DOC_MAN1_GOGS\" | sed 's/\.gog/\.pod/g'`"

  AC_SUBST(DOC_GOG_SKELS)
  AC_SUBST(DOC_MAN1_GOGS)
  AC_SUBST(DOC_GOGS)

  ##-- re-call DOC_POD
  AX_DOC_POD()
])

dnl=============================================================================
dnl AX_DOC_GOG_LINKS([srcdir=src/programs [, dstdir=doc/programs]])
AC_DEFUN([AX_DOC_GOG_LINKS],
[
  test -n "$1" && gogsrcdir="$1" || gogsrcdir="src/programs"
  test -n "$2" && gogdstdir="$2" || gogdstdir="doc/programs"
  ##vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv
  ## documentation: .gog: links
  for g in $DOC_MAN1_GOGS ; do
    AC_CONFIG_LINKS(${gogdstdir}/${g}:${gogsrcdir}/${g})  
  done
])
