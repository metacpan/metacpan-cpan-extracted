require 5.008;

BEGIN { eval "use Devel::ThreadsForks; 1" or do 'threadsforks' } #BEGIN

$LIB_TREE= 'Thread';
$REQUIRED= '5.014';
eval "use Devel::MaintBlead; 1" or do 'maintblead';

use ExtUtils::MakeMaker;
eval "use Devel::Required maint_blead => $REQUIRED";

my @prereq= qw( Storable 0 );
push @prereq, $MAINT
  ? qw( load        0.10 )
  : qw( Test::More  0.88 );

WriteMakefile (
 NAME         => "Thread::Serialize",
 AUTHOR       => 'Elizabeth Mattijsen (liz@dijkmat.nl)',
 ABSTRACT     => 'serialize data-structures between threads',
 VERSION_FROM => 'lib/Thread/Serialize.pm',
 LICENSE      => 'perl',
 PREREQ_PM    => { @prereq },
);
