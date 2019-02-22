## File: doc/Makefile.am
## Description:
##   + automake file for doc/ subdir
##-----------------------------------------------------------------------

##-----------------------------------------------------------------------
## Primaries: headers
##-----------------------------------------------------------------------

## --- recursion subdirectories
SUBDIRS = dot programs DTA-TokWrap

#-----------------------------------------------------------------------
# Variables: cleanup
#-----------------------------------------------------------------------

## --- mostlyclean: built by 'make' & commonly rebuilt
MOSTLYCLEANFILES = pod2htm*.tmp

## --- clean:  built by 'make'
CLEANFILES =

## --- distclean: built by 'configure'
DISTCLEANFILES = README.pod

## -- maintainerclean: built by maintainer / by hand
MAINTAINERCLEANFILES = *~ .*~ Makefile Makefile.in

#-----------------------------------------------------------------------
# Variables: primaries
#-----------------------------------------------------------------------

pkgdoc_DATA = dtatw.css
DOC_PODS = README.pod

#POD2HTMLFLAGS = --css=dtatw.css --podroot="$(top_srcdir)/DTA-TokWrap/blib" --podpath="script" --header --backlink="(Back to Top)"
POD2HTMLFLAGS = --css=dtatw.css --podroot="$(top_srcdir)/DTA-TokWrap/blib" --podpath="script" --header

SUFFIXES = .pod .txt .html

txt: $(DOC_PODS:.pod=.txt)
html: $(DOC_PODS:.pod=.html)

if HAVE_POD2TEXT
pkgdoc_DATA += $(DOC_PODS:.pod=.txt)
.pod.txt:
	$(POD2TEXT) $< $@
CLEANFILES += $(DOC_PODS:.pod=.txt)
endif

if HAVE_POD2HTML
pkgdoc_DATA += $(DOC_PODS:.pod=.html)
.pod.html:
	$(POD2HTML) $(POD2HTMLFLAGS) --infile=$< --outfile=$@
CLEANFILES += $(DOC_PODS:.pod=.html)
endif




#-----------------------------------------------------------------------
# Variables: (un)install
#-----------------------------------------------------------------------
pkgdoc_UNINSTALL_FILES = $(SUBDIRS) README.txt README.html
uninstall-local:
	for f in $(pkgdoc_UNINSTALL_FILES) ; do \
	   rm -rf $(DESTDIR)$(pkgdocdir)/$$f ;\
	done

#-----------------------------------------------------------------------
# Variables: distribution
#-----------------------------------------------------------------------

## --- extra distribution files
EXTRA_DIST = \
	$(pkgdoc_DATA)

## --- recursion subdirectories for 'make dist'
#DIST_SUBDIRS =

#-----------------------------------------------------------------------
# Rules: cleanup
#-----------------------------------------------------------------------
.PHONY: cvsclean

cvsclean: maintainer-clean ;
