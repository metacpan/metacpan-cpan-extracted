#!perl
# vim:ts=4:sw=4:expandtab

use Test::More tests => 6;
use Test::Deep;
use X11::XCB qw(:all);
use List::Util qw(first);

BEGIN {
	use_ok('X11::XCB::Connection') or BAIL_OUT('Unable to load X11::XCB::Connection');
	use_ok('X11::XCB::Screen');
}

my $x;

SKIP: {
    eval { $x = X11::XCB::Connection->new; };

    skip "Could not setup X11 connection", 4 if $@ or $x->has_error();

    my $screens = $x->screens;
    my $first = first { 1 } @{$screens};
    isa_ok($first, 'X11::XCB::Screen');

    my $primary = first { $_->primary } @{$screens};
    isa_ok($primary, 'X11::XCB::Screen');
    is($primary->rect->x, 0, 'primary screens x == 0');
    is($primary->rect->y, 0, 'primary screens y == 0');
}

diag( "Testing X11::XCB, Perl $], $^X" );
