#   The following is a trick to get CPAN clients to follow prerequisites:
#
#    PREREQ_PM
#

# --- MakeMaker post_initialize section:


AUTOMAKE_OPTIONS = foreign
SUBDIRS = . include library module glue
EXTRA_DIST = LICENSE NOTICE README INSTALL CHANGES STATUS FAQ.pod MANIFEST.SKIP Makefile.PL buildconf build win32 docs libapreq.rc
APU_SRCDIR=`@APU_CONFIG@ --srcdir`
APR_SRCDIR=`@APR_CONFIG@ --srcdir`
APU_DOX = (cd $(APU_SRCDIR); cat docs/doxygen.conf - | doxygen -)
APR_DOX = (cd $(APR_SRCDIR); cat docs/doxygen.conf - | doxygen -)
SED_BODY_TAG= s(^[\S\s]+<body.+|</body>[\S\s]+$$)()gi, \
	s(href="/Apache2(?:/\w+)*/([^/]+).html")(href="group__apreq__xs__\L$$1.html")g, \
	s(href="/APR/Request/Param/(?:Table|Cookie).html")(href="group__apreq__xs__apr__request.html")g, \
	s(href="/APR/Request.html")(href="group__apreq__xs__apr__request.html")g, \
	s(href="/APR/Request/([^/]+).html")(href="group__apreq__xs__apr__request__\L$$1.html")g, \
	s(href="/APR/Brigade.html")(href="http://apr.apache.org/docs/apr-util/$(APU_DOC_VERSION)/apr__buckets_8h.html")g, \
	s(href="/APR/([^/]+).html")(href="http://apr.apache.org/docs/apr/$(APR_DOC_VERSION)/apr__\L$$1s_8h.html")g

EUM=ExtUtils::Manifest
PM_DIR=glue/perl/lib/Apache2
XS_DIR=glue/perl/xsbuilder/APR
bin_SCRIPTS = apreq2-config
CLEANFILES = $(bin_SCRIPTS)

POD2HTML = @PERL@ -MPod::Html -wle 'pod2html @ARGV'

if BUILD_PERL_GLUE
PERL_TEST = perl_test
else
PERL_TEST = 
endif

TAR=@TAR@

release: distclean docs_clean reconfig distdir
	@PERL@ build/version_check.pl > $(distdir)/PREREQUISITES
	@PERL@ build/version_check.pl -version=@PACKAGE_VERSION@ > $(distdir)/META.yml
	echo MANIFEST > $(distdir)/MANIFEST
	@cd $(distdir); @PERL@ -M$(EUM) -e "$(EUM)::mkmanifest"
	@PERL@ -ple '$$_="$(distdir)/$$_"' $(distdir)/MANIFEST | $(TAR) -czf $(distdir).tar.gz -T -
	rm -rf $(distdir)
	@echo "Made $(distdir).tar.gz"

release_test:
	-rm -rf $(distdir)
	if [ ! -x $(TAR) ]; then echo "$(TAR) is not executable."; fi
	$(TAR) xzvf $(distdir).tar.gz
	@cd $(distdir); @PERL@ -M$(EUM) -e "die 'Bogus MANIFEST' if $(EUM)::manicheck"
	@cd $(distdir); @PERL@ Makefile.PL -apxs @APACHE2_APXS@ && $(MAKE) test
	rm -rf $(distdir)
	@echo "$(distdir).tar.gz is kosher."

reconfig:
	./buildconf.nice
	./config.nice

docs_clean:
	-rm -rf docs
	-rm -rf *.html  pod2*.tmp

docs:	pod2html build/doxygen.conf apr_tags docs/html/feather.gif
	@PERL@ build/version_check.pl doxygen
	doxygen build/doxygen.conf

docs_install: docs
	@$(NORMAL_INSTALL)
	$(mkinstalldirs) $(DESTDIR)$(pkgdatadir)
	cp *.html docs/html
	cp -R docs $(DESTDIR)$(pkgdatadir)

