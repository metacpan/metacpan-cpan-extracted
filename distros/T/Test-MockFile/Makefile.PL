use 5.010;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME               => 'Test::MockFile',
    AUTHOR             => q{Todd Rinaldo <toddr@cpanel.net>},
    VERSION_FROM       => 'lib/Test/MockFile.pm',
    ABSTRACT_FROM      => 'lib/Test/MockFile.pm',
    LICENSE            => 'artistic_2',
    PL_FILES           => {},
    MIN_PERL_VERSION   => '5.006',
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '0',
    },
    BUILD_REQUIRES => {
        'Test::More'                => '1.302133',
        'Test2::Bundle::Extended'   => '0.000084', # Oldest version provided on CPAN isa_ok changed in 0.000035 and we need that.
        'Test2::Tools::Explain'     => '0',
        'Test2::Plugin::NoWarnings' => '0',
        'File::Slurper'             => 0,
    },
    PREREQ_PM => {
        'Overload::FileCheck' => '0.007',
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES    => 'Test-MockFile-*' },
    META_MERGE => {
        resources => {
            license    => 'http://dev.perl.org/licenses/',
            bugtracker => 'https://github.com/cpanelinc/Test-MockFile/issues',
            repository => 'https://github.com/cpanelinc/Test-MockFile',
        }
    },
);
