# -*- Mode: Perl -*-

package One;

# BEGIN {$mcoder::debug=1}

use mcoder new => qw(new),
    [qw(set get)] => [qw(runner walker)],
    [qw(calculated delete undef set)] => qw(weight),
    [qw(bool_set bool_unset get)] => qw(is_good),
    [qw(array_set array_calculated)] => qw(sons),
    virtual => q(dont);

sub _calculate_sons { qw(melany john eneko) }

sub _calculate_weight {
    return 70;
}

package testing;

use Test::More tests => 16;

my $o;
ok($o=One->new(walker=>'lucas grihander'), 'constructor');

is($o->weight, 70, "weight");
is($o->weight, 70, "weight cached");

is($o->set_weight(50), 50, "set_weight");

# use Data::Dumper;
# print STDERR Dumper $o;

is($o->weight, 50, "weight");

$o->undef_weight;

is($o->weight, 70, "undefined weight");

$o->delete_weight;

is($o->weight, 70, "deleted weight");

is($o->set_runner('pecador'), 'pecador', 'set');

is($o->walker, 'lucas grihander', 'get after ctor');

is($o->runner, 'pecador', 'cobarde, pecador, aigg!');

$o->set_is_good;
ok($o->is_good, 'good');

$o->unset_is_good;
ok(!$o->is_good, 'bad');

$o->set_is_good(4);
is($o->is_good, 4, 'good 4');

is_deeply([$o->sons], [qw(melany john eneko)], 'sons');
is_deeply([$o->sons], [qw(melany john eneko)], 'sons cached');

$o->set_sons;
is_deeply([$o->sons], [], 'empty sons');
