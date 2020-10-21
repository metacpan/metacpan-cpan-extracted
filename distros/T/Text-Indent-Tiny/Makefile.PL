use 5.004;
use strict;
use warnings;
use ExtUtils::MakeMaker;

my %WriteMakefileArgs = (
    NAME             => 'Text::Indent::Tiny',
    AUTHOR           => q{Ildar Shaimordanov <ildar.shaimordanov@gmail.com>},
    VERSION_FROM     => 'lib/Text/Indent/Tiny.pm',
    ABSTRACT_FROM    => 'lib/Text/Indent/Tiny.pm',
    LICENSE          => 'MIT',
    MIN_PERL_VERSION => '5.004',
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '0',
    },
    TEST_REQUIRES => {
        'Test::More' => '0',
    },
    PREREQ_PM => {
        'Carp' => '0',
    },
    META_MERGE => {
        resources => {
            license    => 'https://github.com/ildar-shaimordanov/indent-pm/blob/master/LICENSE',
            homepage   => 'https://github.com/ildar-shaimordanov/indent-pm',
            bugtracker => 'https://github.com/ildar-shaimordanov/indent-pm/issues',
            repository => 'https://github.com/ildar-shaimordanov/indent-pm.git',
        },
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Text-Indent-Tiny-*' },
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
