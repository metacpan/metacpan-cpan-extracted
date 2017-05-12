use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Text::Cloze',
    AUTHOR              => 'David Romano <unobe@cpan.org>',
    VERSION_FROM        => 'lib/Text/Cloze.pm',
    ABSTRACT_FROM       => 'lib/Text/Cloze.pm',
    LICENSE             => 'perl',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'Test::use::ok' => 0,
        'List::Util' => 0,
        'version'    => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Text-Cloze-*' },
);
