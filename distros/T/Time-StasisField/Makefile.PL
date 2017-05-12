use strict;
use warnings;

use ExtUtils::MakeMaker;
use ExtUtils::MakeMaker::CPANfile;

WriteMakefile(
	NAME                => 'Time::StasisField',
	AUTHOR              => q{Aaron Cohen <acohen@shutterstock.com>},
	VERSION_FROM        => 'lib/Time/StasisField.pm',
	ABSTRACT_FROM       => 'lib/Time/StasisField.pm',
);
