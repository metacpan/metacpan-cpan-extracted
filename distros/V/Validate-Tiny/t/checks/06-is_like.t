use strict;
use warnings;
use Test::More tests => 6;
use Validate::Tiny ':all';

my $r = { fields => [qw/a b/] };

$r->{checks} = [ a => is_like(qr/^[a-z]$/) ];
ok validate({a => ''}, $r)->{success};
ok !validate({a => '0'}, $r)->{success};
ok validate({a => '0'}, $r)->{error}->{a};
ok validate({a => 'a'}, $r)->{success};

$r->{checks} = [ a => is_like(qr/^[a-z]$/,'NO') ];
is validate({a => '0'}, $r)->{error}->{a}, 'NO';

eval { is_like('non-regex') };
ok $@;
