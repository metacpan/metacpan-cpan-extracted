use CPAN::MakeMaker;
WriteMakefile(
	      'NAME'	=> 'XML::SAXDriver::vCard',
	      ($[ >= 5.005) ?
	      (AUTHOR   => 'Aaron Straup Cope (cpan@aaronland.net)',
	       ABSTRACT => 'Simple OOP-ish interface to the Google API') : (),
	      'VERSION_FROM' => 'lib/XML/SAXDriver/vCard.pm',
	      'PREREQ_PM'    => {
				 XML::SAX      => '0.11',
				 FileHandle    => '0',
				 LWP::Simple   => '0',
				 Test::More    => '0',
				},
	      dist	        => {COMPRESS => 'gzip', SUFFIX => 'tar.gz'},
);
