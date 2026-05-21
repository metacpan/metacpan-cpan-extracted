#!/usr/bin/env perl

# extended_tests.t - additional tests targeting uncovered branches, LCSAJ path
# sequences, and conditions not fully exercised by function.t, unit.t,
# integration.t, or edge_cases.t.
# Goal: push statement coverage above 95% and maximise TER3 score.

use strict;
use warnings;

use Test::More;
use Scalar::Util qw(blessed);
use File::Temp   qw(tempfile);
use Readonly;

use XML::PP;

Readonly::Scalar my $CLASS => 'XML::PP';

END { done_testing() }

# ================================================================
# new() — filename string logger (requires Log::Abstraction)
# ================================================================
subtest 'new() with filename logger' => sub {
	eval { require Log::Abstraction };
	if($@) {
		plan skip_all => 'Log::Abstraction not installed';
		return;
	}
	# POD: logger may be a filename; Log::Abstraction wraps it in a blessed object
	my ($fh, $filename) = tempfile(UNLINK => 1, SUFFIX => '.log');
	close $fh;
	my $obj = $CLASS->new(logger => $filename);
	isa_ok($obj, $CLASS,               'filename logger: returns XML::PP object');
	ok(blessed($obj->{logger}),        'filename logger wrapped in a blessed object');
};

# ================================================================
# _handle_error() — full six-mode matrix covering every branch combination
# ================================================================
subtest '_handle_error() mode-and-logger matrix' => sub {

	Readonly::Scalar my $MSG => 'matrix test error';

	# Build a fake logger that records calls by method name without
	# needing Log::Abstraction to be installed
	my $make_logger = do {
		my $counter = 0;
		sub {
			my @log;
			my $pkg  = 'MatrixLogger' . ++$counter;
			my $fake = bless { log => \@log }, $pkg;
			{
				no strict 'refs';
				for my $method (qw(fatal warn notice)) {
					my $m = $method;
					*{"${pkg}::$m"} = sub {
						push @{$_[0]->{log}}, [$m, $_[1]];
					};
				}
			}
			return ($fake, \@log);
		};
	};

	subtest 'strict=1 + logger: fatal() called then dies' => sub {
		my ($logger, $log) = $make_logger->();
		my $obj = bless { strict => 1, warn_on_error => 1, logger => $logger }, $CLASS;
		eval { $obj->_handle_error($MSG) };
		ok($@,                          'dies in strict+logger mode');
		ok(scalar @{$log} > 0,         'logger method called before die');
		is($log->[0][0], 'fatal',       'fatal() called for strict mode');
		like($log->[0][1], qr/\Q$MSG\E/, 'logged message contains error text');
	};

	subtest 'strict=1 + no logger: dies with prefixed message' => sub {
		my $obj = bless { strict => 1, warn_on_error => 1 }, $CLASS;
		eval { $obj->_handle_error($MSG) };
		like($@, qr/XML::PP.*XML Parsing Error.*\Q$MSG\E/,
			'strict+no-logger dies with fully prefixed message');
	};

	subtest 'warn_on_error=1 + logger: warn() called, no die' => sub {
		my ($logger, $log) = $make_logger->();
		my $obj = bless { strict => 0, warn_on_error => 1, logger => $logger }, $CLASS;
		my $warned = 0;
		local $SIG{__WARN__} = sub { $warned++ };
		eval { $obj->_handle_error($MSG) };
		ok(!$@,                         'does not die in warn+logger mode');
		ok(!$warned,                    'no Perl warning when logger present');
		ok(scalar @{$log} > 0,         'logger method called');
		is($log->[0][0], 'warn',        'warn() called for warn_on_error mode');
	};

	subtest 'warn_on_error=1 + no logger: Perl warning emitted' => sub {
		my $obj    = bless { strict => 0, warn_on_error => 1 }, $CLASS;
		my $warned = 0;
		local $SIG{__WARN__} = sub { $warned++ };
		$obj->_handle_error($MSG);
		ok($warned, 'Perl warning emitted in warn+no-logger mode');
	};

	subtest 'default mode + logger: notice() called, no die, no Perl warn' => sub {
		# This is the previously untested branch: neither flag set, logger present
		my ($logger, $log) = $make_logger->();
		my $obj    = bless { strict => 0, warn_on_error => 0, logger => $logger }, $CLASS;
		my $warned = 0;
		local $SIG{__WARN__} = sub { $warned++ };
		eval { $obj->_handle_error($MSG) };
		ok(!$@,                         'does not die in default+logger mode');
		ok(!$warned,                    'no Perl warning in default+logger mode');
		ok(scalar @{$log} > 0,         'logger method called');
		is($log->[0][0], 'notice',      'notice() called in default+logger mode');
		like($log->[0][1], qr/\Q$MSG\E/, 'notice message contains error text');
	};

	subtest 'default mode + no logger: prints to STDERR only' => sub {
		my $obj    = bless { strict => 0, warn_on_error => 0 }, $CLASS;
		my $stderr = '';
		my $warned = 0;
		local $SIG{__WARN__} = sub { $warned++ };
		# Redirect STDERR to a scalar so we can inspect it
		open(my $saved, '>&', \*STDERR) or die "Cannot dup STDERR: $!";
		close STDERR;
		open(STDERR, '>', \$stderr)      or die "Cannot redirect STDERR: $!";
		eval { $obj->_handle_error($MSG) };
		close STDERR;
		open(STDERR, '>&', $saved)       or die "Cannot restore STDERR: $!";
		close $saved;
		ok(!$@,                          'does not die in default+no-logger mode');
		ok(!$warned,                     'no Perl warning in default+no-logger mode');
		like($stderr, qr/\Q$MSG\E/,      'error text printed to STDERR');
	};
};

