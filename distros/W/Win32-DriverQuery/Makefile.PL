#!perl -w

require 5.008;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
  NAME	=> 'Win32::DriverQuery',
  VERSION_FROM => 'DriverQuery.pm',
  MIN_PERL_VERSION => '5.014001', # s///r
  PREREQ_PM => {
    'Win32::API' => 0,
    'Win32' => 0,
  },
  META_MERGE => {
    "meta-spec" => { version => 2 },
    resources => {
      repository => {
	type => 'git',
	url => 'git://github.com/mohawk2/win32-driverquery',
	web => 'https://github.com/mohawk2/win32-driverquery',
      },
    },
  },
);
