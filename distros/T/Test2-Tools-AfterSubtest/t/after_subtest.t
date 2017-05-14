#!/usr/bin/env perl

use strict;
use warnings;
use Test2::Bundle::More;
use Test2::Tools::AfterSubtest qw/after_subtest/;

my $callback_called;
after_subtest(sub {
    $callback_called = 1;
});

ok(!$callback_called, 'Callback has not yet been called');

subtest 'subtest' => sub {
    ok(1, 'subtest runs');
};

ok($callback_called, 'The callback has been called after subtest');

done_testing();
