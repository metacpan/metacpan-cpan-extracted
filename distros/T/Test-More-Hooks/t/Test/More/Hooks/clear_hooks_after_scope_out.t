use strict;
use warnings;

use Test::More;
use Test::More::Hooks;

my $before_call_flag = 0;
my $after_call_flag  = 0;
subtest "register before and after hooks" => sub {
    before { $before_call_flag = 1; };
    after  { $after_call_flag  = 1; };

    is $before_call_flag, 0;
    is $after_call_flag, 0;

    subtest "called hook" => sub {
        is $before_call_flag, 1;
    };
    is $after_call_flag, 1;
};

$before_call_flag = 0;
$after_call_flag  = 0;

subtest "clear hooks" => sub {
    subtest "don't called hook" => sub {
        is $before_call_flag, 0;
    };
    is $after_call_flag, 0;
};

done_testing;
