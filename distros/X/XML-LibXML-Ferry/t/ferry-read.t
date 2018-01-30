#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;
use Test::Deep;

use XML::LibXML;
use XML::LibXML::Ferry;

use lib 't/';
use Test::FerryObject;

plan tests => 6;

my $doc = XML::LibXML->load_xml(location => 't/document.xml');
my $root = $doc->documentElement();


## XML::LibXML::Element::attr()
#

is(($root->attr())->{rootAttribute}, 'rootAttributeValue', 'Empty attr() returns attribute hash');


## XML::LibXML::Element::ferry()
#

sub _answer {
	my ($obj, $val) = @_;
	$val = $val->textContent if ref($val);
	return int($val) + 1;
}

my $hdoc = {
	lang    => undef,
	url     => undef,
	emails  => [],
	color   => undef,
	tailles => [],
	answer  => undef,
	text    => undef,
	nono    => undef,
	short   => undef,
	long    => undef,
};
$root->ferry($hdoc, {
	'xml:lang' => 'lang',
	'xml:foo'  => '__IGNORE',
	FirstRoot  => {
		firstRootAttribute1 => { 'nono' => 'nono' },
		Bizarre             => [ 'answer', \&_answer ],
		# URL is implicit
	},
	Metas => {
		Meta => {
			__meta_name    => 'name',
			__meta_content => 'value',
			# email is implicit
		},
		Attribute => {
			__meta_name => 'type',
			size        => 'tailles',
			# color is implicit
		},
	},
	Depth => {
		Base => {
			Sub => {
				__meta_name => 'kind',
				'bar' => {
					SubOne => { __text => 'text' },  # CONVOLUTED: could be just 'text' but we want to test __text
				},
			},
		},
	},
	ShallowIsh => {
		Inside => {
			__text => 'short',
		},
		__text => 'long',
	},
});

cmp_deeply(
	$hdoc,
	{
		lang => 'fr-CA',
		url => 'https://example.com/',
		emails => [
			'foo1@example.com',
			'foo2@example.com',
			'foo3@example.com',
		],
		color => 'Blue',
		tailles => [
			'Small',
		],
		answer => 42,
		text   => 'TestSubOne2',
		nono   => undef,
		short  => 'inside text',
		long   => 'This is an example sentence.',
	},
	'Ferry to hash flattens'
);

my $rootObj = Test::FerryObject->new();
$root->ferry($rootObj, {
	FirstRoot => {
		# URL is implicit
	},
	Metas => {
		Meta => {
			__meta_name    => 'name',
			__meta_content => 'value',
			# email is implicit
		},
	},
	Depth => {
		Base => {
			Sub => [ 'nest', 'Test::FerryObject2' ],
		},
	},
});

isa_ok($rootObj->{_nest}, 'Test::FerryObject2', 'Ferry to object can nest');
cmp_deeply(
	$rootObj,
	noclass({
		_url   => 'https://example.com/',
		_email => 'foo3@example.com',
		_nest  => {
			_text  => 'TestSubTwo1',
		},
	}),
	'Ferry to object flattens'
);


## XML::LibXML::Document->toHash()
## XML::LibXML::Element->toHash()
#

cmp_deeply(
	$doc->getElementsByTagName('Shallow')->[0]->toHash,
	{
		'__attributes' => {},
		'__text'       => '',
		'Inside'       => [{
			'__attributes' => { name => 'value' },
			'__text'       => '',
		}]
	},
	'toHash handles small elements gracefully'
);
cmp_deeply(
	$doc->toHash,
	{
		'__attributes' => {
			'rootAttribute' => 'rootAttributeValue',
			'{http://www.w3.org/XML/1998/namespace}lang' => 'fr-CA',
		},
		'__text'    => '',
		'FirstRoot' => [
			{
				'__attributes' => {
					'firstRootAttribute1' => 'fra1',
					'firstRootAttribute2' => 'fra2',
					'unknown' => 'This is ignored',
				},
				'__text' => '',
				'URL' => [
					{
						'__attributes' => {},
						'__text' => 'https://example.com/',
					},
				],
				'Bizarre' => [
					{
						'__attributes' => {},
						'__text' => '41',
					}
				],
				'Unsupported' => [
					{
						'__attributes' => {},
						'__text' => 'This is ignored',
					}
				],
			},
		],
		'Metas' => [
			{
				'__attributes' => {},
				'__text' => '',
				'Meta' => [
					{
						'__attributes' => {
							'name' => 'email',
							'value' => 'foo1@example.com',
						},
						'__text' => ''
					},
					{
						'__attributes' => {
							'name' => 'email',
							'value' => 'foo2@example.com',
						},
						'__text' => ''
					},
					{
						'__attributes' => {
							'name' => 'email',
							'value' => 'foo3@example.com',
						},
						'__text' => '',
					}
				],
				'Attribute' => [
					{
						'__attributes' => { 'type' => 'color' },
						'__text' => 'Blue',
					},
					{
						'__attributes' => { 'type' => 'size' },
						'__text' => 'Small',
					}
				]
			}
		],
		'Depth' => [
			{
				'__attributes' => {},
				'__text'       => '',
				'Base'         => [{
					'__attributes' => {},
					'__text' => '',
					'Sub' => [
						{
							'__attributes' => { 'kind' => 'foo' },
							'__text' => '',
							'SubOne' => [
								{
									'__attributes' => {},
									'__text' => 'TestSubOne1',
								}
							],
							'SubTwo' => [
								{
									'__attributes' => {},
									'__text' => 'TestSubTwo1',
								}
							],
						},
						{
							'__attributes' => { 'kind' => 'bar' },
							'__text' => '',
							'SubOne' => [
								{
									'__attributes' => {},
									'__text' => 'TestSubOne2',
								}
							],
							'SubTwo' => [
								{
									'__attributes' => {},
									'__text' => 'TestSubTwo2',
								}
							],
						}
					]
				}]
			}
		],
		'Shallow' => [{
			'__attributes' => {},
			'__text' => '',
			'Inside' => [{
				'__attributes' => { name => 'value' },
				'__text'       => '',
			}]
		}],
		'ShallowIsh' => [{
			'__attributes' => {},
			'__text' => 'This is an example sentence.',
			'Inside' => [{
				'__attributes' => { name => 'value' },
				'__text'       => 'inside text',
			}]
		}],
	},
	'toHash imports a whole document at once'
);
