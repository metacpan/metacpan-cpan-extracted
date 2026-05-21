#!/usr/bin/env perl

# unit.t - black-box tests for all public methods in XML::PP,
# exercised strictly through their documented API (POD).
# Non-core external calls are mocked via Test::Mockingbird.

use strict;
use warnings;

use Test::More;
use Test::Mockingbird 0.08;
use Readonly;

use_ok('XML::PP');

Readonly::Scalar my $CLASS => 'XML::PP';

END { done_testing() }

# ================================================================
# new()
# ================================================================
subtest 'new()' => sub {
	subtest 'returns a blessed XML::PP object with no args' => sub {
		my $obj = new_ok($CLASS);
		isa_ok($obj, $CLASS, 'no-arg construction returns an XML::PP object');
	};

	subtest 'accepts strict => 1' => sub {
		# POD: strict causes the parser to die on unknown entities or
		# unescaped ampersands
		my $obj = $CLASS->new(strict => 1);
		isa_ok($obj, $CLASS, 'strict => 1 still returns an XML::PP object');
	};

	subtest 'accepts warn_on_error => 1' => sub {
		my $obj = $CLASS->new(warn_on_error => 1);
		isa_ok($obj, $CLASS, 'warn_on_error => 1 still returns an XML::PP object');
	};

	subtest 'strict enables warn_on_error implicitly' => sub {
		# POD: warn_on_error is enabled automatically when strict is enabled
		my $obj = $CLASS->new(strict => 1);
		ok($obj->{warn_on_error},
			'warn_on_error implicitly set when strict => 1');
	};

	subtest 'accepts a pre-blessed logger object' => sub {
		# POD: logger may be a blessed object understanding warn() and trace()
		my $fake = bless {}, 'FakeLogger';
		my $obj  = $CLASS->new(logger => $fake);
		isa_ok($obj, $CLASS, 'construction with blessed logger succeeds');
	};

	subtest 'accepts a coderef logger' => sub {
		# Log::Abstraction may be absent due to the circular dependency
		# XML::PP -> Log::Abstraction -> Config::Abstraction -> XML::PP
		eval { require Log::Abstraction };
		if($@) {
			plan skip_all => 'Log::Abstraction not installed; skipping coderef logger test';
			return;
		}
		my $obj = $CLASS->new(logger => sub { });
		isa_ok($obj, $CLASS, 'construction with coderef logger succeeds');
	};

	subtest 'accepts an arrayref logger' => sub {
		# Same circular dependency caveat as above
		eval { require Log::Abstraction };
		if($@) {
			plan skip_all => 'Log::Abstraction not installed; skipping arrayref logger test';
			return;
		}
		my $obj = $CLASS->new(logger => []);
		isa_ok($obj, $CLASS, 'construction with arrayref logger succeeds');
	};
};