# ================================================================
# collapse_structure() — push-onto-existing-arrayref branch (3rd+ duplicate)
# ================================================================
subtest 'collapse_structure() third-and-beyond duplicate uses push branch' => sub {
	my $p = $CLASS->new();

	subtest 'four duplicates: promote then push three times' => sub {
		# First duplicate: scalar → arrayref (promote).
		# Each subsequent duplicate: push onto existing arrayref (push branch).
		# We need 4 entries to verify the push branch is hit more than once.
		my $input = { name => 'r', children => [
			{ name => 'x', children => [ { text => 'one'   } ] },
			{ name => 'x', children => [ { text => 'two'   } ] },
			{ name => 'x', children => [ { text => 'three' } ] },
			{ name => 'x', children => [ { text => 'four'  } ] },
		] };
		my $result = $p->collapse_structure($input);
		is(ref($result->{r}{x}),       'ARRAY', 'four duplicates produce arrayref');
		is(scalar @{$result->{r}{x}},  4,       'all four values present');
		is($result->{r}{x}[0],         'one',   'first value correct');
		is($result->{r}{x}[2],         'three', 'third value (first push) correct');
		is($result->{r}{x}[3],         'four',  'fourth value (second push) correct');
	};

	subtest 'mixed unique and repeated names in same parent' => sub {
		my $input = { name => 'r', children => [
			{ name => 'a', children => [ { text => 'solo'   } ] },
			{ name => 'b', children => [ { text => 'first'  } ] },
			{ name => 'b', children => [ { text => 'second' } ] },
			{ name => 'b', children => [ { text => 'third'  } ] },
			{ name => 'a', children => [ { text => 'twin'   } ] },
		] };
		my $result = $p->collapse_structure($input);
		# 'a' appears twice, 'b' three times
		is(ref($result->{r}{a}),       'ARRAY', 'duplicate a promoted to array');
		is($result->{r}{a}[0],         'solo',  'first a value');
		is($result->{r}{a}[1],         'twin',  'second a value');
		is(ref($result->{r}{b}),       'ARRAY', 'duplicate b promoted to array');
		is(scalar @{$result->{r}{b}},  3,       'all three b values present');
	};
};

# ================================================================
# collapse_structure() — children with no resolvable value are skipped
# ================================================================
subtest 'collapse_structure() undefined and void value paths' => sub {
	my $p = $CLASS->new();

	subtest 'child with no children key produces undef value — skipped' => sub {
		# When child has no children key, the if-branch is not entered,
		# $value stays undef, and next fires — this exercises the
		# "next unless defined $value" guard
		my $input = { name => 'r', children => [
			{ name => 'absent' },
			{ name => 'present', children => [ { text => 'val' } ] },
		] };
		my $result = $p->collapse_structure($input);
		ok(!exists $result->{r}{absent},  'child with no children key skipped');
		is($result->{r}{present}, 'val',  'sibling with text still present');
	};

	subtest 'child with empty children array: $value stays undef — skipped' => sub {
		my $input = { name => 'r', children => [
			{ name => 'void', children => [] },
			{ name => 'real', children => [ { text => 'ok' } ] },
		] };
		my $result = $p->collapse_structure($input);
		ok(!exists $result->{r}{void}, 'empty-children child skipped');
		is($result->{r}{real}, 'ok',   'non-empty sibling present');
	};

	subtest 'child whose sole grandchild has empty text — skipped' => sub {
		my $input = { name => 'r', children => [
			{ name => 'empty', children => [ { text => '' } ] },
			{ name => 'full',  children => [ { text => 'x' } ] },
		] };
		my $result = $p->collapse_structure($input);
		ok(!exists $result->{r}{empty}, 'empty-text child filtered out');
		is($result->{r}{full}, 'x',     'non-empty sibling present');
	};
};

