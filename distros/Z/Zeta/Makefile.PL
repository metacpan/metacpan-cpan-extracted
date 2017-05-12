use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Zeta',
    AUTHOR              => q{Gregory S. Youngblood <zeta@cpan.org>},
    VERSION_FROM        => 'lib/Zeta.pm',
    ABSTRACT_FROM       => 'lib/Zeta.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0.96,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Zeta-*' },
);
