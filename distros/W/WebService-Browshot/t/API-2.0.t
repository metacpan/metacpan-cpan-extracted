use strict;
use warnings;
use Test::More;
use HTTP::Response;
use JSON;
use URI;
use WebService::Browshot;

{
	package BrowshotV2TestUA;

	sub new { return bless { replies => [], requests => [] }, shift; }

	sub get {
		my ($self, $url) = @_;
		push @{$self->{requests}}, { method => 'GET', uri => URI->new($url) };
		return shift @{$self->{replies}};
	}

	sub post {
		my ($self, $url, %args) = @_;
		push @{$self->{requests}}, { method => 'POST', uri => URI->new($url), %args };
		return shift @{$self->{replies}};
	}
}

my $browshot = WebService::Browshot->new(key => 'unit-test-key');
my $ua = BrowshotV2TestUA->new();
$browshot->{_ua} = $ua;

sub reply {
	my ($status, $body, $content_type) = @_;
	push @{$ua->{replies}}, HTTP::Response->new(
		$status, '', ['Content-Type' => $content_type || 'application/json; charset=utf-8'], $body,
	);
}

sub requested_path {
	return $ua->{requests}->[-1]->{uri}->path;
}

sub query {
	my ($key) = @_;
	my @parameters = $ua->{requests}->[-1]->{uri}->query_form;
	my @values;
	while (@parameters) {
		my ($name, $value) = splice @parameters, 0, 2;
		push @values, $value if ($name eq $key);
	}
	return \@values;
}

my $destination = 'https://example.org/?x=a+b&lang=en';
foreach my $case (
	['screenshot_create', 'screenshot/create', { url => $destination }],
	['screenshot_create', 'screenshot/create', { url => $destination, device => 'iphone_15_pro', country => 'fr' }],
	['screenshot_multiple', 'screenshot/multiple', { urls => [$destination] }],
	['batch_create', 'batch/create', { file => '/fixture/urls.csv', country => 'in' }],
	['crawl_create', 'crawl/create', { domain => 'example.org' }],
) {
	my ($method, $action, $parameters) = @$case;
	reply(200, '{"id":42}');
	is($browshot->$method(%$parameters)->{id}, 42, "$method accepts capture without an instance");
	is(requested_path(), "/api/v2/$action", "$method chooses v2");
	is_deeply(query('instance_id'), [], "$method omits instance ID");
}
is($browshot->{last_error}, '', 'Batch and crawl need no instance ID or explicit crawl start URL');

foreach my $case (
	['screenshot_create', 'screenshot/create', { instance_id => 0 }],
	['screenshot_create', 'screenshot/create', { screen => '640x480' }],
	['screenshot_create', 'screenshot/create', { hook => 'https://example.org/hook' }],
	['screenshot_create', 'screenshot/create', { hosting_bucket => 'test-bucket' }],
	['screenshot_create', 'screenshot/create', { details => 3 }],
	['screenshot_multiple', 'screenshot/multiple', { urls => [$destination], instances => [12, 373] }],
	['screenshot_multiple', 'screenshot/multiple', { urls => [$destination], instance_id => [12, 373] }],
	['batch_create', 'batch/create', { file => '/fixture/urls.csv', instance_id => 373 }],
	['crawl_create', 'crawl/create', { domain => 'example.org', instance_id => 373 }],
	['screenshot_host', 'screenshot/host', { id => 42 }],
	['instance_list', 'instance/list', {}],
	['instance_info', 'instance/info', { id => 373 }],
	['browser_info', 'browser/info', { id => 47 }],
	['account_info', 'account/info', { details => 2 }],
) {
	my ($method, $action, $parameters) = @$case;
	reply(200, '{"id":42}');
	$browshot->$method(url => $destination, %$parameters);
	is(requested_path(), "/api/v1/$action", "$method keeps v1 for legacy options");
	if ($method eq 'screenshot_multiple') {
		is_deeply(query('instance_id'), [12, 373], 'Serializes legacy repeated instance IDs');
	}
}