# ================================================================
# collapse_structure() — defined $node->{name} guard variants (new code)
# ================================================================
subtest 'collapse_structure() defined-name guard branch variants' => sub {
	my $p = $CLASS->new();

	subtest 'name => undef triggers defined guard, returns {}' => sub {
		# Exercises the new defined $node->{name} check specifically
		my $result = $p->collapse_structure({ name => undef, children => [] });
		is_deeply($result, {}, 'name => undef returns {}');
	};

	subtest 'name => 0 is defined so guard passes; wraps under "0"' => sub {
		# "0" passes defined() even though it is false in boolean context;
		# the guard uses defined not truth, so this should not return {}
		my $result = $p->collapse_structure({ name => '0', children => [] });
		is_deeply($result, { '0' => {} },
			'name => "0" passes defined guard, wrapped under key "0"');
	};

	subtest 'missing children key triggers children guard, returns {}' => sub {
		my $result = $p->collapse_structure({ name => 'r' });
		is_deeply($result, {}, 'missing children key returns {}');
	};
};

# ================================================================
# parse() — post-preprocessing empty-check branch (new code)
# ================================================================
subtest 'parse() post-preprocessing empty-check covers all strip combinations' => sub {
	my $p = $CLASS->new();

	subtest 'declaration only returns {}' => sub {
		# After s/<\?xml.*?\?>//, nothing remains
		is_deeply($p->parse('<?xml version="1.0"?>'), {},
			'declaration-only returns {}');
	};

	subtest 'declaration + trailing whitespace returns {}' => sub {
		is_deeply($p->parse('<?xml version="1.0"?>   '), {},
			'declaration + whitespace returns {}');
	};

	subtest 'single comment only returns {}' => sub {
		is_deeply($p->parse('<!-- just a comment -->'), {},
			'single comment-only returns {}');
	};

	subtest 'multiple comments with no element return {}' => sub {
		is_deeply($p->parse('<!-- a --><!-- b --><!-- c -->'), {},
			'multiple comments only return {}');
	};

	subtest 'declaration + comment + whitespace returns {}' => sub {
		is_deeply($p->parse('<?xml version="1.0"?><!-- intro -->   '), {},
			'declaration + comment + whitespace returns {}');
	};

	subtest 'multiline comment only returns {}' => sub {
		is_deeply($p->parse("<!--\n  multi\n  line\n-->"), {},
			'multiline comment-only returns {}');
	};
};

