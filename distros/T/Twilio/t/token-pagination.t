use 5.016;
use warnings;

use lib 't/lib';

use Test::More;

use Local::Resources;

use Twilio::TokenPaginationPage;

my $URL = 'https://api.twilio.com/2010-04-01/Items';

{

  package Local::TokenPage;
  use parent -norequire, 'Twilio::TokenPaginationPage';

  sub build_instance {
    my ($self, $payload) = @_;
    return $payload;
  }
}

subtest 'the next URL comes from the last request and the token' => sub {
  my ($http, $version) =
    fetched(body({ nextToken => 'abc', pageSize => 2 }, 'A'), { Status => 'on' });

  is(
    $version->{page}->get_next_page_url,
    "$URL?Status=on&pageSize=2&pageToken=abc",
    'other parameters stay'
  );
  is($version->{page}->get_previous_page_url, undef, 'no previous page');
};

subtest 'the previous URL' => sub {
  my ($http, $version) = fetched(body({ previousToken => 'old' }, 'A'));

  is($version->{page}->get_previous_page_url, "$URL?pageToken=old", 'built the same way');
  is($version->{page}->get_next_page_url,     undef,                'no next page');
};

subtest 'a token and page size already in the URL are replaced' => sub {
  my ($http, $version) =
    fetched(body({ nextToken => 'new', pageSize => 5 }, 'A'),
    { pageToken => 'old', pageSize => 9 });

  is($version->{page}->get_next_page_url, "$URL?pageSize=5&pageToken=new", 'one of each');
};

subtest 'with no page size in the answer, the one in the URL stays' => sub {
  my ($http, $version) = fetched(body({ nextToken => 'new' }, 'A'), { pageSize => 9 });

  is($version->{page}->get_next_page_url, "$URL?pageSize=9&pageToken=new", 'kept');
};

subtest 'repeated parameters stay' => sub {
  my ($http, $version) = fetched(body({ nextToken => 'new' }, 'A'), { Tag => ['x', 'y'] });

  is($version->{page}->get_next_page_url, "$URL?Tag=x&Tag=y&pageToken=new", 'both values');
};

subtest 'a token is encoded' => sub {
  my ($http, $version) = fetched(body({ nextToken => 'a b/c+d' }, 'A'));

  is($version->{page}->get_next_page_url, "$URL?pageToken=a+b%2Fc%2Bd", 'safe in a URL');
};

subtest 'a repeated token is the end' => sub {
  my ($http, $version) = fetched(body({ nextToken => 'same' }, 'A'), { pageToken => 'same' });
  is($version->{page}->get_next_page_url, undef, 'next');

  ($http, $version) = fetched(body({ previousToken => 'same' }, 'A'), { pageToken => 'same' });
  is($version->{page}->get_previous_page_url, undef, 'previous');
};

subtest 'a repeated token is found through its encoding' => sub {
  my ($http, $version) = fetched(body({ nextToken => 'a b+c/d' }, 'A'), { pageToken => 'a b+c/d' });

  is($version->{page}->get_next_page_url, undef, 'the end');
};

subtest 'an empty token is the end' => sub {
  my ($http, $version) = fetched(body({ nextToken => q{} }, 'A'));
  is($version->{page}->get_next_page_url, undef, 'empty');

  ($http, $version) = fetched(body({ nextToken => undef }, 'A'));
  is($version->{page}->get_next_page_url, undef, 'null');
};

subtest 'a zero is a real token' => sub {
  my ($http, $version) = fetched(body({ nextToken => '0' }, 'A'));

  is($version->{page}->get_next_page_url, "$URL?pageToken=0", 'it is used');
};

subtest 'a stream follows tokens to the end' => sub {
  my ($http, $version) = fetched(body({ nextToken => 'second', pageSize => 1 }, 'A'));
  $http->mock(200, body({ nextToken => 'third', pageSize => 1 }, 'B'));
  $http->mock(200, body({ pageSize  => 1 },                      'C'));

  my $stream = $version->stream($version->{page});
  my @sids;
  while (my $item = $stream->next) {
    push @sids, $item->{sid};
  }

  is_deeply(\@sids, ['A', 'B', 'C'], 'every record');
  is_deeply(
    [map { $_->{url} } $http->requests],
    ["$URL", "$URL?pageSize=1&pageToken=second", "$URL?pageSize=1&pageToken=third"],
    'each page uses the token of the one before'
  );
};

