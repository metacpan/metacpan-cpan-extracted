# @(#) $Id$

use strict;
use warnings;

use Test::More;

BEGIN {
    foreach ( qw( XML::Twig ) ) {
        eval "use $_";
        plan skip_all => "$_ not present" if $@;
    }
}

use Test::XML::Twig;

plan tests => 10;

#---------------------------------------------------------------------

sub handler {
    my ( $t, $el ) = @_;
    $el->set_gi( 'bar' );
}

#---------------------------------------------------------------------

my $t = get_twig( '>' );
is( $t, undef, 'get_twig() bad input' );

$t = get_twig( '<foo/>' );
isa_ok( $t, 'XML::Twig' );

#---------------------------------------------------------------------

eval { test_twig_handler() };
like( $@, qr/^usage: /, 'test_twig_handler() no args failure' );

eval { test_twig_handler( \&handler ) };
like( $@, qr/^usage: /, 'test_twig_handler() 1 args failure' );

eval { test_twig_handler( \&handler, '<foo/>' ) };
like( $@, qr/^usage: /, 'test_twig_handler() 2 args failure' );

eval { test_twig_handler( \&handler, '<foo/>', '<bar/>' ) };
like( $@, qr/^usage: /, 'test_twig_handler() 3 args failure' );

eval { test_twig_handler( 'handler', '<foo/>', '<bar/>', 'testname' ) };
like( $@, qr/^usage: /, 'test_twig_handler() arg 1 type failure' );

test_twig_handler(
    \&handler,
    '<foo />',
    '<bar></bar>',
    'test_twig_handler() with handler()',
);

test_twig_handler(
    \&handler,
    '<foo />',
    qr/\bbar\b/,
    'test_twig_handler() with qr//',
);

#---------------------------------------------------------------------

test_twig_handlers(
    { start_tag_handlers => { 'foo' => \&handler } },
    '<foo />',
    '<bar></bar>',
    'test_twig_handlers() with handler()',
);

# Local Variables:
# mode: cperl
# cperl-indent-level: 4
# indent-tabs-mode: nil
# End:
# vim: set ai et sw=4 syntax=perl :
