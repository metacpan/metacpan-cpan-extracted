#!perl

use strict;
use Config;
use ExtUtils::MakeMaker;

my $error = 0;

if ($^O ne "MSWin32") {
    warn "This module works on MSWin32 only";
    $error++;
}

if ($] < 5.009005) {
    warn "perl 5.9.5 or later is required";
    $error++;
}

if ( $Config{ccname} ne "cl" ) {
    warn "Compilation with " . $Config{ccname} . " is not supported";
    $error++;
}

if ( int( $Config{ccversion} ) < 14 ) {
    warn "Visual C++ 2005 or later is required";
    $error++;
}

if ($error) {
    die "Compilation stop";
}

my $inc = '';

if ($ENV{INCLUDE}) {
    for my $inc_dir ( split /;/, $ENV{INCLUDE} ) {
        next if $inc_dir eq '%INCLUDE%';
        $inc .= qq( "-I$inc_dir" );
    }
}

$inc .= q( "-IC:\Program Files\Microsoft Visual Studio 8\VC\PlatformSDK\Include" );

WriteMakefile(
    NAME              => 'Win32::CLR',
    VERSION_FROM      => 'lib/Win32/CLR.pm',
    PREREQ_PM         => {'Test::More' => 0},
    XSOPT             => '-noprototypes',
    ABSTRACT_FROM     => 'lib/Win32/CLR.pm',
    AUTHOR            => 'Toshiyuki Yamato <toshiyuki.yamato@gmail.com>',
    LICENSE           => 'perl',

    # -clr: Run on the common language runtime
    # -TP : Specifies a C++ source file
    CC => 'cl -clr -TP',

    # mscoree: Microsoft .NET Runtime Execution Engine
    # msvcmrt: C runtime import library for mixed managed/native code
    LIBS => ['-lmscoree -lmsvcmrt'],
    INC  => $inc,
);