foreach my $id (40371238, 71504921) {
	reply(200, encode_json({ id => $id, status => 'finished', browser => 'chrome' }));
	is($browshot->screenshot_info(id => $id)->{id}, $id, 'Accepts an existing screenshot ID');
	is(requested_path(), '/api/v2/screenshot/info', 'Shared IDs prefer v2 without a lookup');
	is_deeply(query('id'), [$id], 'Sends only the original screenshot ID');
}
foreach my $legacy ({ details => 0 }, { details => 3 }, { api_version => 1 }) {
	reply(200, '{"id":42,"instance_id":373}');
	is($browshot->screenshot_info(id => 42, %$legacy)->{instance_id}, 373, 'Caller can keep the v1 instance field');
	is(requested_path(), '/api/v1/screenshot/info', 'Selects the legacy response format');
	is_deeply(query('api_version'), [], 'Version option stays client-side');
}

foreach my $case (
	[{ url => $destination }, 2],
	[{ url => $destination, instance_id => 12 }, 1],
) {
	my ($args, $version) = @$case;
	reply(200, "\211PNG", 'image/png');
	my ($status, $bytes) = $browshot->simple(%$args);
	is($status, 200, 'Simple preserves the HTTP status');
	is($bytes, "\211PNG", 'Simple preserves the image');
	is(requested_path(), "/api/v$version/simple", 'Simple uses the selected API version');
}

my $pinned = WebService::Browshot->new(key => 'unit-test-key', base => 'https://browshot.test/api/v1/');
$pinned->{_ua} = $ua;
reply(200, '{"id":42}');
$pinned->screenshot_info(id => 42);
is(requested_path(), '/api/v1/screenshot/info', 'Explicit base keeps v1 for the whole client');
reply(200, '{"id":42}');
$pinned->screenshot_info(id => 42, api_version => 2);
is(requested_path(), '/api/v2/screenshot/info', 'Per-call version changes the path of a versioned base');
is($ua->{requests}->[-1]->{uri}->host, 'browshot.test', 'Version override preserves custom host');

my $profiles = [{ browser => 'chrome', country => 'fr' }, { device => 'iphone_15_pro', country => 'in' }];
my $urls = [$destination, 'https://example.net/'];
reply(200, '{"42":{"id":42},"43":{"id":43}}');
my $shots = $browshot->screenshot_multiple(urls => $urls, profiles => $profiles, apps => ['archive', 'notify']);
is_deeply([sort keys %$shots], [42, 43], 'Preserves screenshot ID keys');
is(requested_path(), '/api/v2/screenshot/multiple', 'Multiple profiles use v2');
is_deeply(query('url'), $urls, 'Encodes and repeats URLs');
is_deeply(query('apps'), ['archive', 'notify'], 'Repeats app IDs');
is_deeply(decode_json(query('profiles')->[0]), $profiles, 'Encodes the profile array as JSON');
is_deeply($urls, [$destination, 'https://example.net/'], 'Leaves the caller URL list intact');

reply(200, '{"id":42}');
$browshot->batch_create(file => '/fixture/urls.csv', apps => { archive => 'captures/{id}.png' });
is($ua->{requests}->[-1]->{method}, 'POST', 'Batch upload still uses POST');
is($ua->{requests}->[-1]->{Content_Type}, 'form-data', 'Batch upload is multipart');
is_deeply(query('apps[archive]'), ['captures/{id}.png'], 'Encodes per-capture S3 filename overrides');

foreach my $args (
	{ id => 42, width => 120 },
	{ url => 'https://legacy.test/image/42?width=120' },
	{ url => 'https://legacy.test/api/v1/screenshot/thumbnail?id=42&width=120&key=external-key' },
	{ url => 'https://legacy.test/api/v2/screenshot/thumbnail?id=42&width=120&key=external-key' },
) {
	reply(200, "\211PNG", 'image/png');
	is($browshot->screenshot_thumbnail(%$args), "\211PNG", 'Retrieves bytes using ID or a returned thumbnail URL');
	is(requested_path(), '/api/v2/screenshot/thumbnail', 'Thumbnail always prefers v2 in automatic mode');
	is_deeply(query('id'), [42], 'Resolves image ID');
	is_deeply(query('width'), [120], 'Preserves requested size');
	is_deeply(query('key'), ['unit-test-key'], 'Authenticates with only the configured key');
}

