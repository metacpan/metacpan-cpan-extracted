use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'WebService::Google::Closure',
    AUTHOR              => q{Magnus Erixzon <magnus@erixzon.com>},
    VERSION_FROM        => 'lib/WebService/Google/Closure.pm',
    ABSTRACT_FROM       => 'lib/WebService/Google/Closure.pm',
    LICENSE             => 'perl',
    PL_FILES            => {},
    PREREQ_PM => {
        'Moose' => 0,
        'MooseX::Types' => 0,
        'Perl6::Junction' => 0,
        'Test::More' => 0,
        'Test::Class' => 0,
        'LWP::UserAgent::Mockable' => 0,
        'File::Slurp' => 0,
        'JSON' => 0,
        'Class::MOP' => "1.09",
    },
    EXE_FILES           => [qw(bin/closure-compile)],
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'WebService-Google-Closure-*' },
);
