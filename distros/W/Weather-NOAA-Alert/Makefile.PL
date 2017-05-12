use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Weather::NOAA::Alert',
    AUTHOR              => q{Michael Stovenour <michael@stovenour.net>},
    VERSION_FROM        => 'lib/Weather/NOAA/Alert.pm',
    ABSTRACT_FROM       => 'lib/Weather/NOAA/Alert.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'LWP::Simple' => 0,
        'XML::Twig' => 0,
        'Data::Dumper' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Weather-NOAA-Alert-*' },
);