foreach my $case (
	['browser_list', 'browser/list', {}],
	['browser_info', 'browser/info', { browser => 'firefox' }],
	['browser_info', 'browser/info', { id => 42 }],
	['device_list', 'device/list', {}],
	['app_list', 'app/list', {}],
	['app_info', 'app/info', { id => 42 }],
) {
	my ($method, $action, $parameters) = @$case;
	reply(200, '{"id":42}');
	$browshot->$method(%$parameters);
	is(requested_path(), "/api/v2/$action", "$method uses the v2 catalog or app endpoint");
}

foreach my $case (
	['create', { type => 'webhook', app_id => 'notify', name => "Test \x{e9}", config => { url => 'https://example.org/events' } }],
	['update', { id => 42, isActive => JSON::false }],
	['delete', { id => 42 }],
	['test', { id => 42 }],
	['run', { screenshot_id => 42, apps => ['notify', '42'] }],
) {
	my ($action, $body) = @$case;
	my $method = "app_$action";
	reply(200, encode_json({ id => 42, name => "Test \x{e9}" }));
	my %args = %$body;
	$args{isActive} = 0 if ($action eq 'update');
	$args{apps} = ['notify', 42] if ($action eq 'run');
	is($browshot->$method(%args)->{name}, "Test \x{e9}", "$method returns decoded JSON");
	is(requested_path(), "/api/v2/app/$action", "$method uses the v2 endpoint");
	is($ua->{requests}->[-1]->{method}, 'POST', "$method uses POST");
	is($ua->{requests}->[-1]->{Content_Type}, 'application/json', "$method uses JSON");
	is_deeply(decode_json($ua->{requests}->[-1]->{Content}), $body, "$method sends the API's expected JSON types");
}

my $unavailable = '{"success":false,"error":"NOT_FOUND","message":"Page not found"}';
reply(404, $unavailable);
reply(200, '{"id":42,"instance_id":12}');
my $before = @{$ua->{requests}};
is($browshot->screenshot_info(id => 42)->{instance_id}, 12, 'Uses v1 when the v2 route is unavailable');
is_deeply([map { $_->{uri}->path } @{$ua->{requests}}[$before .. $before + 1]],
	['/api/v2/screenshot/info', '/api/v1/screenshot/info'], 'Makes one v2 lookup and one safe fallback');
foreach my $case (
	['screenshot_info', { id => 42 }, 404, '{"error":"NOT_FOUND","message":"Screenshot or resource not found","success":false}'],
	['screenshot_info', { id => 42 }, 503, '{"error":"API_UNAVAILABLE"}'],
	['screenshot_info', { id => 42, api_version => 2 }, 404, $unavailable],
	['screenshot_create', { url => $destination, country => 'fr' }, 404, $unavailable],
	['app_list', {}, 404, $unavailable],
) {
	my ($method, $parameters, $status, $error) = @$case;
	reply($status, $error);
	my $count = @{$ua->{requests}};
	ok($browshot->$method(%$parameters)->{error}, "$method returns the API error");
	is(scalar @{$ua->{requests}}, $count + 1, "$method does not retry this response on v1");
}

reply(404, $unavailable);
reply(200, '{"id":42}');
is($browshot->batch_create(file => '/fixture/urls.csv')->{id}, 42, 'Batch can fall back before capture is queued');
is(requested_path(), '/api/v1/batch/create', 'Batch fallback keeps multipart upload on v1');
is_deeply($ua->{requests}->[-1]->{Content}, [file => ['/fixture/urls.csv']], 'Batch fallback resends the same file');
is(scalar @{$ua->{replies}}, 0, 'All fixture responses consumed');
done_testing;
