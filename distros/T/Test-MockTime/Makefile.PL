#!perl

use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
		'NAME'          => 'Test::MockTime',
		'AUTHOR'        => q{David Dick <ddick@cpan.org>},
		'VERSION_FROM'  => 'lib/Test/MockTime.pm',
		'ABSTRACT_FROM' => 'lib/Test/MockTime.pm',
	    ($ExtUtils::MakeMaker::VERSION >= 6.3002
	      ? ('LICENSE'=> 'perl')
	      : ()),
		'PREREQ_PM'     => {
				'Test::More' => 0,
				'Time::Local' => 0,
				'Time::Piece' => '1.08',
					},
);
