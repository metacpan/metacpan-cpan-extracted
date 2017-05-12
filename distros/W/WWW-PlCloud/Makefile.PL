use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'WWW::PlCloud',
    AUTHOR           => q{MC Cheung <mc.cheung@aol.com>},
    VERSION_FROM     => 'lib/WWW/PlCloud.pm',
    ABSTRACT_FROM    => 'lib/WWW/PlCloud.pm',
    LICENSE          => 'artistic_2',
    PL_FILES         => {},
    MIN_PERL_VERSION => 5.006,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More' => 0,
    },
    PREREQ_PM => {
      'Moo' => 0,
      'LWP::UserAgent' => 0,
      'JSON' => 0,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'WWW-PlCloud-*' },
);
