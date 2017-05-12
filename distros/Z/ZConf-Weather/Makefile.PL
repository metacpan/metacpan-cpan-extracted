use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'ZConf::Weather',
    AUTHOR              => 'Zane C. Bowers <vvelox@vvelox.net>',
    VERSION_FROM        => 'lib/ZConf/Weather.pm',
    ABSTRACT_FROM       => 'lib/ZConf/Weather.pm',
    PL_FILES            => {},
    INST_SCRIPT => 'bin',
    PREREQ_PM => {
	'Test::More' => 0,
 	'Text::NeatTemplate' => 0,
 	'Weather::Underground' => 0,
 	'ZConf' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'ZConf-Weather-*' },
);
