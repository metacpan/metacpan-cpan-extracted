NAME=libdownsexta-perl
NAMED=DataSexta
NAMEX=SextaXML
NAMEDIR=DownVideos
EXAMPLEDS=ejemplo_datasexta
EXAMPLEXML=ejemplo_sextaxml
EXAMPLEDSXML=ejemplo_datasexta_sextaxml
MANFILE=DownVideos::DataSexta
PREFIX=/usr/
DATADIR=$(PREFIX)/share
DOCDIR=$(DATADIR)/doc/$(NAME)/
HTMLDIR=$(DOCDIR)/html
EXAMPLESDIR=$(DATADIR)/$(NAME)/examples
LIBDIR=$(DATADIR)/perl5/$(NAMEDIR)
MANDIR=$(DATADIR)/man/man3

all: libdownsexta

libdownsexta:
	@mkdir -p build

	cp $(NAMED).pm  build/$(NAMED).pm
	cp $(NAMEX).pm  build/$(NAMEX).pm
	cp ./examples/*.pl build/
	cp ./doc/man/*.3pm.gz build/
	cp ./doc/html/*.html build/
	

install:
	mkdir -p	\
			$(PREFIX) \
			$(DATADIR) \
			$(EXAMPLESDIR) \
			$(LIBDIR) \
			$(MANDIR) \
			$(HTMLDIR)

	install -m 0664 build/$(NAMED).pm			$(LIBDIR)/
	install -m 0664 build/$(NAMEX).pm			$(LIBDIR)/
	install -m 0644 build/*.pl			$(EXAMPLESDIR)/
	install -m 0664 build/*.3pm.gz			$(MANDIR)/
	install -m 0664	build/*.html				$(HTMLDIR)/

uninstall:
	rm -fr $(LIBDIR)
	rm $(MANDIR)/$(MANFILE).3pm.gz
	rm -fr $(DATADIR)/$(NAME)
	rm -fr $(DOCDIR)

clean:
	rm -fr build build-stamp install-stamp
	rm -fr debian/libdownsexta*
