
# $Id: Makefile.PL,v 1.6 2003-11-28 22:17:23 kiesling Exp $

my $makefile = <<EOMAKEFILE;
all: install

install: 
	perl installscripts

clean:
	rm -f Makefile Makefile.old

test:
	sh -c true
EOMAKEFILE

print "Creating Makefile in eg/.\n";
open OUT, ">Makefile" or die "Couldn't create Makefile: $!\n";
print OUT $makefile;
close OUT;
