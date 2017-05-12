
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME          => 'ZCS::LocalConfig',
    AUTHOR        => 'Phil Pearl <phil@zimbra.com>',
    VERSION_FROM  => 'lib/ZCS/LocalConfig.pm',
    ABSTRACT_FROM => 'lib/ZCS/LocalConfig.pm',
    PREREQ_PM     => {
        'Test::More'  => 0,
        'XML::Parser' => 0,
    },
);
