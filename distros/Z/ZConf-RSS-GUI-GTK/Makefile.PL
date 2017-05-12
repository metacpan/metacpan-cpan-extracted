use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
			  NAME                => 'ZConf::RSS::GUI::GTK',
			  AUTHOR              => 'Zane C. Bowers <vvelox@vvelox.net>',
			  VERSION_FROM        => 'lib/ZConf/RSS/GUI/GTK.pm',
			  ABSTRACT_FROM       => 'lib/ZConf/RSS/GUI/GTK.pm',
			  ($ExtUtils::MakeMaker::VERSION >= 6.3002
			   ? ('LICENSE'=> 'perl')
			   : ()),
			  PL_FILES            => {},
			  PREREQ_PM => {
							'Test::More' => 0,
							'ZConf'=>0,
							'ZConf::GUI'=>0,
							'ZConf::RSS'=>0,
							'ZConf::RSS::GUI'=>0,
							'Gtk2'=>0,
							'Gtk2::SimpleList'=>0,
							},
			  dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
			  clean               => { FILES => 'ZConf-RSS-GUI-GTK-*' },
			  );
