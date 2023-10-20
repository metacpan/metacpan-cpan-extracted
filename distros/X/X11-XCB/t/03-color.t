#!perl
# vim:ts=4:sw=4:expandtab

use Test::More tests => 4;
use Test::Deep;
use X11::XCB qw(:all);
use Data::Dumper;

BEGIN {
	use_ok('X11::XCB::Connection') or BAIL_OUT('Unable to load X11::XCB::Connection');
	use_ok('X11::XCB::Color');
}

my $x;

SKIP: {
    eval { $x = X11::XCB::Connection->new; };

    skip "Could not setup X11 connection", 2 if $@ or $x->has_error();

    my $color = $x->color(hexcode => 'C0C0C0');
    is($color->pixel, 12632256, 'grey colorpixel matches');

    $color = $x->color(hexcode => '#C0C0C0');
    is($color->pixel, 12632256, 'grey colorpixel matches with #');
}

diag( "Testing X11::XCB, Perl $], $^X" );
