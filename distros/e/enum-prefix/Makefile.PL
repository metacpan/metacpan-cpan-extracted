use strict;
use warnings;
use ExtUtils::MakeMaker::CPANfile;

WriteMakefile(
    NAME          => 'enum::prefix',
    AUTHOR        => 'electricface <electricface@qq.com>',
    VERSION_FROM  => 'lib/enum/prefix.pm',
    ABSTRACT_FROM => 'lib/enum/prefix.pm',
    LICENSE       => 'perl',
    META_MERGE => {
        resources => {
            repository => 'https://gitcafe.com/electricface/enum-prefix',
        },
    },
);
