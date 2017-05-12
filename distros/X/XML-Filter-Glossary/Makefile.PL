use ExtUtils::MakeMaker;

WriteMakefile(
	      'NAME'	=> 'XML::Filter::Glossary',
	      ($[ >= 5.005) ?
	      (AUTHOR   => 'Aaron Straup Cope (cpan@aaronland.net)',
	       ABSTRACT => '') : (),
	      'VERSION_FROM' => 'lib/XML/Filter/Glossary.pm',
	      'PREREQ_PM'    => {
				 XML::SAX           => "0.11",
				 XML::SAX::Machines => "0.38",

				 # For test.pl
				 XML::SAX::Writer   => "0.44",
				},
	      dist	        => {COMPRESS => 'gzip', SUFFIX => 'tar.gz'},
);