# ================================================================
# _parse_node() — mixed content while(1) loop branch coverage (new code)
# ================================================================
subtest '_parse_node() while(1) mixed content loop paths' => sub {
	my $p = $CLASS->new();

	subtest 'text before first child, nothing after' => sub {
		my $result   = $p->parse('<p>intro<em>bold</em></p>');
		my @children = @{$result->{children}};
		is($children[0]{text}, 'intro', 'leading text node captured');
		is($children[1]{name}, 'em',    'element child follows text');
	};

	subtest 'text after last child, nothing before' => sub {
		# Text captured after the last element in the loop
		my $result   = $p->parse('<p><em>bold</em>outro</p>');
		my @children = @{$result->{children}};
		is($children[0]{name}, 'em',    'element child is first');
		is($children[1]{text}, 'outro', 'trailing text captured after element');
	};

	subtest 'text before and after child element' => sub {
		my $result = $p->parse('<p>before<b>mid</b>after</p>');
		my @ch     = @{$result->{children}};
		is($ch[0]{text}, 'before', 'pre-child text node');
		is($ch[1]{name}, 'b',      'child element');
		is($ch[2]{text}, 'after',  'post-child text node');
	};

	subtest 'multiple text+element sequences interleaved' => sub {
		my $result = $p->parse('<p>a<b/>b<i/>c</p>');
		my @ch     = @{$result->{children}};
		# text(a), elem(b), text(b), elem(i), text(c)
		is($ch[0]{text}, 'a', 'first text node');
		is($ch[1]{name}, 'b', 'first element');
		is($ch[2]{text}, 'b', 'second text node');
		is($ch[3]{name}, 'i', 'second element');
		is($ch[4]{text}, 'c', 'third text node');
	};

	subtest 'loop exits immediately when no text and no children' => sub {
		my $result = $p->parse('<empty></empty>');
		is_deeply($result->{children}, [], 'empty element has no children');
	};

	subtest 'whitespace-only text between siblings discarded by loop' => sub {
		my $result   = $p->parse("<r>\n  <a/>\n  <b/>\n</r>");
		my @elements = grep { defined $_->{name} } @{$result->{children}};
		is(scalar @elements,   2,   'two element children; whitespace nodes discarded');
		is($elements[0]{name}, 'a', 'first element is a');
		is($elements[1]{name}, 'b', 'second element is b');
	};

	subtest 'deeply interleaved mixed content in a real-world-style paragraph' => sub {
		my $xml    = '<p>See <a>here</a> and <em>also</em> this.</p>';
		my $result = $p->parse($xml);
		my @ch     = @{$result->{children}};
		is($ch[0]{text},  'See',  'first text: See');
		is($ch[1]{name},  'a',    'first element: a');
		is($ch[2]{text},  'and',  'second text: and');
		is($ch[3]{name},  'em',   'second element: em');
		is($ch[4]{text},  'this.','third text: this.');
	};
};

# ================================================================
# _parse_node() — closing tag detection (new code) — full branch matrix
# ================================================================
subtest '_parse_node() missing/mismatched closing tag branch matrix' => sub {

	subtest 'missing closing tag: dies in strict mode' => sub {
		my $strict = $CLASS->new(strict => 1);
		eval { $strict->parse('<root>') };
		like($@, qr/XML Parsing Error/i,
			'missing closing tag dies in strict mode');
	};

	subtest 'missing closing tag: warns in warn_on_error mode' => sub {
		my $warn_p = $CLASS->new(warn_on_error => 1);
		my $warned = 0;
		local $SIG{__WARN__} = sub { $warned++ };
		eval { $warn_p->parse('<root>') };
		ok($warned, 'missing closing tag emits warning in warn_on_error mode');
	};

	subtest 'missing closing tag: prints to STDERR in default mode' => sub {
		my $p      = $CLASS->new();
		my $stderr = '';
		open(my $saved, '>&', \*STDERR) or die "Cannot dup STDERR: $!";
		close STDERR;
		open(STDERR, '>', \$stderr)      or die "Cannot redirect STDERR: $!";
		eval { $p->parse('<root>') };
		close STDERR;
		open(STDERR, '>&', $saved)       or die "Cannot restore STDERR: $!";
		close $saved;
		like($stderr, qr/XML Parsing Error/i,
			'missing closing tag prints to STDERR in default mode');
	};

	subtest 'mismatched closing tag: dies in strict mode' => sub {
		my $strict = $CLASS->new(strict => 1);
		eval { $strict->parse('<a><b></a></b>') };
		like($@, qr/XML Parsing Error/i,
			'mismatched closing tag dies in strict mode');
	};

	subtest 'mismatched closing tag: warns in warn_on_error mode' => sub {
		my $warn_p = $CLASS->new(warn_on_error => 1);
		my $warned = 0;
		local $SIG{__WARN__} = sub { $warned++ };
		eval { $warn_p->parse('<a><b></a></b>') };
		ok($warned, 'mismatched closing tag emits warning in warn_on_error mode');
	};

	subtest 'valid closing tag does not trigger error' => sub {
		my $strict = $CLASS->new(strict => 1);
		my $result = eval { $strict->parse('<root><child/></root>') };
		ok(!$@,                    'valid closing tags cause no error');
		is($result->{name}, 'root', 'root parsed correctly');
	};
};

