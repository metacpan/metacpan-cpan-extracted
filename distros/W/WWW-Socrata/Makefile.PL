use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'WWW::Socrata',
    AUTHOR              => q{Benjamin Marcus <ben@fourthfloorequipment.com>},
    VERSION_FROM        => 'lib/WWW/Socrata.pm',
    ABSTRACT_FROM       => 'lib/WWW/Socrata.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'WWW::Curl::Easy' => 0.01,
	'JSON' => 2.53,
	'URI::Escape' => 3.31
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'WWW-Socrata-*' },
);
