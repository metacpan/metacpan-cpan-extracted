use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'XML::CommonNS',
    AUTHOR              => 'Chris Prather <perigrin@cpan.org>',
    VERSION_FROM        => 'lib/XML/CommonNS.pm',
    ABSTRACT_FROM       => 'lib/XML/CommonNS.pm',
    PL_FILES            => {},
    PREREQ_PM => {
		'XML::NamespaceFactory'	=> 0,
        'Test::More' => 0,
        'version'    => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'XML-CommonNS-*' },
);
