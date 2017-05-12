use strict;
use ExtUtils::MakeMaker;
eval 'use ExtUtils::MakeMaker::Coverage';

WriteMakefile(
    NAME                => 'WWW::ColiPoste',
    LICENSE             => 'perl',
    AUTHOR              => 'Sebastien Aperghis-Tramoni <sebastien@aperghis.net>',
    VERSION_FROM        => 'lib/WWW/ColiPoste.pm',
    ABSTRACT_FROM       => 'lib/WWW/ColiPoste.pm',
    EXE_FILES           => [ 'bin/coliposte' ],
    PREREQ_PM => {
        # prereqs
        'Carp'              => 0,
        'File::Slurp'       => 0,
        'LWP::UserAgent'    => 0,
        'HTML::Entities'    => 0,
        'HTML::TreeBuilder' => 0,
        'URI'               => 0,

        # build/test prereqs
        'Test::More'    => 0,
    },
    PL_FILES            => {},
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz' },
);
