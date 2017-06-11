use strict;
use warnings;

use Test2::API qw( intercept );
use Test2::Bundle::Extended;
use Test2::Plugin::NoWarnings;

my $events = intercept {
    ok(1);
    warn 'Oh noes!';
    ok(2);
};

is(
    $events,
    array {
        event Ok => sub {
            call pass => T();
        };
        event Ok => sub {
            call causes_fail      => T();
            call increments_count => T();
            call name             => match qr/^Unexpected warning: Oh noes!/;
        };
        event Ok => sub {
            call pass => T();
        };
        end();
    }
);

done_testing();
