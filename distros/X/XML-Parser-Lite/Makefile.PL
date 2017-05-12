#!/usr/bin/perl

use strict;
use warnings;

use ExtUtils::MakeMaker 6.30;

my $mm_ver = $ExtUtils::MakeMaker::VERSION;
if ($mm_ver =~ /_/) {
    # developer release
    $mm_ver = eval $mm_ver;
    die $@ if $@;
}

my @REQUIRES = (
    'strict'    => 0,
    'warnings'  => 0,
);

my @TEST_REQUIRES = (
    'Test::More'        => 0.88,
    'Test::Requires'    => 0.06,
    'diagnostics'       => 0,
);

push(@REQUIRES, @TEST_REQUIRES) if $mm_ver < 6.64;

WriteMakefile(
    NAME          => 'XML::Parser::Lite',
    VERSION_FROM  => 'lib/XML/Parser/Lite.pm',
    PREREQ_PM     => { @REQUIRES },
    ABSTRACT_FROM => 'lib/XML/Parser/Lite.pm',
    AUTHOR        => 'Byrne Reese (byrne@majordojo.com)',
    META_MERGE    => {
        resources => {
            repository =>
              'https://github.com/redhotpenguin/perl-XML-Parser-Lite',
        },
    },

    ($mm_ver >= 6.48
        ? (MIN_PERL_VERSION => 5.006)
        : ()
    ),

    ($mm_ver >= 6.31 ? (LICENSE => 'perl') : ()),

    ($mm_ver >= 6.64
        ? (TEST_REQUIRES => { @TEST_REQUIRES })
        : ()
    ),

    ($mm_ver >= 6.52
        ? (CONFIGURE_REQUIRES => {
                'ExtUtils::MakeMaker' => 6.30,
          })
        : ()
    ),

);
