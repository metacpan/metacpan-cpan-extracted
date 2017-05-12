require 5.008;
use threads (); # just to force breakage if threads are not available
use ExtUtils::MakeMaker;
eval "use Devel::Required";

WriteMakefile (
 NAME		=> "Thread::Tie",
 AUTHOR		=> 'Elizabeth Mattijsen (liz@dijkmat.nl)',
 ABSTRACT	=> 'tie variables into a thread of their own',
 VERSION_FROM	=> 'lib/Thread/Tie.pm',
 PREREQ_PM	=> {qw(
		   load			0.11
		   Thread::Serialize	0.07
                   )},
);
