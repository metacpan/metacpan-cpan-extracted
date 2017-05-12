require 5.008;
use threads (); # just to force breakage if threads are not available
use ExtUtils::MakeMaker;
eval "use Devel::Required";

WriteMakefile (
 NAME		=> "Thread::Exit",
 AUTHOR		=> 'Elizabeth Mattijsen (liz@dijkmat.nl)',
 ABSTRACT	=> 'provide thread-local exit(), BEGIN {} and END {}',
 VERSION_FROM	=> 'lib/Thread/Exit.pm',
 PREREQ_PM	=> {
		    'load'	=> '0.12',
                   },
);
