use 5.016;
use strict;
use warnings;
use ExtUtils::MakeMaker;

my %WriteMakefileArgs = (
    NAME             => 'XTP',
    AUTHOR           => q{Dylibso <dylibso@cpan.org>},
    VERSION_FROM     => 'lib/XTP.pm',
    ABSTRACT_FROM    => 'lib/XTP.pm',
    LICENSE          => 'perl_5',
    MIN_PERL_VERSION => '5.016',
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '0',
    },
    TEST_REQUIRES => {
        'Test::More' => '0',
    },
    PREREQ_PM => {
        'Carp' => '1.26',
        'Date::Parse' => '2.33',
        'Extism' => 'v0.2.0',
        'JSON::PP' => '2.27105',
        'LWP::Protocol::https' => '6.14',
        'LWP::UserAgent' => '6.77',
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'XTP-*' },
    META_MERGE => {
        'meta-spec' => { version => 2 },
        resources => {
            bugtracker => {
                web => 'https://docs.xtp.dylibso.com/docs/support/'
            },
            homepage   => 'https://www.getxtp.com/',
        },
    },
);

# Compatibility with old versions of ExtUtils::MakeMaker
unless (eval { ExtUtils::MakeMaker->VERSION('6.64'); 1 }) {
    my $test_requires = delete $WriteMakefileArgs{TEST_REQUIRES} || {};
    @{$WriteMakefileArgs{PREREQ_PM}}{keys %$test_requires} = values %$test_requires;
}

unless (eval { ExtUtils::MakeMaker->VERSION('6.55_03'); 1 }) {
    my $build_requires = delete $WriteMakefileArgs{BUILD_REQUIRES} || {};
    @{$WriteMakefileArgs{PREREQ_PM}}{keys %$build_requires} = values %$build_requires;
}

my %min_eumm_version = (
    CONFIGURE_REQUIRES => '6.52',
    MIN_PERL_VERSION   => '6.48',
    LICENSE            => '6.31',
    META_MERGE         => '6.46',
);
for my $parameter ( keys %min_eumm_version ) {
    delete $WriteMakefileArgs{$parameter}
      unless eval {
          ExtUtils::MakeMaker->VERSION( $min_eumm_version{$parameter} );
          1;
      };
}

WriteMakefile(%WriteMakefileArgs);
