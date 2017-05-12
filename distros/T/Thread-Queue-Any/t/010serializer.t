BEGIN {                # Magic Perl CORE pragma
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

use Storable;
use Thread::Queue::Any
  freeze => \&Storable::freeze,
  thaw   => \&Storable::thaw,
;;
use Test::More;

diag "threads loaded" if $Loaded{threads};
diag "forks loaded"   if $Loaded{forks};
ok( $Loaded{threads} || $Loaded{forks}, "thread-like module loaded" );

my $class= 'Thread::Queue::Any';
my $q= $class->new;
isa_ok( $q, $class, 'check object type' );

# enqueing
$q->enqueue( qw( a b c ) );
$q->enqueue( [ qw( a b c ) ] );
$q->enqueue( { a => 1, b => 2, c => 3 } );
is( $q->pending, 3,              'check number pending');

# dequeueing
my $l= $q->dequeue;
is( $l, 'a',                     'check simple list in scalar context' );

my $lr= $q->dequeue_nb;
is( ref($lr), 'ARRAY',           'check type of list ref' );
ok(
 ($lr->[0] eq 'a' and $lr->[1] eq 'b' and $lr->[2] eq 'c'),
 'check list ref'
);

my $hr= $q->dequeue_keep;
is( ref($hr), 'HASH',            'check type of hash ref, #1' );

$hr= $q->dequeue;
is( ref($hr), 'HASH',            'check type of hash ref, #2' );
ok(
 ($hr->{a} == 1 and $hr->{b} == 2 and $hr->{c} == 3),
 'check hash ref'
);

my $e= $q->dequeue_dontwait;
ok( !defined($e),                'check empty' );

# serializer
ok( !eval "use $class serializer => 'FrobNob'; 1", "different serializer" );
like( $@, qr#Cannot serialize with 'FrobNob', already using freeze/thaw# );
ok( !eval "use $class freeze => sub {}; 1", "specific freeze" );
like( $@, qr#Cannot specify new 'freeze', already using freeze/thaw# );
ok( !eval "use $class thaw => sub {}; 1", "specific thaw" );
like( $@, qr#Cannot specify new 'thaw', already using freeze/thaw# );

done_testing(16);
