## File: doc/PERLMODULE/Makefile.am
## Description:
##   + automake file for doc/PERLMODULE subdir
##-----------------------------------------------------------------------

##-----------------------------------------------------------------------
## Overrides
##-----------------------------------------------------------------------

## CSS file, relative to $(PWD)
CSS_SRC ?= $(srcdir)/../dtatw.css
PKGDOC_SUBDIR = $(DESTDIR)$(pkgdocdir)/$(notdir $(PWD))

##-----------------------------------------------------------------------
## Globals
##-----------------------------------------------------------------------

PMSRC = $(top_builddir)/DTA-TokWrap
PMDEPS = $(PMSRC)/Makefile
$(PMSRC)/Makefile: $(PMSRC)/Makefile.PL
	cd $(PMSRC); $(PERL) Makefile.PL $(MAKEPLFLAGS)

ALL_LOCAL_DEPS =
CLEAN_LOCAL_DEPS =
PKGDOC_DIRS =
DIST_HOOK_DEPS =
EXTRA_DIST =

all-local: $(ALL_LOCAL_DEPS)
clean-local: $(CLEAN_LOCAL_DEPS)

##-----------------------------------------------------------------------
## POD (debug)

POD_DIR ?= pod

pod: pod-index
#pod.stamp

if HAVE_PODSELECT
pod.stamp: $(PMDEPS)
	$(MAKE) -C $(PMSRC) INST_PODDIR=$(PWD)/$(POD_DIR) podifypods
	touch $@

