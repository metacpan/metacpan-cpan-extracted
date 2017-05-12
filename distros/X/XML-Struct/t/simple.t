use strict;
use Test::More;
use XML::Struct::Simple;

my $micro = [ 
    root => { xmlns => 'http://example.org/' }, 
    [ '!', [ x => {}, [42] ] ]
];

sub convert {
    XML::Struct::Simple->new(@_)->transform($micro)
}

is_deeply convert( root => 'record' ),
    { record => { xmlns => 'http://example.org/', x => 42 } },
    'synopsis';

is_deeply convert(),
    { xmlns => 'http://example.org/', x => 42 },
    'root disabled by default';

is_deeply convert( root => 1 ),
    { root => { xmlns => 'http://example.org/', x => 42 } },
    'root enabled';

is_deeply convert( depth => 0 ), 
    $micro, 
    'depth 0';

is_deeply explain convert( depth => 1 ),
    { xmlns => 'http://example.org/', x => [ [ x => {}, [42] ] ] },
    'depth 1';

is_deeply convert( depth => 1, root => 'r' ),
    { r => { xmlns => 'http://example.org/', x => [ [ x => {}, [42] ] ] } },
    'depth 1, root';

foreach ('remove','0') {
    is_deeply convert( root => 1, attributes => $_ ),
        { root => { x => 42 } },
        'remove attributes';
}

is_deeply(
    XML::Struct::Simple->new->transform(
    [ root => [ ['text'] ] ] ),
    { text => {} }, 'empty tag');

# this was a bug until 0.25
is_deeply(
    XML::Struct::Simple->new->transform(
    [ root => [ ['text', {} ] ] ] ),
    { text => {} }, 'empty tag, no attributes');

is_deeply(
    XML::Struct::Simple->new( root => 1 )->transform( [ 'root' ] ),
    { root => {} }, 'empty <root/>');

is_deeply( XML::Struct::Simple->new->transform( [ root => ['text'] ] ),
    { root => 'text' }, 'special case <root>text</root>');

is_deeply( XML::Struct::Simple->new->transform(
    [ root => { x => 1 }, [] ] ),
    { x => 1 }, 'attributes only');

is_deeply( XML::Struct::Simple->new->transform(
    [ root => { x => 1 }, ['text'] ] ),
    { x => 1, content => 'text' }, 'mix attributes and text content');

done_testing;
