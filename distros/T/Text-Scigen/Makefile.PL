use 5.008001;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Text::Scigen',
    VERSION_FROM      => 'lib/Text/Scigen.pm', # finds $VERSION
    PREREQ_PM         => {
		'Text::Autoformat' => 0.0,
	}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Text/Scigen.pm', # retrieve abstract from module
       AUTHOR         => 'Tim Brody <tdb2@>') : ()),
	dist              => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
);
