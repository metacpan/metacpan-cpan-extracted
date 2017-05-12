use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    (MM->can('signature_target') ? (SIGN => 1) : ()),
    NAME                => 'Win32::Status',
    AUTHOR              => q{Rohan McGovern <rohan@mcgovern.id.au>},
    VERSION_FROM        => 'lib/Win32/Status.pm',
    ABSTRACT_FROM       => 'lib/Win32/Status.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'lgpl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More'    => 0,
        'Readonly'      => 0,
        'Carp'          => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Win32-Status-*' },
);
