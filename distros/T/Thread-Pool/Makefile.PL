require 5.008;
use threads (); # just to force breakage if threads are not available
use ExtUtils::MakeMaker;
eval "use Devel::Required";

WriteMakefile (
 NAME		=> "Thread::Pool",
 AUTHOR		=> 'Elizabeth Mattijsen (liz@dijkmat.nl)',
 ABSTRACT	=> 'group of threads for performing similar jobs',
 VERSION_FROM	=> 'lib/Thread/Pool.pm',
 PREREQ_PM	=> {
                    'Thread::Conveyor' => '0.15',
                    'Thread::Conveyor::Monitored' => '0.11',
                   },
);
