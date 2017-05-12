use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'WWW::TamperData',
    AUTHOR              => 'Eldar Marcussen <merliin@nastynerds.com>',
    VERSION_FROM        => 'lib/WWW/TamperData.pm',
    ABSTRACT_FROM       => 'lib/WWW/TamperData.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
	'XML::Simple' => 0,
	'LWP::UserAgent' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'WWW-TamperData-*' },
    #test                => { TESTS => 't/*' },
);
