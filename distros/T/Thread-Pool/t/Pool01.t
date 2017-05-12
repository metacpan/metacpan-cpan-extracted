BEGIN {				# Magic Perl CORE pragma
    if ($ENV{PERL_CORE}) {
        chdir 't' if -d 't';
        @INC = '../lib';
    }
}

use strict;
use warnings;
use Test::More tests => 42;

$SIG{__DIE__} = sub { require Carp; Carp::confess() };
$SIG{__WARN__} = sub { require Carp; Carp::confess() };

diag( "Test general functionality" );

BEGIN { use_ok('Thread::Pool') }

my $t0 = () = threads->list; # remember number of threads now

my $pool = pool();
isa_ok( $pool,'Thread::Pool',		'check object type' );

can_ok( $pool,qw(
 abort
 add
 autoshutdown
 new
 notused
 done
 dont_set_result
 frequency
 job
 jobid
 join
 monitor
 remove
 remove_me
 removed
 result
 result_any
 result_dontwait
 self
 set_result
 shutdown
 todo
 waitfor
 workers
) );

cmp_ok( scalar($pool->workers),'==',1,	'check number of workers' );
$pool->job( qw(d e f) );	# do a job, for statistics only

my $todo = $pool->todo;
ok( ($todo >= 0 and $todo <= 1),		'check # jobs todo, #1' );
cmp_ok( scalar($pool->workers),'==',1,	'check number of workers, #1' );

my $jobid1 = $pool->job( qw(g h i) );
cmp_ok( $jobid1,'==',1,			'check first jobid' );

my $jobid2 = $pool->job( qw(k l m) );
cmp_ok( $jobid2,'==',2,			'check second jobid' );

cmp_ok( $pool->add,'>=',2,		'check tid of 2nd worker thread' );
cmp_ok( scalar($pool->workers),'==',2,	'check number of workers, #2' );

$pool->workers( 10 );
cmp_ok( scalar($pool->workers),'==',10,	'check number of workers, #3' );

$pool->workers( 5 );
my $workers = $pool->workers;
ok( ($workers >= 5 and $workers <= 10),	'check number of workers, #4' );
my $removed = $pool->removed;
ok( ($removed >= 0 and $removed <= 5),	'check number of removed, #1' );

$todo = $pool->todo;
ok( ($todo >= 0 and $todo <= 3),	'check # jobs todo, #2' );

my @result = $pool->result_dontwait( $jobid1 );
ok( (!@result or ("@result" eq 'i h g')), 'check result_dontwait' );

@result = $pool->result( $jobid2 );
is( join('',@result),'mlk',		'check result' );

my $jobid3 = $pool->remove;
cmp_ok( $jobid3,'==',3,			'check third jobid' );

@result = $pool->result( $jobid3 );
is( join('',@result),'abcabc',		'check result remove' );

$workers = $pool->workers;
ok( ($workers >= 4 and $workers <= 10),	'check number of workers, #5' );
$removed = $pool->removed;
ok( ($removed >= 0 and $removed <= 6),	'check number of removed, #2' );

$pool->shutdown;
#foreach (threads->list) {
#  warn "Thread #".$_->tid." still alive\n";
#}
cmp_ok( scalar(()=threads->list),'==',$t0,'check for remaining threads' );

cmp_ok( scalar($pool->workers),'==',0,	'check number of workers, #6' );
cmp_ok( scalar($pool->removed),'==',10,	'check number of removed, #3' );
cmp_ok( $pool->todo,'==',0,		'check # jobs todo, #3' );
cmp_ok( $pool->done,'==',3,		'check # jobs done, #3' );

my $notused = $pool->notused;
ok( ($notused >= 0 and $notused < 10),	'check not-used threads, #1' );

#================================================================

$pool = pool();
isa_ok( $pool,'Thread::Pool',		'check object type' );

my $jobid4 = $pool->job( 1,2,3 );
cmp_ok( $jobid4,'==',1,			'check fourth jobid' );

my @worker = $pool->workers;
cmp_ok( scalar($pool->workers),'==',1,	'check number of workers, #7' );

@result = $pool->result( $jobid4 );
is( join('',@result),'321',		'check result after add' );

@result = $pool->waitfor( qw(m n o) );
is( join('',@result),'onm',		'check result waitfor' );

my $jobid5 = $pool->job( 4,5,6 );
cmp_ok( $jobid5,'==',3,			'check fifth jobid' );

my $foundjobid;
@result = $pool->result_any( \$foundjobid );
is( join('',@result),'654',		'check result after add' );
cmp_ok( $foundjobid,'==',$jobid5,	'check whether job id found ok' );

my $jobid6 = $pool->job( 'remove_me' );
cmp_ok( $jobid6,'==',4,			'check sixth jobid' );

my ($result) = $pool->result( $jobid6 );
is( $result,'remove_me',		'check result remove_me' );

$pool->shutdown;
cmp_ok( $pool->todo,'==',0,		'check # jobs todo, #4' );
cmp_ok( $pool->done,'==',4,		'check # jobs done, #4' );
cmp_ok( scalar($pool->workers),'==',0,	'check number of workers, #7' );
cmp_ok( scalar($pool->removed),'==',1,	'check number of removed, #4' );
cmp_ok( scalar(()=threads->list),'==',$t0,'check for remaining threads' );

$notused = $pool->notused;
ok( ($notused >= 0 and $notused < 11),	'check not-used threads, #2' );

sub pool { Thread::Pool->new(
 {
  pre		=> 'pre',
  do		=> 'main::do',
  post		=> \&post,
 },
 qw(a b c)
)
}

sub pre { reverse @_ }

sub do {
  Thread::Pool->self->remove_me if $_[0] eq 'remove_me';
  reverse @_;
}

sub post { (@_,@_) }
