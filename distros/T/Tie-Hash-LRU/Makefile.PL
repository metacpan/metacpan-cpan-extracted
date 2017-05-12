
use ExtUtils::MakeMaker;

WriteMakefile(
    dist => {
        PREOP    => 'pod2text lib/Tie/Hash/LRU.pm '.
                      '| tee README >$(DISTVNAME)/README; '.
                    'chmod -R u=rwX,go=rX . ;',
        COMPRESS => 'gzip -9v',
        SUFFIX   => '.gz',
    },

    NAME          => 'Tie::Hash::LRU',
    VERSION_FROM  => 'lib/Tie/Hash/LRU.pm',
    ABSTRACT_FROM => 'lib/Tie/Hash/LRU.pm',
    AUTHOR        => 'Alexandr Gomoliako <zzz@zzz.org.ua>',
    PREREQ_PM     => {
        'Test::More' => 0,
    },
    INC          => '-I.', 
    DEFINE       => '', 
    OBJECT       => '$(O_FILES)', 
);

