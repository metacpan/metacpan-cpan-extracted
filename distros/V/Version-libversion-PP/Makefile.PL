#!perl

use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME               => 'Version::libversion::PP',
    AUTHOR             => q{Giuseppe Di Terlizzi <gdt@cpan.org>},
    VERSION_FROM       => 'lib/Version/libversion/PP.pm',
    ABSTRACT_FROM      => 'lib/Version/libversion/PP.pm',
    LICENSE            => 'artistic_2',
    MIN_PERL_VERSION   => 5.010,
    CONFIGURE_REQUIRES => {'ExtUtils::MakeMaker' => '0'},
    TEST_REQUIRES      => {'Test::More'          => '0'},
    PREREQ_PM          => {},
    META_MERGE         => {
        'meta-spec' => {version => 2},
        'resources' => {
            bugtracker => {web => 'https://github.com/giterlizzi/perl-Version-libversion-PP/issues'},
            repository => {
                type => 'git',
                url  => 'git://github.com/giterlizzi/perl-Version-libversion-PP',
                web  => 'https://github.com/giterlizzi/perl-Version-libversion-PP'
            },
        },
        x_purl => 'pkg:cpan/GDT/Version-libversion-PP'
    },
    dist  => {COMPRESS => 'gzip -9f', SUFFIX => 'gz'},
    clean => {FILES    => 'Version-libversion-PP-*'},
);