# ================================================================
# _parse_node() — /s flag: newline inside quoted attribute value (new code)
# ================================================================
subtest '_parse_node() /s flag on attribute regex' => sub {
	my $p = $CLASS->new();

	subtest 'newline in double-quoted attribute value preserved' => sub {
		my $result = $p->parse("<r a=\"line1\nline2\"/>");
		is($result->{attributes}{a}, "line1\nline2",
			'newline in double-quoted value preserved');
	};

	subtest 'newline in single-quoted attribute value preserved' => sub {
		my $result = $p->parse("<r a='line1\nline2'/>");
		is($result->{attributes}{a}, "line1\nline2",
			'newline in single-quoted value preserved');
	};

	subtest 'tab in attribute value preserved' => sub {
		my $result = $p->parse("<r a=\"col1\tcol2\"/>");
		is($result->{attributes}{a}, "col1\tcol2",
			'tab character in attribute value preserved');
	};

	subtest 'multiple newlines in attribute value all preserved' => sub {
		my $result = $p->parse("<r a=\"a\nb\nc\"/>");
		is($result->{attributes}{a}, "a\nb\nc",
			'multiple newlines in attribute value preserved');
	};

	subtest 'attribute value containing both newlines and entities' => sub {
		my $result = $p->parse("<r a=\"line1\n&amp;\nline2\"/>");
		is($result->{attributes}{a}, "line1\n&\nline2",
			'newlines and entity in attribute value both processed correctly');
	};
};

# ================================================================
# _decode_entities() — known-entity pass-through after &amp; decode
# ================================================================
subtest '_decode_entities() known-entity pass-through branch' => sub {
	my $p = $CLASS->new();

	# Only &amp;lt; and &amp;gt; exhibit true pass-through: their substitutions
	# run BEFORE &amp; is decoded, so the resulting &lt;/&gt; is never re-decoded.
	# &amp;quot; and &amp;apos; do NOT pass through — their substitutions run
	# AFTER &amp;, so they are fully decoded to " and ' respectively.

	subtest '&amp;lt; decodes to &lt; without triggering unknown-entity error' => sub {
		my $result = $p->parse('<r>&amp;lt;</r>');
		is($result->{children}[0]{text}, '&lt;',
			'&amp;lt; stops at &lt; — known entity pass-through confirmed');
	};

	subtest '&amp;gt; decodes to &gt; without triggering unknown-entity error' => sub {
		my $result = $p->parse('<r>&amp;gt;</r>');
		is($result->{children}[0]{text}, '&gt;',
			'&amp;gt; stops at &gt; — known entity pass-through confirmed');
	};

	subtest '&amp;amp; decodes to &amp; without triggering unknown-entity error' => sub {
		my $result = $p->parse('<r>&amp;amp;</r>');
		is($result->{children}[0]{text}, '&amp;',
			'&amp;amp; decodes to &amp; correctly');
	};

	subtest '&amp;quot; is fully decoded to " (no pass-through)' => sub {
		# quot substitution runs after amp, so double-decoding goes all the way
		my $result = $p->parse('<r>&amp;quot;</r>');
		is($result->{children}[0]{text}, '"',
			'&amp;quot; fully decoded to "');
	};

	subtest '&amp;apos; is fully decoded to apostrophe (no pass-through)' => sub {
		my $result = $p->parse("<r>&amp;apos;</r>");
		is($result->{children}[0]{text}, "'",
			"&amp;apos; fully decoded to apostrophe");
	};
};

# ================================================================
# _parse_node() — attribute normalisation whitespace branch
# ================================================================
subtest '_parse_node() attribute whitespace normalisation' => sub {
	my $p = $CLASS->new();

	subtest 'multiple spaces between attributes collapsed' => sub {
		my $result = $p->parse('<r   a="1"   b="2"   c="3"/>');
		is($result->{attributes}{a}, '1', 'a with extra leading spaces');
		is($result->{attributes}{b}, '2', 'b with extra leading spaces');
		is($result->{attributes}{c}, '3', 'c with extra leading spaces');
	};

	subtest 'tab between attributes handled' => sub {
		my $result = $p->parse("<r\ta=\"1\"\tb=\"2\"/>");
		is($result->{attributes}{a}, '1', 'a with tab separator');
		is($result->{attributes}{b}, '2', 'b with tab separator');
	};

	subtest 'spaces inside quoted value not collapsed' => sub {
		# Whitespace normalisation must not touch quoted value content
		my $result = $p->parse('<r desc="hello   world"/>');
		is($result->{attributes}{desc}, 'hello   world',
			'spaces inside quoted value preserved unchanged');
	};
};

