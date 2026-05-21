#!/usr/bin/env perl

# function.t - white-box tests for every subroutine in XML::PP,
# including private helpers; non-core dependencies are mocked via
# Test::Mockingbird so each routine is tested in isolation.

use strict;
use warnings;

use Test::Most;
use Test::Mockingbird 0.08;
use Readonly;

use_ok('XML::PP');

# ================================================================
# Shared constants
# ================================================================
Readonly::Scalar my $CLASS     => 'XML::PP';
Readonly::Scalar my $TEST_ERR  => 'something went wrong';

# ================================================================
# new()
# ================================================================
subtest 'new()' => sub {
	subtest 'default construction' => sub {
		# Mock get_params so the constructor receives an empty param set
		mock_scoped('Params::Get' => 'get_params' => sub { return {} });
		my $obj = new_ok($CLASS);
		# Verify the object is correctly blessed and carries no flags
		isa_ok($obj, $CLASS,         'returns a blessed XML::PP object');
		ok(!$obj->{strict},          'strict defaults to false');
		ok(!$obj->{warn_on_error},   'warn_on_error defaults to false');
	};

	subtest 'strict implies warn_on_error' => sub {
		# Strict mode must force warn_on_error on at construction time
		mock_scoped('Params::Get' => 'get_params' => sub { return { strict => 1 } });
		my $obj = $CLASS->new(strict => 1);
		ok($obj->{strict},           'strict flag is set');
		ok($obj->{warn_on_error},    'warn_on_error forced on by strict');
	};

	subtest 'warn_on_error without strict' => sub {
		mock_scoped('Params::Get' => 'get_params' => sub { return { warn_on_error => 1 } });
		my $obj = $CLASS->new(warn_on_error => 1);
		# Strict must remain false; only warn_on_error should be set
		ok(!$obj->{strict},          'strict not set');
		ok($obj->{warn_on_error},    'warn_on_error is set');
	};

	subtest 'pre-blessed logger stored as-is' => sub {
		# When the logger is already a blessed object, new() should store it directly
		# without attempting to wrap it in Log::Abstraction
		my $fake_logger = bless {}, 'FakeLogger';
		mock_scoped('Params::Get' => 'get_params' => sub { return { logger => $fake_logger } });
		my $obj = $CLASS->new(logger => $fake_logger);
		is(ref($obj->{logger}), 'FakeLogger', 'pre-blessed logger stored directly');
	};
};

# ================================================================
# parse()
# ================================================================
subtest 'parse()' => sub {

	# Construct a default (non-strict) parser for this block
	my $obj = XML::PP->new();

	subtest 'empty string returns empty hashref' => sub {
		# parse() must short-circuit on an empty input before calling _parse_node
		mock_scoped('Params::Get' => 'get_params' => sub { return { xml => '' } });
		my $result = $obj->parse('');
		is_deeply($result, {}, 'empty string returns {}');
	};

	subtest 'XML declaration stripped' => sub {
		my $xml = '<?xml version="1.0" encoding="UTF-8"?><root/>';
		mock_scoped('Params::Get'  => 'get_params'  => sub { return { xml => $xml } });
		mock_scoped('Return::Set'  => 'set_return'  => sub { return $_[0] });
		# The <?xml ...?> header must be consumed before parsing begins
		my $result = $obj->parse($xml);
		is($result->{name}, 'root', 'XML declaration stripped before parsing');
	};

	subtest 'comments stripped' => sub {
		my $xml = '<root><!-- ignored --><child>text</child></root>';
		mock_scoped('Params::Get'  => 'get_params'  => sub { return { xml => $xml } });
		mock_scoped('Return::Set'  => 'set_return'  => sub { return $_[0] });
		my $result = $obj->parse($xml);
		# Only the <child> element should survive; the comment must be gone
		is(scalar @{$result->{children}}, 1,       'comment removed, one child remains');
		is($result->{children}[0]{name},  'child',  'surviving child is <child>');
	};

	subtest 'scalar ref to XML accepted' => sub {
		my $xml = '<root/>';
		mock_scoped('Params::Get'  => 'get_params'  => sub { return { xml => \$xml } });
		mock_scoped('Return::Set'  => 'set_return'  => sub { return $_[0] });
		# parse() must dereference a scalar ref before proceeding
		my $result = $obj->parse(\$xml);
		is($result->{name}, 'root', 'scalar ref input accepted and parsed');
	};

	subtest 'surrounding whitespace trimmed' => sub {
		my $xml = "   <root/>   ";
		mock_scoped('Params::Get'  => 'get_params'  => sub { return { xml => $xml } });
		mock_scoped('Return::Set'  => 'set_return'  => sub { return $_[0] });
		my $result = $obj->parse($xml);
		is($result->{name}, 'root', 'leading and trailing whitespace trimmed');
	};
};

