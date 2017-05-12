#!/usr/bin/perl
use ExtUtils::MakeMaker;

WriteMakefile(
	NAME=>'Config::Sofu',
	VERSION_FROM=>'lib/Config/Sofu.pm',
	PREREQ_PM=>{
                         'Data::Sofu' => 0,
                      }

);
