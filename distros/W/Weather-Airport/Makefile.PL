use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Weather::Airport',
    AUTHOR              => q{Droogie <droogie@foster.stonedcoder.org>},
    VERSION_FROM        => 'lib/Weather/Airport.pm',
    ABSTRACT_FROM       => 'lib/Weather/Airport.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'LWP::UserAgent' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Weather-Airport-*' },
);

