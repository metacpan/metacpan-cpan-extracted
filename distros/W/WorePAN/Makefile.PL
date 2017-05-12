use strict;
use warnings;
use ExtUtils::MakeMaker::CPANfile;

WriteMakefile(
    NAME          => 'WorePAN',
    AUTHOR        => 'Kenichi Ishigaki <ishigaki@cpan.org>',
    VERSION_FROM  => 'lib/WorePAN.pm',
    ABSTRACT_FROM => 'lib/WorePAN.pm',
    LICENSE       => 'perl',
    EXE_FILES => ['bin/worepan'],
    MIN_PERL_VERSION => '5.008001',
    META_MERGE => {
        resources => {
            repository => 'https://github.com/charsbar/worepan',
        },
    },
);
