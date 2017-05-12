use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'WWW::VieDeMerde',
    AUTHOR              => 'Olivier Schwander <olivier.schwander@ens-lyon.org>',
    LICENSE             => 'perl',
    VERSION_FROM        => 'lib/WWW/VieDeMerde.pm',
    ABSTRACT_FROM       => 'lib/WWW/VieDeMerde.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
		'LWP::UserAgent' => 2,
		'XML::Twig' => 3,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'WWW-VieDeMerde-*' },
);

