use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Win32::Env',
    AUTHOR              => 'Oleg "Rowaa[SR13]" V. Volkov <ROWAA@cpan.org>',
    VERSION_FROM        => 'lib/Win32/Env.pm',
    ABSTRACT_FROM       => 'lib/Win32/Env.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
	'Win32::API' => 0,
	'Win32::TieRegistry' => 0
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Win32-Env-*' },
);
