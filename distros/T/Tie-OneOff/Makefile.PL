#!/usr/bin/env perl

use ExtUtils::MakeMaker;

WriteMakefile(
    VERSION_FROM    => "lib/Tie/OneOff.pm",
    NAME            => "Tie::OneOff",
    PREREQ_PM       => { 'Scalar::Util' => '1.07',
			 'Test::Simple' => '0.68',
                       },
    DISTNAME        => "Tie-OneOff",
);
