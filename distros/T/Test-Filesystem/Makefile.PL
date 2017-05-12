use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Test::Filesystem',
    AUTHOR              => q{Erik Wasser <fuzz@namm.de>},
    VERSION_FROM        => 'lib/Test/Filesystem.pm',
    ABSTRACT_FROM       => 'lib/Test/Filesystem.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'Test::Deep' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Test-Filesystem-*' },
);
