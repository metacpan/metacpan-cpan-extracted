use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
			  NAME                => 'ZConf::Cron::GUI::GTK',
			  AUTHOR              => 'Zane C. Bowers <vvelox@vvelox.net>',
			  VERSION_FROM        => 'lib/ZConf/Cron/GUI/GTK.pm',
			  ABSTRACT_FROM       => 'lib/ZConf/Cron/GUI/GTK.pm',
			  ($ExtUtils::MakeMaker::VERSION >= 6.3002
			   ? ('LICENSE'=> 'perl')
			   : ()),
			  PL_FILES            => {},
			  INST_SCRIPT => 'bin',
			  PREREQ_PM => {
							'Test::More' => 0,
							'Gtk2'=>0,
							'ZConf::Cron'=>0,
							'ZConf'=>0,
							'ZConf::GUI'=>0,
							'String::ShellQuote'=>0,
							},
			  dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
			  clean               => { FILES => 'ZConf-Cron-GUI-GTK-*' },
			  );
