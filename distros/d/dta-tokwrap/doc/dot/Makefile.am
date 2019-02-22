## File: doc/dot/Makefile.am
## Package: *
## Description:
##   + dot-graph -level automake file
##-----------------------------------------------------------------------

##-----------------------------------------------------------------------
## Sources
##-----------------------------------------------------------------------

DOT_FILES = \
	dataflow-scripts.dot \
	dataflow-perl-doc.dot \
	dataflow-perl-files.dot \
	dataflow-tcf-files.dot

#dataflow-perl-files.dot

##-----------------------------------------------------------------------
## Potential targets
##-----------------------------------------------------------------------

##-----------------------------------------------------------------------
## Conditional targets: chosen by 'configure' & co. [should be safe]
##-----------------------------------------------------------------------

##-- accumulator
DOT_TARGETS=

##-- accumulate: raw dot files
DOT_TARGETS += $(DOT_FILES)

##-- accumulate: .pdf
if HAVE_DOT
DOT_TARGETS  += $(DOT_FILES:.dot=.pdf)
else
#DOT_TARGETS  += $(DOT_FILES:.dot=.pdf)
endif

##-----------------------------------------------------------------------
## Primary targets
##-----------------------------------------------------------------------

pkgdocdot_DATA = $(DOT_TARGETS)

##-----------------------------------------------------------------------
## sources
##-----------------------------------------------------------------------

SUFFIXES = .dot .eps .ps .pdf .png .xps .xeps .xpdf .xpng

##-----------------------------------------------------------------------
## local hooks & aliases
##-----------------------------------------------------------------------
all-local: $(DOT_TARGETS)

ps: $(DOT_FILES:.dot=.ps)
eps: $(DOT_FILES:.dot=.eps)
pdf: $(DOT_FILES:.dot=.pdf)
png: $(DOT_FILES:.dot=.png)

.SECONDARY:

if HAVE_DOT
.dot.ps:
	$(DOT) -Tps -o $@ $<

.dot.eps:
	$(DOT) -Teps -o $@ $<

.dot.png:
	$(DOT) -Tpng -o $@ $<
endif

if HAVE_DOT
if HAVE_EPSTOPDF
#.eps.pdf:
.ps.pdf:
	epstopdf $< -o $@
#else
#if HAVE_PS2PDF
#.ps.pdf:
#	ps2pdf $< $@
else
.dot.pdf:
	dot -Tpdf -o $@ $<
#endif
endif
endif

.ps.xps:
	gv -spartan -watch -scale=-2 $< &
.eps.xps:
	gv -spartan -watch -scale=-2 $< &

.pdf.xpdf:
	xpdf -z 'page' $< &

.png.xpng:
	eog $< &

##-----------------------------------------------------------------------
## Variables: cleanup
##-----------------------------------------------------------------------

## --- mostlyclean: built by 'make' & commonly rebuilt
#MOSTLYCLEANFILES =

## --- clean:  built by 'make'
CLEANFILES = \
	*.ps *.eps *.pdf *.png

## --- distclean: built by 'configure'
#DISTCLEANFILES =

## -- maintainerclean: built by maintainer / by hand
MAINTAINERCLEANFILES = \
	*~ .*~ Makefile Makefile.in \
	$(CLEANFILES)

##-----------------------------------------------------------------------
## Variables: distribution
##-----------------------------------------------------------------------

## --- extra distribution files
EXTRA_DIST = \
	$(DOT_FILES)

## --- recursion subdirectories for 'make dist'
#DIST_SUBDIRS = $(SUBDIRS)

## --- dist-hook: when another 'Makefile.am' is overkill
#DISTHOOK_DIRS = foo
#DISTHOOK_FILES = foo/bar.txt foo/baz.txt
#dist-hook:
#	for d in $(DISTHOOK_DIRS); do\
#	  mkdir -p $(distdir)/$$d ;\
#	done
#	for f in $(DISTHOOK_FILES); do\
#	  cp -p $(srcdir)/$$f $(distdir)/$$f ;\
#	done

##-----------------------------------------------------------------------
## Rules: cleanup
##-----------------------------------------------------------------------
.PHONY: cvsclean svnclean

cvsclean: maintainer-clean ;
svnclean: cvsclean ;
