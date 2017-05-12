use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
			  NAME                => 'ZConf::Runner::GUI::GTK',
			  AUTHOR              => 'Zane C. Bowers <vvelox@vvelox.net>',
			  VERSION_FROM        => 'lib/ZConf/Runner/GUI/GTK.pm',
			  ABSTRACT_FROM       => 'lib/ZConf/Runner/GUI/GTK.pm',
			  PL_FILES            => {},
			  PREREQ_PM => {
							'Test::More'=>0,
							'ZConf'=>0,
							'ZConf::Runner'=>0,
							'Gtk2'=>0,
							'Gtk2::SimpleList'=>0,
							'File::MimeInfo::Magic'=>0,
							'File::MimeInfo::Applications'=>0
							},
			  dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
			  clean               => { FILES => 'ZConf-Runner-GUI-GTK-*' },
			  );
