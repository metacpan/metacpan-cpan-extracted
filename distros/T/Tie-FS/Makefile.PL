use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Tie::FS',
    AUTHOR              => q{Deven T. Corzine <deven@ties.org>},
    VERSION_FROM        => 'lib/Tie/FS.pm',
    ABSTRACT_FROM       => 'lib/Tie/FS.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Tie-FS-*' },
);
