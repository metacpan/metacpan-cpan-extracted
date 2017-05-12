#!/usr/bin/perl
use ExtUtils::MakeMaker;

WriteMakefile(
	NAME=>'Tie::MultiKeyInsertOrderHash',
	VERSION_FROM=>'lib/Tie/MultiKeyInsertOrderHash.pm',
	PREREQ_PM=>{
                         'Tie::Hash' => 0,
		 }
);
