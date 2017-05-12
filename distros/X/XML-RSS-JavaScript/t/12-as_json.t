use strict;
use warnings;
use Test::More tests => 6;

use_ok( 'XML::RSS::JavaScript' );
my $rss = XML::RSS::JavaScript->new();
isa_ok( $rss, 'XML::RSS::JavaScript' );

$rss->channel(
    'title'       => 'title',
    'link'        => 'link',
    'description' => 'description'
);

$rss->add_item(
    'title'       => 'title1',
    'link'        => 'link1',
    'description' => 'desc1'
);

$rss->add_item(
    'title'       => 'title2',
    'link'        => 'link2',
    'description' => 'desc2'
);

my $expected = <<'JAVASCRIPT_TEXT';
if(typeof(RSSJSON) == 'undefined') RSSJSON = {}; RSSJSON.posts = [{u:"link1",d:"title1"},{u:"link2",d:"title2"}]
JAVASCRIPT_TEXT
chomp( $expected );

my $expected_max = <<'JAVASCRIPT_TEXT';
if(typeof(RSSJSON) == 'undefined') RSSJSON = {}; RSSJSON.posts = [{u:"link1",d:"title1"}]
JAVASCRIPT_TEXT
chomp( $expected_max );

my $expected_obj = <<'JAVASCRIPT_TEXT';
if(typeof(MyPosts) == 'undefined') MyPosts = {}; MyPosts.posts = [{u:"link1",d:"title1"},{u:"link2",d:"title2"}]
JAVASCRIPT_TEXT
chomp( $expected_obj );

is( $rss->as_json,      $expected,     'as_json' );
is( $rss->as_json( 1 ), $expected_max, 'as_json' );
is( $rss->as_json( 3 ), $expected,     'as_json( max too big )' );
is( $rss->as_json( undef, 'MyPosts' ),
    $expected_obj, 'as_json( custom object )' );