# ================================================================
# _parse_node() — xmlns default namespace declaration branch
# ================================================================
subtest '_parse_node() xmlns default namespace (k2 undef) branch' => sub {
	my $p = $CLASS->new();

	subtest 'default xmlns stored in nsmap; unprefixed element has undef ns_uri' => sub {
		# xmlns="uri" (no k2) maps to $local_nsmap{''};
		# unprefixed elements are NOT given ns_uri — only prefixed ones are
		my $uri    = 'http://www.w3.org/1999/xhtml';
		my $result = $p->parse(qq{<html xmlns="$uri"><body/></html>});
		is($result->{name},              'html', 'root element name correct');
		is($result->{ns},                undef,  'unprefixed element: ns is undef');
		is($result->{ns_uri},            undef,  'unprefixed element: ns_uri is undef');
		is($result->{children}[0]{name}, 'body', 'child element still parsed');
	};

	subtest 'default xmlns does not prevent prefixed child from resolving' => sub {
		my $uri1   = 'http://default.example/';
		my $uri2   = 'http://prefixed.example/';
		my $xml    = qq{<root xmlns="$uri1" xmlns:p="$uri2"><p:child/></root>};
		my $result = $p->parse($xml);
		# The prefixed child must resolve to its own URI, not the default one
		my $child  = $result->{children}[0];
		is($child->{ns},     'p',     'prefixed child has correct ns prefix');
		is($child->{ns_uri}, $uri2,   'prefixed child resolves to correct URI');
	};
};

# ================================================================
# End-to-end pipeline exercising all recently changed code paths together
# ================================================================
subtest 'end-to-end pipeline exercising all recent code changes together' => sub {
	my $p = $CLASS->new();

	subtest 'preprocessing + mixed content + entities + collapse' => sub {
		# Exercises:
		# - post-preprocessing empty check (declaration + comment stripped first)
		# - /s flag (newline in attribute value)
		# - mixed content while(1) loop (text between siblings)
		# - entity decoding in both text and attributes
		# - closing tag verification
		# - collapse_structure push branch (duplicate section names)
		my $xml = '<?xml version="1.0"?>'
			. '<!-- preamble comment -->'
			. "<doc label=\"line1\nline2\">"
			.   '<section id="1&amp;2">'
			.     'intro<em>bold &lt;text&gt;</em>outro'
			.   '</section>'
			.   '<section id="3">'
			.     '<para>second</para>'
			.   '</section>'
			. '</doc>';

		my $tree = $p->parse($xml);

		# Post-preprocessing: declaration and comment stripped, root is doc
		is($tree->{name}, 'doc', 'root parsed after preprocessing strips');

		# /s flag: newline in attribute
		like($tree->{attributes}{label}, qr/line1/, 'multiline attribute parsed');

		# Entity decoding in attribute value
		is($tree->{children}[0]{attributes}{id}, '1&2',
			'entity decoded in attribute');

		# Mixed content while(1) loop: text before and after em child
		my @sec1_ch = @{$tree->{children}[0]{children}};
		is($sec1_ch[0]{text}, 'intro', 'pre-element text in mixed content');
		is($sec1_ch[1]{name}, 'em',    'element child in mixed content');
		is($sec1_ch[2]{text}, 'outro', 'post-element text in mixed content');

		# Entity decoding in nested text node
		is($sec1_ch[1]{children}[0]{text}, 'bold <text>',
			'entity decoded in nested element text');

		# collapse_structure: duplicate section names produce array; push branch
		my $result = $p->collapse_structure($tree);
		is(ref($result->{doc}{section}), 'ARRAY',
			'duplicate sections collapsed to arrayref');
		is(scalar @{$result->{doc}{section}}, 2,
			'both sections present');
	};

	subtest 'strict parser survives clean document after prior failed parse' => sub {
		# Verify strict mode parser instance isolation after a die
		my $strict = $CLASS->new(strict => 1);
		eval { $strict->parse('<r>&bogus;</r>') };
		ok($@, 'first call died as expected');
		# Second call on the same instance must not carry over any bad state
		my $result = eval { $strict->parse('<ok><child>val</child></ok>') };
		ok(!$@,                            'second call succeeds after prior die');
		is($result->{name}, 'ok',          'root element correct');
		is($result->{children}[0]{name}, 'child', 'child element correct');
	};

	subtest 'collapse_structure with "0" text value not filtered' => sub {
		# "0" is defined and non-empty — must survive the "next unless defined"
		# and "ne ''" guards without being silently dropped
		my $xml    = '<r><n>0</n><m>1</m></r>';
		my $tree   = $p->parse($xml);
		my $result = $p->collapse_structure($tree);
		is($result->{r}{n}, '0', '"0" text value survives collapse filters');
		is($result->{r}{m}, '1', '"1" sibling also correct');
	};
};
