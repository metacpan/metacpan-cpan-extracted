require 5.008;
use Config;
use ExtUtils::MakeMaker;

WriteMakefile (
 NAME		=> "threads::farm",
 ($[ >= 5.005) ?
 (AUTHOR	=> 'Elizabeth Mattijsen (liz@dijkmat.nl)',
  ABSTRACT	=> 'group of threads for performing similar jobs') : (),
 VERSION_FROM	=> 'lib/threads/farm.pm',
 PREREQ_PM	=> {
                    'threads::shared::queue::any' => 0,
                    'Storable' => 0,
                   },
);
