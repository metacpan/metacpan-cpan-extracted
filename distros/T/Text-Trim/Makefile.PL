use strict;
use warnings;
use ExtUtils::MakeMaker;

my %WriteMakefileArgs   = (
    NAME                => 'Text::Trim',
    AUTHOR              => [q{Matt Lawrence <mattlaw@cpan.org>},
                            q{Ryan Thompson <rjt@cpan.org>}],
    VERSION_FROM        => 'lib/Text/Trim.pm',
    ABSTRACT_FROM       => 'lib/Text/Trim.pm',
    LICENSE             => 'perl_5',
    MIN_PERL_VERSION    => '5.006',

    CONFIGURE_REQUIRES  => {
        'ExtUtils::MakeMaker'   => '0',
    },
    TEST_REQUIRES       => {
        'Test::More'            => '0',
        'File::Spec::Functions' => '0',
    },
    PREREQ_PM           => { },

    META_MERGE          => {
        resources => {
            'meta-spec' => { version => 2 },
            repository  => 'https://github.com/rjt-pl/Text-Trim.git',
            bugtracker  => 'https://github.com/rjt-pl/Text-Trim/issues',
        },
    },

    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES    => 'Text-Trim-*' },
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
