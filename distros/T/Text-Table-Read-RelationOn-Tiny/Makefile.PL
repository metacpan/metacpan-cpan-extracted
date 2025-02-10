use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

my %WriteMakefileArgs = (
    NAME             => 'Text::Table::Read::RelationOn::Tiny',
    AUTHOR           => q{Abdul al Hazred <451@gmx.eu>},
    VERSION_FROM     => 'lib/Text/Table/Read/RelationOn/Tiny.pm',
    ABSTRACT_FROM    => 'lib/Text/Table/Read/RelationOn/Tiny.pm',
    LICENSE          => 'artistic_2',
    MIN_PERL_VERSION => '5.010001',
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '0'
    },
    TEST_REQUIRES => {
        'Test::More' => '0',
        'strict'   => '0',
        'warnings' => '0',
    },
    PREREQ_PM => {
        'version'  => '0.77',
        'autodie'  => '0',
        'Carp'     => '0',
        'strict'   => '0',
        'warnings' => '0',
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', DIST_CP => 'cp',
               PREOP => 'perl tools/pm_filter_simple.pl $(DISTVNAME)'},
    clean => { FILES => 'Text-Table-Read-RelationOn-Tiny-*' },
);

if ($ENV{AAHAZRED_PERL_DEVEL}) {
  $WriteMakefileArgs{PM_FILTER} = 'perl tools/pm_filter_simple.pl';
}

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