# ================================================================
# parse()
# ================================================================
subtest 'parse()' => sub {

	my $parser = $CLASS->new();

	subtest 'returns empty hashref for empty string' => sub {
		# POD implies parse returns a tree; empty input is a degenerate case
		my $result = $parser->parse('');
		is_deeply($result, {}, 'empty string returns {}');
	};

	subtest 'returns a hashref with a name field' => sub {
		# POD: returned structure has a name field for the tag name
		my $result = $parser->parse('<note/>');
		is($result->{name}, 'note', 'name field matches root tag');
	};

	subtest 'returns an attributes hashref' => sub {
		# POD: returned structure has an attributes field (hash ref)
		my $result = $parser->parse('<note id="1"/>');
		is(ref($result->{attributes}), 'HASH', 'attributes field is a hashref');
		is($result->{attributes}{id},  '1',    'attribute value correct');
	};

	subtest 'returns a children arrayref' => sub {
		# POD: returned structure has a children field (array ref)
		my $result = $parser->parse('<root><child/></root>');
		is(ref($result->{children}), 'ARRAY', 'children field is an arrayref');
	};

	subtest 'text content appears as a child text node' => sub {
		# POD: children may be text nodes or further elements
		my $result = $parser->parse('<msg>Hello</msg>');
		my $child  = $result->{children}[0];
		ok(exists $child->{text},    'text node has a text key');
		is($child->{text}, 'Hello',  'text node value correct');
	};

	subtest 'child elements are represented as hashrefs with name' => sub {
		my $result = $parser->parse('<root><item/></root>');
		my $child  = $result->{children}[0];
		is(ref($child),    'HASH',  'child element is a hashref');
		is($child->{name}, 'item',  'child name field set correctly');
	};

	subtest 'namespace prefix captured in ns field' => sub {
		# POD: ns field holds the namespace prefix
		my $xml    = '<soap:Body xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/"/>';
		my $result = $parser->parse($xml);
		is($result->{ns},   'soap', 'ns field holds namespace prefix');
		is($result->{name}, 'Body', 'name field holds local name only');
	};

	subtest 'namespace URI captured in ns_uri field' => sub {
		# POD: ns_uri field holds the namespace URI
		my $uri    = 'http://schemas.xmlsoap.org/soap/envelope/';
		my $xml    = qq{<soap:Body xmlns:soap="$uri"/>};
		my $result = $parser->parse($xml);
		is($result->{ns_uri}, $uri, 'ns_uri field holds resolved namespace URI');
	};

	subtest 'ns and ns_uri are undef when no namespace present' => sub {
		my $result = $parser->parse('<root/>');
		is($result->{ns},     undef, 'ns is undef when no prefix');
		is($result->{ns_uri}, undef, 'ns_uri is undef when no namespace');
	};

	subtest 'multiple attributes all captured' => sub {
		my $result = $parser->parse('<tag a="1" b="2" c="3"/>');
		is($result->{attributes}{a}, '1', 'attribute a');
		is($result->{attributes}{b}, '2', 'attribute b');
		is($result->{attributes}{c}, '3', 'attribute c');
	};

	subtest 'deeply nested children parsed correctly' => sub {
		my $xml    = '<a><b><c>deep</c></b></a>';
		my $result = $parser->parse($xml);
		# Walk the tree: a -> b -> c -> text
		my $b    = $result->{children}[0];
		my $c    = $b->{children}[0];
		my $text = $c->{children}[0];
		is($b->{name},    'b',    'second-level child name correct');
		is($c->{name},    'c',    'third-level child name correct');
		is($text->{text}, 'deep', 'leaf text node correct');
	};

	subtest 'XML declaration in input is silently consumed' => sub {
		my $xml    = '<?xml version="1.0" encoding="UTF-8"?><root/>';
		my $result = $parser->parse($xml);
		# The declaration must not appear in the returned tree
		is($result->{name}, 'root',
			'XML declaration stripped; root element still parsed');
	};

	subtest 'comments in input are silently consumed' => sub {
		my $xml    = '<root><!-- a comment --><child/></root>';
		my $result = $parser->parse($xml);
		# The comment must not appear as a child node
		is(scalar @{$result->{children}}, 1,
			'comment stripped; one element child remains');
	};

	subtest 'scalar ref to XML string accepted' => sub {
		# POD does not forbid this; parse() dereferences scalar refs
		my $xml    = '<root/>';
		my $result = $parser->parse(\$xml);
		is($result->{name}, 'root', 'scalar ref input accepted');
	};

	subtest 'strict mode dies on unknown entity' => sub {
		my $strict = $CLASS->new(strict => 1);
		eval { $strict->parse('<root>&unknown;</root>') };
		like($@, qr/XML Parsing Error/i,
			'strict mode dies on unknown entity in content');
	};

	subtest 'warn_on_error mode warns on unknown entity' => sub {
		my $warn_parser = $CLASS->new(warn_on_error => 1);
		my $warned      = 0;
		local $SIG{__WARN__} = sub { $warned++ };
		$warn_parser->parse('<root>&unknown;</root>');
		ok($warned, 'warn_on_error emits a Perl warning on unknown entity');
	};

	subtest 'standard named entities decoded in text content' => sub {
		my $xml    = '<root>&lt;&gt;&amp;&quot;&apos;</root>';
		my $result = $parser->parse($xml);
		is($result->{children}[0]{text}, '<>&"\'',
			'all five predefined XML entities decoded in text');
	};

	subtest 'decimal numeric entity decoded in text content' => sub {
		# &#65; is the decimal reference for 'A'
		my $result = $parser->parse('<root>&#65;</root>');
		is($result->{children}[0]{text}, 'A',
			'decimal numeric entity decoded correctly');
	};

	subtest 'hex numeric entity decoded in text content' => sub {
		# &#x41; is the hex reference for 'A'
		my $result = $parser->parse('<root>&#x41;</root>');
		is($result->{children}[0]{text}, 'A',
			'hex numeric entity decoded correctly');
	};

	subtest 'SYNOPSIS example parses correctly' => sub {
		# Taken verbatim from the POD SYNOPSIS to verify the documented example
		my $xml = '<note id="1"><to priority="high">Tove</to><from>Jani</from>'
			. '<heading>Reminder</heading>'
			. '<body importance="high">Don\'t forget me this weekend!</body></note>';
		my $tree = $parser->parse($xml);
		is($tree->{name},                    'note', 'root name is note');
		is($tree->{children}[0]->{name},     'to',   'first child is to');
		is($tree->{attributes}{id},          '1',    'root id attribute correct');
		is($tree->{children}[0]{attributes}{priority}, 'high',
			'child priority attribute correct');
	};
};

