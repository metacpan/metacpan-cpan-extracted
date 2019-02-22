## File: doc/programs/Makefile.am
## Package: *
## Description:
##   + program-doc-level automake file
##-----------------------------------------------------------------------

##-----------------------------------------------------------------------
## Misc flags
##-----------------------------------------------------------------------

HTML_CSS_SRC        =../dtatw.css
HTML_CSS_LOCAL      = $(notdir $(HTML_CSS_SRC))
POD2MAN_CENTER_STR  ="DTA Tokenization Utilities"
POD2MAN_RELEASE_STR ="dta-tokwrap v$(VERSION)"

##-----------------------------------------------------------------------
## static vs. built: PODs
##-----------------------------------------------------------------------

#DYNAMIC_MAN1_PODS =$(DOC_MAN1_GOGS:.gog=.pod) $(DOC_PROG_INDEX_SKEL:.skel=.pod)
#DYNAMIC_MAN5_PODS =
STATIC_MAN1_PODS  = \
	dta-tokwrap.perl.pod dtatw-add-c.perl.pod dtatw-add-ws.perl.pod \
	dtatw-cids2local.perl.pod dtatw-txml2uxml.perl.pod dtatw-mkpx.perl.pod \
	dtatw-splice.perl.pod \
	dtatw-get-ddc-attrs.perl.pod dtatw-get-header.perl.pod dtatw-sanitize-header.perl.pod \
	dtatw-xml2ddc.perl.pod \
	dtatw-pn2p.perl.pod
#	dtatw-txml2cspan.perl.pod
STATIC_MAN5_PODS  = dtatw-files.pod

DYNAMIC_PODS = $(DYNAMIC_MAN1_PODS) $(DYNAMIC_MAN5_PODS)
STATIC_PODS  = $(STATIC_MAN1_PODS)  $(STATIC_MAN5_PODS)

##-----------------------------------------------------------------------
## Potential targets
##-----------------------------------------------------------------------

##-- pods
DOC_MAN1_PODS = $(DYNAMIC_MAN1_PODS) $(STATIC_MAN1_PODS)
DOC_MAN5_PODS = $(DYNAMIC_MAN5_PODS) $(STATIC_MAN5_PODS)
DOC_PODS      = $(DOC_MAN1_PODS) $(DOC_MAN5_PODS)

##--- manpages (section 1: always)
DOC_MAN1_TARGETS = $(DOC_MAN1_PODS:.pod=.1)
DOC_MAN5_TARGETS = $(DOC_MAN5_PODS:.pod=.5)
DOC_MAN_TARGETS  = $(DOC_MAN1_TARGETS) $(DOC_MAN5_TARGETS)

##-- text
DOC_TXT_TARGETS = $(DOC_PODS:.pod=.txt)

##-- html
DOC_HTML_STATIC  = $(HTML_CSS_LOCAL)
DOC_HTML_TARGETS = $(DOC_PODS:.pod=.html)

##-- latex
DOC_LATEX_TARGETS = $(DOC_PODS:.pod=.tex)
DOC_DVI_TARGETS   = $(DOC_PODS:.pod=.dvi)
DOC_PS_TARGETS    = $(DOC_PODS:.pod=.ps)
DOC_PDF_TARGETS   = $(DOC_PODS:.pod=.pdf)


##-----------------------------------------------------------------------
## Conditional targets: chosen by 'configure' & co. [should be safe]
##-----------------------------------------------------------------------

##-- automake 'EXTRA_*' vars
EXTRA_man1_MANS = $(DOC_MAN1_TARGETS)
EXTRA_man5_MANS = $(DOC_MAN5_TARGETS)

##-- automake doesn't appear to understand EXTRA_${whatever}_DATA
EXTRA_pkgdocprog_DATAFILES = \
	$(DOC_PODS) \
	$(DOC_TXT_TARGETS) \
	$(DOC_HTML_TARGETS) $(DOC_HTML_STATIC) \
	$(DOC_DVI_TARGETS) \
	$(DOC_PS_TARGETS) \
	$(DOC_PDF_TARGETS)

##-- accumulation variables
BUILD_PODS=
BUILD_MAN1_MANS=
BUILD_MAN5_MANS=
BUILD_DOCS=

STATIC_MAN1_MANS=
STATIC_MAN5_MANS=
STATIC_DOCS=

##--- selected: pods
if HAVE_OPTGEN
BUILD_PODS  += $(DYNAMIC_PODS)
else
STATIC_PODS += $(DYNAMIC_PODS)
endif

##--- selected: manpages (section 1: always)
if DOC_WANT_MAN
if HAVE_POD2MAN
BUILD_MAN1_MANS += $(DOC_MAN1_PODS:.pod=.1)
BUILD_MAN5_MANS += $(DOC_MAN5_PODS:.pod=.5)
else
STATIC_MAN1_MANS += $(DOC_MAN1_PODS:.pod=.1)
STATIC_MAN5_MANS += $(DOC_MAN5_PODS:.pod=.5)
endif
endif

##-- selected: text
if DOC_WANT_TXT
if HAVE_POD2TEXT
BUILD_DOCS += $(DOC_PODS:.pod=.txt)
endif
endif

##-- selected: html
if DOC_WANT_HTML
if HAVE_POD2HTML
BUILD_DOCS  += $(DOC_PODS:.pod=.html)
STATIC_DOCS += $(DOC_HTML_STATIC)
else
STATIC_DOCS += $(DOC_PODS:.pod=.html) $(DOC_HTML_STATIC)
endif
endif

