## File: scripts/Makefile.am
## Description:
##   + automake file for scripts/ subdir
##-----------------------------------------------------------------------

##-----------------------------------------------------------------------
## Primaries: headers
##-----------------------------------------------------------------------

## --- recursion subdirectories
#SUBDIRS =

#-----------------------------------------------------------------------
# Variables: cleanup
#-----------------------------------------------------------------------

## --- mostlyclean: built by 'make' & commonly rebuilt
MOSTLYCLEANFILES =

## --- clean:  built by 'make'
CLEANFILES =

## --- distclean: built by 'configure'
DISTCLEANFILES =

## -- maintainerclean: built by maintainer / by hand
MAINTAINERCLEANFILES = *~ .*~ Makefile Makefile.in

#-----------------------------------------------------------------------
# Variables: primaries
#-----------------------------------------------------------------------

pkgxsl_DATA = \
	dtatw-add-lb.xsl \
	dtatw-assign-cids.xsl \
	dtatw-rm-c.xsl \
	dtatw-rm-lb.xsl \
	dtatw-txml2tt.xsl \
	dtatw-serialize-prevnext.xsl \
	dtatw-txmlsort.xsl

bin_SCRIPTS = \
	dtatw-pn2p.perl \
	dtatw-add-c.perl \
	dtatw-cids2local.perl \
	dtatw-mkpx.perl \
	dtatw-format.perl \
	dtatw-add-ws.perl \
	dtatw-rm-lb.perl \
	dtatw-rm-c.perl \
	dtatw-rm-ws.perl \
	dtatw-tt-dictapply.perl \
	dtatw-cabtt2xml.perl \
	dtatw-txml2uxml.perl \
	dtatw-splice.perl \
	dtatw-get-ddc-attrs.perl \
	dtatw-fast-ddc-attrs.perl \
	dtatw-get-header.perl \
	dtatw-insert-header.perl \
	dtatw-xml2ddc.perl \
	dtatw-sanitize-header.perl \
	dtatw-t-check.perl \
	dtatw-ls-ids.perl \
	dtatw-sanitize-prevnext.perl \
	dtatw-restore-namespaces.perl \
	dtatw-nsdefault-encode.perl \
	dtatw-nsdefault-decode.perl \
	dtatw-seg2prevnext.perl \
	dtatw-add-xpath.perl \
	dtatw-ensure-lb.perl \
	dtatw-lb-encode.perl \
	dtatw-percent-encode.perl \
	dtatw-percent-decode.perl \
	file-substr.perl

#	dtatw-txml2cspan.perl

#-----------------------------------------------------------------------
# Variables: distribution
#-----------------------------------------------------------------------

## --- extra distribution files
EXTRA_DIST = \
	$(pkgxsl_DATA) \
	$(bin_SCRIPTS)

## --- recursion subdirectories for 'make dist'
#DIST_SUBDIRS =

#-----------------------------------------------------------------------
# Rules: cleanup
#-----------------------------------------------------------------------
.PHONY: cvsclean

cvsclean: maintainer-clean ;
