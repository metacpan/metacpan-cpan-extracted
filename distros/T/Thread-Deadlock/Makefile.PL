require 5.008;
use threads (); # just to force breakage if threads are not available
use ExtUtils::MakeMaker;
eval "use Devel::Required";

WriteMakefile (
 NAME		=> "Thread::Deadlock",
 AUTHOR		=> 'Elizabeth Mattijsen (liz@dijkmat.nl)',
 ABSTRACT	=> 'report deadlocks with stacktrace',
 VERSION_FROM	=> 'lib/Thread/Deadlock.pm',
 PREREQ_PM	=> {
		    load => 0,
                   },
);