# ================================================================
# collapse_structure()
# ================================================================
subtest 'collapse_structure()' => sub {

	my $obj = XML::PP->new();

	subtest 'non-hash-ref inputs return empty hash' => sub {
		# Guard clause must fire for all non-hash-ref values
		is_deeply($obj->collapse_structure(undef),  {}, 'undef returns {}');
		is_deeply($obj->collapse_structure('foo'),  {}, 'string returns {}');
		is_deeply($obj->collapse_structure([]),     {}, 'arrayref returns {}');
	};

	subtest 'hash ref without children key returns empty hash' => sub {
		is_deeply($obj->collapse_structure({ name => 'note' }), {},
			'missing children key returns {}');
	};

	subtest 'simple flat structure collapses correctly' => sub {
		my $input = {
			name     => 'note',
			children => [
				{ name => 'to',   children => [ { text => 'Tove' } ] },
				{ name => 'from', children => [ { text => 'Jani' } ] },
			],
		};
		# Each single-text child should map to its text value under the root key
		my $expected = { note => { to => 'Tove', from => 'Jani' } };
		is_deeply($obj->collapse_structure($input), $expected,
			'flat structure collapsed to name => text pairs');
	};

	subtest 'children with empty text are skipped' => sub {
		my $input = {
			name     => 'root',
			children => [
				{ name => 'empty', children => [ { text => '' } ] },
				{ name => 'full',  children => [ { text => 'val' } ] },
			],
		};
		my $result = $obj->collapse_structure($input);
		# Empty text must be filtered; only 'full' should appear
		ok(!exists $result->{root}{empty}, 'empty text child skipped');
		is($result->{root}{full}, 'val',   'non-empty text child retained');
	};

	subtest 'duplicate child names collapsed to array' => sub {
		my $input = {
			name     => 'list',
			children => [
				{ name => 'item', children => [ { text => 'one'   } ] },
				{ name => 'item', children => [ { text => 'two'   } ] },
				{ name => 'item', children => [ { text => 'three' } ] },
			],
		};
		my $result = $obj->collapse_structure($input);
		# Same-name siblings must be promoted to an arrayref in order
		is(ref($result->{list}{item}), 'ARRAY', 'duplicate names produce an arrayref');
		is_deeply($result->{list}{item}, [ 'one', 'two', 'three' ],
			'all duplicate values preserved in order');
	};

	subtest 'nested children recurse correctly' => sub {
		my $input = {
			name     => 'outer',
			children => [
				{
					name     => 'inner',
					children => [
						{ name => 'leaf', children => [ { text => 'val' } ] },
					],
				},
			],
		};
		my $result = $obj->collapse_structure($input);
		# Recursion must produce a nested hash, not a flat one
		is_deeply($result, { outer => { inner => { leaf => 'val' } } },
			'nested structure recursed and collapsed correctly');
	};

	subtest 'children without a name key are skipped' => sub {
		my $input = {
			name     => 'root',
			children => [
				{ text => 'bare text node' },            # no name key
				{ name => 'child', children => [ { text => 'x' } ] },
			],
		};
		my $result = $obj->collapse_structure($input);
		is(scalar keys %{ $result->{root} }, 1, 'nameless child skipped');
		is($result->{root}{child}, 'x',          'named child present');
	};
};

