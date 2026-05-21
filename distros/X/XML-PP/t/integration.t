#!/usr/bin/env perl

# integration.t - end-to-end black-box tests for XML::PP exercising
# multiple routines together, stateful behaviour across calls, and
# integration with other packages (Params::Get, Log::Abstraction,
# Return::Set, Scalar::Util).  No mocking — all dependencies are real.

use strict;
use warnings;

use Test::More;
use Scalar::Util qw(blessed);
use File::Temp qw(tempfile);
use Readonly;

use XML::PP;

Readonly::Scalar my $CLASS    => 'XML::PP';
Readonly::Scalar my $SOAP_URI => 'http://schemas.xmlsoap.org/soap/envelope/';

END { done_testing() }

# ================================================================
# Parser state is independent between instances
# ================================================================
subtest 'independent parser instances do not share state' => sub {

	my $strict  = $CLASS->new(strict       => 1);
	my $lenient = $CLASS->new(warn_on_error => 1);

	# Both parsers must coexist without contaminating each other's flags
	ok($strict->{strict},          'strict instance has strict set');
	ok(!$lenient->{strict},        'lenient instance does not inherit strict');
	ok($strict->{warn_on_error},   'strict instance has warn_on_error implied');
	ok($lenient->{warn_on_error},  'lenient instance has warn_on_error set');

	# A valid document must parse cleanly on both
	my $xml   = '<root><child>text</child></root>';
	my $tree1 = $strict->parse($xml);
	my $tree2 = $lenient->parse($xml);
	is_deeply($tree1, $tree2, 'same XML produces identical trees from both parsers');
};

# ================================================================
# Repeated parse() calls on the same instance
# ================================================================
subtest 'same parser instance reused across multiple parse() calls' => sub {

	my $parser = $CLASS->new();

	# Parse two completely different documents in sequence
	my $tree1 = $parser->parse('<a><b>1</b></a>');
	my $tree2 = $parser->parse('<x><y>2</y></x>');

	# Each result must reflect only its own document
	is($tree1->{name},                   'a', 'first parse: root name correct');
	is($tree1->{children}[0]{name},      'b', 'first parse: child name correct');
	is($tree1->{children}[0]{children}[0]{text}, '1',
		'first parse: leaf text correct');

	is($tree2->{name},                   'x', 'second parse: root name correct');
	is($tree2->{children}[0]{name},      'y', 'second parse: child name correct');
	is($tree2->{children}[0]{children}[0]{text}, '2',
		'second parse: leaf text correct');

	# Prior result must be unaffected by the subsequent parse
	is($tree1->{name}, 'a', 'first result unchanged after second parse');
};

# ================================================================
# parse() feeding collapse_structure()
# ================================================================
subtest 'parse() then collapse_structure() round-trip' => sub {

	my $parser = $CLASS->new();

	subtest 'POD SYNOPSIS round-trip' => sub {
		my $xml = '<note id="1">'
			. '<to priority="high">Tove</to>'
			. '<from>Jani</from>'
			. '<heading>Reminder</heading>'
			. '<body importance="high">Don\'t forget me this weekend!</body>'
			. '</note>';

		my $tree     = $parser->parse($xml);
		my $result   = $parser->collapse_structure($tree);

		# Top-level key must be the root element name
		ok(exists $result->{note}, 'top-level key is the root element name');

		# Child text values must be present after collapsing
		is($result->{note}{to},      'Tove',     'to child collapsed correctly');
		is($result->{note}{from},    'Jani',     'from child collapsed correctly');
		is($result->{note}{heading}, 'Reminder', 'heading child collapsed correctly');
		like($result->{note}{body},  qr/weekend/, 'body child collapsed correctly');
	};

	subtest 'repeated same-name children become an arrayref after round-trip' => sub {
		my $xml    = '<items><item>one</item><item>two</item><item>three</item></items>';
		my $tree   = $parser->parse($xml);
		my $result = $parser->collapse_structure($tree);

		is(ref($result->{items}{item}), 'ARRAY',
			'repeated children produce an arrayref');
		is_deeply($result->{items}{item}, [qw(one two three)],
			'repeated children values in document order');
	};

	subtest 'deeply nested round-trip' => sub {
		my $xml    = '<a><b><c><d>leaf</d></c></b></a>';
		my $tree   = $parser->parse($xml);
		my $result = $parser->collapse_structure($tree);

		is_deeply($result, { a => { b => { c => { d => 'leaf' } } } },
			'four levels of nesting survive round-trip');
	};
};

