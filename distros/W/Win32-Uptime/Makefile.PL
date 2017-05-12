# $Id: Makefile.PL 22 2010-09-23 23:04:07Z stro $

use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
  'NAME'          => 'Win32::Uptime',
  'ABSTRACT'      => 'Calculate uptime for Win32 systems',
  'AUTHOR'        => 'Serguei Trouchelle <stro@railways.dp.ua>',
  'VERSION_FROM'  => 'Uptime.pm',
  'LICENSE'       => 'perl',
  'PREREQ_PM' => {
      'Win32::API' => 0,
      'Win32::TieRegistry' => '0.20',
  },
  'EXE_FILES'     => [ 'uptime.pl', ],
);
