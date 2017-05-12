DOCXML=docbook-xml-4.5CR3

FILES=$(DOCXML).zip docbook-xsl-1.75.2.tar.bz2 fop-0.95-bin.tar.gz jai-1_1_3-lib.zip \
	offo-hyphenation-fop-stable_v1.2.zip xml-commons-resolver-1.2.tar.gz links.tgz

DIRS=$(DOCXML) docbook-xsl-1.75.2 fop-0.95 jai-1_1_3 \
	offo-hyphenation-fop-stable xml-commons-resolver-1.2

all: download extract

extract:
	[ -d $(DOCXML) ] || mkdir $(DOCXML)
	cd $(DOCXML) && unzip -o ../$(DOCXML).zip
	tar xjvf docbook-xsl-1.75.2.tar.bz2
	tar xzvf fop-0.95-bin.tar.gz
	unzip -o jai-1_1_3-lib.zip
	unzip -o offo-hyphenation-fop-stable_v1.2.zip
	tar xzvf xml-commons-resolver-1.2.tar.gz
	tar xzvf links.tgz

download:
	for i in $(FILES); do [ -f "$$i" ] || wget "http://downloads.sourceforge.net/project/triceps/docbook-for-1.0/$$i" || exit 1; done

clean:
	rm -rf $(DIRS)

distclean: clean
	rm -f $(FILES)
