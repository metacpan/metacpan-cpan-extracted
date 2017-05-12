use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Weather::Bug',
    AUTHOR              => 'G. Wade Johnson <wade@anomaly.org>',
    VERSION_FROM        => 'lib/Weather/Bug.pm',
    ABSTRACT_FROM       => 'lib/Weather/Bug.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'Moose'      => 0,
        'Test::Group' => 0,
        'DateTime' => 0,
        'DateTime::Format::Builder' => 0,
        'XML::LibXML' => 0,
        'LWP::Simple' => 0,
        'overload' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Weather-Bug-*' },
);
