use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Var::Pairs',
    AUTHOR              => 'Damian Conway <DCONWAY@CPAN.org>',
    VERSION_FROM        => 'lib/Var/Pairs.pm',
    ABSTRACT_FROM       => 'lib/Var/Pairs.pm',
    PL_FILES            => {},
    LICENSE             => 'perl',
    PREREQ_PM => {
        'Test::More'      => 0,
        'Devel::Callsite' => 0.06,
($] < 5.022 ? ('Data::Alias' => 1.16) : ()),
        'PadWalker'       => 1.93,
        'experimental'    => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Var-Pairs-*' },
);
