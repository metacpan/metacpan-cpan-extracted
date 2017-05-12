#!perl

use lib 't';
use warnings;
no warnings qw 'utf8 parenthesis regexp once qw bareword';

use Test::More;
use URI'file;
use WWW::Scripter;

use tests 15;

$w = new WWW::Scripter;
$w->get(my $url = new_abs URI'file "t/fragments.html");
my $response = $w->response;
$w->follow_link(n=>1);
is $w->response, $response,'same response object after clicking frag link';
is $w->location, "$url#bdext", 'location after clicking frag link';
is $w->uri, $url, 'same ->uri after clicking frag link';
$w->follow_link(n=>2);
is $w->response, $response,
 'same response object after clicking 2nd frag link';
is $w->location, "$url#dwed", 'location after clicking second frag link';
is $w->uri, $url, 'same ->uri after clicking second frag link';
$w->get($url = new_abs URI'file "t/blank.html");
cmp_ok my $new_response = $w->response, '!=', $response,
 'different response object after loading unrelated url';
is $w->location, $url, 'location after loading unrelated URL';
is $w->uri, $url, '->uri after loading unrelated URL';
$w->get("$url#clit");
is $w->response, $new_response,
 'response is the same after fetching fraggy URL with ->get';
is $w->location, "$url#clit", q"URL is updated too (with ->get($fraggy))";
is $w->uri, $url, 'but ->uri is still the same (with ->get)';
$w->get("about:blank#foo");
is $w->uri, "about:blank",
 'URL used when fetching fraggy URL directly (not adding to existing URL)';

$w->get("data:text/html,");
$w->get("#foo");
is $w->location, "data:text/html,#foo", 'location with data: and fragment';
is $w->uri, 'data:text/html,', '->uri after fetching frag on data: page';
