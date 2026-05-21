#!/usr/bin/env perl

# edge_cases.t - destructive, pathological, and boundary-condition tests
# for XML::PP.  Correctness under adversarial input is the goal.

use strict;
use warnings;

use Test::More;
use Scalar::Util qw(blessed looks_like_number);
use List::Util   qw(reduce);
use Readonly;

use XML::PP;

Readonly::Scalar my $CLASS      => 'XML::PP';

# Depth and width limits for stress tests
# 100 hits Perl's deep-recursion warning threshold exactly; use 50
Readonly::Scalar my $DEEP_NEST => 50;
Readonly::Scalar my $WIDE_KIDS  => 500;
Readonly::Scalar my $LONG_VALUE => 100_000;

END { done_testing() }

# ================================================================
# Empty and near-empty inputs
# ================================================================
subtest 'empty and near-empty inputs' => sub {

	my $p = $CLASS->new();

	subtest 'empty string returns {}' => sub {
		is_deeply($p->parse(''), {}, 'empty string');
	};

	subtest 'undef-equivalent: whitespace only returns {}' => sub {
		# Whitespace gets trimmed; nothing remains to parse
		is_deeply($p->parse('   '), {}, 'whitespace-only input');
	};

	subtest 'only an XML declaration returns {}' => sub {
		# After stripping <?xml?> nothing remains
		is_deeply($p->parse('<?xml version="1.0"?>'), {},
			'XML declaration only returns {}');
	};

	subtest 'only a comment returns {}' => sub {
		is_deeply($p->parse('<!-- just a comment -->'), {},
			'comment-only input returns {}');
	};

	subtest 'scalar ref to empty string returns {}' => sub {
		my $xml = '';
		is_deeply($p->parse(\$xml), {}, 'scalar ref to empty string');
	};
};

# ================================================================
# Malformed XML — strict mode must die, lenient must not
# ================================================================
subtest 'malformed XML handling' => sub {

	my $strict  = $CLASS->new(strict       => 1);
	my $lenient = $CLASS->new(warn_on_error => 1);

	subtest 'unclosed opening tag dies in strict mode' => sub {
		eval { $strict->parse('<root>') };
		ok($@, 'unclosed opening tag dies in strict mode');
	};

	subtest 'mismatched tags dies in strict mode' => sub {
		eval { $strict->parse('<a><b></a></b>') };
		ok($@, 'mismatched tags die in strict mode');
	};

	subtest 'no root element dies in strict mode' => sub {
		eval { $strict->parse('just text') };
		ok($@, 'bare text with no root element dies in strict mode');
	};

	subtest 'multiple root elements — only first is returned' => sub {
		# XML::PP is not validating; it stops after the first root
		local $SIG{__WARN__} = sub { };
		my $result = $lenient->parse('<a/><b/>');
		is($result->{name}, 'a', 'only the first root element returned');
	};

	subtest 'tag with no closing angle bracket dies in strict mode' => sub {
		eval { $strict->parse('<root') };
		ok($@, 'tag missing closing > dies in strict mode');
	};

	subtest 'stray closing tag silently consumed in lenient mode' => sub {
		local $SIG{__WARN__} = sub { };
		my $result = eval { $lenient->parse('</orphan><root/>') };
		# Parser should survive without dying
		ok(!$@ || $result, 'stray closing tag does not crash lenient parser');
	};
};

