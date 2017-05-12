use strict;
use warnings;
use vars qw(%ENV);
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Text::DeDuper',
    AUTHOR              => 'Jan Pomikalek <xpomikal@fi.muni.cz>',
    VERSION_FROM        => 'lib/Text/DeDuper.pm',
    ABSTRACT_FROM       => 'lib/Text/DeDuper.pm',
    PREREQ_PM => {
        'Encode'      => 2.12,
        'Digest::MD4' => 1.5,
    },
    dist   => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
);