subtest 'a server that repeats its token does not loop forever' => sub {
  my ($http, $version) = fetched(body({ nextToken => 'stuck' }, 'A'));
  $http->mock(200, body({ nextToken => 'stuck' }, 'B'));

  my $stream = $version->stream($version->{page});
  my @sids;
  while (my $item = $stream->next) {
    push @sids, $item->{sid};
  }

  is_deeply(\@sids, ['A', 'B'], 'it stops');
  is(scalar(() = $http->requests), 2, 'after two requests');
};

subtest 'going back' => sub {
  my ($http, $version) = fetched(body({ previousToken => 'back' }, 'B'));
  $http->mock(200, body({}, 'A'));

  my $previous = $version->{page}->previous_page;

  isa_ok($previous, 'Local::TokenPage');
  is(($previous->records)[0]{sid}, 'A', 'its records');
};

subtest 'records' => sub {
  my ($http, $version) =
    fetched({ things => ['one', { sid => 'two' }], meta => { key => 'things' } });
  my $page = $version->{page};

  is_deeply([$page->records], [{ id => 'one' }, { sid => 'two' }], 'a plain value becomes an id');
  $page->rewind;
  is_deeply($page->next, { id => 'one' }, 'next does the same');
};

subtest 'the list is found with no key in meta' => sub {
  my ($http, $version) = fetched({ items => [{ sid => 'A' }], meta => { pageSize => 1 } });

  is(($version->{page}->records)[0]{sid}, 'A', 'the only list');
};

subtest 'an answer with no meta at all' => sub {
  my ($http, $version) = fetched({ items => [{ sid => 'A' }] });
  my $page = $version->{page};

  is(($page->records)[0]{sid},     'A',   'the list is found');
  is($page->get_next_page_url,     undef, 'no next page');
  is($page->get_previous_page_url, undef, 'no previous page');
};

subtest 'an answer with no list dies' => sub {
  my ($http, $version) = Local::Resources::build();
  $http->mock(200, {});
  my $response = $version->page('GET', '/Items');

  my $ok = eval { Local::TokenPage->new($version, $response); 1 };
  ok(!$ok, 'as in twilio-php');
};

# twilio-php's testStreamWithTokenPaginationWithQueryParams: a filter in the first URL stays on
# every page, and both kinds of limit stop the stream where they should.
subtest 'a stream keeps the query parameters and honours limits' => sub {
  my @cases = (
    ['no limits',      undef, undef, 5],
    ['a record limit', 3,     undef, 3],
    ['a page limit',   undef, 1,     2]
  );

  for my $case (@cases) {
    my ($name, $limit, $page_limit, $expected) = @{$case};
    my ($http, $version) =
      fetched(body({ nextToken => 'token1', pageSize => 2 }, 'A', 'B'), { Status => 'on' });
    $http->mock(200,
      body({ nextToken => 'token2', previousToken => 'token0', pageSize => 2 }, 'C', 'D'));
    $http->mock(200, body({ previousToken => 'token1', pageSize => 1 }, 'E'));

    my $stream = $version->stream($version->{page}, $limit, $page_limit);
    my $count  = 0;
    $count++ while $stream->next;

    is($count, $expected, "$name: records");
    my @urls = map { $_->{url} } $http->requests;
    ok(!grep({ !/[?]Status=on\b/ } @urls), "$name: every page keeps the filter");
  }
};

subtest 'an error answer' => sub {
  my ($http, $version) = Local::Resources::build();
  $http->mock(500, { code => 1, message => 'broken' });

  my $response = $version->page('GET', '/Items');
  my $ok       = eval { Local::TokenPage->new($version, $response); 1 };
  my $error    = $@;

  ok(!$ok, 'it dies');
  isa_ok($error, 'Twilio::Exceptions::RestException');
};

subtest 'a client that keeps no last request cannot end the list silently' => sub {
  my ($http, $version) = fetched(body({ nextToken => 'abc' }, 'A'));
  my $page = $version->{page};
  $page->{url} = q{};

  my $ok    = eval { $page->get_next_page_url; 1 };
  my $error = $@;
  ok(!$ok, 'it dies');
  like("$error", qr/did not record the last request/, 'says why');
  is($page->get_previous_page_url, undef, 'with no token there is nothing to build');
};

done_testing;

sub body {
  my ($meta, @sids) = @_;
  return { items => [map { { sid => $_ } } @sids], meta => { key => 'items', %{$meta} } };
}

# The version carries the page only so that each test reads in one line.
sub fetched {
  my ($content, $params) = @_;

  my ($http, $version) = Local::Resources::build();
  $http->mock(200, $content);
  my $response = $version->page('GET', '/Items', { params => $params // {} });
  $version->{page} = Local::TokenPage->new($version, $response);
  return ($http, $version);
}
