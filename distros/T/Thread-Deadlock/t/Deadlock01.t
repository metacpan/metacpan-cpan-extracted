BEGIN {				# Magic Perl CORE pragma
    if ($ENV{PERL_CORE}) {
        chdir 't' if -d 't';
        @INC = '../lib';
    }
}

BEGIN {
    warn <<EOD if -t STDERR;


Please note that some warnings may appear during testing.  These seem to be
the result of a weird interaction between Thread::Deadlock, Test::More and
threads.  During normal operation, Thread::Deadlock should not produce any
warnings.  If you should see any warnings, please report these.  Thank you
for your attention.

EOD
} #BEGIN

use strict;
use warnings;
use Test::More tests => 7;

BEGIN { use_ok( 'Thread::Deadlock' ) }
BEGIN { use_ok( 'threads::shared' ) } # export cond_family

can_ok( 'Thread::Deadlock',qw(
 callers
 disable
 encoding
 format
 import
 off
 on
 output
 report
 shorten
 summary
 trace
) );

my $report = 'report';
is( Thread::Deadlock->output,'STDERR',	'check default output setting' );
is( Thread::Deadlock->output($report),$report,'check new output setting' );

my $trace = 'trace';
unlink( $trace );
ok( !defined( Thread::Deadlock->trace ),'check default trace setting' );
is( Thread::Deadlock->trace($trace),$trace,'check new trace setting' );

my $lock : shared;

threads->new( sub {
 Thread::Deadlock->off;
 lock( $lock );
 $lock = 1;
 cond_wait( $lock );
} );
threads->yield until $lock;

{
 lock( $lock );
 cond_signal( $lock );
}

threads->new( sub {
 lock( $lock );
 $lock = 0;
 cond_wait( $lock );
} );
threads->yield while $lock;

Thread::Deadlock->off;
{
 lock( $lock );
 cond_broadcast( $lock );
}
$_->join foreach threads->list;
