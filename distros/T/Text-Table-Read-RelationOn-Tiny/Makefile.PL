use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

use File::Spec::Functions;
use autodie;

my $PM_File = catfile(qw(lib Text Table Read RelationOn Tiny.pm));

open(my $h, '<', $PM_File);
my $Version;
foreach my $line (<$h>) {
  if ($line =~ /\bour\s+\$VERSION\s+.*?["'](v[^"']+)["']/) {
    $Version = $1;
    last;
  }
}
close($h);
die("VERSION not found in $PM_File") if !$Version;


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
    META_MERGE => {
        "meta-spec" => { version => 2 },
        dynamic_config => 0,
        resources => {
            repository => {
                type => 'git',
                url  => 'https://github.com/AAHAZRED/perl-Text-Table-Read-RelationOn-Tiny.git',
                web  => 'https://github.com/AAHAZRED/perl-Text-Table-Read-RelationOn-Tiny',
            },
            bugtracker => {
                web => 'https://github.com/AAHAZRED/perl-Text-Table-Read-RelationOn-Tiny/issues'
            },

        },
                   provides => { 'Text::Table::Read::RelationOn::Tiny' => {file => $PM_File,
                                                                           version => $Version
                                                               },
                    },
        no_index => {package => 'Text::Table::Read::RelationOn::Tiny::_Relation_Matrix'}
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
