use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Text::ParseAHD',
    AUTHOR              => 'Crabtree, Nathan <crabtree@cpan.org>',
    VERSION_FROM        => 'lib/Text/ParseAHD.pm',
    ABSTRACT_FROM       => 'lib/Text/ParseAHD.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'version'    => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Text-ParseAHD-*' },
);
