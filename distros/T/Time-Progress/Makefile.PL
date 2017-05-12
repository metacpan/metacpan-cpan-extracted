use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

my $mm_ver = $ExtUtils::MakeMaker::VERSION;
if ($mm_ver =~ /_/) {
    $mm_ver = eval $mm_ver;
    die $@ if $@;
}

my @REQUIRES = (
    'strict'        => 0,
    'warnings'      => 0,
    'Carp'          => 0,
);

my @TEST_REQUIRES = (
    'Test::More'    => 0.88,
);

push(@REQUIRES, @TEST_REQUIRES) if $mm_ver < 6.64;

WriteMakefile(
    NAME            => 'Time::Progress',
    VERSION_FROM    => 'lib/Time/Progress.pm',
    ABSTRACT_FROM   => 'lib/Time/Progress.pm',
    PREREQ_PM       => { @REQUIRES },
    AUTHOR          => 'Vladi Belperchinov-Shabanski <cade@bis.bg>',

    ($mm_ver >= 6.64
        ? (TEST_REQUIRES => { @TEST_REQUIRES })
        : ()
    ),

    ($mm_ver >= 6.48
        ? (MIN_PERL_VERSION => 5.006)
        : ()
    ),

    ($mm_ver >= 6.31
        ? (LICENSE => 'perl')
        : ()
    ),

    ($mm_ver <= 6.45 ? () : (META_MERGE => {
        'meta-spec' => { version => 2 },
        resources => {
            repository  => {
                type => 'git',
                web  => 'https://github.com/cade-vs/perl-time-progress',
                url  => 'https://github.com/cade-vs/perl-time-progress.git',
            },
        },
    })),

);
