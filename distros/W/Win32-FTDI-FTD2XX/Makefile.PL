################################################################################
# $Id: Makefile.PL,v 1.3 2008/11/13 20:46:27 395502 Exp $
################################################################################
#
use 5.008008;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME           => 'Win32::FTDI::FTD2XX',
    VERSION_FROM   => 'lib/Win32/FTDI/FTD2XX.pm',
    PREREQ_PM      => { Win32::API => 0.53, File::Copy => 0.0 }, 
    PL_FILES       => {'bin/instp5dll.pl' => 'lib/Win32/FTDI/p5ftd2xx.dll'},
    ABSTRACT_FROM  => 'lib/Win32/FTDI/FTD2XX.pm',
    AUTHOR         => 'Scott K MacPherson <skmacphe@cpan.org>',
);
