#!/usr/bin/perl -w

use strict;
use lib::abs '../lib';
use XML::RPC::Enc::LibXML;
use XML::Hash::LX 0.05;
use Test::More;
use Test::NoWarnings;
use Encode;
BEGIN{
	binmode Test::More->builder->$_, ':utf8'
		for qw(failure_output todo_output output);
}

plan tests => 42;

my $enc = XML::RPC::Enc::LibXML->new(
	internal_encoding => 'utf8',
);

my $hd = qq{<?xml version="1.0" encoding="utf-8"?>\n};
my ($xml,$data);

#$xml = q{<?xml version="1.0" encoding="utf-8"?><methodCall><methodName>bss.storeDataStorage</methodName><params><param><value><struct><member><name>value</name><value><string>€€€</string></value></member><member><name>name</name><value><string>test</string></value></member></struct></value></param></params></methodCall>};
#print + Dumper $enc->decode( $xml );exit;
#print my $xml = $enc->request( test => bless( \do {my $o}, 'custom' ) );#exit;
#use Data::Dumper; print + Dumper $enc->decode( $xml );
#exit;

$SIG{__DIE__} = sub { require Carp;Carp::confess @_ };

is
	$xml = $enc->request( test => () ),
	$hd."<methodCall><methodName>test</methodName><params/></methodCall>\n",
	'undef args',
	or diag explain ($xml)
;
is_deeply
	$data = [ $enc->decode($xml) ],
	[ test => () ],
	'decode empty',
	or diag explain $data
;

is
	$xml = $enc->request( test => bless( \do {my $o}, 'custom' ) ),
	$hd."<methodCall><methodName>test</methodName><params><param><value><custom/></value></param></params></methodCall>\n",
	'custom undef args',
	or diag explain ($xml)
;
is_deeply
	$data = [ $enc->decode($xml) ],
	[ test => bless( \do {my $o}, 'custom' ) ],
	'decode empty custom',
	or diag explain $data
;

is_deeply xml2hash( $enc->request( test => 1 ) ),
	{ methodCall => { methodName => "test", params => { param => { value => { i4 => 1 } } } } },
	'request i4';
is_deeply xml2hash( $enc->request( test => 1.1 ) ),
	{ methodCall => { methodName => "test", params => { param => { value => { double => 1.1 } } } } },
	'request double';
is_deeply xml2hash( $enc->request( test => 'z' ) ),
	{ methodCall => { methodName => "test", params => { param => { value => { string => 'z' } } } } },
	'request string';

is_deeply xml2hash( $xml = $enc->request( test => { a => 1 } ) ),
	{ methodCall => { methodName => "test", params => { param => { value => {
		struct => { member => { name => 'a', value => { i4 => 1 } } }
	} } } } },
	'request struct';

is $xml,
	$hd."<methodCall><methodName>test</methodName><params><param><value><struct><member><name>a</name><value><i4>1</i4></value></member></struct></value></param></params></methodCall>\n",
	'request xml struct'
	or diag explain $xml
;

is_deeply xml2hash( $enc->request( test => [ 1,2 ] ) ),
	{ methodCall => { methodName => "test", params => { param => { value => {
		array => { data => { value => [ {i4 => 1},{i4 => 2} ] } }
	} } } } },
	'request array';

is_deeply xml2hash( $enc->request( test => sub {{ custom => '12345' }}, ) ),
	{ methodCall => { methodName => "test", params => { param => { value => {
		custom => '12345'
	} } } } },
	'request custom compat';

is_deeply xml2hash( $enc->request( test => bless( do{\(my $o = '12345')}, 'custom' ) ) ),
	{ methodCall => { methodName => "test", params => { param => { value => {
		custom => '12345'
	} } } } },
	'request custom bless';

is_deeply xml2hash( $enc->request( test => bless( do{\(my $o = { a => 1 })}, 'custom' ) ) ),
	{ methodCall => { methodName => "test", params => { param => { value => {
		custom => { a => 1 }
	} } } } },
	'request custom bless';

is_deeply xml2hash( $enc->response( 1 ) ),
	{ methodResponse => { params => { param => { value => { i4 => 1 } } } } },
	'response i4';