##-- selected: latex->(dvi|ps|pdf)
if HAVE_POD2LATEX

if DOC_WANT_DVI
BUILD_DOCS += $(DOC_PODS:.pod=.dvi)
endif

if DOC_WANT_PS
BUILD_DOCS += $(DOC_PODS:.pod=.ps)
endif

if DOC_WANT_PDF
BUILD_DOCS += $(DOC_PODS:.pod=.pdf)
endif

endif

##-----------------------------------------------------------------------
## Primary targets
##-----------------------------------------------------------------------

##-- primaries
man1_MANS       = $(BUILD_MAN1_MANS) $(STATIC_MAN1_MANS)
man5_MANS       = $(BUILD_MAN5_MANS) $(STATIC_MAN5_MANS)
pkgdocprog_DATA = $(BUILD_DOCS)      $(STATIC_DOCS)

##-----------------------------------------------------------------------
## sources
##-----------------------------------------------------------------------

SUFFIXES = .skel .gog .pod .txt .1 .5 .html .tex .dvi .ps .pdf

##-----------------------------------------------------------------------
## local hooks
##-----------------------------------------------------------------------
all-local: $(man_MANS)

txt: $(DOC_TXT_TARGETS)
man: $(DOC_MAN_TARGETS)
html: $(DOC_HTML_TARGETS)
latex: $(DOC_LATEX_TARGETS)
dvi-doc: $(DOC_DVI_TARGETS)
ps: $(DOC_PS_TARGETS)
pdf: $(DOC_PDF_TARGETS)

.SECONDARY:

##-----------------------------------------------------------------------
## pod compilation rules: Getopt::Gen
##-----------------------------------------------------------------------

OPTGENFLAGS = -l

if HAVE_OPTGEN
.gog.pod:
	$(OPTGEN_PERL) $(OPTGENFLAGS) --nocfile --nohfile --notimestamp -F $* $<
endif

##-----------------------------------------------------------------------
## pod compilation rules: Getopt::Gen (from skel)
##-----------------------------------------------------------------------
OPTGEN_SKELFLAGS = \
	--nocfile --nohfile --nopod \
	--no-handle-help \
	--no-handle-version \
	--no-handle-rcfile \
	--no-handle-error \
	--notimestamp

if HAVE_OPTGEN
.skel.pod:
	echo | $(OPTGEN_PERL) $(OPTGEN_SKELFLAGS) --template=$< - > $@ 2>/dev/null
endif

##-----------------------------------------------------------------------
## pod conversion rules
##-----------------------------------------------------------------------

POD2MANFLAGS = \
	--center  $(POD2MAN_CENTER_STR) \
	--release $(POD2MAN_RELEASE_STR)

$(HTML_CSS_LOCAL): $(HTML_CSS_SRC)
	rm -f $@
	cp $< $@

POD2HTMLFLAGS = --podpath="$(srcdir):." --htmlroot="." --css="$(HTML_CSS_LOCAL)"

if HAVE_POD2MAN
.pod.1:
	-$(POD2MAN) $(POD2MANFLAGS) --section=1 $< $@

.pod.5:
	-$(POD2MAN) $(POD2MANFLAGS) --section=5 $< $@
endif

if HAVE_POD2TEXT
.pod.txt:
	-$(POD2TEXT) $< $@
endif

if HAVE_POD2HTML
.pod.html:
	-$(POD2HTML) $(POD2HTMLFLAGS) --infile=$< --outfile=$@
endif

if HAVE_POD2LATEX
.pod.tex:
	-$(POD2LATEX) --full --out $@ $<
endif

##-----------------------------------------------------------------------
## latex compilation
##-----------------------------------------------------------------------
.tex.dvi:
	latex -interaction=nonstopmode $*
	latex -interaction=nonstopmode $*

.dvi.ps:
	dvips $*

.tex.pdf:
	ps2pdf $* $@

##-----------------------------------------------------------------------
## Variables: cleanup
##-----------------------------------------------------------------------

## --- mostlyclean: built by 'make' & commonly rebuilt
#MOSTLYCLEANFILES =

## --- clean:  built by 'make'
CLEANFILES = \
	*.dvi *.ps *.pdf \
	*.log *.aux *.toc *.idx *~~ *.tmp

## --- distclean: built by 'configure'
DISTCLEANFILES = \
	*.gog acknowledge.pod

## -- maintainerclean: built by maintainer / by hand
MAINTAINERCLEANFILES = \
	*~ .*~ Makefile Makefile.in \
	*.man *.1 *.5 *.html *.txt *.tex \
	$(CLEANFILES) \
	$(DYNAMIC_PODS)

if HAVE_OPTGEN
CLEANFILES += $(DYNAMIC_PODS)
endif
if HAVE_POD2MAN
CLEANFILES += *.man *.1 *.5
endif
if HAVE_POD2HTML
CLEANFILES += *.html
endif
if HAVE_POD2TEXT
CLEANFILES += *.txt
endif
if HAVE_POD2LATEX
CLEANFILES += *.tex
endif

##-----------------------------------------------------------------------
## Variables: distribution
##-----------------------------------------------------------------------

## --- extra distribution files
EXTRA_DIST = \
	$(DOC_PROG_INDEX_SKEL) \
	$(DOC_PODS) \
	$(DOC_MAN_TARGETS) \
	$(DOC_HTML_TARGETS) \
	$(HTML_CSS_LOCAL)

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
.PHONY: cvsclean

cvsclean: maintainer-clean ;
