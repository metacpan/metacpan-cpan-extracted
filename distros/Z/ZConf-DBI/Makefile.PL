use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
			  NAME                => 'ZConf::DBI',
			  AUTHOR              => 'Zane C. Bowers <vvelox@vvelox.net>',
			  VERSION_FROM        => 'lib/ZConf/DBI.pm',
			  ABSTRACT_FROM       => 'lib/ZConf/DBI.pm',
			  ($ExtUtils::MakeMaker::VERSION >= 6.3002
			   ? ('LICENSE'=> 'perl')
			   : ()),
			  PL_FILES            => {},
			  INST_SCRIPT => 'bin',
			  PREREQ_PM => {
							'Test::More' => 0,
							'ZConf' => 0,
							'DBI' => 0,
							'DBI::Shell' => 0,
							'Getopt::Std' => 0,
							'Term::ReadKey'=>0,
							'Error::Helper'=>0,
							},
			  dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
			  clean               => { FILES => 'ZConf-DBI-*' },
			  );
