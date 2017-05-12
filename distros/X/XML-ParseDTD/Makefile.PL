use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
	NAME	=> 'XML::ParseDTD',
	VERSION_FROM => 'ParseDTD.pm', # finds $VERSION
	PREREQ_PM => {
		'LWP::UserAgent' => 2.003,
		'Cache::Cache' => 1.02,
	},
);
