use 5.010;
use strict;
use warnings;
use ExtUtils::MakeMaker;

my %WriteMakefileArgs = (
    NAME             => 'WWW::Crawl',
    AUTHOR           => q{Ian Boddison <bod@cpan.org>},
    VERSION_FROM     => 'lib/WWW/Crawl.pm',
    ABSTRACT_FROM    => 'lib/WWW/Crawl.pm',
    LICENSE          => 'Perl',
    MIN_PERL_VERSION => '5.010',
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '0',
    },
    TEST_REQUIRES => {
        'Test::More' => '0',
    },
    PREREQ_PM => {
        'HTTP::Tiny'    => '0.083',
        'URI'           => '5.05',
        'JSON::PP'      => '2.00',
    },
    META_MERGE => {
            'meta-spec' => {
                version => '2',
                url     => 'http://search.cpan.org/perldoc?CPAN::Meta::Spec',
            },
            resources => {
                bugtracker => {
                    web     => 'https://github.com/IanBod/WWW-Crawl/issues',
                },
                repository => {
                    url     => 'https://github.com/IanBod/WWW-Crawl.git',
                    web     => 'https://github.com/IanBod/WWW-Crawl',
                    type    => 'git',
                },
            },
    },
    dist  => { COMPRESS => q{perl -MIO::Compress::Gzip=gzip,:constants -e"my $$in = $$ARGV[0]; gzip($$in => qq($$in.gz), q(Level) => Z_BEST_COMPRESSION, q(BinModeIn) => 1) or die q(gzip failed); unlink $$in;"}, SUFFIX => 'gz', },
    clean => { FILES => 'WWW-Crawl-*' },
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
