use strict;
use warnings FATAL => 'all';
use Test::More;
use Test::LWP::UserAgent;
use URI;
use Try::Tiny;
use File::Slurper qw(read_text);
use v5.10;

use FindBin;
use lib "$FindBin::Bin/lib";

BEGIN {
	use_ok( 'WebService::E4SE' ) || BAIL_OUT("Can't use WebService::E4SE");
}

my $RESPONSE = 	join('', (
	'<?xml version="1.0" encoding="utf-8" ?>',
	'<soap:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">',
	'<soap:Header><ICEResponseHeader xmlns="http://epicor.com/ice/1/2"><ccmReply><ccmStatus>Unclaimed</ccmStatus></ccmReply><HoldList /><AttachmentList /></ICEResponseHeader>',
	'</soap:Header><soap:Body>',
	'<GetUserIDNameResponse xmlns="http://epicor.com/webservices/"><GetUserIDNameResult>Bar, Foo</GetUserIDNameResult>',
	'</GetUserIDNameResponse></soap:Body></soap:Envelope>'
));
my $GETUSERIDNAME_RESPONSE = {'ICEResponseHeader' => {'AttachmentList' => {},'HoldList' => {},'ccmReply' => {'ccmStatus' => 'Unclaimed'}}, 'parameters' => {'GetUserIDNameResult' => 'Bar, Foo'}};

# setup mock responses
my $ua = Test::LWP::UserAgent->new();
isa_ok($ua,'Test::LWP::UserAgent');
$ua->map_response(
	qr{epicor/e4se/Resource\.asmx\?WSDL},
	HTTP::Response->new('200', 'OK', ['Content-Type' => 'text/xml'], read_text("./t/resource.wsdl"))
);
$ua->map_response( sub {
		my $request = shift;
		return 0 unless $request->method eq 'POST';
		return 1 if $request->uri =~ /Resource\.asmx/;
	},
	HTTP::Response->new('200', 'OK', ['Content-Type' => 'text/xml'], $RESPONSE)
);

my $ws = WebService::E4SE->new(_ua=>$ua);
can_ok('WebService::E4SE', (
	qw(_ua base_url files force_wsdl_reload password realm site username), # attributes,
	qw(_get_port _valid_file call get_object operations), # methods
));

isa_ok($ws,'WebService::E4SE');
isa_ok($ws->_ua(),'LWP::UserAgent');
isa_ok($ws->base_url(),'URI');

is($ws->username, '', 'attribute: username default');
is($ws->username('foo'), 'foo', 'attribute: username foo');
is($ws->password, '', 'attribute: password default');
is($ws->password('foo'), 'foo', 'attribute: password foo');
is($ws->realm, '', 'attribute: realm default');
is($ws->realm('foo'),'foo', 'attribute: realm foo');
is($ws->site, 'epicor:80', 'attribute: site default');
is($ws->site('foo'), 'foo', 'attribute: site foo');
is($ws->base_url, 'http://epicor/e4se/', 'attribute: base_url default');
is($ws->base_url(URI->new('http://foo.com')), 'http://foo.com', 'attribute: base_url foo.com');
is($ws->force_wsdl_reload, 0, 'attribute: force_wsdl_reload default');
is($ws->force_wsdl_reload(1), 1, 'attribute: force_wsdl_reload 1');
is($ws->force_wsdl_reload('true'), 1, 'attribute: force_wsdl_reload true');
is($ws->force_wsdl_reload('false'), 0, 'attribute: force_wsdl_reload false');
isa_ok($ws->files, 'ARRAY');

# coverage tests for _get_port()
is($ws->_get_port(), 'WSSoap', '_get_port: empty call');
is($ws->_get_port(undef), 'WSSoap', '_get_port: undef call');
is($ws->_get_port(''), 'WSSoap', '_get_port: empty string');
is($ws->_get_port('foo.asmx'), 'fooWSSoap', '_get_port: proper value');

# coverage tests for _valid_file()
is($ws->_valid_file(), 0, '_valid_file: empty call');
is($ws->_valid_file(undef), 0, '_valid_file: undef call');
is($ws->_valid_file(''), 0, '_valid_file: empty string');
is($ws->_valid_file('foo.asmx'), 0, '_valid_file: bad file');
is($ws->_valid_file('Resource.asmx'), 1, '_valid_file: bad file');

# reset for mock testing
$ws->base_url('http://epicor/e4se/');

{
	my $res;
	$res = try { $ws->get_object('Resource.asmx') } catch { $_ };
	isa_ok($res, 'XML::Compile::WSDL11', 'get_object: got a proper response');
	$res = try { $ws->operations('Resource.asmx') } catch { $_ };
	isa_ok($res, 'ARRAY', 'operations: got an array reference');
	is( (grep {$_ eq 'GetUserIDName'} @$res), 1, 'operations: contains GetUserIDName');
	$res = try { $ws->call('Resource.asmx', 'GetUserIDName', userID => 'foobar') } catch { $_ };
	is_deeply( $res, $GETUSERIDNAME_RESPONSE, 'call: GetUserIDName foobar');
}
done_testing();
