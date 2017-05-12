use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'vars::global',
    AUTHOR              => 'Flavio Poletti <flavio [at] polettix [dot] it>',
    VERSION_FROM        => 'lib/vars/global.pm',
    ABSTRACT_FROM       => 'lib/vars/global.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'version'    => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'vars-global-*' },
);
