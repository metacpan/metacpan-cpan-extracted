use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Test::HTML::Tidy',
    VERSION_FROM        => 'Tidy.pm',
    ABSTRACT_FROM       => 'Tidy.pm',
    PREREQ_PM => {
        'HTML::Tidy'            => 1.00,
        'Test::More'            => 0,
        'Test::Builder::Tester' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Test-HTML-Tidy-*' },
);
