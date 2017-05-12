BEGIN {                                # Magic Perl CORE pragma
    if ($ENV{PERL_CORE}) {
        chdir 't' if -d 't';
        @INC = '../lib';
    }
}


use strict;
use warnings;

my %Loaded;
BEGIN {
    $Loaded{threads}= eval "use threads; 1";
    $Loaded{forks}=   eval "use forks; 1" if !$Loaded{threads};
}

use Thread::Queue::Monitored;
use Test::More;

diag "threads loaded" if $Loaded{threads};
diag "forks loaded"   if $Loaded{forks};
ok( $Loaded{threads} || $Loaded{forks}, "thread-like module loaded" );

my $class= 'Thread::Queue::Monitored';
my $times= 1000;
my $file=  'outmonitored';
my $done=  'done';
my $handle;
my $object : shared;

# set up monitored queue writing to a file
my ( $q, $t ) = $class->new( {
  pre => sub {
      open( $handle,">$_[0]" ) or die "Cannot create file $_[0]: $!";
      $object= ref( $class->self );
  },
  monitor => sub { print $handle $_[0] },
  post    => sub { close( $handle ); return $done },
 },
 $file
);
isa_ok( $q, $class, 'check queue object type' );

# set up queue
$q->enqueue($_) foreach 1 .. $times;
my $pending= $q->pending;
ok( ( $pending >= 0 and $pending <= $times ),
  'check number of values on queue' );
$q->enqueue(undef); # stop monitoring
is( $t->join, $done, 'check result of join()' );

# sanity check
is( $object, $class, 'check result of ->self' );
my $check= '';
$check .= $_ foreach 1 .. $times;
open( my $in, '<', $file ) or die "Could not open file: $!";
is( join( '', readline($in) ), $check, 'check whether monitoring ok' );
close($in);

1 while unlink $file; # multiversioned filesystems

# we're done
done_testing(6);
