use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'ZConf::BGSet::GUI::GTK',
    AUTHOR              => 'Zane C. Bowers <vvelox@vvelox.net>',
    VERSION_FROM        => 'lib/ZConf/BGSet/GUI/GTK.pm',
    ABSTRACT_FROM       => 'lib/ZConf/BGSet/GUI/GTK.pm',
    PL_FILES            => {},
	INST_SCRIPT => 'bin',
    PREREQ_PM => {
				  'Test::More'=>0,
				  'Gtk2'=>0,
				  'Gtk2::Ex::Simple::List'=>0,
				  'ZConf::BGSet'=>0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'ZConf-BGSet-GUI-GTK-*' },
);
