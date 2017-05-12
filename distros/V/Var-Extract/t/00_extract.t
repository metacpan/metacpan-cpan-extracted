#!perl 

use strict;
use warnings;
use Test::More tests => 3;
use Class::Struct qw(struct);

BEGIN {
    use_ok("Var::Extract", qw(vars_from_hash vars_from_getters));
}
use Var::Extract qw(vars_from_hash);
my $h = {
    foo => 'FOO',
    bar => 'BAR',
    baz => 'BAZ',
};

vars_from_hash($h, my ($foo,$bar,$baz));
is ($foo.$bar.$baz, "FOOBARBAZ", "from hash");
#eval {
#    vars_from_hash($h, my (%h,@a))
#};
#like ($@, qr/must be scalar/i, "Die on non-scalar lexical");

struct Klass => [ map {"get_".$_."2" => '$'} qw(foo bar baz) ];
my $klass = Klass->new(
    get_foo2 => 'FOO2',
    get_bar2 => 'BAR2',
    get_baz2 => 'BAZ2');

vars_from_getters("get_", $klass, my ($foo2,$bar2,$baz2));
is ($foo2.$bar2.$baz2, "FOO2BAR2BAZ2", "from class accessors");