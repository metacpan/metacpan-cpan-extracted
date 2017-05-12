#!perl -T

use lib 't/lib';

use Test::More tests => 8;

use LWP::UserAgent;
use Test::Override::UserAgent for => 'testing';

# Create a configuration
my $conf = Test::Override::UserAgent->new->override_request(
	host => 'localhost',
	path => '/bad-code.psgi',
	sub { return [2, ['Content-Type' => 'text/plain'], []]; },
)->override_request(
	host => 'localhost',
	path => '/bad-header-element.psgi',
	sub { return [200, 0, []]; },
)->override_request(
	host => 'localhost',
	path => '/bad-header-element-count.psgi',
	sub { return [200, [1], []]; },
)->override_request(
	host => 'localhost',
	path => '/bad-header-keys.psgi',
	sub { return [200, ['Status' => 200, ':W' => 2, 32 => 1], []]; },
)->override_request(
	host => 'localhost',
	path => '/bad-header-values.psgi',
	sub { return [200, ['hash' => {}, 'null' => "\x00"], []]; },
)->override_request(
	host => 'localhost',
	path => '/missing-ct.psgi',
	sub { return [200, [], []]; },
)->override_request(
	host => 'localhost',
	path => '/present-cl.psgi',
	sub { return [204, ['Content-Length' => 0], []]; },
)->override_request(
	host => 'localhost',
	path => '/correct.psgi',
	sub { return [200, ['Content-Type' => 'text/plain', 'Content-Length' => 10], ['013456789']]; },
);

# Create the UA
my $ua = $conf->install_in_user_agent(LWP::UserAgent->new);

is $ua->get('http://localhost/bad-code.psgi')->status_line,
	'417 PSGI HTTP status code MUST be 100 or greater',
	'PSGI bad status code';

is $ua->get('http://localhost/bad-header-element.psgi')->status_line,
	'417 PSGI headers MUST be an array reference',
	'PSGI bad header element';

is $ua->get('http://localhost/bad-header-element-count.psgi')->status_line,
	'417 PSGI headers MUST have even number of elements',
	'PSGI bad header element count';

is $ua->get('http://localhost/bad-header-keys.psgi')->status_line,
	'417 PSGI headers have invalid key(s): 32, :W, Status',
	'PSGI bad header keys';

is $ua->get('http://localhost/bad-header-values.psgi')->status_line,
	'417 PSGI headers have invalid value(s): hash, null',
	'PSGI bad header values';

is $ua->get('http://localhost/missing-ct.psgi')->status_line,
	'417 There MUST be a Content-Type for code other than 1xx, 204, and 304',
	'PSGI missing content type';

is $ua->get('http://localhost/present-cl.psgi')->status_line,
	'417 There MUST NOT be a Content-Length for 1xx, 204, and 304',
	'PSGI missing content type';

is $ua->get('http://localhost/correct.psgi')->status_line,
	'200 OK',
	'PSGI passed checks';
