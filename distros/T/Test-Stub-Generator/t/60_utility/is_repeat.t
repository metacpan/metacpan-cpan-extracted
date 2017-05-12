use strict;
use warnings;

use Test::More;
use Test::Stub::Generator qw(make_method_utils);

package main;

my ($method, $util);
($method, $util) = make_method_utils(
    { expects => [0], return => 1 },
    { is_repeat => 1 },
);
ok($util->is_repeat, 'repeat');

($method, $util) = make_method_utils {
    expects => [0], return => 1
};
ok(!$util->is_repeat, 'no repeat');

done_testing;
