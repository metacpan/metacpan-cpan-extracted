#!/usr/bin/perl

use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
    NAME         => 'Win32::AutoItX',
    VERSION_FROM => 'lib/Win32/AutoItX.pm',
    ABSTRACT     => 'AutoItX3 perl interface',
    AUTHOR       => 'Mikhail Telnov <Mikhail.Telnov@gmail.com>',
    LICENSE      => 'perl',
    PREREQ_PM    => {
        'Carp'         => 0,
        'Scalar::Util' => 0,
        'Win32::API'   => 0,
        'Win32::OLE'   => 0,
    },
    test => { TESTS => "t/*.t" },
);
