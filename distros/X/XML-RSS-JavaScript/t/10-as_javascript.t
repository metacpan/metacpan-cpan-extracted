use strict;
use warnings;
use Test::More tests => 7;

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
    'title'       => 'title2 & test',
    'link'        => 'link2 & test',
    'description' => 'desc2 & test'
);

my $expected = <<'JAVASCRIPT_TEXT';
document.write('<div class=\"rss_feed\">');
document.write('<div class=\"rss_feed_title\">title</div>');
document.write('<ul class=\"rss_item_list\">');
document.write('<li class=\"rss_item\"><span class=\"rss_item_title\"><a class=\"rss_item_link\" href=\"link1\">title1</a></span> <span class=\"rss_item_desc\">desc1</span></li>');
document.write('<li class=\"rss_item\"><span class=\"rss_item_title\"><a class=\"rss_item_link\" href=\"link2 &#x26; test\">title2 &#x26; test</a></span> <span class=\"rss_item_desc\">desc2 &#x26; test</span></li>');
document.write('</ul>');
document.write('</div>');
JAVASCRIPT_TEXT

my $expected_max = <<'JAVASCRIPT_TEXT';
document.write('<div class=\"rss_feed\">');
document.write('<div class=\"rss_feed_title\">title</div>');
document.write('<ul class=\"rss_item_list\">');
document.write('<li class=\"rss_item\"><span class=\"rss_item_title\"><a class=\"rss_item_link\" href=\"link1\">title1</a></span> <span class=\"rss_item_desc\">desc1</span></li>');
document.write('</ul>');
document.write('</div>');
JAVASCRIPT_TEXT

my $expected_nodesc = <<'JAVASCRIPT_TEXT';
document.write('<div class=\"rss_feed\">');
document.write('<div class=\"rss_feed_title\">title</div>');
document.write('<ul class=\"rss_item_list\">');
document.write('<li class=\"rss_item\"><span class=\"rss_item_title\"><a class=\"rss_item_link\" href=\"link1\">title1</a></span></li>');
document.write('<li class=\"rss_item\"><span class=\"rss_item_title\"><a class=\"rss_item_link\" href=\"link2 &#x26; test\">title2 &#x26; test</a></span></li>');
document.write('</ul>');
document.write('</div>');
JAVASCRIPT_TEXT

is( $rss->as_javascript,      $expected,     'as_javascript' );
is( $rss->as_javascript( 1 ), $expected_max, 'as_javascript( max )' );
is( $rss->as_javascript( undef, 0 ),
    $expected_nodesc, 'as_javascript( undef, nodesc )' );
is( $rss->as_javascript( 3 ), $expected, 'as_javascript( max too big )' );
is( $rss->as_javascript( undef, 1 ),
    $expected, 'as_javascript( undef, desc )' );
