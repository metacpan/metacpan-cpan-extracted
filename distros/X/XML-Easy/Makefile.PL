use ExtUtils::MakeMaker;
use strict;
use warnings;

# TK: Test here for C compiler

my $mm_ver = ExtUtils::MakeMaker->VERSION;

my %WriteMakefileArgs = (
    NAME                => 'XML::Easy',
    VERSION_FROM        => 'lib/XML/Easy.pm',
    AUTHOR              => 'James E Keenan (jkeenan@cpan.org)',
    ABSTRACT            => 'XML processing with a clean interface',
    INSTALLDIRS         => ($] < 5.011 ? 'perl' : 'site'),
    MIN_PERL_VERSION    => '5.10.1',
    test                => {
        TESTS => ($ENV{PERL_AUTHOR_TESTING}
            ? "t/*.t xt/*.t"
            : "t/*.t")
    },
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    PREREQ_PM           => {
        "Encode" => 0,
        "Internals" => 0,
        "Params::Classify" => 0,
        "parent" => 0,
        "strict" => 0,
        "warnings" => 0,
        "XSLoader" => 0,
    },
    ( $mm_ver < 6.63_03 ? 'BUILD_REQUIRES' : 'TEST_REQUIRES' ) => {
        "IO::File" => 0,
        "Scalar::Util" => 0,
        "Test::Simple" => 0.44,
        "utf8" => 0,
    },
    ($mm_ver < 6.46 ? () : (META_MERGE => {
        'meta-spec' => { version => 2 },
        dynamic_config => 1,
        resources => {
            homepage    => 'http://thenceforward.net/perl/modules/XML-Easy/',
            repository  => {
                url         => 'https://github.com/jkeenan/p5-XML-Easy.git',
                web         => 'https://github.com/jkeenan/p5-XML-Easy',
                type        => 'git',
            },
            bugtracker => {
                web         => 'https://github.com/jkeenan/p5-XML-Easy/issues',
            },
        },
    })),
);

WriteMakefile(%WriteMakefileArgs);
