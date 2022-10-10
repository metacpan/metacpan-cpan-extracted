use strict;
use warnings;

use Test2::V0;
use Text::HyperScript qw(h raw true);

sub main {

    # tag only
    is( h('hr'),   '<hr />',         'tag only' );
    is( h('<hr>'), '<&lt;hr&gt; />', 'tag only but with escape' );

    # tag with content
    is( h( 'p', 'hi,' ),           '<p>hi,</p>',          'tag with simple content' );
    is( h( 'p', ['hi,'] ),         '<p>hi,</p>',          'tag with simple content but passed by array ref' );
    is( h( 'p', '<hr />' ),        '<p>&lt;hr /&gt;</p>', 'tag with content but need escape' );
    is( h( 'p', raw('<hr />') ),   '<p><hr /></p>',       'tag with raw html content' );
    is( h( 'p', h( 'b', 'hi,' ) ), '<p><b>hi,</b></p>',   'tag with nested html content' );

    # tag with attributes
    is( h( 'hr', { id      => 'id' } ),                   '<hr id="id" />',                   'tag with simple attributes' );
    is( h( 'hr', { id      => 'id', class => 'class' } ), '<hr class="class" id="id" />',     'tag with multiple attributes' );
    is( h( 'hr', { class   => [qw(foo bar baz)] } ),      '<hr class="bar baz foo" />',       'tag with multiple attribute values by array ref' );
    is( h( 'hr', { "<foo>" => "<bar>" } ),                '<hr &lt;foo&gt;="&lt;bar&gt;" />', 'tag with attribute but need escape' );
    is( h( 'hr', { "<foo>" => ["<bar>"] } ),              '<hr &lt;foo&gt;="&lt;bar&gt;" />', 'tag with multiple attributes but need escape' );

    is( h( 'script', { crossorigin => true }, '' ), '<script crossorigin></script>', 'tag with value-less attribute' );

    # tag with prefixed attribute
    is( h( "hr", { data => { id     => 'id' } } ),                   '<hr data-id="id" />',                    'tag with prefixed attribute' );
    is( h( "hr", { data => { id     => 'id', class => 'class' } } ), '<hr data-class="class" data-id="id" />', 'tag with prefixed attribute' );
    is( h( 'hr', { data => { key    => [qw(foo bar baz)] } } ), '<hr data-key="bar baz foo" />', 'tag with multiple prefixed attribute values by array ref' );
    is( h( "hr", { data => { "<id>" => '<id>' } } ),   '<hr data-&lt;id&gt;="&lt;id&gt;" />',    'tag with prefixed attribute but need escape' );
    is( h( "hr", { data => { "<id>" => ['<id>'] } } ), '<hr data-&lt;id&gt;="&lt;id&gt;" />',    'tag with prefixed attribute by array ref but need escape' );
    is( h( 'hr', { data => { key    => true } } ),     '<hr data-key />',                        'tag with value-less attribute' );

    # example
    is(
        h( 'p', { id => 'msg' }, h( 'b', [ 'hello', 'world' ], { data => { value => '<foo>' } } ) ),
        '<p id="msg"><b data-value="&lt;foo&gt;">helloworld</b></p>',
        'complex example code',
    );

    done_testing;
}

main;
