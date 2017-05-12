use v5.14;
use warnings;
use Test::More;

BEGIN { use_ok('Tweet::ToDelicious') };

subtest 'new_ok' => sub {
    new_ok 'Tweet::ToDelicious';
};

subtest 'can_ok' => sub {
    my $t2d = Tweet::ToDelicious->new({});
    can_ok $t2d, $_ for qw/run delicious/;
};

done_testing;
