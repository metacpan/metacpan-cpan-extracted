use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Types',
    AUTHOR              => 'Eugene Grigoriev <eugene.grigoriev@gmail.com>',
    VERSION_FROM        => 'lib/Types.pm',
    ABSTRACT_FROM       => 'lib/Types.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More'   => 0,
        'Data::Dumper' => 0,
        'Carp'         => 0
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Types-*' },
);
