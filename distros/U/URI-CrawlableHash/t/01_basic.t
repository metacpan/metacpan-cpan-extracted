use Test::More;

BEGIN { use_ok 'URI::CrawlableHash' }

use URI;

my $uri = URI->new('http://example.com/?_escaped_fragment_=key1=value1%26key2=value2');
is ($uri->query_to_fragment,  "http://example.com/#!key1=value1&key2=value2", "to hash");

$uri = URI->new('http://example.com/?user=a&q=b&_escaped_fragment_=key1=value1%26key2=value2');
is ($uri->query_to_fragment,  "http://example.com/?user=a&q=b#!key1=value1&key2=value2", "to hash");



my $uri2 = URI->new("http://example.com/#!key1=value1&key2=value2");
is ($uri2->fragment_to_query, "http://example.com/?_escaped_fragment_=key1=value1%26key2=value2", "to query");

$uri2 = URI->new("http://example.com/path?old_query#!key1=value1&key2=value2");
is ($uri2->fragment_to_query, "http://example.com/path?old_query&_escaped_fragment_=key1=value1%26key2=value2", "to query");

$uri2 = URI->new("http://example.com/path?_escaped_fragment_=hoge#!key1=value1&key2=value2");
is ($uri2->fragment_to_query, "http://example.com/path?_escaped_fragment_=key1=value1%26key2=value2", "to query");


done_testing;

