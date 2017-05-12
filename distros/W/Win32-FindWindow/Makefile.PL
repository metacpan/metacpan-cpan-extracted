use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Win32::FindWindow',
    AUTHOR              => 'Michiya Honda <pia@cpan.org>',
    VERSION_FROM        => 'lib/Win32/FindWindow.pm',
    ABSTRACT_FROM       => 'lib/Win32/FindWindow.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More'         => 0,
        'Test::Perl::Critic' => 0,
        'Win32::API'         => 0,
        'Class::Accessor'    => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Win32-FindWindow-*' },
);

