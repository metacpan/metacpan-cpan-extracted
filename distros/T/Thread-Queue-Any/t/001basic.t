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

use Thread::Queue::Any;
use Test::More;

diag "threads loaded" if $Loaded{threads};
diag "forks loaded"   if $Loaded{forks};
ok( $Loaded{threads} || $Loaded{forks}, "thread-like module loaded" );

my $class= 'Thread::Queue::Any';
my $q= $class->new;
isa_ok( $q, $class, 'check object type' );
can_ok( $q, qw(
 dequeue
 dequeue_dontwait
 dequeue_keep
 dequeue_nb
 enqueue
 new
 pending
 THAW
) );

# enqueing
$q->enqueue( qw( a b c ) );
$q->enqueue( [ qw( a b c ) ] );
$q->enqueue( { a => 1, b => 2, c => 3 } );
is( $q->pending, 3,              'check number pending');

# dequeueing
my @l= $q->dequeue;
is( @l, 3,                       'check # elements simple list' );
ok( ($l[0] eq 'a' and $l[1] eq 'b' and $l[2] eq 'c'), 'check simple list' );

my @lr= $q->dequeue_nb;
cmp_ok( @lr, '==', 1,            'check # elements list ref' );
is( ref($lr[0]), 'ARRAY',        'check type of list ref' );
ok(
 ($lr[0]->[0] eq 'a' and $lr[0]->[1] eq 'b' and $lr[0]->[2] eq 'c'),
 'check list ref'
);

my @hr= $q->dequeue_keep;
cmp_ok( @hr, '==', 1,            'check # elements hash ref, #1' );
is( ref($hr[0]), 'HASH',         'check type of hash ref, #1' );
ok(
 ($hr[0]->{a} == 1 and $hr[0]->{b} == 2 and $hr[0]->{c} == 3),
 'check hash ref'
);

@hr= $q->dequeue;
cmp_ok( @hr, '==', 1,            'check # elements hash ref, #2' );
is( ref($hr[0]), 'HASH',         'check type of hash ref, #2' );
ok(
 ($hr[0]->{a} == 1 and $hr[0]->{b} == 2 and $hr[0]->{c} == 3),
 'check hash ref'
);

my @e= $q->dequeue_dontwait;
cmp_ok( @e, '==', 0,             'check # elements non blocking' );

# serializer
ok( eval "use $class serializer => 'Storable'; 1", "same serializer later" );
ok( !eval "use $class serializer => 'FrobNob'; 1", "different serializer" );
like( $@, qr#Cannot serialize with 'FrobNob', already using 'Storable'# );
ok( !eval "use $class freeze => sub {}; 1", "specific freeze" );
like( $@, qr#Cannot specify 'freeze', already using serializer 'Storable'# );
ok( !eval "use $class thaw => sub {}; 1", "specific thaw" );
like( $@, qr#Cannot specify 'thaw', already using serializer 'Storable'# );
ok( !eval "use $class frobnob => 1; 1", "unknown specification" );
like( $@, qr#Don't know what to do with: frobnob# );

done_testing(25);
