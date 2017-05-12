require 5.004;
use ExtUtils::MakeMaker;

WriteMakefile(
	NAME		=> 'URI::OpenURL',
	VERSION_FROM	=> 'lib/URI/OpenURL.pm',
	PREREQ_PM	=> {
				'URI' => 1.19,
				'URI::Escape' => 0,
			},
	dist		=> { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
);