# ================================================================
# collapse_structure()
# ================================================================
subtest 'collapse_structure()' => sub {

	my $parser = $CLASS->new();

	subtest 'SYNOPSIS example collapses correctly' => sub {
		# POD SYNOPSIS example used as the canonical black-box reference
		my $input = {
			name     => 'note',
			children => [
				{ name => 'to',      children => [ { text => 'Tove'     } ] },
				{ name => 'from',    children => [ { text => 'Jani'     } ] },
				{ name => 'heading', children => [ { text => 'Reminder' } ] },
				{ name => 'body',    children => [
					{ text => "Don't forget me this weekend!" }
				] },
			],
			attributes => { id => 'n1' },
		};
		my $result   = $parser->collapse_structure($input);
		my $expected = {
			note => {
				to      => 'Tove',
				from    => 'Jani',
				heading => 'Reminder',
				body    => "Don't forget me this weekend!",
			}
		};
		is_deeply($result, $expected, 'POD SYNOPSIS example collapses correctly');
	};

	subtest 'returns a hashref' => sub {
		my $input  = { name => 'root', children => [
			{ name => 'a', children => [ { text => '1' } ] }
		] };
		my $result = $parser->collapse_structure($input);
		is(ref($result), 'HASH', 'collapse_structure always returns a hashref');
	};

	subtest 'result is wrapped under the root element name' => sub {
		# POD: the final result is wrapped in the node name as the top-level key
		my $input  = { name => 'wrapper', children => [
			{ name => 'x', children => [ { text => 'y' } ] }
		] };
		my $result = $parser->collapse_structure($input);
		ok(exists $result->{wrapper}, 'top-level key is the root element name');
	};

	subtest 'child text content mapped to element name as key' => sub {
		# POD: each child element is mapped to its name as the key,
		# and the text content is mapped as the corresponding value
		my $input  = { name => 'root', children => [
			{ name => 'city', children => [ { text => 'London' } ] }
		] };
		my $result = $parser->collapse_structure($input);
		is($result->{root}{city}, 'London', 'child text mapped to element name');
	};

	subtest 'empty or undef input returns empty hashref' => sub {
		is_deeply($parser->collapse_structure(undef),  {}, 'undef returns {}');
		is_deeply($parser->collapse_structure({}),     {}, 'empty hash returns {}');
	};

	subtest 'children with empty text are excluded from result' => sub {
		my $input  = { name => 'root', children => [
			{ name => 'blank', children => [ { text => '' } ] },
			{ name => 'full',  children => [ { text => 'ok' } ] },
		] };
		my $result = $parser->collapse_structure($input);
		ok(!exists $result->{root}{blank}, 'empty text child excluded');
		is($result->{root}{full}, 'ok',    'non-empty text child present');
	};

	subtest 'duplicate element names collapsed into an arrayref' => sub {
		# POD implies multiple same-name children produce an array
		my $input = { name => 'list', children => [
			{ name => 'item', children => [ { text => 'one'   } ] },
			{ name => 'item', children => [ { text => 'two'   } ] },
			{ name => 'item', children => [ { text => 'three' } ] },
		] };
		my $result = $parser->collapse_structure($input);
		is(ref($result->{list}{item}), 'ARRAY',
			'duplicate element names produce an arrayref');
		is_deeply($result->{list}{item}, [ 'one', 'two', 'three' ],
			'all values preserved in document order');
	};

	subtest 'nested child structure recursed and collapsed' => sub {
		# POD: the function collapses nested hash structures
		my $input = { name => 'outer', children => [
			{ name => 'inner', children => [
				{ name => 'leaf', children => [ { text => 'val' } ] },
			] },
		] };
		my $result = $parser->collapse_structure($input);
		is_deeply($result, { outer => { inner => { leaf => 'val' } } },
			'nested structure recursed and collapsed to nested hash');
	};

	subtest 'round-trips correctly via parse then collapse_structure' => sub {
		# Verify the two public methods compose correctly end-to-end
		my $xml      = '<note><to>Tove</to><from>Jani</from></note>';
		my $tree     = $parser->parse($xml);
		my $result   = $parser->collapse_structure($tree);
		my $expected = { note => { to => 'Tove', from => 'Jani' } };
		is_deeply($result, $expected,
			'parse() then collapse_structure() round-trip produces correct result');
	};
};
