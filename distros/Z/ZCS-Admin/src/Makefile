#
# Set variables as needed for your environment and make:
#   WSDL2PERL=/site/soap-wsdl/default/bin/wsdl2perl.pl
#   PERL5LIB=/site/soap-wsdl/default/lib:/site/perl/default/lib
#   make -e

ADMINWSDL = ZimbraAdmin.wsdl
PLTYPEMAP = zcs-admin-custom-typemap.pl

TMPLIBDIR = newlib
ZCSADMINDIR = ZCS/Admin
TMPLIBPATH = $(TMPLIBDIR)/$(ZCSADMINDIR)/
ZCSLIBPATH = ../lib/$(ZCSADMINDIR)/

RSYNC = /usr/bin/rsync
RSYNCARGS = -rlcv

WSDL2PERL = wsdl2perl.pl
WSDLARGS  = -a ZCS::Admin::Attributes \
	-t ZCS::Admin::Types \
	-e ZCS::Admin::Elements \
	-m ZCS::Admin::Typemaps \
	-i ZCS::Admin::Interfaces \
	-sp ZCS::Admin::Server \
	-mi $(PLTYPEMAP) \
	-b $(TMPLIBDIR) \
        file:$(ADMINWSDL)

wsdl2perl: $(PLTYPEMAP) $(ADMINWSDL) $(WSDL2PERL)
	$(WSDL2PERL) $(WSDLARGS)
	@echo run 'make updatelib' to copy updates from $(TMPLIBDIR) to $(ZCSLIBPATH)

updatelib: $(TMPLIBPATH) $(ZCSLIBPATH) $(rsync)
	-$(RSYNC) $(RSYNCARGS) $(TMPLIBPATH) $(ZCSLIBPATH)

all: wsdl2perl updatelib

clean: $(TMPLIBDIR)
	-rm -rf $(TMPLIBDIR)
