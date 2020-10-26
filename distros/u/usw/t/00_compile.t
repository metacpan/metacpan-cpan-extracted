use strict;
use Test::More 0.98 tests => 4;

my @list = qw(usw usww);

for (@list) {
    use_ok $_;
    eval "no $_;1" and BAIL_OUT "something wrong. succeeded to call `no $_;`";
    like $@, qr/^$_ doesn't provide `no` pragma/, "successfully deny `no $_` pragma";
}

done_testing;
