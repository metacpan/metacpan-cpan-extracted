use strict;
use warnings;

use Test::More tests => 4;

use_ok( 'URI::Template' );

# variables w/ context
{
    my $text     = 'http://foo.com/{bar}/{baz}?{foo}=%7B&{abr}=1';
    my $template = URI::Template->new( $text );
    isa_ok( $template, 'URI::Template' );
    my @l_vars = $template->variables;
    is_deeply( \@l_vars, [ 'bar', 'baz', 'foo', 'abr' ], 'variables() in list context' );
    my $s_vars = $template->variables;
    is( $s_vars, 4, 'variables() in scalar context' );
}

