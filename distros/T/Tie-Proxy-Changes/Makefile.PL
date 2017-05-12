#!/usr/bin/perl
use ExtUtils::MakeMaker;

WriteMakefile(
	NAME=>'Tie::Proxy::Changes',
	VERSION_FROM=>'lib/Tie/Proxy/Changes.pm',
	PREREQ_PM=>{
		 "Carp"=>0,
         "overload"=>0,
         "Scalar::Util"=>0,
	}
);
