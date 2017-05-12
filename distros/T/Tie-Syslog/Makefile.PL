use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Tie::Syslog',
    AUTHOR              => q{Giacomo Montagner <kromg@entirelyunlike.net>},
    VERSION_FROM        => 'lib/Tie/Syslog.pm',
    ABSTRACT_FROM       => 'lib/Tie/Syslog.pod',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' =>  0,
        'Carp'       =>  0,
        'Sys::Syslog' => 0.11,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Tie-Syslog-*' },
);
