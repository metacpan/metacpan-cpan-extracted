use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'WebService::Audioscrobbler',
    AUTHOR              => 'Nilson Santos Figueiredo Júnior <nilsonsfj@cpan.org>',
    VERSION_FROM        => 'lib/WebService/Audioscrobbler.pm',
    ABSTRACT_FROM       => 'lib/WebService/Audioscrobbler.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Cache::FileCache'      => 0,
        'Carp'                  => 0,
        'CLASS'                 => 0,
        'Class::Accessor::Fast' => 0,
        'Class::Data::Accessor' => 0,
        'LWP::Simple'           => 0,
        'Test::More'            => 0,
        'UNIVERSAL::require'    => 0,
        'URI'                   => 0,
        'URI::Escape'           => 0,
        'XML::Simple'           => 0,
	'NEXT'                  => 0
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'WebService-Audioscrobbler-*' },
);
