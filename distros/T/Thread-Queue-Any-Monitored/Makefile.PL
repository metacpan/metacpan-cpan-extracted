require 5.008;

# do we have threads or forks??
BEGIN { eval "use Devel::ThreadsForks"  || do 'threadsforks' } #BEGIN;

# make sure we have the right code path
our $LIB_TREE= 'Thread/Queue/Any';
our $REQUIRED= '5.014';
eval "use Devel::MaintBlead; 1" || do 'maintblead';

# set version and dependency info
use ExtUtils::MakeMaker;
eval "use Devel::Required maint_blead => $REQUIRED";

# set up prerequisites
my @prereq_pm= (
  'Thread::Queue::Any'       => $MAINT ? '0.16' : '1.13',
  'Thread::Queue::Monitored' => $MAINT ? '0.14' : '1.04',
);
push @prereq_pm, (
  'Test::More' => 0.88,
) if !$MAINT;

# set up
WriteMakefile (
 NAME         => "Thread::Queue::Any::Monitored",
 AUTHOR       => 'Elizabeth Mattijsen (liz@dijkmat.nl)',
 ABSTRACT     => 'monitor a queue for any specific content',
 VERSION_FROM => 'lib/Thread/Queue/Any/Monitored.pm',
 LICENSE      => 'perl',
 PREREQ_PM    => { @prereq_pm },
);
