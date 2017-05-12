
TARGETS = guide # allpics # samples
HTMLTARGETS = $(foreach t, $(TARGETS), ../html/$(t).html)
PDFTARGETS = $(foreach t, $(TARGETS), ../pdf/$(t).pdf)
SOURCES =  $(foreach t, $(TARGETS), $(t).xml)
DEPENDSOURCES =  $(foreach t, $(TARGETS), docsrc/$(t).xml)

# The config files require the absolute paths.
DOC_SRC := $(shell pwd)
DOC_CFG = $(DOC_SRC)/cfg

ifeq (,$(TRICEPS_TOOLS_BASE))
	TOOLS_BASE = $(shell readlink -f '$(DOC_SRC)'/../dbtools)
else
	TOOLS_BASE = $(TRICEPS_TOOLS_BASE)
endif

TOOLS_XSL = $(TOOLS_BASE)/docbook-xsl-1.75.2
TOOLS_DTD = $(TOOLS_BASE)/docbook-xml-4.5CR3
TOOLS_FOP = $(TOOLS_BASE)/fop-0.95

TOOLS_SETTINGS = $(DOC_CFG)/profile.incl
TOOLS_CATALOG = $(DOC_CFG)/catalog.xml
TOOLS_MANAGER = $(DOC_CFG)/CatalogManager.properties

DTD = $(TOOLS_DTD)/docbookx.dtd
#STYLESHEET_FO = $(TOOLS_XSL)/fo/docbook.xsl
STYLESHEET_FO = myfo.xsl
STYLESHEET_HTML = myhtml.xsl
ENTS_FO = entpdf/user.ent
ENTS_HTML = enthtml/user.ent
FOP = $(TOOLS_FOP)/fop

CONFIGS = Makefile $(TOOLS_SETTINGS) $(TOOLS_CATALOG) $(TOOLS_MANAGER) $(STYLESHEET_FO) \
	$(DOC_CFG)/excatalog.xml $(DOC_CFG)/excataloghtml.xml

.PHONY: all pdf html cfg

all: cfg pdf html

cfg: $(TOOLS_SETTINGS) $(TOOLS_CATALOG) $(TOOLS_MANAGER) \
	$(DOC_CFG)/excatalog.xml $(DOC_CFG)/excataloghtml.xml

pdf: subdirs autodepend $(PDFTARGETS)

html: subdirs autodepend $(HTMLTARGETS)

subdirs:
	$(MAKE) -C seq
	$(MAKE) -C figrefs
	[ -d doc ] || mkdir doc

ex:
	$(MAKE) -C ../ex extxml

depend:
	rm -f .depends
	$(MAKE) autodepend

autodepend: .depends

.depends:: Makefile xmldep.pl $(DEPENDSOURCES)
ifeq (,$(strip $(NODEP) $(filter help% clean% %clean clobber% cfg%, $(MAKECMDGOALS))))
	$(MAKE) -C seq
	./xmldep.pl $(DEPENDSOURCES) >.depends.tmp
	mv .depends.tmp .depends
endif

# only remove the work files, not the final results
cleanwork:
	rm -f .depends .depends.tmp *.xml *.pdf *.fo *.png *.gif *.tiff *.svg docsrc/allpics.xml
	rm -rf cfg doc
	$(MAKE) -C seq clean
	$(MAKE) -C figrefs clean

clean: cleanwork
	rm -f ../pdf/* ../html/*

docsrc/allpics.xml: mkallpics docsrc/0*.xml
	./mkallpics >$@

$(DOC_CFG)/%: cfgsrc/% Makefile
	[ -d cfg ] || mkdir cfg
	sed 's|\$${DOC_SRC}|$(DOC_SRC)|g;s|\$${TOOLS_BASE}|${TOOLS_BASE}|g' <$< >$@

%.xml: docsrc/%.xml xmlpre.pl
	./xmlpre.pl <$< >$@

CATALOG_DEBUG_SETTING = # XML_DEBUG_CATALOG=1 
#FONT_SIZE_PARAM = --stringparam body.font.master 10
#			--stringparam use.extensions 0 \
#			--stringparam  page.height 9in \
#			--stringparam  page.width 6in \
#			--stringparam  page.margin.inner 1in \
#			--stringparam  page.margin.outer 0.75in \
#			--stringparam  double.sided 1 \
#			--stringparam  fop1.extensions 1 \
#			--stringparam  body.start.indent 0pt \
#			--stringparam  section.autolabel 1 \
#			--stringparam  section.label.includes.component.label 1 \
#			--stringparam  insert.xref.page.number yes \
#			--stringparam  insert.link.page.number yes \
#			--stringparam  ulink.hyphenate.chars '/&?%' \
#			--stringparam  ulink.hyphenate ' ' \
#			$(FONT_SIZE_PARAM) \
#			
%.fo: %.xml $(CONFIGS) $(STYLESHEET_FO) $(ENTS_FO)
	. $(TOOLS_SETTINGS); \
		XML_CATALOG_FILES="$(TOOLS_XSL)/catalog.xml $(TOOLS_DTD)/catalog.xml $(DOC_CFG)/excatalog.xml" \
		$(CATALOG_DEBUG_SETTING) \
		xsltproc --output $@ --xinclude \
			$(STYLESHEET_FO) $<

../html/%.html: %.xml $(CONFIGS) $(STYLESHEET_HTML) $(ENTS_HTML)
	. $(TOOLS_SETTINGS); \
		XML_CATALOG_FILES="$(TOOLS_XSL)/catalog.xml $(TOOLS_DTD)/catalog.xml $(DOC_CFG)/excataloghtml.xml" \
		$(CATALOG_DEBUG_SETTING) \
		xsltproc --output $@ --xinclude \
			$(STYLESHEET_HTML) $<

../pdf/%.pdf: %.fo $(CONFIGS)
	. $(TOOLS_SETTINGS); FOP_OPTS="-Xmx900M" $(FOP) $< $@

%.ps: %.fo $(CONFIGS)
	. $(TOOLS_SETTINGS); FOP_OPTS="-Xmx900M" $(FOP) $< $@

# Saving images from OpenOffice Draw is a pain, it can't save a decent
# scalable .svg and screws up the resolution in .png. So save as .eps
# and use convert:
%.png: ../fig/%.eps
	convert -depth 1 -density 1200 $< $@

# For HTML version generate a low-resolution but high-depth picture
%.lowres.png: ../fig/%.eps
	convert -density 100 $< $@

# For the already-png files, just copy them
%.lowres.png: ../fig/%.png_orig
	 convert -geometry 450x550 $< $@

# Place the file for the
../html/%.lowres.png: %.lowres.png
	ln $< $@

# .tiff gives the real depth 1 images, much smaller than png
%.tiff: ../fig/%.eps
	convert -depth 1 -compress Group4 -density 1200 $< $@

# the correct way to produce svg from eps
%.svg: ../fig/%.eps
	./eps2svg $< $@

# just rename from the suffix that makes sure that the file won't be deleted
%.png: ../fig/%.png_orig
	cp $< $@

ifeq (,$(strip $(filter help% clean% %clean clobber% cfg%, $(MAKECMDGOALS))))
sinclude .depends
endif
