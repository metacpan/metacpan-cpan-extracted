require 5.008001;
use ExtUtils::MakeMaker;
eval "use Devel::Required";

WriteMakefile (
 NAME		=> "Thread::Bless",
 AUTHOR		=> 'Elizabeth Mattijsen (liz@dijkmat.nl)',
 ABSTRACT	=> 'make blessed objects thread-aware',
 VERSION_FROM	=> 'lib/Thread/Bless.pm',
 PREREQ_PM	=> {
		    'Scalar::Util'	=> '1.08', # need refaddr()
                   },
);
