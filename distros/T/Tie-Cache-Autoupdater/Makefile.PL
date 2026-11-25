use strict;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME	    => 'Tie::Cache::Autoupdater',
    VERSION_FROM=> 'Autoupdater.pm',
    AUTHOR      => 'Anton Morozov <antonfin@cpan.org>',
    ABSTRACT_FROM=> 'Autoupdater.pm',
    LICENSE     => 'perl_5',
    MIN_PERL_VERSION => '5.008',
    PREREQ_PM   => { Storable => 0 },
    test        => { TESTS => 't/*.t' },
);

1;

