# $Id: Makefile.PL,v 1.5 2003-07-20 19:47:01 kiesling Exp $

# This is how ExtUtils::MakeMaker tests for installed packages.
my $eval = 'require Tk';
eval $eval;

if ($@) {
    warn "Warning: prerequisite $prereq failed to load: $@";
}

my $makefile = <<EOMAKEFILE;
all: install

install: 
	perl installscripts

clean:
	rm -f Makefile Makefile.old

test:
	
EOMAKEFILE

print "Creating Makefile in tkdm/.\n";
open OUT, ">Makefile" or die "Couldn't create Makefile: $!\n";
print OUT $makefile;
close OUT;
