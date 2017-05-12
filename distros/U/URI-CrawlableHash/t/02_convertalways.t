use Test::More;

use URI;
BEGIN { use_ok 'URI::CrawlableHash' }

my $guard = URI::CrawlableHash->convert_always("query");

my $uri2 = URI->new("http://example.com/#!key1=value1&key2=value2");
is ($uri2, "http://example.com/?_escaped_fragment_=key1=value1%26key2=value2", "always to query");

undef $guard;
$uri2 = URI->new("http://example.com/#!key1=value1&key2=value2");
is ($uri2, "http://example.com/#!key1=value1&key2=value2", "restore");


$guard = URI::CrawlableHash->convert_always("hash");
my $uri = URI->new('http://example.com/?_escaped_fragment_=key1=value1%26key2=value2', "always to pretty");
is ($uri,  "http://example.com/#!key1=value1&key2=value2", "to hash");

undef $guard;
$uri = URI->new('http://example.com/?_escaped_fragment_=key1=value1%26key2=value2', "restore");
is ($uri, "http://example.com/?_escaped_fragment_=key1=value1%26key2=value2");






done_testing;

