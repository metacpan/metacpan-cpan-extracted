require 5.008;

# do we have threads/forks?
BEGIN { eval "use Devel::ThreadsForks; 1" || do 'threadsforks' } #BEGIN

# make sure we have the right code path
$LIB_TREE= 'Thread/Queue';
$REQUIRED= '5.014';
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
 NAME         => 'Thread::Queue::Any',
 AUTHOR       => 'Elizabeth Mattijsen (liz@dijkmat.nl)',
 ABSTRACT     => 'thread-safe queues for any data-structure',
 VERSION_FROM => 'lib/Thread/Queue/Any.pm',
 LICENSE      => 'perl',
 PREREQ_PM    => { @prereq_pm },
);
