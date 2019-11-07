use 5.020;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

my %WriteMakefileArgs = (
    NAME             => 'ojo::ServeDir',
    AUTHOR           => q{Mirko Westermeier <mirko@westermeier.de>},
    VERSION_FROM     => 'lib/ojo/ServeDir.pm',
    ABSTRACT_FROM    => 'lib/ojo/ServeDir.pm',
    LICENSE          => 'mit',
    MIN_PERL_VERSION => '5.020',
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '0',
    },
    PREREQ_PM => {
        Mojolicious => '8.0',
    },
    META_MERGE => {resources => {
        bugtracker => 'https://github.com/memowe/Mojo-ServeDir/issues',
        repository => 'https://github.com/memowe/Mojo-ServeDir',
    }},
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'ojo-ServeDir-*' },
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

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
    unless eval { ExtUtils::MakeMaker->VERSION('6.52'); 1 };
delete $WriteMakefileArgs{MIN_PERL_VERSION}
    unless eval { ExtUtils::MakeMaker->VERSION('6.48'); 1 };
delete $WriteMakefileArgs{LICENSE}
    unless eval { ExtUtils::MakeMaker->VERSION('6.31'); 1 };

WriteMakefile(%WriteMakefileArgs);