pod-dist: pod.stamp $(POD_DIR)/index.pod
	$(mkdir_p) $(distdir)/$(POD_DIR)
	for f in $(POD_DIR)/*.pod ; do \
	  cp -p $$f $(distdir)/$(POD_DIR) ;\
	done

index.pod: make-pod-index.perl pod.stamp
	$(PERL) make-pod-index.perl $(filter-out $(POD_DIR)/index.pod,$(wildcard $(POD_DIR)/*.pod)) -- > $@

CLEAN_LOCAL_DEPS += no-pod
else
pod.stamp:
	$(mkdir_p) $(POD_DIR)
	touch $@
pod-dist: pod.stamp
	@:
#index.pod:
#	touch $@
endif

pod-index: $(POD_DIR)/index.pod
$(POD_DIR)/index.pod: index.pod
	$(mkdir_p) $(POD_DIR)
	cp index.pod $@

pod-readme: $(POD_DIR)/README.pod

$(POD_DIR)/README.pod: README.pod
	$(mkdir_p) $(POD_DIR)
	cp -p README.pod $@

README.pod: $(PMSRC)/README.rpod
	cp -p $(PMSRC)/README.rpod $@

EXTRA_DIST += make-pod-index.perl index.pod

no-pod:
	rm -f pod.stamp
	rm -f index.pod
	rm -f $(POD_DIR)/*.pod $(POD_DIR)/.exists || true
	test -d $(POD_DIR) && rmdir $(POD_DIR) || true

#if DOC_WANT_POD
#ALL_LOCAL_DEPS += pod.stamp
#PKGDOC_DIRS += $(POD_DIR)
#DIST_HOOK_DEPS += pod-dist
#endif




##-----------------------------------------------------------------------
## text

TXT_DIR ?= txt

txt: txt.stamp

if HAVE_POD2TEXT
txt.stamp: $(PMDEPS) $(TXT_DIR)/index.txt $(TXT_DIR)/README.txt
	$(MAKE) -C $(PMSRC) INST_TEXTDIR=$(PWD)/$(TXT_DIR) textifypods
	$(POD2TEXT) $(PMSRC)/README.rpod $(TXT_DIR)/README.txt
	touch $@

txt-dist: txt.stamp txt-index
	$(mkdir_p) $(distdir)/$(TXT_DIR)
	for f in $(TXT_DIR)/*.txt ; do \
	  cp -p $$f $(distdir)/$(TXT_DIR) ;\
	done

index.txt: index.pod
	$(POD2TEXT) index.pod $@

README.txt: README.pod
	$(POD2TEXT) README.pod $@

CLEAN_LOCAL_DEPS += no-txt
else
txt.stamp: $(TXT_DIR)/index.txt
	touch $@
txt-dist: txt.stamp
	@:
index.txt: index.pod
	cp -p index.pod $@
endif

txt-index: $(TXT_DIR)/index.txt
$(TXT_DIR)/index.txt: index.txt
	$(mkdir_p) $(TXT_DIR)
	cp -p index.txt $@

txt-readme: $(TXT_DIR)/README.txt
$(TXT_DIR)/README.txt: README.txt
	$(mkdir_p) $(TXT_DIR)
	cp -p README.txt $@

no-txt:
	-rm -f txt.stamp index.txt
	-rm -f $(TXT_DIR)/*.txt $(TXT_DIR)/.exists
	-test -d $(TXT_DIR) && rmdir $(TXT_DIR)


if DOC_WANT_TXT
ALL_LOCAL_DEPS += txt.stamp
PKGDOC_DIRS += $(TXT_DIR)
DIST_HOOK_DEPS += txt-dist
EXTRA_DIST += index.txt README.txt
endif

##-----------------------------------------------------------------------
## html

HTML_DIR ?= html
CSS = $(notdir $(CSS_SRC))

css: $(HTML_DIR)/$(CSS)
$(HTML_DIR)/$(CSS): $(CSS_SRC)
	rm -f $@
	cp -p $(CSS_SRC) $@
no-html-css:
	-rm -f $(HTML_DIR)/$(CSS)
	-rmdir $(HTML_DIR)
CLEAN_LOCAL_DEPS += no-html-css

html: html.stamp css

if HAVE_POD2HTML
html.stamp: $(PMDEPS) $(HTML_DIR)/index.html $(HTML_DIR)/README.html
	$(MAKE) -C $(PMSRC) INST_HTMLDIR=$(PWD)/$(HTML_DIR) INST_CSS=$(CSS) htmlifypods
	touch $@

html-dist: html.stamp
	$(mkdir_p) $(distdir)/$(HTML_DIR)
	for f in $(HTML_DIR)/*.html ; do \
	  cp -p $$f $(distdir)/$(HTML_DIR) ;\
	done

index.html: index.pod
	$(POD2HTML) --css=$(CSS) --podroot=$(POD_DIR) --podpath=. --infile=index.pod \
	| $(PERL) -p \
	   -e'sub hackhref {($$href=shift)=~s|^[/\.]*||; $$href=~s|/|.|g; $$href;}' \
	   -e's/<a href="([^"]*)/'\''<a href="'\''.hackhref($$1)/eg;' \
	 > $@ || (rm -f $@; false)

README.html: README.pod
	$(POD2HTML) --css=$(CSS) --podroot=$(POD_DIR) --podpath=. --infile=index.pod \
	| $(PERL) -p \
	   -e'sub hackhref {($$href=shift)=~s|^[/\.]*||; $$href=~s|/|.|g; $$href;}' \
	   -e's/<a href="([^"]*)/'\''<a href="'\''.hackhref($$1)/eg;' \
	 > $@ || (rm -f $@; false)

CLEAN_LOCAL_DEPS += no-html
else
html.stamp:
	$(mkdir_p) $(HTML_DIR)
	touch $@
html-dist: html.stamp
	@:
endif

html-index: $(HTML_DIR)/index.html
$(HTML_DIR)/index.html: index.html
	$(mkdir_p) $(HTML_DIR)
	cp -p index.html $@

html-readme: $(HTML_DIR)/README.html
$(HTML_DIR)/README.html: README.html
	$(mkdir_p) $(HTML_DIR)
	cp -p README.html $@

no-html:
	-rm -f html.stamp index.html
	-rm -f $(HTML_DIR)/*.html $(HTML_DIR)/.exists
	-test -d $(HTML_DIR) && rmdir $(HTML_DIR)

if DOC_WANT_HTML
ALL_LOCAL_DEPS += html
PKGDOC_DIRS += $(HTML_DIR)
DIST_HOOK_DEPS += html-dist
EXTRA_DIST += index.html README.html
endif

##-----------------------------------------------------------------------
## Install: local
##-----------------------------------------------------------------------

install-data-local:
	$(mkdir_p) $(PKGDOC_SUBDIR) ;\
	for d in $(PKGDOC_DIRS); do \
	  test -d "$$d" || continue; \
	  $(mkdir_p) $(PKGDOC_SUBDIR)/$$d ;\
	  for f in "$$d"/* ; do \
	    $(INSTALL_DATA) $$f $(PKGDOC_SUBDIR)/$$d ;\
	  done ;\
	done

uninstall-local:
	rm -rf $(PKGDOC_SUBDIR)

dist-hook: $(DIST_HOOK_DEPS)

#-----------------------------------------------------------------------
# Variables: cleanup
#-----------------------------------------------------------------------

## --- mostlyclean: built by 'make' & commonly rebuilt
MOSTLYCLEANFILES = pod2htm*.tmp

## --- clean:  built by 'make'
CLEANFILES = \
	pod.stamp txt.stamp html.stamp

## --- distclean: built by 'configure'
#DISTCLEANFILES =

## -- maintainerclean: built by maintainer / by hand
MAINTAINERCLEANFILES = \
	*~ .*~ Makefile Makefile.in

#-----------------------------------------------------------------------
# Rules: cleanup
#-----------------------------------------------------------------------
.PHONY: cvsclean

cvsclean: maintainer-clean ;
