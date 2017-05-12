use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Text::FixedWidth',
    AUTHOR              => 'Jay Hannah <jay.hannah@iinteractive.com>',
    VERSION_FROM        => 'lib/Text/FixedWidth.pm',
    ABSTRACT_FROM       => 'lib/Text/FixedWidth.pm',
    PL_FILES            => {},
    PREREQ_PM => {
    },
    TEST_REQUIRES => {
        'Test::More' => 0,
        'Test::Warn' => 0,
    },
    META_MERGE => {
         resources => {
             repository  =>  'https://github.com/jhannah/text-fixedwidth',
         },
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Text-FixedWidth-*' },
);
