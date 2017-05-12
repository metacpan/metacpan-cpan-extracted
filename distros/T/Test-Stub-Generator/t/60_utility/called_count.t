use strict;
use warnings;

use Test::More;
use Test::Stub::Generator qw(make_method_utils);

package Some::Class;
sub new { bless {}, shift }
sub increment;

package main;

my ($method, $util) = make_method_utils(
    { expects => [0], return => 1 },
    { is_repeat => 1 }
);

my $obj = Some::Class->new;
*Some::Class::increment = $method;

is $util->called_count, 0, 'called_count';
$obj->increment(0);
is $util->called_count, 1, 'called_count';
$obj->increment(0);
is $util->called_count, 2, 'called_count';
$obj->increment(0);
is $util->called_count, 3, 'called_count';
$obj->increment(0);

done_testing;
