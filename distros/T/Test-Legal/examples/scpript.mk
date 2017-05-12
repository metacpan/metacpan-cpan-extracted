.PHONY: $(shell ls)
.SILENT: 

files = tel2num.pl tel2mnemonic.pl

all: grep

grep :
	-grep "Copyright" $(files)
prune:
	perl -ni -e 'print unless /Copyrigh/' tel2num.pl
	perl -ni -e 'print unless /Copyrigh/' tel2mnemonic.pl
add:
	echo 'Copyright' >> tel2num.pl
	echo 'Copyright' >> tel2mnemonic.pl
