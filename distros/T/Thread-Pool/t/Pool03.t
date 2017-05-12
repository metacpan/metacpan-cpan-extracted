BEGIN {				# Magic Perl CORE pragma
    if ($ENV{PERL_CORE}) {
        chdir 't' if -d 't';
        @INC = '../lib';
    }
}

use strict;
use warnings;
use IO::Handle; # needed, cause autoflush method doesn't load it
use Test::More tests => 3 + (2*2*4*21);

$SIG{__DIE__} = sub { require Carp; Carp::confess() };
$SIG{__WARN__} = sub { require Carp; Carp::confess() };

diag( "Test monitoring to file with checkpointing" );

BEGIN { use_ok('Thread::Pool') }
cmp_ok( Thread::Pool->frequency( 10 ),'==',10,	'check default frequency' );

my $t0 = () = threads->list; # remember number of threads now

my $check;
my $format = '%5d';
my @list;

my $file = 'anymonitor';
my $handle;
my $checkpointed : shared;

# [int(2+rand(8)),int(1+rand(1000))],
my @amount = (
 [10,0],
 [5,5],
 [10,100],
 [1,1000],
);


sub pre {
  return if Thread::Pool->self;
  open( $handle,">$_[0]" ) or die "Could not open monitoring file";
}

sub post {
  return unless Thread::Pool->monitor;
  close( $handle ) or die "Could not close monitoring file";
}

sub do { sprintf( $format,$_[0] ) }

sub yield { threads->yield; sprintf( $format,$_[0] ) }

sub file { print $handle $_[0] }

sub checkpoint { $checkpointed++ }

foreach my $optimize (qw(cpu memory)) {
  diag( qq(*** Test using faster "do", optimize for $optimize ***) );
  _runtest( $optimize,@{$_},qw(pre do file post checkpoint) ) foreach @amount;

  diag( qq(*** Test using slower "yield", optimize for $optimize ***) );
  _runtest( $optimize,@{$_},qw(pre yield file post checkpoint)) foreach @amount;
}

ok( unlink( $file ),			'check unlinking of file' );
1 while unlink $file; # multiversioned filesystems


sub _runtest {

my ($optimize,$t,$times,$pre,$do,$monitor,$post,$cp) = @_;
diag( "Now testing $t thread(s) for $times jobs" );

my $checkpoints = int($times/10);
$checkpointed = 0;

my $pool = pool( $optimize,$t,$pre,$do,$monitor,$post,$cp,$file );
isa_ok( $pool,'Thread::Pool',		'check object type' );
cmp_ok( scalar($pool->workers),'==',$t,	'check initial number of workers' );

$check = '';
foreach ( 1..$times ) {
  $pool->job( $_ );
  $check .= sprintf( $format,$_ );
}

$pool->shutdown;
cmp_ok( scalar(()=threads->list),'==',$t0,'check for remaining threads, #1' );
cmp_ok( scalar($pool->workers),'==',0,	'check number of workers, #1' );
cmp_ok( scalar($pool->removed),'==',$t, 'check number of removed, #1' );
cmp_ok( $pool->todo,'==',0,		'check # jobs todo, #1' );
cmp_ok( $pool->done,'==',$times,	'check # jobs done, #1' );

my $notused = $pool->notused;
ok( ($notused >= 0 and $notused <= $t),	'check not-used threads, #1' );

open( my $in,"<$file" ) or die "Could not read $file: $!";
is( join('',<$in>),$check,		'check first result' );
close( $in );

cmp_ok( $checkpointed,'==',$checkpoints,'check correct # checkpoints, #1' );
$checkpointed = 0;

diag( "Now testing ".($t+$t)." thread(s) for $times jobs" );
$pool = pool( $optimize,$t,$pre,$do,$monitor,$post,$cp,$file );
isa_ok( $pool,'Thread::Pool',		'check object type' );
cmp_ok( scalar($pool->workers),'==',$t,	'check initial number of workers' );

$pool->job( $_ ) foreach 1..$times;

$pool->workers( $t+$t);
cmp_ok( scalar($pool->workers),'==',$t+$t, 'check number of workers, #2' );

$pool->shutdown;
cmp_ok( scalar(()=threads->list),'==',$t0,'check for remaining threads, #2' );
cmp_ok( scalar($pool->workers),'==',0,	'check number of workers, #2' );
cmp_ok( scalar($pool->removed),'==',$t+$t, 'check number of removed, #2' );
cmp_ok( $pool->todo,'==',0,		'check # jobs todo, #2' );
cmp_ok( $pool->done,'==',$times,	'check # jobs done, #2' );

$notused = $pool->notused;
ok( ($notused >= 0 and $notused <= $t+$t),	'check not-used threads, #2' );

open( $in,"<$file" ) or die "Could not read $file: $!";
is( join('',<$in>),$check,		'check second result' );
close( $in );

cmp_ok( $checkpointed,'==',$checkpoints,'check correct # checkpoints, #2' );

} #_runtest


sub pool { Thread::Pool->new(
 {
  optimize => shift,
  workers => shift,
  pre => shift,
  do => shift,
  monitor => shift,
  post => shift,
  checkpoint => shift,
  maxjobs => undef,
 },
 shift
);
} #pool
