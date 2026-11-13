use 5.016;
use warnings;

use lib 't/lib';

use Test::More;

use Local::Resources;
use Twilio::Http::Response;
use Twilio::Version;

my $URL = 'https://api.twilio.com/2010-04-01/Accounts.json';

subtest 'URLs join without doubled or missing slashes' => sub {
  my (undef, $version) = Local::Resources::build();

  is($version->absolute_url('/Accounts.json'),  $URL, 'leading slash');
  is($version->absolute_url('Accounts.json'),   $URL, 'no slash');
  is($version->absolute_url('/Accounts.json/'), $URL, 'trailing slash');

  is($version->relative_uri('/Accounts.json'), '2010-04-01/Accounts.json', 'relative');
  is($version->get_version,                    '2010-04-01',               'version');

  my $domain = $version->get_domain;
  is($domain->absolute_url('/a?b=c&d=e'), 'https://api.twilio.com/a?b=c&d=e', 'query kept');
  isa_ok($domain->get_client, 'Twilio::Rest::Client');
};

# twilio-php's relativeUriProvider: every mix of leading and trailing slashes on the version and
# on the path gives the same URI.
subtest 'slashes on either side never change the URI' => sub {
  my (undef, $built) = Local::Resources::build();
  my $domain = $built->get_domain;
  my %modes  = (normal => '%s', prepend => '/%s', append => '%s/', surround => '/%s/');

  for my $case (['v1', 'path'], ['v2', 'path/to/resource']) {
    my ($name, $path) = @{$case};
    for my $version_mode (sort keys %modes) {
      for my $path_mode (sort keys %modes) {
        my $version = Twilio::Version->new($domain);
        $version->{version} = sprintf $modes{$version_mode}, $name;
        my $uri = sprintf $modes{$path_mode}, $path;

        is($version->relative_uri($uri),
          "$name/$path", "$path: version $version_mode, path $path_mode");
        is(
          $version->absolute_url($uri),
          "https://api.twilio.com/$name/$path",
          'and the absolute URL'
        );
      }
    }
  }
};

subtest 'a version without a path still builds a URI' => sub {
  my (undef, $version) = Local::Resources::build();
  is(Twilio::Version->new($version->get_domain)->relative_uri('/x'), '/x', 'empty version');
};

subtest 'requests go through the client with its credentials' => sub {
  my ($http, $version) = Local::Resources::build();
  $http->mock(200, { ok => 1 });

  my $response = $version->request('POST', '/Accounts.json', { data => { Body => 'hi' } });
  my ($request) = $http->requests;

  is($request->{method},  'POST',    'method');
  is($request->{url},     $URL,      'url');
  is($request->{content}, 'Body=hi', 'data');
  like($request->{headers}{Authorization}, qr/\ABasic /, 'authenticated');
  is($response->get_status_code, 200, 'response returned');
};

subtest 'the client routing applies to version requests' => sub {
  my ($http, $version) = Local::Resources::build({ edge => 'sydney', region => 'au1' });
  $http->mock(200, {});

  $version->request('GET', '/Accounts.json');
  my ($request) = $http->requests;

  is(
    $request->{url},
    'https://api.sydney.au1.twilio.com/2010-04-01/Accounts.json',
    'edge and region applied'
  );
};

subtest 'read limits' => sub {
  my (undef, $version) = Local::Resources::build();

  my @cases = (
    ['nothing',                [],            undef, undef],
    ['limit becomes the size', [20],          20,    20],
    ['explicit size wins',     [20, 50],      20,    50],
    ['size alone',             [undef, 50],   undef, 50],
    ['limit above the cap',    [5000],        5000,  1000],
    ['size above the cap',     [undef, 1001], undef, 1000],
    ['size at the cap',        [undef, 1000], undef, 1000],
    ['zero means no limit',    [0, 0],        undef, undef],
  );

  for my $case (@cases) {
    my ($name, $arguments, $limit, $page_size) = @{$case};
    is_deeply($version->read_limits(@{$arguments}),
      { limit => $limit, page_size => $page_size, page_limit => undef }, $name);
  }
};

subtest 'exceptions carry what Twilio sent' => sub {
  my (undef, $version) = Local::Resources::build();

  my $body = {
    code      => 21211,
    message   => 'Invalid To',
    more_info => 'https://www.twilio.com/docs/errors/21211',
    details   => { field => 'To' },
  };
  my $json = Twilio::Json::encode($body);
  my $error =
    $version->exception(Twilio::Http::Response->new(400, $json), 'Unable to create record');

  isa_ok($error, 'Twilio::Exceptions::RestException');
  is($error->get_message,     '[HTTP 400] Unable to create record: Invalid To', 'message');
  is($error->get_code,        21211,                                            'code');
  is($error->get_status_code, 400,                                              'status');
  is($error->get_more_info,   $body->{more_info},                               'more info');
  is_deeply($error->get_details, { field => 'To' }, 'details');
};

subtest 'exceptions fall back to the status code' => sub {
  my (undef, $version) = Local::Resources::build();

  my $not_json = $version->exception(Twilio::Http::Response->new(502, '<html>'), 'Unable to fetch');
  is($not_json->get_message,     '[HTTP 502] Unable to fetch', 'message without a body');
  is($not_json->get_code,        502,                          'code is the status');
  is($not_json->get_status_code, 502,                          'status');

  my $partial = $version->exception(Twilio::Http::Response->new(404, '{}'), 'Unable to fetch');
  is($partial->get_message, '[HTTP 404] Unable to fetch', 'message without a Twilio message');
  is($partial->get_code,    404,                          'code without a Twilio code');
};

subtest 'error bodies that are JSON but not objects' => sub {
  my (undef, $version) = Local::Resources::build();

  for my $body ('[1]', '"text"', '1') {
    my $error = $version->exception(Twilio::Http::Response->new(500, $body), 'Unable to fetch');
    is($error->get_message, '[HTTP 500] Unable to fetch', "message for $body");
    is($error->get_code,    500,                          "code for $body");
  }
};

subtest 'handle_request judges the status' => sub {
  my @accepted = (200, 201, 204, 302, 399);
  my @refused  = (100, 199, 400, 404, 500);

  for my $status (@accepted) {
    my ($http, $version) = Local::Resources::build();
    $http->mock($status, {});
    is($version->handle_request('GET', '/x', 'fetch')->get_status_code, $status,
      "$status accepted");
  }

  for my $status (@refused) {
    my ($http, $version) = Local::Resources::build();
    $http->mock($status, { message => 'No' });

    my $ok    = eval { $version->handle_request('GET', '/x', 'fetch'); 1 };
    my $error = $@;

    ok(!$ok, "$status refused");
    is($error->get_message, "[HTTP $status] Unable to fetch record: No", 'names the operation');
  }
};

subtest 'handle_request passes the options on' => sub {
  my ($http, $version) = Local::Resources::build();
  $http->mock(200, {});

  $version->handle_request('POST', '/x', 'update', { data => { A => 1 } });
  my ($request) = $http->requests;
  is($request->{content}, 'A=1', 'data sent');
};

done_testing;