# ================================================================
# _parse_node()
# ================================================================
subtest '_parse_node()' => sub {

	# Default parser; strict variants created per-subtest as needed
	my $obj = XML::PP->new();

	subtest 'simple open/close tag' => sub {
		mock_scoped('Return::Set' => 'set_return' => sub { return $_[0] });
		my $xml  = '<root></root>';
		my $node = $obj->_parse_node(\$xml, {});
		is($node->{name},              'root', 'tag name parsed');
		is($node->{ns},                undef,  'no namespace prefix');
		is($node->{ns_uri},            undef,  'no namespace URI');
		is_deeply($node->{children},   [],     'no children');
		is_deeply($node->{attributes}, {},     'no attributes');
	};

	subtest 'self-closing tag' => sub {
		mock_scoped('Return::Set' => 'set_return' => sub { return $_[0] });
		my $xml  = '<br/>';
		my $node = $obj->_parse_node(\$xml, {});
		# A self-closing tag has a name but no children
		is($node->{name},            'br', 'self-closing tag name parsed');
		is_deeply($node->{children}, [],   'self-closing tag has no children');
	};

	subtest 'malformed self-closing tag warns on redundant closing tag' => sub {
		# <br/></br> is invalid; _handle_error must be triggered
		my $warn_obj = XML::PP->new(warn_on_error => 1);
		mock_scoped('Return::Set' => 'set_return' => sub { return $_[0] });
		my $xml     = '<br/></br>';
		my $warned  = 0;
		local $SIG{__WARN__} = sub { $warned++ };
		$warn_obj->_parse_node(\$xml, {});
		ok($warned, 'redundant closing tag after self-closing triggers a warning');
	};

	subtest 'attributes parsed and entity-decoded' => sub {
		mock_scoped('Return::Set' => 'set_return' => sub { return $_[0] });
		my $xml  = '<tag id="1" label="a &amp; b"></tag>';
		my $node = $obj->_parse_node(\$xml, {});
		# Plain and entity-encoded attribute values must both decode correctly
		is($node->{attributes}{id},    '1',      'plain attribute parsed');
		is($node->{attributes}{label}, 'a & b',  'entity in attribute decoded');
	};

	subtest 'text content captured as child node' => sub {
		mock_scoped('Return::Set' => 'set_return' => sub { return $_[0] });
		my $xml  = '<msg>Hello world</msg>';
		my $node = $obj->_parse_node(\$xml, {});
		is(scalar @{$node->{children}}, 1,             'one child node');
		is($node->{children}[0]{text},  'Hello world', 'text content captured');
	};

	subtest 'namespace prefix and URI resolved from xmlns declaration' => sub {
		mock_scoped('Return::Set' => 'set_return' => sub { return $_[0] });
		my $uri = 'http://schemas.xmlsoap.org/soap/envelope/';
		my $xml = qq{<soap:Body xmlns:soap="$uri"></soap:Body>};
		my $node = $obj->_parse_node(\$xml, {});
		# Namespace must be stripped from the local name and resolved to its URI
		is($node->{name},   'Body',  'local name excludes prefix');
		is($node->{ns},     'soap',  'namespace prefix captured');
		is($node->{ns_uri}, $uri,    'namespace URI resolved from xmlns declaration');
	};

	subtest 'nested children parsed recursively' => sub {
		mock_scoped('Return::Set' => 'set_return' => sub { return $_[0] });
		my $xml  = '<root><child>text</child></root>';
		my $node = $obj->_parse_node(\$xml, {});
		# The child element and its text grandchild must both be present
		is(scalar @{$node->{children}},              1,       'one child element');
		is($node->{children}[0]{name},               'child', 'child name correct');
		is($node->{children}[0]{children}[0]{text},  'text',  'grandchild text correct');
	};

	subtest 'undef xml_ref dies with BUG message' => sub {
		# This is a programmer error, not a user error; must always die regardless of mode
		my $strict_obj = XML::PP->new(strict => 1);
		eval { $strict_obj->_parse_node(undef, {}) };
		like($@, qr/BUG.*xml_ref not defined/i,
			'undef xml_ref dies with BUG message');
	};

	subtest 'invalid XML dies in strict mode' => sub {
		mock_scoped('Return::Set' => 'set_return' => sub { return $_[0] });
		my $strict_obj = XML::PP->new(strict => 1);
		my $xml = 'not xml at all';
		eval { $strict_obj->_parse_node(\$xml, {}) };
		like($@, qr/XML Parsing Error/i,
			'strict mode dies when no valid opening tag found');
	};
};

# ================================================================
# _decode_entities()
# ================================================================
subtest '_decode_entities()' => sub {

	my $obj = XML::PP->new();

	subtest 'undef input returns undef' => sub {
		is($obj->_decode_entities(undef), undef, 'undef in, undef out');
	};

	subtest 'five predefined named entities decoded' => sub {
		is($obj->_decode_entities('&lt;'),   '<',  '&lt; decoded to <');
		is($obj->_decode_entities('&gt;'),   '>',  '&gt; decoded to >');
		is($obj->_decode_entities('&amp;'),  '&',  '&amp; decoded to &');
		is($obj->_decode_entities('&quot;'), '"',  '&quot; decoded to "');
		is($obj->_decode_entities('&apos;'), "'",  '&apos; decoded to apostrophe');
	};

	subtest 'decimal numeric entity decoded' => sub {
		# &#65; is the decimal code point for 'A'
		is($obj->_decode_entities('&#65;'), 'A', '&#65; decoded to A');
	};

	subtest 'hex numeric entity decoded' => sub {
		# &#x41; is the hex code point for 'A'
		is($obj->_decode_entities('&#x41;'), 'A', '&#x41; decoded to A');
	};

	subtest 'plain text passed through unchanged' => sub {
		is($obj->_decode_entities('hello world'), 'hello world',
			'plain text with no entities unchanged');
	};

	subtest 'multiple entities in one string all decoded' => sub {
		my $input    = '&lt;tag&gt; &amp; &quot;value&quot;';
		my $expected = '<tag> & "value"';
		is($obj->_decode_entities($input), $expected,
			'multiple entities in one string all decoded');
	};

	subtest 'unknown entity warns in warn_on_error mode' => sub {
		my $warn_obj = XML::PP->new(warn_on_error => 1);
		my $warned   = 0;
		local $SIG{__WARN__} = sub { $warned++ };
		$warn_obj->_decode_entities('&unknown;');
		ok($warned, 'unknown entity triggers a warning');
	};

	subtest 'unknown entity dies in strict mode' => sub {
		my $strict_obj = XML::PP->new(strict => 1);
		eval { $strict_obj->_decode_entities('&unknown;') };
		like($@, qr/Unknown or malformed XML entity/,
			'unknown entity dies in strict mode');
	};

	subtest 'unescaped ampersand warns in warn_on_error mode' => sub {
		my $warn_obj = XML::PP->new(warn_on_error => 1);
		my $warned   = 0;
		local $SIG{__WARN__} = sub { $warned++ };
		$warn_obj->_decode_entities('foo & bar');
		ok($warned, 'unescaped ampersand triggers a warning');
	};

	subtest 'unescaped ampersand dies in strict mode' => sub {
		my $strict_obj = XML::PP->new(strict => 1);
		eval { $strict_obj->_decode_entities('foo & bar') };
		like($@, qr/Unescaped ampersand/,
			'unescaped ampersand dies in strict mode');
	};
};

