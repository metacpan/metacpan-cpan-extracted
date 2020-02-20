## File: Makefile.am
## Description: automake file, src-level
##-----------------------------------------------------------------------

##-----------------------------------------------------------------------
## Includes
include $(top_srcdir)/Common.am

##-----------------------------------------------------------------------
## PROGRAMS

bin_PROGRAMS = \
	dtatw-mkindex \
	dtatw-cx2dat \
	dtatw-rm-namespaces \
	dtatw-xml-depth \
	dtatw-tokenize-dummy \
	dtatw-b2xb \
	dtatw-tok2xml

EXTRA_PROGRAMS_OLD = dtatw-cxlexer \
	dtatw-txml2master \
	dtatw-txml2wxml \
	dtatw-txml2sxml \
	dtatw-txml2axml

BUILT_SOURCES = \
	dtatwConfigNoAuto.h

common_deps = dtatwCommon.c dtatwCommon.h config.h dtatwConfig.h dtatwConfigAuto.h dtatwConfigNoAuto.h
expat_deps = dtatwExpat.c dtatwExpat.h
utf8_deps = dtatwUtf8.h dtatwUtf8.c

dtatw_mkindex_SOURCES = dtatw-mkindex.c $(common_deps) $(expat_deps) $(utf8_deps)
dtatw_mkindex_LDADD = $(EXPAT_LIBS)

dtatw_cx2dat_SOURCES = dtatw-cx2dat.c $(common_deps)

if HAVE_FLEX
dtatw_tokenize_dummy_SOURCES = dtatw-tokenize-dummy.l
else
dtatw_tokenize_dummy_SOURCES = dtatw-tokenize-dummy.c
endif

dtatw_rm_namespaces_SOURCES = dtatw-rm-namespaces.c $(common_deps) $(expat_deps)
dtatw_rm_namespaces_LDADD = $(EXPAT_LIBS)

dtatw_xml_depth_SOURCES = dtatw-xml-depth.c $(common_deps) $(expat_deps)
dtatw_xml_depth_LDADD = $(EXPAT_LIBS)

dtatw_tok2xml_SOURCES = dtatw-tok2xml.c $(common_deps)

dtatw_b2xb_SOURCES = dtatw-b2xb.c $(common_deps)

#dtatw_txml2wxml_SOURCES = dtatw-txml2wxml.c $(common_deps) $(expat_deps)
#dtatw_txml2wxml_LDADD   = $(EXPAT_LIBS)
#
#dtatw_txml2sxml_SOURCES = dtatw-txml2sxml.c $(common_deps) $(expat_deps)
#dtatw_txml2sxml_LDADD   = $(EXPAT_LIBS)
#
#dtatw_txml2axml_SOURCES = dtatw-txml2axml.c $(common_deps) $(expat_deps)
#dtatw_txml2axml_LDADD   = $(EXPAT_LIBS)

extra: $(EXTRA_PROGRAMS)

##----------------------------------------------------
## Additional rules

dtatwConfigNoAuto.h: dtatwConfigAuto.h
	echo "/* src/dtatwConfigNoAuto.h. Generated from dtatwConfigAuto.h by make */" > dtatwConfigNoAuto.h
	sed 's/^#define \([^ ]*\).*$$/#undef \1/;' dtatwConfigAuto.h >> dtatwConfigNoAuto.h


##-----------------------------------------------------------------------
## Dist

EXTRA_DIST += \
	dtatw-tokenize-dummy.l dtatw-tokenize-dummy.c

##--- clean: built by 'make'
CLEANFILES += \
	dtatwConfigNoAuto.h

##--- distclean: built by 'configure'
#DISTCLEANFILES =

##--- maintainerclean: built by maintainer / by hand
#MAINTAINERCLEANFILES =

