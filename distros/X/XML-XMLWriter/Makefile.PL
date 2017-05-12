use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
	NAME	=> 'XML::XMLWriter',
	VERSION_FROM => 'XMLWriter.pm', # finds $VERSION
	PREREQ_PM => {
		'XML::ParseDTD' => 0.1.3,
		'Carp' => 1.01,
	        'Encode' => 1.98,
	},
);
