BEGIN {				# Magic Perl CORE pragma
    if ($ENV{PERL_CORE}) {
        chdir 't' if -d 't';
        @INC = '../lib';
    }
}

use Test::More tests => 13;

BEGIN { use_ok('threads') }
BEGIN { use_ok('threads::shared::queue::any') }

my $q = threads::shared::queue::any->new;
isa_ok( $q, 'threads::shared::queue::any', 'check object type' );

$q->enqueue( qw(a b c) );
$q->enqueue( [qw(a b c)] );
$q->enqueue( {a => 1, b => 2, c => 3} );

is( $q->pending, 3,			'check number pending');

my @l = $q->dequeue;
is( @l, 3,				'check # elements simple list' );
ok( $l[0] eq 'a' and $l[1] eq 'b' and $l[2] eq 'c', 'check simple list' );

my @lr = $q->dequeue_nb;
cmp_ok( @lr, '==', 1,			'check # elements list ref' );
is( ref($lr[0]), 'ARRAY',		'check type of list ref' );
ok(
 $lr[0]->[0] eq 'a' and $lr[0]->[1] eq 'b' and $lr[0]->[2] eq 'c',
 'check list ref'
);

my @hr = $q->dequeue;
cmp_ok( @hr, '==', 1,			'check # elements hash ref' );
is( ref($hr[0]), 'HASH',		'check type of hash ref' );
ok(
 $hr[0]->{a} == 1 and $hr[0]->{b} == 2 and $hr[0]->{c} == 3,
 'check hash ref'
);

my @e = $q->dequeue_nb;
cmp_ok( @e, '==', 0,			'check # elements non blocking' );
