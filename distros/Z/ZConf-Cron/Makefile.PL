use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
	NAME                => 'ZConf::Cron',
	AUTHOR              => 'Zane C. Bowers <vvelox@vvelox.net>',
	VERSION_FROM        => 'lib/ZConf/Cron.pm',
	ABSTRACT_FROM       => 'lib/ZConf/Cron.pm',
	PL_FILES            => {},
	INST_SCRIPT => 'bin',
	PREREQ_PM => {
		'Test::More' => 0,
		'ZConf' => 0,
		'ZConf::GUI'=>0,
		'DateTime::Event::Cron'=>0,
		'DateTime::Duration'=>0,
		'DateTime::Format::Strptime'=>0,
		'Error::Helper'=>0,
		'Getopt::Std'=>0,
		'Term::CallEditor'=>0,
	},
	dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
	clean               => { FILES => 'ZConf-Cron-*' },
	);