%.html: $(POD_DIR)/%.pm Makefile.am 
	${POD2HTML} < $< | @PERL@ -0777 -pe '$(SED_BODY_TAG)' > $@

Apache2__Request.html: $(PM_DIR)/Request.pm
	${POD2HTML} < $< | @PERL@ -0777 -pe '$(SED_BODY_TAG)' > $@

Apache2__Upload.html: $(PM_DIR)/Upload.pm
	${POD2HTML} < $< | @PERL@ -0777 -pe '$(SED_BODY_TAG)' > $@

Apache2__Cookie.html: $(PM_DIR)/Cookie.pm
	${POD2HTML} < $< | @PERL@ -0777 -pe '$(SED_BODY_TAG)' > $@

APR__Request.html: $(XS_DIR)/Request/Request.pod
	${POD2HTML} < $< | @PERL@ -0777 -pe '$(SED_BODY_TAG)' > $@

APR__Request__Param.html: $(XS_DIR)/Request/Param/Param.pod
	${POD2HTML} < $< | @PERL@ -0777 -pe '$(SED_BODY_TAG)' > $@

APR__Request__Cookie.html: $(XS_DIR)/Request/Cookie/Cookie.pod
	${POD2HTML} < $< | @PERL@ -0777 -pe '$(SED_BODY_TAG)' > $@

APR__Request__Error.html: $(XS_DIR)/Request/Error/Error.pod
	${POD2HTML} < $< | @PERL@ -0777 -pe '$(SED_BODY_TAG)' > $@

APR__Request__Apache2.html: $(XS_DIR)/Request/Apache2/Apache2.pod
	${POD2HTML} < $< | @PERL@ -0777 -pe '$(SED_BODY_TAG)' > $@

APR__Request__CGI.html: $(XS_DIR)/Request/CGI/CGI.pod
	${POD2HTML} < $< | @PERL@ -0777 -pe '$(SED_BODY_TAG)' > $@

FAQ.html: Makefile.am FAQ.pod
	${POD2HTML} < FAQ.pod | @PERL@ -0777 -pe '$(SED_BODY_TAG)' > FAQ.html

pod2html :: Apache2__Request.html Apache2__Cookie.html Apache2__Upload.html 
pod2html :: APR__Request.html APR__Request__Cookie.html
pod2html :: APR__Request__Param.html APR__Request__Error.html
pod2html :: APR__Request__Apache2.html APR__Request__CGI.html FAQ.html


$(POD_DIR)/%.t: $(POD_DIR)/%.pod
	(cd glue/perl ; pod2test docs/$*.pod docs/$*.t)

pod2test :: $(POD_DIR)/Request.t $(POD_DIR)/Cookie.t $(POD_DIR)/Upload.t $(POD_DIR)/Error.t $(POD_DIR)/Table.t

apr_tags: docs/apr.tag docs/apu.tag

docs/html/feather.gif:
	${mkinstalldirs} docs
	${mkinstalldirs} docs/html
	cp feather.gif docs/html

docs/apu.tag:
	${mkinstalldirs} docs
	echo GENERATE_TAGFILE=`pwd`/docs/apu.tag | $(APU_DOX)

docs/apr.tag:
	${mkinstalldirs} docs
	echo GENERATE_TAGFILE=`pwd`/docs/apr.tag | $(APR_DOX)

test: all library_test module_test $(PERL_TEST)

module_test:
	cd module; $(MAKE) test

library_test:
	cd library; $(MAKE) test

perl_install:
	cd glue/perl; $(MAKE) install

perl_test:
	cd glue/perl; $(MAKE) test

perl_glue:
	cd glue/perl; @PERL@ ../../build/xsbuilder.pl run
	cd glue/perl; @PERL@ Makefile.PL -apxs @APACHE2_APXS@
	cd glue/perl; $(MAKE)

if BUILD_HTTPD

install-exec-local: httpd_install

httpd_install:
	cd @APACHE2_SRC@; $(MAKE) install

endif