# ================================================================
# _handle_error()
# ================================================================
subtest '_handle_error()' => sub {

	subtest 'strict mode dies with prefixed message' => sub {
		my $obj = XML::PP->new(strict => 1);
		eval { $obj->_handle_error($TEST_ERR) };
		# Message must include both the package prefix and the caller's text
		like($@, qr/XML::PP.*XML Parsing Error.*\Q$TEST_ERR\E/,
			'strict mode dies with fully prefixed message');
	};

	subtest 'warn_on_error mode emits a warning' => sub {
		my $obj    = XML::PP->new(warn_on_error => 1);
		my $warned = 0;
		local $SIG{__WARN__} = sub { $warned++ };
		$obj->_handle_error($TEST_ERR);
		ok($warned, 'warn_on_error mode emits a Perl warning');
	};

	subtest 'default mode (neither flag) prints to STDERR' => sub {
		my $obj    = XML::PP->new();
		my $stderr = '';
		# Capture STDERR to a scalar for inspection
		open(my $old_stderr, '>&', \*STDERR) or die "Cannot dup STDERR: $!";
		close STDERR;
		open(STDERR, '>', \$stderr)           or die "Cannot redirect STDERR: $!";
		$obj->_handle_error($TEST_ERR);
		close STDERR;
		open(STDERR, '>&', $old_stderr)       or die "Cannot restore STDERR: $!";
		close $old_stderr;
		like($stderr, qr/\Q$TEST_ERR\E/, 'default mode prints to STDERR');
	};

	subtest 'warning message carries package and label prefix' => sub {
		my $obj  = XML::PP->new(warn_on_error => 1);
		my $msg  = '';
		local $SIG{__WARN__} = sub { $msg = $_[0] };
		$obj->_handle_error($TEST_ERR);
		# Both the package name and the "XML Parsing Error:" label must appear
		like($msg, qr/XML::PP/,           'message prefixed with package name');
		like($msg, qr/XML Parsing Error/, 'message carries error label');
	};

	subtest 'logger->warn() called in warn_on_error mode' => sub {
		# Inject a fake logger object directly into the blessed hash
		my @log;
		my $fake_logger = bless { log => \@log }, 'FakeLogger';
		{ no strict 'refs'; *{'FakeLogger::warn'} = sub { push @{$_[0]->{log}}, $_[1] } }
		my $obj = bless { warn_on_error => 1, strict => 0, logger => $fake_logger }, $CLASS;
		$obj->_handle_error($TEST_ERR);
		ok(scalar @log > 0,             'logger->warn() was called');
		like($log[0], qr/\Q$TEST_ERR\E/, 'logged message contains error text');
	};

	subtest 'logger->fatal() called then dies in strict mode' => sub {
		my @log;
		my $fake_logger = bless { log => \@log }, 'FakeLogger';
		{ no strict 'refs'; *{'FakeLogger::fatal'} = sub { push @{$_[0]->{log}}, $_[1] } }
		my $obj = bless { strict => 1, warn_on_error => 1, logger => $fake_logger }, $CLASS;
		eval { $obj->_handle_error($TEST_ERR) };
		# logger->fatal() must fire before the die
		ok(scalar @log > 0,             'logger->fatal() called before die');
		like($@, qr/\Q$TEST_ERR\E/,     'also dies with the error message');
	};
};

done_testing();
