
use strict;
use warnings;
use Test::More tests => 6;
use Validate::Tiny ':all';

my $r = { fields => [qw/a b/] };

$r->{checks} = [ a => is_equal('b') ];
ok validate({a => '', b => 1}, $r)->{success};
ok !validate({a => '0', b => ''}, $r)->{success};
ok validate({a => '1', b => '1'}, $r)->{success};

$r->{checks} = [ a => [is_required(), is_equal('b')] ];
ok !validate({a => '', b => ''}, $r)->{success};
ok !validate({a => '', b => '1'}, $r)->{success};

$r->{checks} = [ a => [is_equal('b', 'NO')] ];
my $e = validate( {a => '1', b => '2'}, $r );
is $e->{error}->{a}, 'NO';
