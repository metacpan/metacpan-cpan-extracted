use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Tie::Hash::Identity',
    AUTHOR              => q{Cindy Wang (CindyLinz)},
    VERSION_FROM        => 'lib/Tie/Hash/Identity.pm',
    ABSTRACT_FROM       => 'lib/Tie/Hash/Identity.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Tie-Hash-Identity-*' },
);
