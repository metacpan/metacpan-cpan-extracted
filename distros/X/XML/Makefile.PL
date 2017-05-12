use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME         => 'XML::DB::DatabaseManager',
    VERSION_FROM => 'lib/XML/DB/DatabaseManager.pm', # finds $VERSION
    AUTHOR       => 'Graham Seaman (graham@opencollector.org)',
    ABSTRACT     => 'A perl implementation of most of the XML:DB specification',
    PREREQ_PM	=> {	'XML::LibXML' => 1.53,
    			'XML::LibXML::Common' => 0.12, 
			'XML::LibXSLT' => 1.49,
    			'RPC::XML' => 0, 
    			'XML::XUpdate::LibXML' =>0.3,
			'Term::ReadLine' => 0,
			'MIME::Base64' => 0,
			'Getopt::Long' => 0,
			'XML::Normalize::LibXML' => 0,
			},
);

# stop make test running t/* directly
sub MY::test{
	package MY;
	my $old = shift->SUPER::test(@_);
	$old =~ s/\n[^\n]+TEST_FILES\)//;
	$old;
}

