use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

# mandatory stuff
my $ok = 1;
my @deps = ('XML::SAX',
	    'XML::NamespaceSupport',
	    'Clone',
	   );

foreach (@deps) {
    my $try = "require $_;";
    my $ver = '$' . $_ . '::VERSION';
    eval $try;
    if ($@) {
	print "$_ is missing!\n";
	print "It must be installed before you can install XML::STX.\n";
	$ok = 0;
    } else {
	my $v = eval $ver;
	print "$_ $v found\n";
    }
}

exit unless $ok;

# HTML docs
system("pod2html --infile=STX.pm --outfile=doc/STX.html");
system("pod2html --infile=doc/TrAXref.pod --outfile=doc/TrAXref.html --noindex");
system("rm -f *~");
system("rm -f */*~");

WriteMakefile(
    'NAME'		=> 'XML::STX',
    'VERSION_FROM'	=> 'STX.pm',
    'PREREQ_PM'		=> {XML::SAX => 0.10, 
			    XML::NamespaceSupport => 1.07,
			    Clone => 0.13,
			    POSIX => 1.00},
    'EXE_FILES'	        => [ qw(stxcmd.pl stxview.pl) ],
    dist	        => {COMPRESS => 'gzip', SUFFIX => 'tar.gz'},
);
