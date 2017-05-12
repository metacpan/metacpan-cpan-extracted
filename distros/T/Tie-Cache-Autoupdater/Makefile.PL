use strict;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME	    => 'Tie::Cache::Autoupdater',
    VERSION_FROM=> 'Autoupdater.pm',
    AUTHOR      => 'Anton Morozov <antonfin@cpan.org>',
    ABSTRACT    => 'Cache that automatically updated',
    LICENSE     => 'artistic_2',
    PREREQ_PM   => { Storable => 0 },
    test        => { TESTS => 't/*.t' },
);

1;

