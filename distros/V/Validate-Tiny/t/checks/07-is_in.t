use strict;
use warnings;
use Test::More tests => 6;
use Validate::Tiny ':all';

my $r = { fields => [qw/a b/] };

$r->{checks} = [ a => is_in([1,2,3]) ];
ok validate({a => ''}, $r)->{success};
ok !validate({a => '0'}, $r)->{success};
ok validate({a => '0'}, $r)->{error}->{a};
ok validate({a => '3'}, $r)->{success};

$r->{checks} = [ a => is_in([1,2,3], 'NO') ];
is validate({a => '0'}, $r)->{error}->{a}, 'NO';

{
    local $@;
    eval { is_in('boobs') };
    ok $@;
}
