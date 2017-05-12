use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

# mandatory stuff
my $ok = 1;
my @deps = ('File::Spec',
	    'Carp',
	    'Cwd',
	   );

foreach (@deps) {
    my $try = "require $_;";
    eval $try;
    if ($@) {
	print "$_ is missing!\n";
	print "It must be installed before you can install XML::Directory.\n";
	$ok = 0;
    }
}

exit unless $ok;

# optional stuff
my %opts = (Apache => 'mod_perl interface can not be used',
	    RDF::Notation3 => 'support of RDF/N3 metadata can not be used',
	    XML::SAX => "XML::Directory::SAX class can't be used",
	   );

foreach (keys %opts) {
    my $try = "require $_;";
    eval $try;
    if ($@) {
	print "\n$_ is missing.\n";
	print "XML::Directory can be installed with the following limitation:\n";
	print "=> $opts{$_}!\n";
	print "Install $_ from CPAN to be able to use this functionality.\n\n";
    } else {
	print "$_ found...\n";
    }
}

WriteMakefile(
    'NAME'		=> 'XML::Directory',
    'VERSION_FROM'	=> 'Directory.pm',
    'PREREQ_PM'		=> {}, #{mod_perl => 1.0}
    dist	        => {COMPRESS => 'gzip', SUFFIX => 'tar.gz'},
);
