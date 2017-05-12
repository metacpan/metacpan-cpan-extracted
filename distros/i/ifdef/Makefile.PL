require 5.006;

use strict;
use ExtUtils::MakeMaker;
eval "use Devel::Required";

WriteMakefile (
 NAME		=> "ifdef",
 AUTHOR		=> 'Elizabeth Mattijsen (liz@dijkmat.nl)',
 ABSTRACT	=> 'conditionally enable text within pod sections as code',
 VERSION_FROM	=> 'lib/ifdef.pm',

 PREREQ_PM	=> {qw(
		    IO::File		0
		    Filter::Util::Call	0
                   )},
);
