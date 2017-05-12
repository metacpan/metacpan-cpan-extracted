#!/usr/bin/perl

use 5.006;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME               => 'Test::Excel',
    AUTHOR             => q{Mohammad S Anwar <mohammad.anwar@yahoo.com>},
    VERSION_FROM       => 'lib/Test/Excel.pm',
    ABSTRACT_FROM      => 'lib/Test/Excel.pm',
    LICENSE            => 'artistic_2',
    MIN_PERL_VERSION   => 5.006,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More' => 0,
    },
    PREREQ_PM => {
        'Test::Builder'           => 0,
        'Spreadsheet::ParseExcel' => 0.58,
        'OLE::Storage_Lite'       => 0,
        'Crypt::RC4'              => 0,
        'Digest::Perl::MD5'       => 0,
        'Scalar::Util'            => 0,
        'Test::Builder::Tester'   => 0,
        'Test::More'              => 0,
        'File::Spec'              => 0,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Test-Excel-*' },
    (eval { ExtUtils::MakeMaker->VERSION(6.46) } ? (META_MERGE => {
        'meta-spec' => { version => 2 },
        provides    => { 'Test::Excel' => { file => 'lib/Test/Excel.pm', version => '1.39' } },
        resources   => {
            repository => {
                type => 'git',
                url  => 'https://github.com/manwar/Test-Excel.git',
                web  => 'https://github.com/manwar/Test-Excel',
            },
        }})
     : ()
    ),
);
