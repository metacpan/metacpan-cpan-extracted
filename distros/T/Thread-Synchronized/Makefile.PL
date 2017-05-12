require 5.008;
use threads (); # just to force breakage if threads are not available
use ExtUtils::MakeMaker;
eval "use Devel::Required";

WriteMakefile (
 NAME		=> "Thread::Synchronized",
 AUTHOR		=> 'Elizabeth Mattijsen (liz@dijkmat.nl)',
 ABSTRACT	=> 'synchronize subroutine calls between threads',
 VERSION_FROM	=> 'lib/Thread/Synchronized.pm',
 PREREQ_PM	=> {
                   },
);
