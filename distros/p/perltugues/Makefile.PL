use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'perltugues',
    AUTHOR              => 'Fernando Correa de Oliveira <fco@cpan.org>',
    VERSION_FROM        => 'lib/perltugues.pm',
    ABSTRACT_FROM       => 'lib/perltugues.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
	'Filter::Simple' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'perltugues-*' },
);
