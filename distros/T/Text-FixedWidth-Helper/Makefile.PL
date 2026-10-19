use strict;
use warnings;
use ExtUtils::MakeMaker;

my $mm_ver = ExtUtils::MakeMaker->VERSION;

my %WriteMakefileArgs = (
    NAME         => 'Text::FixedWidth::Helper',
    VERSION_FROM => 'lib/Text/FixedWidth/Helper.pm',
    AUTHOR       => 'James E Keenan (jkeenan@pobox.com)',
    ABSTRACT     => 'Create or verify samples of fixed-width data',
    INSTALLDIRS  => ($] < 5.011 ? 'perl' : 'site'),
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },


    PREREQ_PM    => {
                     'Carp' => 0,
                     'Cwd' => 0,
                     'IO::File' => 0,
                     'Scalar::Util' => 0,
                    },
    LICENSE     => 'perl',
    ( $mm_ver < 6.63_03 ? 'BUILD_REQUIRES' : 'TEST_REQUIRES' ) => {
        "Test::Simple" => 0.44,
        'IO::CaptureOutput' => 0, # for testing only
    },
    ($mm_ver < 6.46 ? () : (META_MERGE => {
        'meta-spec' => { version => 2 },
        dynamic_config => 1,
        resources => {
            homepage    => 'http://thenceforward.net/perl/modules/Text-FixedWidth-Helper/',
            repository  => {
                url         => 'https://github.com/jkeenan/Text-FixedWidth-Helper.git',
                web         => 'https://github.com/jkeenan/Text-FixedWidth-Helper',
                type        => 'git',
            },
            bugtracker => {
                web         => 'https://github.com/jkeenan/Text-FixedWidth-Helper/issues',
            },
        },
    })),
);

WriteMakefile(%WriteMakefileArgs);

