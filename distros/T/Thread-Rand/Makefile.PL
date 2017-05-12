require 5.008;
use threads (); # just to force breakage if threads are not available
use ExtUtils::MakeMaker;
eval "use Devel::Required";

WriteMakefile (
 NAME		=> "Thread::Rand",
 AUTHOR		=> 'Elizabeth Mattijsen (liz@dijkmat.nl)',
 ABSTRACT	=> 'repeatable random sequences between threads',
 VERSION_FROM	=> 'lib/Thread/Rand.pm',
 PREREQ_PM	=> {
                   'load'        => 0,
		   'Thread::Tie' => '0.09',
                   },
);
