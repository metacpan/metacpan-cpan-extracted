#!perl

use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME               => 'URI::PackageURL',
    AUTHOR             => q{Giuseppe Di Terlizzi <gdt@cpan.org>},
    VERSION_FROM       => 'lib/URI/PackageURL.pm',
    ABSTRACT_FROM      => 'lib/URI/PackageURL.pm',
    LICENSE            => 'artistic_2',
    EXE_FILES          => ['bin/purl-tool'],
    MIN_PERL_VERSION   => 5.010,
    PL_FILES           => {},
    CONFIGURE_REQUIRES => {'ExtUtils::MakeMaker' => '0'},
    TEST_REQUIRES      => {'Test::More' => '0', 'JSON::PP'   => '0', 'CPAN::DistnameInfo' => 0},
    PREREQ_PM          => {'JSON::PP'   => '0', 'List::Util' => '0'},
    META_MERGE         => {
        'meta-spec' => {version => 2},
        'resources' => {
            bugtracker => {web => 'https://github.com/giterlizzi/perl-URI-PackageURL/issues'},
            repository => {
                type => 'git',
                url  => 'git://github.com/giterlizzi/perl-URI-PackageURL',
                web  => 'https://github.com/giterlizzi/perl-URI-PackageURL'
            },
        },
        x_purl => 'pkg:cpan/GDT/URI-PackageURL'
    },
    dist  => {COMPRESS => 'gzip -9f', SUFFIX => 'gz',},
    clean => {FILES    => 'URI-PackageURL-*'},
);
