#!perl -w

use strict;
use warnings;

use Test::More tests => 7;
use Text::Widont;


my ( $original, $returned, $expected );


# Make sure the nbsp constant was exported correctly...
$expected = {
    html     => '&nbsp;',
    html_dec => '&#160;',
    html_hex => '&#xA0;',
    unicode  => pack( 'U', 0x00A0 ),
};
is_deeply( nbsp, $expected, 'nbsp constant exported correctly');


# functional interface - single string
is(
    widont( 'foo bar baz', nbsp->{html} ),
    'foo bar&nbsp;baz',
    'functional - single string'
);


# functional interface - multiple strings
$original = [ 'foo bar baz', 'goo car caz' ];
$expected = [ 'foo bar&nbsp;baz', 'goo car&nbsp;caz' ];
$returned = widont( $original, nbsp->{html} );

is_deeply( $original, $expected, 'functional - multiple strings - original' );
is_deeply( $returned, $expected, 'functional - multiple strings - returned' );



my $tw = Text::Widont->new( nbsp => nbsp->{html} );

# object interface - single string
is(
    $tw->widont( 'foo bar baz' ),
    'foo bar&nbsp;baz',
    'object - single string'
);


# object interface - multiple strings
$original = [ 'foo bar baz', 'goo car caz' ];
$expected = [ 'foo bar&nbsp;baz', 'goo car&nbsp;caz' ];
$returned = $tw->widont( $original );

is_deeply( $original, $expected, 'object - multiple strings - original' );
is_deeply( $returned, $expected, 'object - multiple strings - returned' );
