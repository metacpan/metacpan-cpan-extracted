use strict;
use warnings;

use Test2::V0;
use Text::HyperScript qw(raw);

sub main {
    my $raw = raw('<p>hello, world!</p>');

    isa_ok( $raw, 'Text::HyperScript::Element' );

    is( $raw->markup, '<p>hello, world!</p>' );
    is( "${raw}",     '<p>hello, world!</p>' );

    done_testing;
}

main;
