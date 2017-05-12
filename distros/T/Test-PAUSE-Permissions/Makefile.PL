use strict;
use warnings;
use ExtUtils::MakeMaker::CPANfile;

WriteMakefile(
    NAME          => 'Test::PAUSE::Permissions',
    AUTHOR        => 'Kenichi Ishigaki <ishigaki@cpan.org>',
    VERSION_FROM  => 'lib/Test/PAUSE/Permissions.pm',
    ABSTRACT_FROM => 'lib/Test/PAUSE/Permissions.pm',
    LICENSE       => 'perl',
    META_MERGE => {
        resources => {
            repository => 'https://github.com/charsbar/Test-PAUSE-Permissions',
        },
    },
);