is_deeply xml2hash( $enc->response( 1.1 ) ),
	{ methodResponse => { params => { param => { value => { double => 1.1 } } } } },
	'response double';
is_deeply xml2hash( $enc->response( 'z' ) ),
	{ methodResponse => { params => { param => { value => { string => 'z' } } } } },
	'response string';
is_deeply $data = xml2hash( $enc->response( "5000000000" ) ),
	{ methodResponse => { params => { param => { value => { i8 => "5000000000" } } } } },
	'response i8'
	or diag explain $data;
is_deeply $data = xml2hash( $enc->response( "-5000000000" ) ),
	{ methodResponse => { params => { param => { value => { i8 => "-5000000000" } } } } },
	'response -i8'
	or diag explain $data;
is_deeply $data = xml2hash( $enc->response( "500000000000000000000" ) ),
	{ methodResponse => { params => { param => { value => { string => "500000000000000000000" } } } } },
	'response very big integer'
	or diag explain $data;
is_deeply $data = xml2hash( $enc->response( "+111111111111111111111111111.1111111111111111111111111" ) ),
	{ methodResponse => { params => { param => { value => { double => "+111111111111111111111111111.1111111111111111111111111" } } } } },
	'response big double'
	or diag explain $data;
is_deeply $data = xml2hash( $enc->response( "+0" ) ),
	{ methodResponse => { params => { param => { value => { i4 => "0" } } } } },
	'response +0'
	or diag explain $data;
is_deeply $data = xml2hash( $enc->response( "-0" ) ),
	{ methodResponse => { params => { param => { value => { i4 => "0" } } } } },
	'response -0'
	or diag explain $data;

is_deeply xml2hash( $enc->fault( 555,'test' ) ),
	{ methodResponse => { fault => { value => { struct => { member => [
		{name => faultCode => value => { i4 => 555 }},
		{name => faultString => value => { string => 'test' }},
	]}}}}},
	'fault';

{
	local $enc->{external_encoding} = 'windows-1251';
	local $enc->{internal_encoding} = undef;
	is $enc->response( Encode::decode utf8 => "тест" ),
	Encode::encode( $enc->{external_encoding} => Encode::decode utf8 => qq{<?xml version="1.0" encoding="windows-1251"?>\n<methodResponse><params><param><value><string>тест</string></value></param></params></methodResponse>\n} ),
	'external_encoding';
}

{
	use bytes;
	local $enc->{internal_encoding} = undef;
	is $enc->response( Encode::decode utf8 => "тест" ),
	qq{<?xml version="1.0" encoding="utf-8"?>\n<methodResponse><params><param><value><string>тест</string></value></param></params></methodResponse>\n},
	'utf8-ness';
}

# Decoder

is_deeply [ $enc->decode( ( $enc->request( test => 1 ) ) ) ],
	[ test => 1 ],
	'decode i4';

is_deeply [ $enc->decode( ( $enc->request( test => 1.2 ) ) ) ],
	[ test => 1.2 ],
	'decode double';

is_deeply [ $enc->decode( ( $enc->request( test => 'z' ) ) ) ],
	[ test => 'z' ],
	'decode string';

is_deeply [ $enc->decode( ( $enc->request( test => sub{{ custom => '12345'}} ) ) ) ],
	[ test => bless(do{\(my $o = '12345')}, 'custom') ],
	'decode custom compat';

is_deeply [ $enc->decode( ( $enc->request( test => bless( do{\(my $o = '12345')}, 'custom' ) ) ) ) ],
	[ test => bless(do{\(my $o = '12345')}, 'custom') ],
	'decode custom bless';

is_deeply $data = [ $enc->decode( ( $xml = $enc->request( test => bless( do{\(my $o = {a => 1})}, 'custom' ) ) ) ) ],
	[ test => bless(do{\(my $o = {a => 1})}, 'custom') ],
	'decode custom bless struct',
	or diag explain($xml,$data)
;

is_deeply $data = [ $enc->decode( ( $xml = $enc->request( test => { a => 1 } ) ) ) ],
	[ test => { a => 1 } ],
	'decode struct',
	or diag explain($xml,$data)
;

SKIP : {
	eval { require MIME::Base64;1 } or skip 'MIME::Base64 required',1;
	is_deeply [ $enc->decode( ( $enc->request( test => sub{{ base64 => MIME::Base64::encode('test') }} ) ) ) ],
		[ test => 'test' ],
		'decode base64';
}

