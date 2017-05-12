use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Text::Lossy',
    AUTHOR              => q{Ben Deutsch <ben@bendeutsch.de>},
    VERSION_FROM        => 'lib/Text/Lossy.pm',
    ABSTRACT_FROM       => 'lib/Text/Lossy.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    EXE_FILES           => ['script/text-lossy'],
    PREREQ_PM => {
        'Test::More' => 0,
        'Test::Exception' => 0,
    },
    META_MERGE => {
        resources => {
            repository => 'https://github.com/bendeutsch/text-lossy',
        },
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Text-Lossy-*' },
);
