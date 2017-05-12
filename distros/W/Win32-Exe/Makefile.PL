#!/usr/bin/env perl
# Copyright 2004, 2007, 2010 by Audrey Tang <cpan@audreyt.org>

use ExtUtils::MakeMaker 6.46;

WriteMakefile(
    NAME           => 'Win32::Exe',
    VERSION_FROM   => 'lib/Win32/Exe.pm',
    AUTHOR         => 'Audrey Tang <cpan@audreyt.org>',
    ABSTRACT       => 'Manipulate Win32 executable files',
    LICENSE        => 'perl',
    EXE_FILES      => [ 'script/exe_update.pl' ],
    MIN_PERL_VERSION => '5.6.0',
    PREREQ_PM      => { 'Parse::Binary'           => 0.11,
                        'XML::Simple'             => 2.18,
                        'XML::Parser'             => 2.36,
                      },
    BUILD_REQUIRES => {  'Test::More' => 0, 'File::Copy' => 0 },
    NORECURS       => ( $^O =~ /^mswin/i ) ? 0 : 1,
);
