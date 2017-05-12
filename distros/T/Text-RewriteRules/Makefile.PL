use strict;
use warnings;
use ExtUtils::MakeMaker;

use 5.010000; # 5.10.0

WriteMakefile(
    NAME                => 'Text::RewriteRules',
    AUTHOR              => 'Alberto Simoes <ambs@cpan.org>',
    VERSION_FROM        => 'lib/Text/RewriteRules.pm',
    ABSTRACT_FROM       => 'lib/Text/RewriteRules.pm',
    EXE_FILES         => [ "scripts/textrr" ],
    PL_FILES            => {},
    PREREQ_PM => {
        'Filter::Simple' => 0.78,
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Text-RewriteRules-*' },
);
