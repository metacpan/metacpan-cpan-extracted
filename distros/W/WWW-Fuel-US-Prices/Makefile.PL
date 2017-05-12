use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'WWW::Fuel::US::Prices',
    AUTHOR              => 'Ashish Kasturia <ashoooo@hotmail.com>',
    VERSION_FROM        => 'lib/WWW/Fuel/US/Prices.pm',
    ABSTRACT_FROM       => 'lib/WWW/Fuel/US/Prices.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'version'    => 0,
	'HTTP::Lite' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'WWW-Fuel-US-Prices-*' },
);
