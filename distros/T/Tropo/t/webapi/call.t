#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;

use_ok 'Tropo::WebAPI::Call';

my $call = Tropo::WebAPI::Call->new(
    to => '+4915212345678',
);

is $call->to, '+4915212345678';

my $error;
eval {
    $call = Tropo::WebAPI::Call->new;
} or $error = 'Missing "to"';
is $error, 'Missing "to"';

done_testing();
