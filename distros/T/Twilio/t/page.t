use 5.016;
use warnings;

use lib 't/lib';

use Test::More;

use Local::Resources;
use Twilio::Http::Response;

sub sids {
  return map { $_->sid } @_;
}

sub response {
  my ($status, $content) = @_;
  return Twilio::Http::Response->new($status,
    ref $content ? Twilio::Json::encode($content) : $content);
}

sub page_of {
  my ($content, $status)  = @_;
  my (undef,    $version) = Local::Resources::build();
  return Local::Page->new($version, response($status // 200, $content));
}

sub error_from {
  my ($code) = @_;
  my $ok     = eval { $code->(); 1 };
  my $error  = $@;
  ok(!$ok, 'died');
  return $error;
}

my %V2010_PAGE = (
  messages          => [{ sid => 'SM1' }, { sid => 'SM2' }],
  uri               => '/2010-04-01/Accounts/ACxx/Messages.json?PageSize=2',
  first_page_uri    => '/2010-04-01/Accounts/ACxx/Messages.json?PageSize=2&Page=0',
  next_page_uri     => '/2010-04-01/Accounts/ACxx/Messages.json?PageSize=2&Page=2&PageToken=PA2',
  previous_page_uri => '/2010-04-01/Accounts/ACxx/Messages.json?PageSize=2&Page=0&PageToken=PB0',
  page              => 1,
  page_size         => 2,
  start             => 2,
  end               => 3,
);

my %PRODUCT_PAGE = (
  services => [{ sid => 'VA1' }],
  meta     => {
    key               => 'services',
    next_page_url     => 'https://verify.twilio.com/v2/Services?PageSize=1&Page=1',
    previous_page_url => undef,
    page              => 0,
    page_size         => 1,
  },
);

subtest 'the 2010 format' => sub {
  my $page = page_of({%V2010_PAGE});

  is_deeply([sids($page->records)], ['SM1', 'SM2'], 'records found next to the paging fields');
  is($page->get_next_page_url, "https://api.twilio.com$V2010_PAGE{next_page_uri}", 'next page url');
  is(
    $page->get_previous_page_url,
    "https://api.twilio.com$V2010_PAGE{previous_page_uri}",
    'previous page url'
  );
};

subtest 'the product format' => sub {
  my $page = page_of({%PRODUCT_PAGE});

  is_deeply([sids($page->records)], ['VA1'], 'records found through meta.key');
  ok($page->has_meta('key'),     'has_meta finds a key');
  ok(!$page->has_meta('absent'), 'has_meta misses a key');
  is($page->get_meta('key'),             'services',                         'get_meta');
  is($page->get_meta('absent', 'other'), 'other',                            'get_meta default');
  is($page->get_next_page_url,           $PRODUCT_PAGE{meta}{next_page_url}, 'next page url');
  is($page->get_previous_page_url,       undef, 'a null url is no url');
};

subtest 'a product page without meta.key still finds its list' => sub {
  my $page = page_of({ meta => { page => 0 }, things => [{ sid => 'X1' }] });
  is_deeply([sids($page->records)], ['X1'], 'meta is not mistaken for the list');
};

subtest 'known paging fields that are lists are not the records' => sub {
  my $page = page_of({ Resources => [{ sid => 'U1' }], schemas => ['urn:x'], totalResults => 1 });
  is_deeply([sids($page->records)], ['U1'], 'schemas is skipped');
};

subtest 'a null meta url wins over a uri' => sub {
  my $page = page_of({ things => [], next_page_uri => '/x', meta => { next_page_url => undef } });
  is($page->get_next_page_url, undef, 'no next page');
};

subtest 'the last page has no next page' => sub {
  my ($http, $version) = Local::Resources::build();
  my $page = Local::Page->new($version, response(200, { things => [], next_page_uri => undef }));

  is($page->get_next_page_url, undef, 'no url');
  is($page->next_page,         undef, 'no page');
  is($page->previous_page,     undef, 'no previous page');
  is(scalar($http->requests),  0,     'nothing fetched');
};

subtest 'an empty list is a page' => sub {
  is_deeply([page_of({ messages => [] })->records], [], 'no records');
};

subtest 'moving between pages' => sub {
  my ($http, $version) = Local::Resources::build();
  my $page = Local::Page->new($version, response(200, {%V2010_PAGE}), { account_sid => 'ACxx' });

  $http->mock(200, { messages => [{ sid => 'SM3' }] });
  my $next = $page->next_page;
  isa_ok($next, 'Local::Page');
  is_deeply([sids($next->records)], ['SM3'],                   'next records');
  is_deeply($next->{solution},      { account_sid => 'ACxx' }, 'solution carried over');

  $http->mock(200, { messages => [{ sid => 'SM0' }] });
  is_deeply([sids($page->previous_page->records)], ['SM0'], 'previous records');

  my @requests = $http->requests;
  is($requests[0]{method}, 'GET',                                              'GET');
  is($requests[0]{url},    "https://api.twilio.com$V2010_PAGE{next_page_uri}", 'next url fetched');
  like($requests[0]{headers}{Authorization}, qr/\ABasic /, 'authenticated');
  is($requests[1]{url}, "https://api.twilio.com$V2010_PAGE{previous_page_uri}", 'previous url');
};

subtest 'next pages follow the client routing' => sub {
  my ($http, $version) = Local::Resources::build({ edge => 'sydney', region => 'au1' });
  my $page = Local::Page->new($version, response(200, {%V2010_PAGE}));

  $http->mock(200, { messages => [] });
  $page->next_page;

  my ($request) = $http->requests;
  like($request->{url}, qr{\Ahttps://api[.]sydney[.]au1[.]twilio[.]com/}, 'edge and region');
};

subtest 'walking a page' => sub {
  my $page = page_of({%V2010_PAGE});

  is($page->next->sid, 'SM1', 'first');
  is($page->next->sid, 'SM2', 'second');
  is($page->next,      undef, 'end of the page');
  is($page->next,      undef, 'still the end');

  $page->rewind;
  is($page->next->sid, 'SM1', 'first again');
};

subtest 'reading past the end is an empty page' => sub {
  my $end = { code => 20006, message => 'Page out of range', status => 400, more_info => 'x' };

  for my $status (200, 400) {
    my $page = page_of({ %{$end} }, $status);
    is_deeply([$page->records], [], "no records on status $status");
    is($page->get_next_page_url, undef, 'no next page');
  }
};

subtest 'error responses throw' => sub {
  my $error = error_from(
    sub { page_of({ code => 20003, message => 'Authenticate', more_info => 'url' }, 401) });

  isa_ok($error, 'Twilio::Exceptions::RestException');
  is($error->get_message,     '[HTTP 401] Unable to fetch page: Authenticate', 'message');
  is($error->get_code,        20003,                                           'code');
  is($error->get_status_code, 401,                                             'status');
  is($error->get_more_info,   'url',                                           'more info');

  my $gateway = error_from(sub { page_of('<html>', 502) });
  is($gateway->get_message, '[HTTP 502] Unable to fetch page', 'body that is not JSON');
};

subtest 'unknown fields are never fatal' => sub {
  my $page = page_of({ %V2010_PAGE, new_flag => 1, new_object => { a => 1 } });
  is_deeply([sids($page->records)], ['SM1', 'SM2'], 'new scalar and object ignored');

  my $product = page_of({ %PRODUCT_PAGE, new_list => [1], meta => { key => 'services' } });
  is_deeply([sids($product->records)], ['VA1'], 'meta.key ignores a new list');
};

subtest 'a named list ignores new lists' => sub {
  my (undef, $version) = Local::Resources::build();
  my $body = { items => [{ sid => 'I1' }], new_list => [1, 2] };
  my $page = Local::KeyedPage->new($version, response(200, $body));

  is_deeply([sids($page->records)], ['I1'], 'records from records_key');
};

subtest 'responses without a list throw' => sub {
  my @cases = (
    ['no list',        { total => 0 }],
    ['two lists',      { a     => [], b => [] }],
    ['not JSON',       '<html>'],
    ['JSON scalar',    '"text"'],
    ['JSON array',     '[1]'],
    ['meta.key gone',  { meta => { key => 'missing' } }],
    ['meta.key wrong', { meta => { key => 'a' }, a => 1 }],
  );

  for my $case (@cases) {
    my ($name, $body) = @{$case};
    my $error = error_from(sub { page_of($body) });
    isa_ok($error, 'Twilio::Exceptions::DeserializeException', $name);
  }
};

subtest 'build_instance is abstract' => sub {
  my (undef, $version) = Local::Resources::build();
  my $page = Twilio::Page->new($version, response(200, { things => [1] }));

  my $error = error_from(sub { $page->records });
  like($error, qr/Twilio::Page must implement build_instance/, 'names the class');
};

done_testing;
