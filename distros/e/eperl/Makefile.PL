##
##  faked Perl 5 MakeMaker Makefile
##  Copyright (c) 1997 Ralf S. Engelschall, All Rights Reserved. 
##

require 5.00325;
use Config; 

$vers = `etc/newvers -l c -D eperl_version.c`;
$vers =~ s|\n$||;
print STDERR "Configuring for ePerl $vers\n";

$perl = $Config{bin} . "/perl";
$args = join(' ', @ARGV);

$cc = $Config{cc};
$ccarg = "";
if ($args =~ m|CC=(\S+)|) {
    $cc = $1;
    $ccarg = "CC=$1 ";
}

unlink("Makefile");
unlink("Makefile.stand");

open(MK, ">Makefile");
print MK <<"EOT";

all:
	\@if [ ! -f Makefile.stand ]; then \\
	    cp Makefile Makefile.perl; \\
		echo "${ccarg}./configure --with-perl=$perl"; \\
	    ${ccarg}./configure --with-perl=$perl; \\
	    mv Makefile Makefile.stand; \\
	    cp Makefile.perl Makefile; \\
		rm Makefile.perl; \\
	fi
	@\$(MAKE) -f Makefile.stand libeperl.a
	\@if [ ! -f mod/Makefile ]; then \\
	    echo "cd mod && $perl Makefile.PL $args"; \\
	    cd mod && $perl Makefile.PL $args; \\
		    sed -e '/^\trm -f */d' <Makefile >Makefile.n && mv Makefile.n Makefile; \\
		    sed -e 's,^CC = .*,CC = $cc,' <Parse/Makefile >Parse/Makefile.n && mv Parse/Makefile.n Parse/Makefile; \\
	fi
	cd mod && \$(MAKE) \$(MFLAGS)

test: all
	cd mod && \$(MAKE) \$(MFLAGS) test

install: all
	\@if [ "x\$(UNINST)" = x1 ]; then \\
	    echo "cd mod && \$(MAKE) \$(MFLAGS) install UNINST=1"; \\
	    cd mod && \$(MAKE) \$(MFLAGS) install UNINST=1; \\
	else \\
	    echo "cd mod && \$(MAKE) \$(MFLAGS) install"; \\
	    cd mod && \$(MAKE) \$(MFLAGS) install; \\
	fi

clean:
	cd mod && rm -rf blib *.o *.c *.bs pm_to_blib
	\$(MAKE) -f Makefile.stand clean

distclean:
	cd mod && \$(MAKE) \$(MFLAGS) distclean
	\$(MAKE) -f Makefile.stand distclean
	-rm -f Makefile.stand
	-rm -f Makefile

EOT
close(MK);

print STDERR "Now please type 'make' to compile. Good luck.\n";

##EOF##
