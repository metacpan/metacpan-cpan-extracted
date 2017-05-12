#!/usr/bin/perl -w

use ExtUtils::MakeMaker;

WriteMakefile (ABSTRACT => 'Wrapper Class for Microsoft Visual SourceSafe',
	       AUTHOR => 'BPrudent (Brandon Prudent)',
	       DISTNAME => 'VSS',
	       INSTALLMAN3DIR => 'none',
	       VERSION => '1.0.4',
	       PREREQ_PM => {
	       		'Win32::OLE' => 0,
			'Win32::TieRegistry' => 1
	       	});
