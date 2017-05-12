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
    'Pod::Coverage' => 0,
    'Test::Builder' => 0,
);

my @TEST_REQUIRES = (
    'Test::Builder::Tester' => 0,
    'Test::More'            => 0,
    'lib'                   => 0,
);

push(@REQUIRES, @TEST_REQUIRES) if $mm_ver < 6.64;

WriteMakefile(
    NAME                => 'Test::Pod::Coverage',
    VERSION_FROM        => 'lib/Test/Pod/Coverage.pm',
    ABSTRACT            => "Check for pod coverage in your distribution",
    PREREQ_PM           => { @REQUIRES },

    ($mm_ver >= 6.64
        ? (TEST_REQUIRES => { @TEST_REQUIRES })
        : ()
    ),

    ($mm_ver >= 6.48
        ? (MIN_PERL_VERSION => 5.006)
        : ()
    ),

    ($mm_ver >= 6.31 ? (LICENSE => 'artistic_2') : ()),

    ($mm_ver <= 6.45 ? () : (META_MERGE => {
        'meta-spec' => { version => 2 },
        resources => {
            repository  => {
                type => 'git',
                web  => 'https://github.com/neilbowers/Test-Pod-Coverage',
                url  => 'git://github.com/neilbowers/Test-Pod-Coverage.git',
            },
        },
    })),

    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Test-Pod-Coverage-*' },
);
