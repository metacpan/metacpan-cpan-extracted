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
);

my $obj = Some::Class->new;
*Some::Class::increment = $method;

is $util->has_next, 1, 'has_next';
$obj->increment(0);
is $util->has_next, 0, 'empty';

done_testing;
