BEGIN {				# Magic Perl CORE pragma
    if ($ENV{PERL_CORE}) {
        chdir 't' if -d 't';
        @INC = '../lib';
    }
}

use strict;
use warnings;
use Test::More tests => 9;

BEGIN { use_ok('threads') }
BEGIN { use_ok('Thread::Queue::Any::Monitored') }

my $times = 1000;
my $file = 'outmonitored';
my $handle;
my $object : shared;

my ($q,$t) = Thread::Queue::Any::Monitored->new(
 {
  pre => sub {
              open( $handle,">$_[0]" ) or die "Cannot create file $_[0]: $!";
              $object = ref(Thread::Queue::Any::Monitored->self);
             },
  monitor => sub { print $handle (%{$_[0]}) },
  post => sub { close( $handle ); return 'anydone' },
 },
 $file
);

isa_ok( $q, 'Thread::Queue::Any::Monitored', 'check queue object type' );
isa_ok( $t, 'threads',		'check thread object type' );

$q->enqueue( {$_ => $_+1} ) foreach 1..$times;
my $pending = $q->pending;
ok( ($pending >= 0 and $pending <= $times), 'check number of values on queue' );

$q->enqueue( undef ); # stop monitoring
is( $t->join,'anydone',			'check result of join' );

is( $object,'Thread::Queue::Any::Monitored', 'check result of ->self' );

my $check = '';
$check .= ($_.($_+1)) foreach 1..$times;
open( my $in,"<$file" ) or die "Could not open file $!";
is( join('',<$in>), $check,		'check whether monitoring ok' );
close( $in );

is( unlink( $file ),'1',"Check if cleanup successful" );
1 while unlink $file; # multi-versioned filesystems
