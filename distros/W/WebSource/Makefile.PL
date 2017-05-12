use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'WebSource',
    'VERSION_FROM'	=> 'WebSource.pm', # finds $VERSION
    'PREREQ_PM'		=> {
		LWP::UserAgent		=> 5.0,
		XML::LibXML			=> 1.0,
		XML::LibXSLT		=> 1.0,
		Getopt::Mixed		=> 0,
		Date::Language		=> 1.0,
		HTML::TreeBuilder 	=> 3.0,
		String::Approx 		=> 3.0,
}, # e.g., Module::Name => 1.1
    'EXE_FILES'         => [ "bin/ws-query", "bin/ws-getform",
                             "bin/ws-xsl", "bin/ws-xpath", "bin/ws-tidy" ],
    'INSTALLSCRIPT'     => '/usr/local/bin',
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'WebSource.pm', # retrieve abstract from module
       AUTHOR     => 'Benjamin Habegger <b@habegger.fr>') : ()),
);