# ================================================================
# Entity edge cases
# ================================================================
subtest 'entity edge cases' => sub {

	my $p      = $CLASS->new();
	my $strict = $CLASS->new(strict => 1);

	subtest 'all five named entities in a single text node' => sub {
		my $result = $p->parse('<r>&lt;&gt;&amp;&quot;&apos;</r>');
		is($result->{children}[0]{text}, q{<>&"'}, 'all five entities decoded');
	};

	subtest 'entity at start of text node' => sub {
		my $result = $p->parse('<r>&amp;foo</r>');
		is($result->{children}[0]{text}, '&foo', 'entity at start decoded');
	};

	subtest 'entity at end of text node' => sub {
		my $result = $p->parse('<r>foo&amp;</r>');
		is($result->{children}[0]{text}, 'foo&', 'entity at end decoded');
	};

	subtest 'adjacent entities with no separator' => sub {
		my $result = $p->parse('<r>&lt;&gt;&lt;&gt;</r>');
		is($result->{children}[0]{text}, '<><>', 'adjacent entities decoded');
	};

	subtest 'decimal entity for NUL byte (&#0;)' => sub {
		# chr(0) is technically valid in Perl strings
		my $result = $p->parse('<r>&#0;</r>');
		is($result->{children}[0]{text}, chr(0), 'NUL decimal entity decoded');
	};

	subtest 'large decimal numeric entity' => sub {
		# U+1F600 = 😀
		my $result = $p->parse('<r>&#128512;</r>');
		is($result->{children}[0]{text}, chr(128512), 'large decimal entity decoded');
	};

	subtest 'large hex numeric entity' => sub {
		my $result = $p->parse('<r>&#x1F600;</r>');
		is($result->{children}[0]{text}, chr(0x1F600), 'large hex entity decoded');
	};

	subtest 'entity in attribute value decoded' => sub {
		my $result = $p->parse('<r a="&lt;tag&gt;"/>');
		is($result->{attributes}{a}, '<tag>', 'entity in attribute decoded');
	};

	subtest 'multiple entities in attribute value' => sub {
		my $result = $p->parse('<r a="&amp;&amp;&amp;"/>');
		is($result->{attributes}{a}, '&&&', 'multiple entities in attribute decoded');
	};

	subtest 'unknown entity dies in strict mode' => sub {
		eval { $strict->parse('<r>&unknown;</r>') };
		like($@, qr/XML Parsing Error/, 'unknown entity dies in strict mode');
	};

	subtest 'bare ampersand dies in strict mode' => sub {
		eval { $strict->parse('<r>a & b</r>') };
		like($@, qr/XML Parsing Error/, 'bare ampersand dies in strict mode');
	};

	subtest '&amp; followed by semicolon is not a double-decode' => sub {
		# &amp; -> & and then the trailing ; is literal, not another entity
		my $result = $p->parse('<r>&amp;lt;</r>');
		is($result->{children}[0]{text}, '&lt;', '&amp;lt; decodes to &lt; not <');
	};
};

# ================================================================
# Attribute edge cases
# ================================================================
subtest 'attribute edge cases' => sub {

	my $p = $CLASS->new();

	subtest 'empty attribute value' => sub {
		my $result = $p->parse('<r a=""/>');
		is($result->{attributes}{a}, '', 'empty attribute value is empty string');
	};

	subtest 'attribute value containing only whitespace' => sub {
		my $result = $p->parse('<r a="   "/>');
		is($result->{attributes}{a}, '   ', 'whitespace attribute value preserved');
	};

	subtest 'attribute with single-quote delimiters' => sub {
		my $result = $p->parse(q{<r a='hello'/>});
		is($result->{attributes}{a}, 'hello', 'single-quoted attribute parsed');
	};

	subtest 'single-quoted attribute containing double quote' => sub {
		my $result = $p->parse(q{<r a='"quoted"'/>});
		is($result->{attributes}{a}, '"quoted"',
			'double quote inside single-quoted attribute preserved');
	};

	subtest 'double-quoted attribute containing apostrophe' => sub {
		my $result = $p->parse('<r a="it\'s"/>');
		is($result->{attributes}{a}, "it's",
			'apostrophe inside double-quoted attribute preserved');
	};

	subtest 'attribute name with hyphen' => sub {
		my $result = $p->parse('<r data-id="42"/>');
		is($result->{attributes}{'data-id'}, '42', 'hyphenated attribute name parsed');
	};

	subtest 'attribute name with dot' => sub {
		my $result = $p->parse('<r xml.space="preserve"/>');
		is($result->{attributes}{'xml.space'}, 'preserve',
			'dotted attribute name parsed');
	};

	subtest 'attribute name with colon (non-xmlns)' => sub {
		my $result = $p->parse('<r xml:lang="en"/>');
		is($result->{attributes}{'xml:lang'}, 'en',
			'colon in non-xmlns attribute name parsed');
	};

	subtest 'many attributes on one element' => sub {
		# Build an element with 50 attributes
		my @pairs  = map { qq{a$_="$_"} } 1 .. 50;
		my $xml    = '<r ' . join(' ', @pairs) . '/>';
		my $result = $p->parse($xml);
		is(scalar keys %{$result->{attributes}}, 50,
			'50 attributes all parsed');
		is($result->{attributes}{a25}, '25', 'spot-check attribute a25');
	};

	subtest 'xmlns declarations not leaked into attributes hash' => sub {
		my $result = $p->parse('<r xmlns:foo="http://example.com/" foo:bar="baz"/>');
		ok(!exists $result->{attributes}{'xmlns:foo'},
			'xmlns declaration not in attributes hash');
		is($result->{attributes}{'foo:bar'}, 'baz',
			'prefixed non-xmlns attribute present');
	};

	subtest 'attribute value with newline' => sub {
		my $result = $p->parse("<r a=\"line1\nline2\"/>");
		like($result->{attributes}{a}, qr/line1/,
			'attribute value containing newline parsed without dying');
	};
};

# ================================================================
# Deeply nested structures
# ================================================================
subtest 'deeply nested structures' => sub {

	my $p = $CLASS->new();

	subtest "nesting $DEEP_NEST levels deep parses and traverses correctly" => sub {
		# Suppress Perl's deep-recursion warning for this stress test
		local $SIG{__WARN__} = sub {
			warn @_ unless $_[0] =~ /Deep recursion/
		};

		# Build <a><a><a>...</a></a></a> DEEP_NEST levels deep
		my $xml = ('<a>' x $DEEP_NEST) . 'leaf' . ('</a>' x $DEEP_NEST);
		my $result = $p->parse($xml);
		ok(defined $result, 'deeply nested XML parsed without dying');
		is($result->{name}, 'a', 'root element name correct');

		# Walk the spine to the leaf and verify depth
		my $node  = $result;
		my $depth = 0;
		while ($node->{children} && @{$node->{children}}) {
			my ($child) = grep { exists $_->{name} } @{$node->{children}};
			last unless $child;
			$node = $child;
			$depth++;
		}
		# The leaf text node is the final child of the innermost element
		my $leaf = $node->{children}[0]{text};
		is($leaf, 'leaf', "leaf text reachable at depth $depth");
	};

	subtest 'collapse_structure survives deep nesting' => sub {
		my $xml    = ('<level>' x 20) . 'deep' . ('</level>' x 20);
		my $tree   = $p->parse($xml);
		my $result = eval { $p->collapse_structure($tree) };
		ok(!$@, 'collapse_structure does not die on deeply nested input');
	};
};

# ================================================================
# Wide structures (many siblings)
# ================================================================
subtest 'wide structures with many sibling elements' => sub {

	my $p = $CLASS->new();

	subtest "$WIDE_KIDS sibling elements all parsed" => sub {
		my $inner  = join('', map { "<item>$_</item>" } 1 .. $WIDE_KIDS);
		my $xml    = "<list>$inner</list>";
		my $result = $p->parse($xml);
		# Count only element children (not text nodes)
		my @elements = grep { exists $_->{name} } @{$result->{children}};
		is(scalar @elements, $WIDE_KIDS,
			"$WIDE_KIDS sibling elements all present");
	};

	subtest "$WIDE_KIDS siblings collapse to array correctly" => sub {
		my $inner  = join('', map { "<n>$_</n>" } 1 .. $WIDE_KIDS);
		my $tree   = $p->parse("<r>$inner</r>");
		my $result = $p->collapse_structure($tree);
		is(ref($result->{r}{n}), 'ARRAY',
			'many same-name siblings produce an arrayref');
		is(scalar @{$result->{r}{n}}, $WIDE_KIDS,
			"all $WIDE_KIDS values present in collapsed array");
		is($result->{r}{n}[0],            '1',        'first value correct');
		is($result->{r}{n}[$WIDE_KIDS-1], $WIDE_KIDS, 'last value correct');
	};
};

# ================================================================
# Very long values
# ================================================================
subtest 'very long content' => sub {

	my $p = $CLASS->new();

	subtest 'very long text node value' => sub {
		my $text   = 'x' x $LONG_VALUE;
		my $result = $p->parse("<r>$text</r>");
		is(length($result->{children}[0]{text}), $LONG_VALUE,
			"text node of $LONG_VALUE chars preserved in full");
	};

	subtest 'very long attribute value' => sub {
		my $val    = 'a' x $LONG_VALUE;
		my $result = $p->parse(qq{<r id="$val"/>});
		is(length($result->{attributes}{id}), $LONG_VALUE,
			"attribute value of $LONG_VALUE chars preserved in full");
	};

	subtest 'very long tag name' => sub {
		my $tag    = 'e' x 200;
		my $result = $p->parse("<$tag/>");
		is($result->{name}, $tag, 'very long tag name parsed correctly');
	};

	subtest 'very long attribute name' => sub {
		my $attr   = 'a' x 200;
		my $result = $p->parse(qq{<r $attr="val"/>});
		is($result->{attributes}{$attr}, 'val',
			'very long attribute name parsed correctly');
	};
};

# ================================================================
# Unicode and special characters
# ================================================================
subtest 'unicode and special character content' => sub {

	my $p = $CLASS->new();

	subtest 'emoji in text content' => sub {
		my $result = $p->parse('<r>😀🎉🌍</r>');
		is($result->{children}[0]{text}, '😀🎉🌍', 'emoji in text preserved');
	};

	subtest 'CJK characters in text content' => sub {
		my $result = $p->parse('<r>日本語テスト</r>');
		is($result->{children}[0]{text}, '日本語テスト', 'CJK text preserved');
	};

	subtest 'Arabic text in text content' => sub {
		my $result = $p->parse('<r>مرحبا بالعالم</r>');
		is($result->{children}[0]{text}, 'مرحبا بالعالم', 'Arabic text preserved');
	};

	subtest 'unicode in attribute values' => sub {
		my $result = $p->parse('<r label="héllo wörld"/>');
		is($result->{attributes}{label}, 'héllo wörld',
			'accented characters in attribute preserved');
	};

	subtest 'unicode tag name' => sub {
		# XML names may include Unicode letters
		my $result = eval { $p->parse('<données>test</données>') };
		ok(!$@ || defined $result, 'unicode tag name does not crash parser');
	};

	subtest 'newlines and tabs in text content preserved' => sub {
		my $result = $p->parse("<r>line1\n\tline2</r>");
		like($result->{children}[0]{text}, qr/line1/,
			'newline in text content survives');
	};
};

# ================================================================
# Namespace edge cases
# ================================================================
subtest 'namespace edge cases' => sub {

	my $p = $CLASS->new();

	subtest 'empty namespace URI' => sub {
		my $result = $p->parse('<r xmlns:foo=""><foo:child/></r>');
		my $child  = $result->{children}[0];
		# foo resolves to empty string URI
		is($child->{ns_uri}, '', 'empty namespace URI resolved correctly');
	};

	subtest 'very long namespace URI' => sub {
		my $uri    = 'http://example.com/' . ('x' x 1000);
		my $result = $p->parse(qq{<foo:r xmlns:foo="$uri"/>});
		is($result->{ns_uri}, $uri, 'very long namespace URI stored correctly');
	};

	subtest 'namespace redeclared on child element' => sub {
		my $uri1   = 'http://first.example/';
		my $uri2   = 'http://second.example/';
		my $xml    = qq{<a:root xmlns:a="$uri1"><a:child xmlns:a="$uri2"/></a:root>};
		my $result = $p->parse($xml);
		# Root resolves to first URI
		is($result->{ns_uri}, $uri1, 'root uses first namespace URI');
		# Child must resolve to the redeclared URI
		my $child = $result->{children}[0];
		is($child->{ns_uri}, $uri2,
			'child uses redeclared namespace URI');
	};

	subtest 'multiple different prefixes for different children' => sub {
		my $xml = '<root '
			. 'xmlns:a="http://a.example/" '
			. 'xmlns:b="http://b.example/">'
			. '<a:one/><b:two/>'
			. '</root>';
		my $result   = $p->parse($xml);
		my @children = @{$result->{children}};
		is($children[0]{ns_uri}, 'http://a.example/', 'first child ns_uri correct');
		is($children[1]{ns_uri}, 'http://b.example/', 'second child ns_uri correct');
	};
};

# ================================================================
# Self-closing tag edge cases
# ================================================================
subtest 'self-closing tag edge cases' => sub {

	my $p      = $CLASS->new();
	my $strict = $CLASS->new(strict => 1);

	subtest 'self-closing with no attributes and no whitespace' => sub {
		my $result = $p->parse('<br/>');
		is($result->{name}, 'br', 'bare self-closing tag parsed');
		is_deeply($result->{children}, [], 'no children');
	};

	subtest 'self-closing with space before slash' => sub {
		my $result = $p->parse('<br />');
		is($result->{name}, 'br', 'self-closing with space before / parsed');
	};

	subtest 'self-closing with attribute and space before slash' => sub {
		my $result = $p->parse('<img src="x.jpg" />');
		is($result->{attributes}{src}, 'x.jpg',
			'attribute before space-slash parsed');
	};

	subtest 'redundant closing tag after self-closing warns' => sub {
		my $warn_p = $CLASS->new(warn_on_error => 1);
		my $warned  = 0;
		# Must use a variable — _parse_node modifies $$xml_ref in-place
		my $xml = '<br/></br>';
		local $SIG{__WARN__} = sub { $warned++ };
		$warn_p->_parse_node(\$xml, {});
		ok($warned, 'redundant closing tag triggers a warning');
	};

	subtest 'self-closing tag preserves sibling order' => sub {
		my $result   = $p->parse('<p><a/>text<b/></p>');
		my @children = @{$result->{children}};
		# Should have: element a, text node, element b
		my @elements = grep { defined $_->{name} } @children;
		is($elements[0]{name}, 'a', 'first sibling element is a');
		is($elements[1]{name}, 'b', 'second sibling element is b');
	};
};

# ================================================================
# Mixed content (text and element children interleaved)
# ================================================================
subtest 'mixed content edge cases' => sub {

	my $p = $CLASS->new();

	subtest 'text before first child element' => sub {
		my $result   = $p->parse('<p>intro<em>word</em></p>');
		my @children = @{$result->{children}};
		is($children[0]{text}, 'intro', 'leading text node captured');
		is($children[1]{name}, 'em',    'element child follows text node');
	};

	subtest 'whitespace-only text between elements not added as child' => sub {
		my $result   = $p->parse("<r>\n  <a/>\n  <b/>\n</r>");
		my @elements = grep { defined $_->{name} } @{$result->{children}};
		is(scalar @elements, 2,   'two element children');
		is($elements[0]{name}, 'a', 'first element is a');
		is($elements[1]{name}, 'b', 'second element is b');
	};
};

# ================================================================
# collapse_structure edge cases
# ================================================================
subtest 'collapse_structure edge cases' => sub {

	my $p = $CLASS->new();

	subtest 'node with no name key returns {}' => sub {
		is_deeply($p->collapse_structure({ children => [] }), {},
			'node missing name key returns {}');
	};

	subtest 'node with empty children array returns empty inner hash' => sub {
		my $result = $p->collapse_structure({ name => 'r', children => [] });
		is_deeply($result, { r => {} }, 'empty children produce empty inner hash');
	};

	subtest 'child with no name is silently skipped' => sub {
		my $input  = { name => 'r', children => [
			{ text => 'bare' },
			{ name => 'ok', children => [ { text => 'val' } ] },
		] };
		my $result = $p->collapse_structure($input);
		is(scalar keys %{$result->{r}}, 1, 'nameless child skipped');
		is($result->{r}{ok}, 'val',         'named child present');
	};

	subtest 'three or more duplicates all promoted to array' => sub {
		my $input = { name => 'r', children => [
			map { { name => 'x', children => [ { text => $_ } ] } } 1..5
		] };
		my $result = $p->collapse_structure($input);
		is(ref($result->{r}{x}), 'ARRAY', '5 duplicates produce an arrayref');
		is(scalar @{$result->{r}{x}}, 5,  'all 5 values present');
	};

	subtest 'undef input returns {}' => sub {
		is_deeply($p->collapse_structure(undef), {}, 'undef input returns {}');
	};

	subtest 'arrayref input returns {}' => sub {
		is_deeply($p->collapse_structure([1,2,3]), {}, 'arrayref input returns {}');
	};

	subtest 'scalar input returns {}' => sub {
		is_deeply($p->collapse_structure('string'), {}, 'string input returns {}');
	};

	subtest 'child whose text is the string "0" is not skipped' => sub {
		# "0" is defined and non-empty; it must not be filtered by a naive truth check
		my $input  = { name => 'r', children => [
			{ name => 'n', children => [ { text => '0' } ] },
		] };
		my $result = $p->collapse_structure($input);
		is($result->{r}{n}, '0', '"0" text value not skipped');
	};
};

# ================================================================
# Parser instance isolation under error conditions
# ================================================================
subtest 'parser instance isolation under error conditions' => sub {

	subtest 'strict parser reusable after die' => sub {
		my $strict = $CLASS->new(strict => 1);
		eval { $strict->parse('<r>&bogus;</r>') };
		ok($@, 'first parse died as expected');
		my $result = eval { $strict->parse('<ok/>') };
		is($result->{name}, 'ok', 'strict parser reusable after a die');
	};

	subtest 'two parsers with different modes do not share flag state' => sub {
		my $a = $CLASS->new(strict       => 1);
		my $b = $CLASS->new(warn_on_error => 1);
		# Changing internal state of one must not affect the other
		$a->{strict} = 0;
		ok($b->{warn_on_error}, 'modifying one instance does not affect the other');
	};
};

# ================================================================
# Input type boundary conditions for parse()
# ================================================================
subtest 'input type boundary conditions' => sub {

	my $p = $CLASS->new();

	subtest 'scalar ref to valid XML parsed correctly' => sub {
		my $xml    = '<root/>';
		my $result = $p->parse(\$xml);
		is($result->{name}, 'root', 'scalar ref input parsed');
	};

	subtest 'scalar ref to empty string returns {}' => sub {
		my $xml = '';
		is_deeply($p->parse(\$xml), {}, 'scalar ref to empty string returns {}');
	};

	subtest 'parse called with named xml => argument' => sub {
		my $result = $p->parse(xml => '<r/>');
		is($result->{name}, 'r', 'named xml => argument accepted');
	};
};

# ================================================================
# Comment stripping edge cases
# ================================================================
subtest 'comment stripping edge cases' => sub {

	my $p = $CLASS->new();

	subtest 'comment containing what looks like a tag' => sub {
		my $result = $p->parse('<r><!-- <fake/> --><real/></r>');
		my @elements = grep { defined $_->{name} } @{$result->{children}};
		is(scalar @elements, 1,      'only one element child after comment stripped');
		is($elements[0]{name}, 'real', 'real element survives; fake inside comment gone');
	};

	subtest 'comment at start of document before root' => sub {
		my $result = $p->parse('<!-- header comment --><root/>');
		is($result->{name}, 'root', 'leading comment stripped before root');
	};

	subtest 'comment at end of document after root' => sub {
		# After the root is consumed the trailing comment is irrelevant
		my $result = $p->parse('<root/><!-- footer -->');
		is($result->{name}, 'root', 'trailing comment does not affect parse');
	};

	subtest 'nested double-dash inside comment does not prematurely close it' => sub {
		# <!-- ... --> must be consumed as a whole even with -- inside
		my $result = eval {
			$p->parse('<r><!-- a -- b --><c/></r>')
		};
		ok(!$@ || defined $result,
			'comment containing -- handled without crashing');
	};
};

# ================================================================
# XML declaration edge cases
# ================================================================
subtest 'XML declaration edge cases' => sub {

	my $p = $CLASS->new();

	subtest 'declaration with encoding attribute' => sub {
		my $result = $p->parse('<?xml version="1.0" encoding="UTF-8"?><r/>');
		is($result->{name}, 'r', 'declaration with encoding stripped correctly');
	};

	subtest 'declaration with standalone attribute' => sub {
		my $result = $p->parse('<?xml version="1.1" standalone="yes"?><r/>');
		is($result->{name}, 'r', 'declaration with standalone stripped correctly');
	};

	subtest 'declaration with all three attributes' => sub {
		my $result = $p->parse(
			'<?xml version="1.0" encoding="UTF-8" standalone="no"?><r/>');
		is($result->{name}, 'r', 'full XML declaration stripped correctly');
	};
};
