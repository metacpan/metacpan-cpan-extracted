BEGIN {				# Magic Perl CORE pragma
    if ($ENV{PERL_CORE}) {
        chdir 't' if -d 't';
        @INC = '../lib';
    }
}

use strict;
use warnings;
use IO::Handle;
use Test::More tests => 1 + (2*2*4*10) + 9;

$SIG{__DIE__} = sub { require Carp; Carp::confess() };
$SIG{__WARN__} = sub { require Carp; Carp::confess() };

diag( "Test job throttling" );

BEGIN { use_ok('Thread::Pool') }

my $t0 = () = threads->list; # remember number of threads now

my $check;
my $format = '%5d';
my @list;

my $file = 'anymonitor';
my $handle;

# [int(5+rand(6)),int(301+rand(700))],
my @amount = (
 [10,0],
 [5,5],
 [1,25],
 [10,100],
);


sub pre {
  open( $handle,">$_[0]" ) or die "Could not open monitoring file";
  $handle->autoflush;
}

sub post {
  close( $handle ) or die "Could not close monitoring file";
}

sub do { sleep( rand(2) ); sprintf( $format,$_[0] ) }

sub yield { threads::yield(); sprintf( $format,$_[0] ) }

sub file { print $handle $_[0] }

foreach my $optimize (qw(cpu memory)) {
  diag( qq(*** Test using fast "do" optimized for $optimize ***) );
  _runtest( $optimize,@{$_},qw(pre do file post) ) foreach @amount;

  diag( qq(*** Test using slower "yield" optimized for $optimize ***) );
  _runtest( $optimize,@{$_},qw(pre yield file post) ) foreach @amount;
}

ok( unlink( $file ) );
1 while unlink $file; # multiversioned filesystems

my $pool = Thread::Pool->new( {do => \&do, workers => 2} );
isa_ok( $pool,'Thread::Pool',		'check object type' );
cmp_ok( $pool->maxjobs,'==',10,		'check maxjobs value, #1' );
cmp_ok( $pool->minjobs,'==',5,		'check minjobs value, #1' );

cmp_ok( $pool->maxjobs(50),'==',50,	'check maxjobs value, #2' );
cmp_ok( $pool->minjobs,'==',25,		'check minjobs value, #2' );
cmp_ok( $pool->minjobs(10),'==',10,	'check minjobs value, #3' );

cmp_ok( $pool->maxjobs(0),'==',0,	'check maxjobs value, #3' );
cmp_ok( $pool->minjobs,'==',0,		'check minjobs value, #4' );

$pool->shutdown;

sub _runtest {

my ($optimize,$t,$times,$pre,$do,$monitor,$post) = @_;
diag( "Now testing $t thread(s) for $times jobs" );

my $pool = Thread::Pool->new(
 {
  optimize => $optimize,
  workers => $t,
  pre => $pre,
  do => $do,
  monitor => $monitor,
  pre_post_monitor_only => 1,
  post => $post,
 },
 $file
);
isa_ok( $pool,'Thread::Pool',		'check object type' );
cmp_ok( scalar($pool->workers),'==',$t,	'check initial number of workers' );

$check = '';
foreach ( 1..$times ) {
  $pool->job( $_ );
  $check .= sprintf( $format,$_ );
}

diag( "Now testing ".($t+$t)." thread(s) for $times jobs" );
$pool->job( $_ ) foreach 1..$times;

$pool->workers( $t+$t );
cmp_ok( scalar($pool->workers),'==',$t+$t, 'check number of workers' );

$pool->shutdown;
cmp_ok( scalar(()=threads->list),'==',$t0,'check for remaining threads' );
cmp_ok( scalar($pool->workers),'==',0,	'check number of workers' );
cmp_ok( scalar($pool->removed),'==',$t+$t, 'check number of removed' );
cmp_ok( $pool->todo,'==',0,		'check # jobs todo' );
cmp_ok( $pool->done,'==',$times+$times,	'check # jobs done' );

my $notused = $pool->notused;
ok( ($notused >= 0 and $notused <= $t+$t),	'check not-used threads' );

open( my $in,"<$file" ) or die "Could not read $file: $!";
is( join('',<$in>),$check.$check,	'check result' );
close( $in );

} #_runtest
