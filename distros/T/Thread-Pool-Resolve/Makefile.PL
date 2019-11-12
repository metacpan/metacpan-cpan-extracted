require 5.008;
use threads (); # just to force breakage if threads are not available
use ExtUtils::MakeMaker;
eval "use Devel::Required";

WriteMakefile (
 NAME		=> "Thread::Pool::Resolve",
 AUTHOR		=> 'Elizabeth Mattijsen (liz@dijkmat.nl)',
 ABSTRACT	=> 'resolve logs asynchronously',
 VERSION_FROM	=> 'lib/Thread/Pool/Resolve.pm',
 PREREQ_PM	=> {
                    'load'         => 0,
                    'Thread::Pool' => '0.29',
                   },
);
