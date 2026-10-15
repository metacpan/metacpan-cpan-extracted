use ExtUtils::MakeMaker;
use strict;
use warnings;

my $mm_ver = ExtUtils::MakeMaker->VERSION;

my %WriteMakefileArgs = (
    NAME         => 'Tie::Filehandle::Preempt::Stdin',
    VERSION_FROM => 'lib/Tie/Filehandle/Preempt/Stdin.pm',
    AUTHOR       => 'James E Keenan (jkeenan@pobox.com)',
    ABSTRACT     => 'Preempt STDIN during testing.',
    INSTALLDIRS         => ($] < 5.011 ? 'perl' : 'site'),
    MIN_PERL_VERSION    => '5.8.0',
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    ( $mm_ver < 6.63_03 ? 'BUILD_REQUIRES' : 'TEST_REQUIRES' ) => {
        "Test::Simple" => 0.44,
    },
    ($mm_ver < 6.46 ? () : (META_MERGE => {
        'meta-spec' => { version => 2 },
        dynamic_config => 1,
        resources => {
            homepage    => 'http://thenceforward.net/perl/modules/Tie-Filehandle-Preempt-Stdin/',
            repository  => {
                url         => 'https://github.com/jkeenan/Tie-Filehandle-Preempt-Stdin.git',
                web         => 'https://github.com/jkeenan/Tie-Filehandle-Preempt-Stdin',
                type        => 'git',
            },
            bugtracker => {
                web         => 'https://github.com/jkeenan/Tie-Filehandle-Preempt-Stdin/issues',
            },
        },
    })),
);

WriteMakefile(%WriteMakefileArgs);
