use warnings;
use strict;
use Test::More;
use Test::Output qw(stderr_from);

my $test_counter = 0;

use_ok 'Zabbix::Sender';
$test_counter++;

# Use various forms of bulk_buf_add method, then retreive accumulated buffer
# using bulk_buf method and compare it with what is expected.

my $host = 'sender';
my $zs = Zabbix::Sender->new( server => 'server', hostname => $host );

# Catch output of carp call from Zabbix::Sender
my $out = stderr_from {
    # Valid usage of bulk_buf_add, these should accumulate in the buffer
    $zs->bulk_buf_add('k11', 'v11', 1234567811, 'k12', 'v12');
    $zs->bulk_buf_add(['k21', 'v21', undef], ['k22', 'v22', 1234567822]);
    $zs->bulk_buf_add(
        'host31', [ ['k31', 'v31', '1234567831'], ['k32', 'v32', ''] ],
        'host32', [ ['k33', 'v33'], ['k34', 'v34', 1234567834] ]);
    # Invalid usage, these shouldn't get to the buffer
    $zs->bulk_buf_add('k');
    $zs->bulk_buf_add({'k' => 'v61'});
    $zs->bulk_buf_add(['k']);
    $zs->bulk_buf_add(['k', 'v', 1, 'dummy']);
    $zs->bulk_buf_add('h', ['k', 'v']);
    $zs->bulk_buf_add('h', {'k' => 'v'});
};

# What we should get
my $test_result = [
    [ 'sender', 'k11', 'v11', 1234567811 ],
    [ 'sender', 'k12', 'v12', 'SOME_NUMBER' ],
    [ 'sender', 'k21', 'v21', 'SOME_NUMBER' ],
    [ 'sender', 'k22', 'v22', 1234567822 ],
    [ 'host31', 'k31', 'v31', 1234567831 ],
    [ 'host31', 'k32', 'v32', 'SOME_NUMBER' ],
    [ 'host32', 'k33', 'v33', 'SOME_NUMBER' ],
    [ 'host32', 'k34', 'v34', 1234567834 ],
];

# Do the tests

my $result = $zs->bulk_buf();
ok(ref($result) eq 'ARRAY', "Buffer valid");
$test_counter++;

for my $i (0 .. $#{$result}) {
    my $t = $test_result->[$i];
    my $r = $result->[$i];

    is($t->[0], $r->[0], "Host $i");
    is($t->[1], $r->[1], "Key $i");
    is($t->[2], $r->[2], "Value $i");
    if ($t->[3] eq 'SOME_NUMBER') {
        like($r->[3], qr/^\d+$/, "Clock $i");
    } else {
        is($t->[3], $r->[3], "Clock $i");
    }
    $test_counter += 4;
}

# Now clear the buffer and check if it's empty
$zs->bulk_buf_clear();
$result = $zs->bulk_buf();
cmp_ok(scalar @{$result}, '==', 0, "Buffer empty");
$test_counter++;

done_testing($test_counter);
