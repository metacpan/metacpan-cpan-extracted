use strict;
use warnings;

use Test::More tests => 28;

use_ok( 'URI::Template' );

#   new, empty template
{
    my $template = URI::Template->new;
    isa_ok( $template, 'URI::Template' );

    {
        my $result = $template->process();
        is( $result, '', 'process() for empty template' );
        isa_ok( $result, 'URI', 'return value from process() isa URI' );
    }
}

#   "0" as a template
{
    my $template = URI::Template->new( '0' );
    isa_ok( $template, 'URI::Template' );
    is( $template->template, '0', 'template() is "0"' );

    {
        my $result = $template->process();
        is( $result, '0', 'process() for "0" template' );
        isa_ok( $result, 'URI', 'return value from process() isa URI' );
    }

    # set template back to empty
    $template->template( '' );
    is( $template->template, '', 'template() is empty' );

    {
        my $result = $template->process();
        is( $result, '', 'process() for new empty template' );
        isa_ok( $result, 'URI', 'return value from process() isa URI' );
    }
}

#   Update template
{
    my $template = URI::Template->new;
    is( "$template", '', 'stringify from empty' );

    my $text = 'http://foo.com/{bar}/{baz}';
    $template->template($text);

    is( "$template", $text, 'stringify from updated template' );

    {
        my $result = $template->process( bar => 'x', baz => 'y' );
        is( $result, 'http://foo.com/x/y', 'process() for updated template' );
        isa_ok( $result, 'URI', 'return value from process() isa URI' );
    }
}

{
    my $text     = 'http://foo.com/{bar}/{baz}?{foo}=%7B&{abr}=1';
    my $template = URI::Template->new( $text );
    isa_ok( $template, 'URI::Template' );
    is_deeply( [ $template->variables ], [ 'bar', 'baz', 'foo', 'abr' ], 'variables() in order of appearance' );
    is( "$template", $text, 'stringify' );

    {
        my $result = $template->process( bar => 'x', baz => 'y', foo => 'b', abr => 'a' );
        is( $result, 'http://foo.com/x/y?b=%7B&a=1', 'process()' );
        isa_ok( $result, 'URI', 'return value from process() isa URI' );
    }
    {
        my $result = $template->process_to_string( bar => 'x', baz => 'y', foo => 'b', abr => 'a' );
        is( $result, 'http://foo.com/x/y?b=%7B&a=1', 'process_to_string()' );
        ok( !ref $result, 'result is not a ref' );
    }
}

{
    my $template = URI::Template->new( 'http://foo.com/{z(}/' );
    my $result = $template->process( 'z(' => 'x' );
    is( $result, 'http://foo.com/x/', 'potential regex issue escaped' );
}

{
    my $template = URI::Template->new( 'http://foo.com/{z}/' );
    {
        my $result = $template->process( 'z' => '{x}' );
        is( $result, 'http://foo.com/%7Bx%7D/', 'values are uri escaped' );
    }
    {
        my $result = $template->process();
        is( $result, 'http://foo.com//', 'no value sent' );
    }
    {
        my $result = $template->process( 'y' => '1' );
        is( $result, 'http://foo.com//', 'no valid keys used' );
    }
}

{
    my $template = URI::Template->new( 'http://foo.com/{z}/{z}/' );
    is_deeply( [ sort $template->variables ], [ 'z' ], 'no duplicates in variables()' );
    my $result = $template->process( 'z' => 'x' );
    is( $result, 'http://foo.com/x/x/', 'multiple replaces' );
}