SKIP : {
	eval { require DateTime::Format::ISO8601; 1 } or skip 'DateTime::Format::ISO8601 required',1;
	is_deeply [ $enc->decode( ( $enc->request( test => sub {{ 'dateTime.iso8601' => '20090816T010203.04+0330' }} ) ) ) ],
		[ test => DateTime::Format::ISO8601->parse_datetime('20090816T010203.04+0330') ],
		'decode datetime';
}

# Tests for Marko Nordberg's testcases

{
	is_deeply $data = [ $enc->decode( q{<?xml version="1.0" encoding="UTF-8"?><methodResponse xmlns:ex="http://ws.apache.org/xmlrpc/namespaces/extensions"><params><param><value><struct><member><name>status</name><value>noError</value></member></struct></value></param></params></methodResponse>} ) ],
		[ { status => 'noError' } ],
		'decode 1',
		or diag explain($data)
	;
}
{
	local $enc->{internal_encoding} = undef;
	is_deeply $data = [ $enc->decode( q{<?xml version="1.0" encoding="utf-8"?><methodCall><methodName>bss.storeDataStorage</methodName><params><param><value><struct><member><name>value</name><value><string>€€€</string></value></member><member><name>name</name><value><string>test</string></value></member></struct></value></param></params></methodCall>} ) ],
		[ 'bss.storeDataStorage' => { name => 'test', value => "\x{20ac}\x{20ac}\x{20ac}", } ],
		'decode 2',
		or diag explain($data)
	;
}

{
	local $enc->{internal_encoding} = undef;
	is $data = length($xml = $enc->request( 'bss.storeDataStorage' => { name => 'test', value => "\x{20ac}\x{20ac}\x{20ac}", } )),
		320,
		'utf8 xml content length'
		or diag explain $data, $xml;
}

is $data = length($xml = $enc->request( 'bss.storeDataStorage' => { name => 'test', value => "€€€", } )),
	320,
	'inplace octets xml content length'
	or diag explain $data, $xml;

is $data = length($xml = $enc->request( 'bss.storeDataStorage' => { name => 'test', value => "\342\202\254\342\202\254\342\202\254", } )),
	320,
	'octets xml content length'
	or diag explain $data, $xml;

{
	local $enc->{internal_encoding} = undef;
	is_deeply $data = [ $enc->decode( q{<?xml version="1.0" encoding="utf-8"?><methodCall><methodName>storeDataStorage</methodName><params><param><value><struct><member><name>value</name><value><string>ÄÄÄ</string></value></member><member><name>name</name><value><string>test</string></value></member></struct></value></param></params></methodCall>} ) ],
		[ storeDataStorage => { name => 'test', value => "\x{c4}\x{c4}\x{c4}", }],
		'decode 3',
		or diag explain($data)
	;
}

{
	#local $enc->{internal_encoding} = undef;
	is_deeply $data = [ $enc->decode( qq{$hd<methodResponse><params><param><value><array/></value></param></params></methodResponse>} ) ],
		[ [] ],
		'decode 4',
		or diag explain($data)
	;
}

__END__
is_deeply $data = [ $enc->decode( q{} ) ],
	[ ],
	'decode 3',
	or diag Dumper($data)
;
my $hash = [
	{
		name => 'rec',
		entries => {
			name => 'ent',
			fields => [ a => 1 ]
		},
	}
];

my @prm = (
	1, 0.1,
	a => { my => [ test => 1 ], -is => 1},
	bless( do{\(my $o = '12345')}, 'estring' ),
	bless( do{\(my $o = { inner => 1 })}, 'xval' ),
	sub {{ bool => '1' }},
	sub {{ base64 => encode_base64('test') } },
	sub {{  }},
#	bless( {}, 'zzz' ),
	sub {{ custom => 'cusval' }},
	#sub {[ { subs => 'subval' }, { -x => 1 } ]},
);
#print $t->parse(my $xml = $enc->encode( test => @prm ))->sprint;
#print $t->parse(my $xml = $enc->response( @prm ))->sprint;
print $t->parse(my $xml = $enc->fault( 111, 'err' ))->sprint;
