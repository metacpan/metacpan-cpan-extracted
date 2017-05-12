use strict;
use warnings;
use ExtUtils::MakeMaker;

my %WriteMakefileArgs = (
    NAME         => 'YAML::AppConfig',
    AUTHOR       => 'Matthew O\'Connor <matthew@canonical.org>',
    ABSTRACT_FROM => 'lib/YAML/AppConfig.pm',
    VERSION_FROM => 'lib/YAML/AppConfig.pm',
    MIN_PERL_VERSION => '5.6.0',
    PREREQ_PM    => {
        get_yamls(),
        'strict'     => 0,
        'warnings'   => 0,
        'Storable'   => 0,
        'Carp'       => 0,
    },
    TEST_REQUIRES => {
        'Test::More' => 0,
    },
    LICENSE => 'perl_5',
    META_MERGE => {
        'meta-spec' => { version => 2 },
        resources => {
            repository => {
                type => 'git',
                url => 'git://github.com/Xaerxess/YAML-AppConfig.git',
                web => 'https://github.com/Xaerxess/YAML-AppConfig',
            },
            bugtracker => {
                web => 'https://rt.cpan.org/Dist/Display.html?Name=YAML-AppConfig',
            },
        },
    },
    test => {
        TESTS => "t/*.t"
    },
);

sub get_yamls {
    my @yamls;
    for my $info (['YAML::Syck' => 0], [YAML => 0.38]) {
        eval "require $info->[0]; 0;";
        push @yamls, @$info unless $@;
    }
    die "YAML >= 0.38 or YAML::Syck >= 0 required.\n" unless @yamls;
    return @yamls;
}

unless (eval { ExtUtils::MakeMaker->VERSION(6.64) }) {
    my $test_requires = delete $WriteMakefileArgs{TEST_REQUIRES};
    if (eval { ExtUtils::MakeMaker->VERSION(6.5503) }) {
        $WriteMakefileArgs{BUILD_REQUIRES} = $test_requires;
    }
}

unless (eval { ExtUtils::MakeMaker->VERSION(6.48) }) {
    delete $WriteMakefileArgs{MIN_PERL_VERSION};
}

unless (eval { ExtUtils::MakeMaker->VERSION(6.46) }) {
    delete $WriteMakefileArgs{META_MERGE};
}

unless (eval { ExtUtils::MakeMaker->VERSION(6.31) }) {
    delete $WriteMakefileArgs{LICENSE};
}

WriteMakefile(%WriteMakefileArgs);
