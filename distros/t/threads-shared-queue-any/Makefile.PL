require 5.008;
use Config;
use ExtUtils::MakeMaker;

WriteMakefile (
 NAME		=> "threads::shared::queue::any",
 ($[ >= 5.005) ?
 (AUTHOR	=> 'Elizabeth Mattijsen (liz@dijkmat.nl)',
  ABSTRACT	=> 'thread-safe queues for any data-structure') : (),
 VERSION_FROM	=> 'lib/threads/shared/queue/any.pm',
 PREREQ_PM	=> {
                    'threads::shared::queue' => 0,
                    'Storable' => 0,
                   },
);
