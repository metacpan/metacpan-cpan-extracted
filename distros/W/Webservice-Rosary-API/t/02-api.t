use strict;
use warnings;
use Test::More;

use Webservice::Rosary::API;

{
  package Local::MockUA;

  sub new {
    my $class = shift;
    return bless { responses => [ @_ ], calls => [] }, $class;
  }

  sub get {
    my ($self, $url) = @_;
    push @{ $self->{calls} }, $url;
    my $response = shift @{ $self->{responses} };
    die "mock transport failure" if ref($response) eq 'HASH' and $response->{die};
    return $response;
  }

  sub calls { return scalar @{ $_[0]->{calls} }; }
}

sub ok_response {
  my $content = shift;
  return {
    success => 1,
    status  => 200,
    reason  => 'OK',
    content => $content,
  };
}

my $ua = Local::MockUA->new(
  ok_response('[{"group_by":"Joyful"}]'),
);
my $rosary = Webservice::Rosary::API->new(ua => $ua, cache_ttl => 60);
is($rosary->ua, $ua, 'constructor preserves an injected user agent');
is($rosary->day('nonesuch'), '', 'invalid day returns empty string');
is($ua->calls, 0, 'invalid day does not make an HTTP call');

my $saturday = $rosary->day('Saturday');
is($saturday->group_by, 'Joyful', 'Saturday is accepted and decoded');
is($ua->calls, 1, 'Saturday made one HTTP call');

my $again = $rosary->day('saturday');
is($again->group_by, 'Joyful', 'fresh cached day response is decoded again');
is($ua->calls, 1, 'fresh cache avoids a duplicate HTTP call');

$rosary->clear_cache;
is(scalar keys %{ $rosary->cache }, 0, 'clear_cache empties the in-memory cache');

my $fallback_ua = Local::MockUA->new(
  ok_response('[{"group_by":"Sorrowful"}]'),
  { success => 0, status => 503, reason => 'Unavailable', content => '' },
);
my $fallback = Webservice::Rosary::API->new(ua => $fallback_ua, cache_ttl => 60);
is($fallback->day('friday')->group_by, 'Sorrowful', 'successful response is returned before fallback test');
my $url = 'https://the-rosary-api.vercel.app/v1/friday';
$fallback->cache->{$url}->{stored_at} = 0;
my $warning = '';
{
  local $SIG{__WARN__} = sub { $warning .= shift };
  is($fallback->day('friday')->group_by, 'Sorrowful', 'stale cache is used after an HTTP failure');
}
like($warning, qr/using cached Rosary API response/, 'stale cache fallback emits a warning');
is($fallback_ua->calls, 2, 'stale entry triggers a network retry before fallback');

my $error_ua = Local::MockUA->new(
  { success => 0, status => 503, reason => 'Unavailable', content => '' },
);
my $error_client = Webservice::Rosary::API->new(ua => $error_ua, cache_ttl => 0);
my $ok = eval { $error_client->day('monday'); 1 };
ok(!$ok, 'HTTP failure without cache dies cleanly');
like($@, qr/HTTP 503 Unavailable/, 'HTTP failure reports status and reason');

my $die_ua = Local::MockUA->new({ die => 1 });
my $die_client = Webservice::Rosary::API->new(ua => $die_ua, cache_ttl => 0);
$ok = eval { $die_client->day('monday'); 1 };
ok(!$ok, 'transport exception is caught and rethrown cleanly');
like($@, qr/mock transport failure/, 'transport error text is preserved');

my $bad_json = Webservice::Rosary::API->new(
  ua => Local::MockUA->new(ok_response('{not json')),
  cache_ttl => 0,
);
$ok = eval { $bad_json->day('monday'); 1 };
ok(!$ok, 'malformed JSON dies cleanly');
like($@, qr/invalid JSON/, 'malformed JSON has a descriptive error');

my $bad_http = Webservice::Rosary::API->new(
  ua => Local::MockUA->new('not a response hash'),
  cache_ttl => 0,
);
$ok = eval { $bad_http->day('monday'); 1 };
ok(!$ok, 'invalid HTTP response shape dies cleanly');
like($@, qr/invalid HTTP response/, 'invalid HTTP response shape is described');

my $mp3_array = Webservice::Rosary::API->new(
  ua => Local::MockUA->new(ok_response('[{"mp3Link":"array.mp3"}]')),
  cache_ttl => 0,
);
is(
  $mp3_array->mp3Link('today'),
  'https://dailyrosary.catholicdevotion.org/array.mp3',
  'single-item array MP3 response uses its first item',
);

my $mp3_hash = Webservice::Rosary::API->new(
  ua => Local::MockUA->new(ok_response('{"mp3Link":"legacy.mp3"}')),
  cache_ttl => 0,
);
is(
  $mp3_hash->mp3Link('tomorrow'),
  'https://dailyrosary.catholicdevotion.org/legacy.mp3',
  'legacy hash MP3 response remains supported',
);

my $empty_mp3 = Webservice::Rosary::API->new(
  ua => Local::MockUA->new(ok_response('[]')),
  cache_ttl => 0,
);
$warning = '';
{
  local $SIG{__WARN__} = sub { $warning .= shift };
  $ok = eval { $empty_mp3->mp3Link('today'); 1 };
}
ok(!$ok, 'empty MP3 response dies');
like($warning, qr/No MP3 content/, 'empty MP3 response gives recovery guidance');
like($@, qr/no MP3 link/i, 'empty MP3 response has a concise exception');

my $random_ua = Local::MockUA->new(
  ok_response('[{"mp3Link":"one.mp3"}]'),
  ok_response('[{"mp3Link":"two.mp3"}]'),
);
my $random = Webservice::Rosary::API->new(ua => $random_ua, cache_ttl => 60);
is($random->mp3Link('random'), 'https://dailyrosary.catholicdevotion.org/one.mp3', 'first random MP3 request succeeds');
is($random->mp3Link('random'), 'https://dailyrosary.catholicdevotion.org/two.mp3', 'random MP3 is not served from fresh cache');
is($random_ua->calls, 2, 'random endpoint is requested each time');

my $details_ua = Local::MockUA->new(
  ok_response('[{"title":"First Joyful Mystery"}]'),
);
my $details = Webservice::Rosary::API->new(ua => $details_ua, cache_ttl => 0);
my $full = $details->details('joyful');
is($full->[0]->title, 'First Joyful Mystery', 'details returns decoded mystery data');
is($details->details('unknown'), '', 'invalid mystery name returns empty string');
is($details_ua->calls, 1, 'invalid mystery name does not make an HTTP call');

done_testing;

