#!perl -w
# Makefile.PL for Win32::GUI::SplashScreen

use strict;
use warnings;
use ExtUtils::MakeMaker;

unless ($^O eq "MSWin32" || $^O eq "cygwin") {
    die "OS unsupported\n";
}

my $mm_ver = $ExtUtils::MakeMaker::VERSION;
if ($mm_ver =~ /_/) { # dev version
    $mm_ver = eval $mm_ver;
    die $@ if $@;
}


WriteMakefile(
    NAME                => 'Win32::GUI::SplashScreen',
    VERSION_FROM        => 'lib\Win32\GUI\SplashScreen.pm',
    ABSTRACT_FROM       => 'lib\Win32\GUI\SplashScreen.pm',
    AUTHOR              => 'Robert May <robertmay@cpan.org>',

    # MIN_PERL_VERSION
    ($mm_ver >= 6.48 ? (MIN_PERL_VERSION => '5.006') : ()),

    # LICENSE
    ($mm_ver >= 6.31 ? (LICENSE => 'perl') : ()),

    PREREQ_PM => {
        'Win32::GUI'           => 1.02,
    },
);
