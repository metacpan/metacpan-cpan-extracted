use strict;
use Test::More skip_all => "these are not the tests you're looking for";

use Test::RequiresInternet 0.05 'httpstatuses.com' => 443;
use Test::RequiresInternet 0.05 'httpstat.us' => 443;

use URI::Fetch;

use constant BASE      => 'https://httpstatuses.com/';
# use constant BASE      => 'https://httpstat.us/';
# use constant BASE      => 'http://status.savanttools.com/';
use constant URI_OK    => BASE . '200';
use constant URI_MOVED => BASE . '301';
use constant URI_GONE  => 'https://httpstat.us/410';
use constant URI_ERROR => BASE . 'error.xml';

my($res, $xml, $etag, $mtime);

## Test a basic fetch.
$res = URI::Fetch->fetch(URI_OK);
ok($res);
is($res->status, URI::Fetch::URI_OK());
is($res->http_status, 200);
# ok($etag = $res->etag);
ok($mtime = $res->last_modified);
is($res->uri, URI_OK);
ok($xml = $res->content);


## Test a fetch using last-modified.
$res = URI::Fetch->fetch(URI_OK, LastModified => $mtime);
ok($res);
is($res->http_status, 304);
is($res->status, URI::Fetch::URI_NOT_MODIFIED());
is($res->content, undef);
ok(!$res->is_success);


## Test a fetch using etag.
# $res = URI::Fetch->fetch(URI_OK, ETag => $etag);
# ok($res);
# is($res->http_status, 304);
# is($res->status, URI::Fetch::URI_NOT_MODIFIED());
# is($res->content, undef);
# ok(!$res->is_success);

## Test a fetch using both.
# $res = URI::Fetch->fetch(URI_OK, ETag => $etag, LastModified => $mtime);
# ok($res);
# is($res->http_status, 304);
# is($res->status, URI::Fetch::URI_NOT_MODIFIED());
# is($res->content, undef);
# ok(!$res->is_success);

## Test a regular fetch using a cache.
my $cache = My::Cache->new;
$res = URI::Fetch->fetch(URI_OK, Cache => $cache);
ok($res);
is($res->http_status, 200);
# ok($etag = $res->etag);
ok($mtime = $res->last_modified);
ok($xml = $res->content);

## Now hit the same URI again using the same cache, and hope to
## get back a not-modified response with the full content from the cache.
$res = URI::Fetch->fetch(URI_OK, Cache => $cache);
ok($res);
is($res->http_status, 304);
is($res->status, URI::Fetch::URI_NOT_MODIFIED());
# is($res->etag, $etag);
is($res->last_modified, $mtime);
ok($res->is_success);
is($res->content, $xml);

## Test fetch of "moved permanently" resouce.
$res = URI::Fetch->fetch('https://httpstat.us/301');
# $res = URI::Fetch->fetch(URI_MOVED);
ok($res);
is($res->status, URI::Fetch::URI_MOVED_PERMANENTLY());
# is($res->http_status, 301);
is($res->uri, 'https://httpstat.us');


## Test fetch of "gone" resource.
$res = URI::Fetch->fetch('https://httpstat.us/410');
# $res = URI::Fetch->fetch(URI_GONE);
ok($res);
is($res->status, URI::Fetch::URI_GONE());
is($res->http_status, 410);

## Test fetch of unhandled error.
$res = URI::Fetch->fetch(URI_ERROR);
ok(!$res);
ok(URI::Fetch->errstr);

## Test ForceResponse.
$res = URI::Fetch->fetch(URI_ERROR, ForceResponse => 1);
isa_ok $res, 'URI::Fetch::Response';
is $res->http_status, 404;
ok $res->http_response;

## Test ContentAlterHook, wiping the cache
$cache = My::Cache->new;
$res = URI::Fetch->fetch(URI_OK, Cache => $cache, ContentAlterHook => sub { my $cref = shift; $$cref = "ALTERED."; });
ok($res);
is($res->http_status, 200);
# ok($etag = $res->etag);
ok($mtime = $res->last_modified);
is($res->content, "ALTERED.");

## using the same cache, should still be altered
$res = URI::Fetch->fetch(URI_OK, Cache => $cache);
ok($res);
is($res->http_status, 304);
is($res->content, "ALTERED.");

## Test NoNetwork, wiping the cache
$cache = My::Cache->new;

## Content is not in cache, fetch should return undef
$res = URI::Fetch->fetch(URI_OK, Cache => $cache, NoNetwork => 1);
is($res, undef);

## Put the content in the cache.
$res = URI::Fetch->fetch(URI_OK, Cache => $cache);
ok($res);
is($res->http_status, 200);
ok($xml = $res->content);
$res = URI::Fetch->fetch(URI_OK, Cache => $cache, NoNetwork => 1);
ok($res);
is($res->status, URI::Fetch::URI_OK());
is($res->content, $xml);
ok(!$res->http_status);   ## No http_status or http_response, because
ok(!$res->http_response); ## we skipped the HTTP request entirely.
ok($res->is_success); ## but still is_* should work
ok(!$res->is_error);
ok(!$res->is_redirect);

## Now sleep for 5 seconds, and try to get the content from the cache
## without a network connection, if the cached content is younger than
## 10 seconds. This should work.
sleep 5;
$res = URI::Fetch->fetch(URI_OK, Cache => $cache, NoNetwork => 10);
ok($res);
is($res->status, URI::Fetch::URI_OK());
is($res->content, $xml);
ok(!$res->http_status);   ## No http_status or http_response, because
ok(!$res->http_response); ## we skipped the HTTP request entirely.

## Now try to get the content from the cache, but only if it is younger
## than 2 seconds. It is not, so we should make a full HTTP response
## with Etag and Last-modified, and get back a 304.
$res = URI::Fetch->fetch(URI_OK, Cache => $cache, NoNetwork => 2);
ok($res);
is($res->status, URI::Fetch::URI_NOT_MODIFIED());
is($res->http_status, 304);
ok($res->http_response);
is($res->content, $xml);

## Test CacheEntryGrep.
$cache = My::Cache->new;
$res = URI::Fetch->fetch(URI_OK, Cache => $cache, CacheEntryGrep => sub {
    my($fetch) = @_;
    $fetch->uri ne URI_OK; ## Do not cache this URI.
});
ok($res);
is($res->http_status, 200);
## Make sure the content was not cached (it would be 304 if it were).
$res = URI::Fetch->fetch(URI_OK, Cache => $cache);
ok($res);
is($res->http_status, 200);

done_testing();

package My::Cache;
sub new { bless {}, shift }
sub get { $_[0]->{ $_[1] } }
sub set { $_[0]->{ $_[1] } = $_[2] }

