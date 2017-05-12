use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'WWW::Twitpic',
    AUTHOR              => 'Diego Kuperman <diego@freekeylabs.com>',
    VERSION_FROM        => 'lib/WWW/Twitpic.pm',
    ABSTRACT_FROM       => 'lib/WWW/Twitpic.pm',
    EXE_FILES           => [ 'bin/twitpic' ],
    PREREQ_PM => {
        'Test::More'                    => 0,
        'Moose'                         => 0,
        'Moose::Util::TypeConstraints'  => 0,
        'URI'                           => 0,
        'LWP::UserAgent'                => 0,
        'HTTP::Request::Common'         => 0,
        'XML::Simple'                   => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'WWW-Twitpic-*' },
);
