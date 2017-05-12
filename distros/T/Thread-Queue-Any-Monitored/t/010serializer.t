BEGIN {                                # Magic Perl CORE pragma
    if ($ENV{PERL_CORE}) {
        chdir 't' if -d 't';
        @INC = '../lib';
    }
}

use strict;
use warnings;

# modules we need
my %Loaded;
BEGIN {
    $Loaded{threads}= eval "use threads; 1";
    $Loaded{forks}=   eval "use forks; 1" if !$Loaded{threads};
} #BEGIN

# modules that we need
use Thread::Queue::Any::Monitored
  serializer => eval "use Thread::Serialize"
    ? 'Thread::Serialize'
    : 'Storable';
use Test::More;

diag "threads loaded" if $Loaded{threads};
diag "forks loaded"   if $Loaded{forks};
ok( $Loaded{threads} || $Loaded{forks}, "thread-like module loaded" );

my $times= 1000;
my $file=  'outmonitored';
my $handle;
my $object : shared;

my $class= 'Thread::Queue::Any::Monitored';
my ( $q, $t )= $class->new( {
  pre     => sub {
      open( $handle, ">$_[0]" ) or die "Cannot create file $_[0]: $!";
      $object= ref( $class->self );
  },
  monitor => sub { print $handle ( %{ $_[0] } ) },
  post    => sub { close($handle); return 'anydone' },
}, $file );

isa_ok( $q, $class, 'check queue object type' );

$q->enqueue( { $_ => $_ + 1 } ) foreach 1..$times;
my $pending= $q->pending;
ok( ( $pending >= 0 and $pending <= $times ),
  'check number of values on queue' );

$q->enqueue(undef); # stop monitoring
is( $t->join,'anydone', 'check result of join' );

is( $object, $class, 'check result of ->self' );

my $check= '';
$check .= ( $_ . ( $_ + 1 ) ) foreach 1..$times;
open( my $in, "<$file" ) or die "Could not open file $!";
is( join( '', <$in> ), $check, 'check whether monitoring ok' );
close($in);

is( unlink($file), '1', "Check if cleanup successful" );
1 while unlink $file; # multi-versioned filesystems

done_testing(7);
