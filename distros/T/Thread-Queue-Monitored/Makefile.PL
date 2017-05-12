require 5.008;

# do we have threads or forks??
BEGIN { eval "use Devel::ThreadsForks"  || do 'threadsforks' } #BEGIN;

# initializations
our $LIB_TREE=   'Thread/Queue';
our $REQUIRED=   '5.014';
eval "use Devel::MaintBlead; 1" || do 'maintblead';

# set version and dependency info
use ExtUtils::MakeMaker;
eval "use Devel::Required maint_blead => $REQUIRED";

# set up prerequisites
my @prereq_pm= (
  'Thread::Queue' => 0,
);
push @prereq_pm, (
  'Test::More'    => 0.88,
) if !$MAINT;

# set up
WriteMakefile (
 NAME         => 'Thread::Queue::Monitored',
 AUTHOR       => 'Elizabeth Mattijsen (liz@dijkmat.nl)',
 ABSTRACT     => 'monitor a queue for specific content',
 VERSION_FROM => 'lib/Thread/Queue/Monitored.pm',
 LICENSE      => 'perl',
 PREREQ_PM    => { @prereq_pm },
);

