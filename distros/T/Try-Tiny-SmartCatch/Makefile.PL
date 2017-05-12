use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Try::Tiny::SmartCatch',
    AUTHOR              => q{Marcin Sztolcman <marcin@urzenia.net>},
    VERSION_FROM        => 'lib/Try/Tiny/SmartCatch.pm',
    ABSTRACT_FROM       => 'lib/Try/Tiny/SmartCatch.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'MIT')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Try-Tiny-SmartCatch-*' },
    META_MERGE        => {
        resources => {
            repository  =>  'https://github.com/mysz/try-tiny-smartcatch',
        },
    },
);
