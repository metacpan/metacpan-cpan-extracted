use warnings;
use strict;

use ExtUtils::MakeMaker;
# The wiringPi presence + version guard is the family-canonical check in
# RPi::Const::BuildCheck (pulled in via CONFIGURE_REQUIRES below). It honours
# RPI_DIST_RELEASE and exits 0 with a message before WriteMakefile when
# wiringPi is missing or too old, so CPAN testers report NA, not FAIL.
eval {
    require RPi::Const::BuildCheck;
    RPi::Const::BuildCheck::wiringpi_build_check();
    1;
} or do {
    # No RPi::Const::BuildCheck (a bare `perl Makefile.PL` with no CPAN client
    # to honour CONFIGURE_REQUIRES). Stay NA-safe: exit 0 unless releasing.
    print "RPi::Const (the build-check dependency) is not installed; install " .
          "it first, or set RPI_DIST_RELEASE to skip the wiringPi check.\n";
    exit 0 if ! $ENV{RPI_DIST_RELEASE};
};

WriteMakefile(
    NAME              => 'WiringPi::API',
    VERSION_FROM      => 'lib/WiringPi/API.pm',
    ($] >= 5.005 ?
      (ABSTRACT_FROM  => 'lib/WiringPi/API.pm',
       AUTHOR         => 'Steve Bertrand <steveb@cpan.org>') : ()),
    LIBS              => ['-lwiringPi -lwiringPiDev -lrt'],
    DEFINE            => '',
    INC               => '-I.',
    META_MERGE => {
        'meta-spec' => { version => 2 },
        resources   => {
            bugtracker => {
                web => 'https://github.com/stevieb9/wiringpi-api/issues',
            },
            repository => {
                type => 'git',
                url => 'https://github.com/stevieb9/wiringpi-api.git',
                web => 'https://github.com/stevieb9/wiringpi-api',
            },
        },
    },
    MIN_PERL_VERSION  => 5.006,
    LICENSE           => 'perl_5',
    CONFIGURE_REQUIRES => {
        'RPi::Const' => '1.07',
    },
    PREREQ_PM         => {
        'RPi::Const' => '1.07',
    },
);
