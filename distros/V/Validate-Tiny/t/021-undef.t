use strict;
use warnings;

use Test::More tests => 3;
use Validate::Tiny ':all';

my $r = {
    fields => ['a'],
    checks => [
        a => is_required
    ]
};

my ($i, $o);

$i = { a => undef };
$o = validate( $i, $r );
ok !$o->{success};

$r->{filters} = [
    a => sub { defined $_[0] ? $_[0] : 'mucus' }
];

$o = validate( $i, $r );
ok $o->{success};
is $o->{data}->{a}, 'mucus';
