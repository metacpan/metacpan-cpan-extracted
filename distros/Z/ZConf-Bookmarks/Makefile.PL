use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'ZConf::Bookmarks',
    AUTHOR              => 'Zane C. Bowers <vvelox@vvelox.net>',
    VERSION_FROM        => 'lib/ZConf/Bookmarks.pm',
    ABSTRACT_FROM       => 'lib/ZConf/Bookmarks.pm',
    PL_FILES            => {},
    PREREQ_PM => {
				  'Test::More' => 0,
				  'ZConf' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'ZConf-Bookmarks-*' },
);