# ================================================================
# Entity handling end-to-end
# ================================================================
subtest 'entity decoding flows through parse() to the returned tree' => sub {

	my $parser = $CLASS->new();

	subtest 'all five predefined entities decoded in text content' => sub {
		my $result = $parser->parse('<r>&lt;&gt;&amp;&quot;&apos;</r>');
		is($result->{children}[0]{text}, q{<>&"'},
			'all five predefined entities decoded in text');
	};

	subtest 'all five predefined entities decoded in attribute values' => sub {
		my $result = $parser->parse('<r a="&lt;&gt;&amp;&quot;&apos;"/>');
		is($result->{attributes}{a}, q{<>&"'},
			'all five predefined entities decoded in attributes');
	};

	subtest 'decimal numeric entity decoded in text and attributes' => sub {
		# &#65; = A, &#66; = B
		my $result = $parser->parse('<r id="&#65;">&#66;</r>');
		is($result->{attributes}{id},          'A', 'decimal entity in attribute');
		is($result->{children}[0]{text},        'B', 'decimal entity in text');
	};

	subtest 'hex numeric entity decoded in text and attributes' => sub {
		# &#x41; = A, &#x42; = B
		my $result = $parser->parse('<r id="&#x41;">&#x42;</r>');
		is($result->{attributes}{id},          'A', 'hex entity in attribute');
		is($result->{children}[0]{text},        'B', 'hex entity in text');
	};

	subtest 'entities survive through collapse_structure' => sub {
		my $xml    = '<root><sym>&lt;</sym></root>';
		my $tree   = $parser->parse($xml);
		my $result = $parser->collapse_structure($tree);
		is($result->{root}{sym}, '<', 'decoded entity preserved through collapse');
	};
};

# ================================================================
# Namespace handling end-to-end
# ================================================================
subtest 'namespace handling flows through parse() to the returned tree' => sub {

	my $parser = $CLASS->new();

	subtest 'single namespace declared on root element' => sub {
		my $xml    = qq{<soap:Body xmlns:soap="$SOAP_URI"/>};
		my $result = $parser->parse($xml);
		is($result->{name},   'Body',     'local name excludes prefix');
		is($result->{ns},     'soap',     'namespace prefix captured');
		is($result->{ns_uri}, $SOAP_URI,  'namespace URI resolved');
	};

	subtest 'multiple namespace prefixes on same element' => sub {
		my $xml = '<root '
			. qq{xmlns:a="http://a.example/" }
			. qq{xmlns:b="http://b.example/"}
			. '><a:child/></root>';
		my $result = $parser->parse($xml);
		my $child  = $result->{children}[0];
		is($child->{ns},     'a',                  'child prefix captured');
		is($child->{ns_uri}, 'http://a.example/',  'child namespace URI resolved');
	};

	subtest 'elements without namespace have undef ns and ns_uri' => sub {
		my $result = $parser->parse('<plain/>');
		is($result->{ns},     undef, 'ns is undef for unprefixed element');
		is($result->{ns_uri}, undef, 'ns_uri is undef for unprefixed element');
	};
	# Default xmlns="" declarations are recorded in the internal nsmap for
	# child resolution but are not exposed on the root node's ns_uri field,
	# since ns_uri is only set for explicitly prefixed elements.
};

# ================================================================
# Strict mode end-to-end
# ================================================================
subtest 'strict mode behaviour across parse() and error paths' => sub {

	my $strict = $CLASS->new(strict => 1);

	subtest 'strict parser dies on unknown entity in text' => sub {
		eval { $strict->parse('<r>&bogus;</r>') };
		like($@, qr/XML Parsing Error/i,
			'strict mode dies on unknown entity in element text');
	};

	subtest 'strict parser dies on unescaped ampersand in text' => sub {
		eval { $strict->parse('<r>foo & bar</r>') };
		like($@, qr/XML Parsing Error/i,
			'strict mode dies on bare ampersand in element text');
	};

	subtest 'strict parser dies on invalid XML structure' => sub {
		eval { $strict->parse('not xml at all') };
		like($@, qr/XML Parsing Error/i,
			'strict mode dies when no valid opening tag found');
	};

	subtest 'strict parser succeeds on valid XML after a failed parse' => sub {
		# A failed parse must not poison the instance for subsequent calls
		eval { $strict->parse('<r>&bogus;</r>') };
		my $result = eval { $strict->parse('<ok/>') };
		is($result->{name}, 'ok',
			'strict parser still usable after a prior failed parse');
	};
};

# ================================================================
# warn_on_error mode end-to-end
# ================================================================
subtest 'warn_on_error mode emits warnings rather than dying' => sub {

	my $parser = $CLASS->new(warn_on_error => 1);

	subtest 'unknown entity warns but does not die' => sub {
		my $warned = 0;
		local $SIG{__WARN__} = sub { $warned++ };
		my $result = eval { $parser->parse('<r>&bogus;</r>') };
		ok(!$@,     'no die in warn_on_error mode');
		ok($warned, 'a warning was emitted for the unknown entity');
	};

	subtest 'subsequent parse succeeds after a warned parse' => sub {
		local $SIG{__WARN__} = sub { };	# suppress noise
		$parser->parse('<r>&bogus;</r>');
		my $result = $parser->parse('<ok/>');
		is($result->{name}, 'ok',
			'parser usable after a warned parse');
	};
};

# ================================================================
# Logger integration (Log::Abstraction)
# ================================================================
subtest 'logger integration with Log::Abstraction' => sub {
	# Skip the entire block if Log::Abstraction is not yet installed;
	# the circular dependency XML::PP -> Log::Abstraction ->
	# Config::Abstraction -> XML::PP means it may legitimately be absent
	# on a fresh install or CI machine building XML::PP first
	eval { require Log::Abstraction };
	if($@) {
		plan skip_all => 'Log::Abstraction not installed; skipping logger integration tests';
		return;
	}

	subtest 'coderef logger receives warn messages' => sub {
		my @messages;
		# POD: logger may be a reference to code
		my $parser = $CLASS->new(
			warn_on_error => 1,
			logger        => sub { push @messages, @_ },
		);
		$parser->parse('<r>&bogus;</r>');
		# Log::Abstraction wraps the coderef; verify it was invoked at least once
		# without assuming the internal calling convention or message format
		ok(scalar @messages > 0, 'coderef logger was invoked at least once');
	};

	subtest 'arrayref logger collects messages' => sub {
		my @log;
		# POD: logger may be a reference to an array
		my $parser = $CLASS->new(
			warn_on_error => 1,
			logger        => \@log,
		);
		$parser->parse('<r>&bogus;</r>');
		ok(scalar @log > 0, 'arrayref logger collected at least one entry');
	};

	subtest 'pre-blessed logger object used directly' => sub {
		# POD: logger may be a blessed object understanding warn() and trace()
		my @calls;
		my $fake = bless {}, 'FakeLogger';
		{
			no strict 'refs';
			# Inject warn() and notice() into FakeLogger for this scope
			*{'FakeLogger::warn'}   = sub { push @calls, ['warn',   $_[1]] };
			*{'FakeLogger::notice'} = sub { push @calls, ['notice', $_[1]] };
			*{'FakeLogger::fatal'}  = sub { push @calls, ['fatal',  $_[1]] };
		}
		my $parser = $CLASS->new(warn_on_error => 1, logger => $fake);
		$parser->parse('<r>&bogus;</r>');
		ok(scalar @calls > 0, 'pre-blessed logger object received method calls');
	};
};

# ================================================================
# Integration with Params::Get (named and positional argument forms)
# ================================================================
subtest 'Params::Get integration: parse() accepts multiple calling conventions' => sub {

	my $parser = $CLASS->new();

	subtest 'plain positional scalar' => sub {
		my $result = $parser->parse('<root/>');
		is($result->{name}, 'root', 'positional scalar accepted');
	};

	subtest 'named argument hash' => sub {
		my $result = $parser->parse(xml => '<root/>');
		is($result->{name}, 'root', 'named argument form accepted');
	};

	subtest 'scalar ref' => sub {
		my $xml    = '<root/>';
		my $result = $parser->parse(\$xml);
		is($result->{name}, 'root', 'scalar ref accepted and dereferenced');
	};
};

# ================================================================
# Comment and processing-instruction stripping
# ================================================================
subtest 'preprocessing strips comments and XML declaration before parsing' => sub {

	my $parser = $CLASS->new();

	subtest 'XML declaration stripped silently' => sub {
		my $result = $parser->parse(
			'<?xml version="1.0" encoding="UTF-8"?><root/>');
		is($result->{name}, 'root',
			'XML declaration stripped; root parsed correctly');
	};

	subtest 'single-line comment stripped' => sub {
		my $result = $parser->parse('<root><!-- comment --><a/></root>');
		is(scalar @{$result->{children}}, 1,  'comment removed; one child remains');
		is($result->{children}[0]{name},  'a', 'surviving child is correct');
	};

	subtest 'multi-line comment stripped' => sub {
		my $xml = "<root><!--\n  multi\n  line\n--><a/></root>";
		my $result = $parser->parse($xml);
		is($result->{children}[0]{name}, 'a',
			'multi-line comment stripped; child survives');
	};

	subtest 'multiple comments all stripped' => sub {
		my $xml    = '<root><!-- one --><a/><!-- two --><b/></root>';
		my $result = $parser->parse($xml);
		is(scalar @{$result->{children}}, 2,
			'both comments stripped; two element children remain');
	};
};

# ================================================================
# Self-closing tags end-to-end
# ================================================================
subtest 'self-closing tags parsed correctly end-to-end' => sub {

	my $parser = $CLASS->new();

	subtest 'bare self-closing tag' => sub {
		my $result = $parser->parse('<br/>');
		is($result->{name},            'br', 'self-closing tag name correct');
		is_deeply($result->{children}, [],   'self-closing tag has no children');
	};

	subtest 'self-closing tag with attributes' => sub {
		my $result = $parser->parse('<img src="photo.jpg" alt="photo"/>');
		is($result->{attributes}{src}, 'photo.jpg', 'src attribute correct');
		is($result->{attributes}{alt}, 'photo',     'alt attribute correct');
	};

	subtest 'self-closing sibling inside parent element' => sub {
		my $result   = $parser->parse('<p>Hello<br/>World</p>');
		my @children = @{$result->{children}};
		ok(scalar @children >= 2, 'parent has at least two children');
		# Guard against text nodes which have no name key
		my ($br) = grep { ref $_ eq 'HASH' && defined $_->{name} && $_->{name} eq 'br' } @children;
		ok(defined $br, 'br self-closing child found among siblings');
	};
};

# ================================================================
# Return::Set integration — return type contract
# ================================================================
subtest 'parse() return type contract enforced by Return::Set' => sub {

	my $parser = $CLASS->new();

	subtest 'parse always returns a defined value' => sub {
		my $result = $parser->parse('<root/>');
		ok(defined $result, 'parse returns a defined value');
	};

	subtest 'parse always returns a hashref for valid XML' => sub {
		my $result = $parser->parse('<root/>');
		is(ref($result), 'HASH', 'parse returns a hashref');
	};

	subtest 'collapse_structure always returns a hashref' => sub {
		my $result = $parser->collapse_structure(
			{ name => 'r', children => [ { name => 'a', children => [ { text => '1' } ] } ] }
		);
		is(ref($result), 'HASH', 'collapse_structure returns a hashref');
	};
};

# ================================================================
# Whitespace handling
# ================================================================
subtest 'whitespace handling across parse() and collapse_structure()' => sub {

	my $parser = $CLASS->new();

	subtest 'leading and trailing whitespace around root element stripped' => sub {
		my $result = $parser->parse("   <root/>   ");
		is($result->{name}, 'root', 'surrounding whitespace stripped');
	};

	subtest 'text node whitespace trimmed' => sub {
		my $result = $parser->parse("<root>  hello  </root>");
		is($result->{children}[0]{text}, 'hello',
			'text node leading and trailing whitespace trimmed');
	};

	subtest 'whitespace-only text nodes not added as children' => sub {
		my $result = $parser->parse("<root>   </root>");
		is(scalar @{$result->{children}}, 0,
			'whitespace-only text produces no child node');
	};
};

# ================================================================
# Real-world XML document round-trips
# ================================================================
subtest 'real-world XML document round-trips' => sub {

	my $parser = $CLASS->new();

	subtest 'RSS-style feed snippet' => sub {
		my $xml = '<?xml version="1.0" encoding="UTF-8"?>'
			. '<rss version="2.0">'
			.   '<channel>'
			.     '<title>My Feed</title>'
			.     '<link>https://example.com</link>'
			.     '<item><title>Post 1</title></item>'
			.     '<item><title>Post 2</title></item>'
			.   '</channel>'
			. '</rss>';
		my $tree   = $parser->parse($xml);
		my $result = $parser->collapse_structure($tree);

		is($tree->{name},              'rss',     'RSS root name correct');
		is($tree->{attributes}{version}, '2.0',   'RSS version attribute correct');

		my $channel = $result->{rss}{channel};
		is($channel->{title}, 'My Feed',          'channel title collapsed');
		is(ref($channel->{item}), 'ARRAY',         'multiple items collapsed to array');
		is(scalar @{$channel->{item}}, 2,          'both items present');
	};

	subtest 'SOAP envelope snippet' => sub {
		my $xml = '<soap:Envelope'
			. qq{ xmlns:soap="$SOAP_URI"}
			. '>'
			.   '<soap:Header/>'
			.   '<soap:Body>'
			.     '<m:GetPrice xmlns:m="https://www.w3schools.com/prices">'
			.       '<m:Item>Apples</m:Item>'
			.     '</m:GetPrice>'
			.   '</soap:Body>'
			. '</soap:Envelope>';

		my $tree = $parser->parse($xml);
		is($tree->{name},   'Envelope', 'SOAP root local name correct');
		is($tree->{ns},     'soap',     'SOAP root namespace prefix correct');
		is($tree->{ns_uri}, $SOAP_URI,  'SOAP root namespace URI correct');

		# Body must be present as a child element
		my ($body) = grep { ref $_ eq 'HASH' && $_->{name} eq 'Body' }
			@{$tree->{children}};
		ok(defined $body, 'soap:Body child found');
		is($body->{ns},   'soap', 'body namespace prefix correct');
	};

	subtest 'SVG-style markup snippet' => sub {
		my $xml = '<svg width="100" height="100" xmlns="http://www.w3.org/2000/svg">'
			. '<circle cx="50" cy="50" r="40" fill="red"/>'
			. '<rect x="10" y="10" width="30" height="30"/>'
			. '</svg>';

		my $tree     = $parser->parse($xml);
		my @children = @{$tree->{children}};

		is($tree->{name},                'svg',   'SVG root name correct');
		is($tree->{attributes}{width},   '100',   'width attribute correct');
		is($tree->{attributes}{height},  '100',   'height attribute correct');
		is(scalar @children,             2,        'two child elements');
		is($children[0]{name},           'circle', 'first child is circle');
		is($children[1]{name},           'rect',   'second child is rect');
		is($children[0]{attributes}{fill}, 'red',  'circle fill attribute correct');
	};
};
