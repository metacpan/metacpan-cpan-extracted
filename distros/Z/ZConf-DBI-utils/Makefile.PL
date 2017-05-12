use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
			  NAME                => 'ZConf::DBI::utils',
			  AUTHOR              => 'Zane C. Bowers <vvelox@vvelox.net>',
			  VERSION_FROM        => 'lib/ZConf/DBI/utils.pm',
			  ABSTRACT_FROM       => 'lib/ZConf/DBI/utils.pm',
			  ($ExtUtils::MakeMaker::VERSION >= 6.3002
			   ? ('LICENSE'=> 'perl')
			   : ()),
			  PL_FILES            => {},
			  INST_SCRIPT => 'bin',
			  PREREQ_PM => {
							'Test::More' => 0,
							'ZConf::DBI'=>0,
							'ZConf'=>0,
							'DBIx::Admin::TableInfo'=>0,
							'DBIx::Admin::CreateTable'=>0,
							},
			  dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
			  clean               => { FILES => 'ZConf-DBI-utils-*' },
			  );
