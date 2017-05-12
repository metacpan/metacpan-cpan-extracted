require 5.008_001;
use ExtUtils::MakeMaker;
eval "use Devel::Required";

WriteMakefile (
 NAME		=> "ogd",
 AUTHOR		=> 'Elizabeth Mattijsen (liz@dijkmat.nl)',
 ABSTRACT	=> 'ordered global destruction of objects stored in globals',
 VERSION_FROM	=> 'lib/ogd.pm',
 PREREQ_PM	=> { qw(
		    B             0
                    Scalar::Util  0
                   ) },
);
