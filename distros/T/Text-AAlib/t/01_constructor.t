use strict;
use warnings;

use Test::More;
use Text::AAlib;

my $aa = Text::AAlib->new(
    width  => 100,
    height => 100,
);

ok $aa, "constructor";
ok $aa->{_context}, "pointer of struct aa_context*";
for my $key (qw/is_closed/) {
    ok $aa->{$key} == 0, "initialize '$key' parameter";
}

done_testing;
