require 5.008;
use Config;
use ExtUtils::MakeMaker;

# do we have threads/forks?
BEGIN { 
        eval {
                require threads;
        };
} #BEGIN

WriteMakefile (
 NAME		=> "threads::farm",
 ($[ >= 5.005) ?
 (AUTHOR	=> 'Elizabeth Mattijsen (liz@dijkmat.nl)',
  ABSTRACT	=> 'group of threads for performing similar jobs') : (),
 VERSION_FROM	=> 'lib/threads/farm.pm',
 PREREQ_PM	=> {
                    'Thread::Queue::Any' => 0,
                    'Storable' => 0,
                   },
);
