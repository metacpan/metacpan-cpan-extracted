use strict;
use Test::More skip_all => "these are not the tests you're looking for";
use Test::RequiresInternet 0.05 'httpstatuses.com' => 443;

use URI::Fetch;
use Data::Dumper;

use constant URI_OK    => 'https://httpstatuses.com/200';

my($res, $xml, $etag, $mtime);

## Test a regular fetch using a cache and alternate freeze/thaw.
my $cache = My::Cache->new;
$res = URI::Fetch->fetch(URI_OK, Cache => $cache, Freeze=>\&freeze, Thaw=>\&thaw);
ok($res);
is($res->http_status, 200);
# ok($etag = $res->etag);
ok($mtime = $res->last_modified);
ok($xml = $res->content);

## Now hit the same URI again using the same cache and see if it has the
## the correct info to get a 304 back.
$res = URI::Fetch->fetch(URI_OK, Cache => $cache, Freeze=>\&freeze, Thaw=>\&thaw);
ok($res);
is($res->http_status, 304);
is($res->status, URI::Fetch::URI_NOT_MODIFIED());
is($res->etag, $etag);
is($res->last_modified, $mtime);
is($res->content, $xml);

done_testing();


#--- alternate freeze/thaw routine

sub freeze {
    my $data = shift; # ref to data structure
    my $d = Data::Dumper->new([$data],['data']);
    $d->Dump;
}

sub thaw {
    my $data; 
    eval shift;     # string from previous data dump
    $data;
}

#--- simple in memory cache object

package My::Cache;
sub new { bless {}, shift }
sub get { $_[0]->{ $_[1] } }
sub set { $_[0]->{ $_[1] } = $_[2] }
