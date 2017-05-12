use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Unicode::Escape',
    AUTHOR              => 'Hitoshi Amano <seijro@gmail.com>',
    VERSION_FROM        => 'lib/Unicode/Escape.pm',
    ABSTRACT_FROM       => 'lib/Unicode/Escape.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'Encode' => 0,
        'Unicode::String' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Unicode-Escape-*' },
);
