#!/usr/bin/perl -w

use strict;

use ExtUtils::MakeMaker;

WriteMakefile(
	NAME         => 'Tie::RefHash::Weak',
	VERSION_FROM => 'lib/Tie/RefHash/Weak.pm',
	INSTALLDIRS  => 'site',
	SIGN         => 1,
	PL_FILES     => { },
	PREREQ_PM    => {
		'Task::Weaken' => 0, # no weak refs before this
		'Scalar::Util' => 0,
		'Tie::RefHash' => '1.34', # use refaddr instead of overload::StrVal
		'Variable::Magic' => 0,
	},
);

