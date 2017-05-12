use 5.008;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => "pluskeys",
    AUTHOR              => q{Tom Christiansen <tchrist@perl.com>},
    VERSION_FROM        => "lib/pluskeys.pm",
    ABSTRACT_FROM       => "lib/pluskeys.pm",
    LICENSE             => "perl_5",
    PL_FILES            => {},
    MIN_PERL_VERSION    => 5.008,
    CONFIGURE_REQUIRES  => {
        "ExtUtils::MakeMaker" => 6.5503,
    },
    BUILD_REQUIRES => {
        "Test::More"    => 0,
        "Test::Exception" => 0,
        "Test::Pod::Coverage" => 0,
        "Test::Pod" => 0,
        "Test::CheckManifest" => 0,
    },
    PREREQ_PM => {
        constant        => 0,
        Carp            => 0,
    },
    dist  => { COMPRESS => "gzip -9f", 
               SUFFIX   => "gz", 
             },
    clean => { FILES    => "pluskeys-*" },
);
