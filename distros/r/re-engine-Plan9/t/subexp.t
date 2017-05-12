=pod

=cut

use Test::More tests => 3;
use re::engine::Plan9;

# Croaks on 32
my $subexp = 31;
my $s = "a" x $subexp;
my $r = ("(.)" x $subexp);

$s =~ $r;

is($15, "a");
is($31, "a");
is($32, undef);
