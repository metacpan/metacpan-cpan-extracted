#!/usr/bin/env perl

# Domain tests: every input parameter of every public method is divided into
# equivalence partitions (one representative value each) and tested at the
# exact edges of its allowed range.  Each parameter is its own subtest.
#
#   Parameter            Valid partitions                       Invalid partitions          Boundaries
#   -------------------  -------------------------------------  --------------------------  -----------------------------
#   new: verbose         true, false, absent (from %ENV)        any reference               '0' false, '00' and '0.0' true
#   new: diag            all, none, level name, array of names  other string, '', undef     emergency (0) .. trace (7);
#                                                               element, hash/code/scalar   [] (prints nothing)
#   new: level           16 level names, any case               '', numbers, unknown names  emergency (0) .. trace (7)
#   new: lang            auto (any case), 2-3 letters [+ rest]  1 or 4+ letters, digits,    lengths 1 | 2 .. 3 | 4
#                                                               non-ASCII first letters
#   new: country         2 ASCII letters, any case              1 or 3 letters, digits,     lengths 1 | 2 | 3
#                                                               non-ASCII
#   new: i18n            hash reference                         any other type
#   level methods        any values, any count                  -                           0, 1, 2 arguments; trailing
#                                                                                           newlines 0, 1, 2
#   message text         ASCII, Latin-1, multibyte, emoji,      -                           length 0, 1, very long
#                        combining marks, RTL, bytes
#   is_*                 -                                      -                           threshold 0 .. 7, each +-1
#   count(level)         undef, level name, unknown name        any reference
#   like/unlike pattern  qr//, string                           undef, reference, bad regex '' (matches everything)
#   test names           undef, string (any characters)         any reference               ''
#   verbose(value)       absent (get), true, false              -
#   level(name)          undef (get), 16 names                  anything else (warns)       emergency (0) .. trace (7)
#   failure listing      -                                      -                           0, 1, 2, 20, 21 entries
#   invalid argument     -                                      -                           explanation 200 | 201 chars
#
# Every rejection is checked against the exact message the POD documents.

use strict;
use warnings;

use lib 't/lib';
use Test::Most;
use Test::Warnings qw(warning);
use Readonly;
use Encode ();
use Capture qw(capture_diag failing printed);

use Test::Log::Abstraction;

# Test names are passed to Test::Builder unchanged (POD: ENCODING), and some
# here are multibyte; give its real output handles a UTF-8 layer, as a test
# with such names must.  (The module sees the layer and does not encode
# twice; output captured in this file goes to plain in-memory handles.)
binmode($_, ':encoding(UTF-8)') foreach (Test::Builder->new()->output(), Test::Builder->new()->failure_output(), Test::Builder->new()->todo_output());

Readonly::Scalar my $CLASS => 'Test::Log::Abstraction';
Readonly::Scalar my $FILE => __FILE__;
Readonly::Scalar my $MOST_SEVERE => 0;	# emergency
Readonly::Scalar my $LEAST_SEVERE => 7;	# debug and trace
Readonly::Scalar my $DEFAULT_PRINT => 4;	# warning: printed by default from here up
Readonly::Scalar my $LANG_MIN => 2;	# letters in a language code
Readonly::Scalar my $LANG_MAX => 3;
Readonly::Scalar my $COUNTRY_LENGTH => 2;
Readonly::Scalar my $MAX_LISTED => 20;	# entries a failing assertion lists
Readonly::Scalar my $MAX_REASON => 200;	# characters of an invalid-argument explanation
Readonly::Scalar my $LONG => 1_000_000;
Readonly::Scalar my $SHOW_STATE => $ENV{'TEST_VERBOSE'};

# The level table from the POD
Readonly::Hash my %LEVEL => (
	emergency => 0, emerg => 0, panic => 0,
	alert => 1,
	critical => 2, crit => 2, fatal => 2,
	error => 3, err => 3,
	warning => 4, warn => 4,
	notice => 5,
	info => 6, informational => 6,
	debug => 7, trace => 7,
);
Readonly::Array my @PREDICATES => qw(trace debug info notice warn error critical alert emergency);

# One level name for each severity number
Readonly::Hash my %NAME_FOR => (0 => 'emergency', 1 => 'alert', 2 => 'critical', 3 => 'error', 4 => 'warning', 5 => 'notice', 6 => 'info', 7 => 'debug');

# Text partitions for anything that accepts user text, as character strings
# (decoded, as text from a file, socket or 'use utf8' source is)
Readonly::Hash my %TEXT => (
	'ASCII' => 'plain text',
	'German umlauts and sharp s' => "Gr\x{fc}\x{df}e aus M\x{fc}nchen, Stra\x{df}e",
	'French accents' => "\x{e9}t\x{e9} \x{e0} l'h\x{f4}tel",
	'CJK' => "\x{65e5}\x{672c}\x{8a9e}\x{4e2d}\x{6587}",
	'emoji' => "\x{1F600}\x{1F4A9}",
	'emoji ZWJ family' => "\x{1F468}\x{200D}\x{1F469}\x{200D}\x{1F467}",
	'flag (regional indicators)' => "\x{1F1E9}\x{1F1EA}",
	'Zalgo (stacked combining marks)' => "Z\x{0335}\x{0353}\x{0346}a\x{0336}\x{0317}\x{0350}l\x{0334}\x{031F}g\x{0338}\x{0322}o\x{0337}\x{0359}",
	'right-to-left override' => "\x{202E}gnirts desrever\x{202C}",
	'Arabic (RTL script)' => "\x{0645}\x{0631}\x{062D}\x{0628}\x{0627}",
	'zero-width characters' => "a\x{200B}b\x{FEFF}c",
);

# Decoded text: what Encode::decode() gives, flagged as characters even
# when every character is below 0x100
sub decoded {
	my $text = shift;

	return Encode::decode('UTF-8', Encode::encode('UTF-8', $text));
}

# Show a value, only when asked to
sub state_diag {
	my ($label, $value) = @_;

	diag(explain({ $label => $value })) if($SHOW_STATE);
	return;
}

sub quiet {
	return $CLASS->new(diag => 'none', verbose => 0, @_);
}

# The exact text of an error raised from this file
sub at_caller {
	my $text = shift;

	return qr/\A\Q$CLASS: $text\E at \Q$FILE\E line \d+\.?\n?\z/;
}

# The start of an "invalid argument" error for one parameter, reported here
sub invalid_argument {
	my $parameter = shift;

	return qr/\A\Q$CLASS: invalid argument: Parameter '$parameter'\E[^\n]* at \Q$FILE\E line \d+\.?\n?\z/;
}

# Which known levels a logger prints
sub printed_levels {
	my $logger = shift;

	my %seen;
	foreach my $level (sort keys %LEVEL) {
		my $out = printed { $logger->$level("mark-$level") };
		$seen{$level} = 1 if($out =~ /mark-\Q$level\E/);
	}
	return \%seen;
}

# ===========================================================================
# new()
# ===========================================================================

subtest 'new: verbose' => sub {
	local $ENV{'TEST_VERBOSE'} = 0;
	local $ENV{'VERBOSE'} = 0;
	my %partition = (
		'true: 1' => [1, 1], 'true: string' => ['yes', 1], 'true: 00' => ['00', 1], 'true: 0.0' => ['0.0', 1], 'true: space' => [' ', 1],
		'false: 0' => [0, 0], 'false: empty string' => ['', 0], "false: '0'" => ['0', 0], 'false: undef' => [undef, 0],
	);
	foreach my $name (sort keys %partition) {
		my ($value, $want) = @{$partition{$name}};
		is(quiet(verbose => $value)->verbose(), $want, $name);
	}
	is($CLASS->new(diag => 'none')->verbose(), 0, 'absent: from %ENV, which is off');
	{
		local $ENV{'TEST_VERBOSE'} = 1;
		is($CLASS->new(diag => 'none')->verbose(), 1, 'absent: from %ENV, which is on');
	}
	foreach my $reference ([], {}, sub { 1 }, \1) {
		throws_ok { quiet(verbose => $reference) } at_caller('invalid argument: Parameter \'verbose\' must be a scalar, not a ' . ref($reference) . ' reference'), 'invalid: ' . ref($reference) . ' reference';
	}
};

subtest 'new: diag' => sub {
	# Valid string partitions, any case
	is_deeply(printed_levels($CLASS->new(diag => 'ALL', verbose => 0)), { map { $_ => 1 } keys %LEVEL }, "'ALL': every level");
	is_deeply(printed_levels($CLASS->new(diag => 'None', verbose => 0)), {}, "'None': nothing");

	# Threshold boundaries: the most and least severe, and either side of the default
	foreach my $threshold ($MOST_SEVERE, $DEFAULT_PRINT - 1, $DEFAULT_PRINT, $DEFAULT_PRINT + 1, $LEAST_SEVERE) {
		my $logger = $CLASS->new(diag => uc($NAME_FOR{$threshold}), verbose => 0);
		my %want = map { $_ => 1 } grep { $LEVEL{$_} <= $threshold } keys %LEVEL;
		is_deeply(printed_levels($logger), \%want, "threshold $NAME_FOR{$threshold} ($threshold): that level and more severe");
	}
	is_deeply(printed_levels($CLASS->new(verbose => 0)), { map { $_ => 1 } grep { $LEVEL{$_} <= $DEFAULT_PRINT } keys %LEVEL }, 'absent: the default, warning');

	# Array partitions: empty, one, all, duplicates
	is_deeply(printed_levels($CLASS->new(diag => [], verbose => 0)), {}, 'empty list: nothing');
	is_deeply(printed_levels($CLASS->new(diag => ['Info'], verbose => 0)), { info => 1 }, 'one name: only that name');
	is_deeply(printed_levels($CLASS->new(diag => [keys %LEVEL], verbose => 0)), { map { $_ => 1 } keys %LEVEL }, 'every name');
	is_deeply(printed_levels($CLASS->new(diag => ['err', 'err', 'ERR'], verbose => 0)), { err => 1 }, 'duplicates: the same as once');

	# Invalid partitions, with the documented messages
	my $type = 'diag must be a level name, "all", "none" or an array reference of level names';
	throws_ok { quiet(diag => 'bogus') } at_caller(q{invalid diag level 'bogus'}), 'unknown name';
	throws_ok { quiet(diag => '') } at_caller(q{invalid diag level ''}), 'empty string';
	throws_ok { quiet(diag => '4') } at_caller(q{invalid diag level '4'}), 'a severity number is not a name';
	throws_ok { quiet(diag => ['info', 'all']) } at_caller(q{invalid diag level 'all'}), "'all' inside a list";
	throws_ok { quiet(diag => [undef]) } at_caller(q{invalid diag level 'undef'}), 'undef inside a list';
	foreach my $reference ({}, sub { 1 }, \'info') {
		throws_ok { quiet(diag => $reference) } at_caller($type), ref($reference) . ' reference';
	}
};

subtest 'new: level' => sub {
	foreach my $name (sort keys %LEVEL) {
		is(quiet(level => uc($name))->level(), $LEVEL{$name}, "$name, any case: $LEVEL{$name}");
	}
	is(quiet()->level(), $LEAST_SEVERE, 'absent: trace');

	# Boundaries: at the minimum only is_emergency is on; at the maximum all are
	my $min = quiet(level => $NAME_FOR{$MOST_SEVERE});
	is_deeply([map { my $m = "is_$_"; $min->$m() } @PREDICATES], [map { ($LEVEL{$_} == $MOST_SEVERE) ? 1 : 0 } @PREDICATES], 'minimum: only is_emergency');
	my $max = quiet(level => $NAME_FOR{$LEAST_SEVERE});
	is_deeply([map { my $m = "is_$_"; $max->$m() } @PREDICATES], [(1) x @PREDICATES], 'maximum: everything');

	# Just outside: numbers are not names, even 0 .. 7
	foreach my $bad ('', '0', '7', '8', '-1', 'loud', 'warn ') {
		throws_ok { quiet(level => $bad) } at_caller(qq{invalid syslog level '$bad'}), "invalid: '$bad'";
	}
};

subtest 'new: lang' => sub {
	# Length boundaries of the language code
	foreach my $length ($LANG_MIN - 1, $LANG_MIN, $LANG_MAX, $LANG_MAX + 1) {
		my $code = substr('dexy', 0, $length);
		if(($length >= $LANG_MIN) && ($length <= $LANG_MAX)) {
			lives_ok { quiet(lang => $code) } "$length letters: accepted";
		} else {
			throws_ok { quiet(lang => $code) } invalid_argument('lang'), "$length letters: rejected";
		}
	}

	# Valid partitions
	my %valid = (de => 'de', DE => 'de', fr => 'fr', zh => 'zh', en => 'en', 'de_DE.UTF-8' => 'de', 'zh-Hant' => 'zh', 'fr@euro' => 'fr', ja => 'en', eng => 'en');
	foreach my $tag (sort keys %valid) {
		is(quiet(lang => $tag)->lang(), $valid{$tag}, "'$tag' -> $valid{$tag}");
	}
	{
		local $ENV{'LC_ALL'} = 'de_DE.UTF-8';
		is(quiet(lang => 'auto')->lang(), 'de', "'auto'");
		is(quiet(lang => 'AUTO')->lang(), 'de', "'AUTO': any case");
	}

	# Invalid format partitions
	foreach my $bad ('', '12', 'd1', "en\n", ' en', "d\x{e9}", "\x{fc}b", '_de', 'auto-x') {
		(my $label = $bad) =~ s/([^\x20-\x7e])/sprintf('\\x{%x}', ord($1))/ge;
		throws_ok { quiet(lang => $bad) } invalid_argument('lang'), "invalid: '$label'";
	}
};

subtest 'new: country' => sub {
	foreach my $length ($COUNTRY_LENGTH - 1, $COUNTRY_LENGTH, $COUNTRY_LENGTH + 1) {
		my $code = substr('DEU', 0, $length);
		if($length == $COUNTRY_LENGTH) {
			is(quiet(country => $code)->lang(), 'de', "$length letters: accepted");
		} else {
			throws_ok { quiet(country => $code) } invalid_argument('country'), "$length letters: rejected";
		}
	}
	my %valid = (GB => 'en', us => 'en', Fr => 'fr', de => 'de', CN => 'zh', JP => 'en', ZZ => 'en');
	foreach my $code (sort keys %valid) {
		is(quiet(country => $code)->lang(), $valid{$code}, "'$code' -> $valid{$code}");
	}
	foreach my $bad ('', '1A', 'G1', ' G', "\x{dc}\x{dc}", "D\x{e9}") {
		(my $label = $bad) =~ s/([^\x20-\x7e])/sprintf('\\x{%x}', ord($1))/ge;
		throws_ok { quiet(country => $bad) } invalid_argument('country'), "invalid: '$label'";
	}
};

subtest 'new: i18n' => sub {
	lives_ok { quiet(i18n => {}) } 'empty hash';
	is(quiet(lang => 'xx', i18n => { xx => { no_method => 'x' } })->lang(), 'xx', 'a hash adding a language');
	foreach my $bad ([], 'text', sub { 1 }, \{}) {
		throws_ok { quiet(i18n => $bad) } at_caller("invalid argument: Parameter 'i18n' must be an hashref"), 'invalid: ' . (ref($bad) || 'string');
	}
};

subtest 'new: options in combination' => sub {
	# Verbose at its maximum beats diag at its minimum
	is_deeply(printed_levels($CLASS->new(diag => [], verbose => 1)), { map { $_ => 1 } keys %LEVEL }, 'verbose on, diag empty: everything prints');
	# The narrowest diag with the widest level, and the reverse
	my $narrow = $CLASS->new(diag => $NAME_FOR{$MOST_SEVERE}, level => $NAME_FOR{$LEAST_SEVERE}, verbose => 0);
	is_deeply(printed_levels($narrow), { map { $_ => 1 } grep { $LEVEL{$_} == $MOST_SEVERE } keys %LEVEL }, 'diag at minimum, level at maximum: diag decides printing');
	is($narrow->is_debug(), 1, '... and level decides is_*');
	my $wide = $CLASS->new(diag => $NAME_FOR{$LEAST_SEVERE}, level => $NAME_FOR{$MOST_SEVERE}, verbose => 0);
	is($wide->is_alert(), 0, 'diag at maximum, level at minimum: is_alert off');
	is(printed_levels($wide)->{'debug'}, 1, '... while debug still prints');
	# The longest valid language code with a country: lang wins, even unknown
	is(quiet(lang => 'eng', country => 'DE')->lang(), 'en', 'lang at its maximum length beats country');
	is(quiet(lang => 'auto', country => 'fr')->lang(), 'fr', "'auto' gives way to country");
	# A clone at the boundaries
	my $clone = $narrow->new(diag => [], level => $NAME_FOR{$MOST_SEVERE});
	is($clone->level(), $MOST_SEVERE, 'clone moved to the other boundary');
};

# ===========================================================================
# Level methods: arguments and text
# ===========================================================================

subtest 'level methods: argument count and shape' => sub {
	my $logger = quiet();
	my @rows = (
		[[], ''], [['a'], 'a'], [['a', 'b'], 'ab'], [[('x') x $MAX_LISTED], 'x' x $MAX_LISTED],
		[["m\n"], 'm'], [["m\n\n"], "m\n"], [["m\n\n\n"], "m\n\n"], [["\n"], ''],
		[['m', {}], 'm'], [[{}], '{}'], [['m', bless({ k => 1 }, 'Local::Hash')], qr/\AmLocal::Hash=HASH/],
	);
	foreach my $row (@rows) {
		my ($args, $want) = @{$row};
		$logger->clear()->info(@{$args});
		my $got = $logger->messages()->[0]->{'message'};
		(my $label = join('|', map { ref($_) || $_ } @{$args})) =~ s/\n/\\n/g;
		if(ref($want)) {
			like($got, $want, "($label)");
		} else {
			is($got, $want, "($label)");
		}
	}
	$logger->clear()->info('m', { k => 1 });
	is_deeply($logger->messages()->[0]->{'fields'}, { k => 1 }, 'two arguments, the second a hash: fields');
	$logger->clear()->info('x' x $LONG);
	is(length($logger->messages()->[0]->{'message'}), $LONG, "length $LONG: kept whole");
};

subtest 'level methods: multibyte and special text' => sub {
	my $logger = $CLASS->new(diag => 'all', verbose => 0);
	foreach my $kind (sort keys %TEXT) {
		my $text = decoded($TEXT{$kind});
		my $out = printed { $logger->clear()->warn($text, ' end') };
		my $stored = $logger->messages()->[0]->{'message'};
		is($stored, "$text end", "$kind: stored unchanged");
		is(length($stored), length($text) + length(' end'), "$kind: character length unchanged");
		ok($logger->like(qr/\Q$text\E/, "$kind: matches itself"), "$kind: like");
		my $bytes = Encode::encode('UTF-8', "$text end");
		is($out, "# $bytes\n", "$kind: printed as UTF-8 bytes, uncorrupted");

		# The same text arriving as UTF-8 bytes is kept as bytes
		my $encoded = Encode::encode('UTF-8', $text);
		my $byte_out = printed { $logger->clear()->warn($encoded) };
		is($logger->messages()->[0]->{'message'}, $encoded, "$kind as bytes: stored unchanged");
		is($byte_out, "# $encoded\n", "$kind as bytes: printed unchanged, not encoded twice");
	}
	printed { $logger->clear()->info($TEXT{'emoji ZWJ family'} x $MAX_LISTED) };
	is(length($logger->messages()->[0]->{'message'}), length($TEXT{'emoji ZWJ family'}) * $MAX_LISTED, 'long multibyte text: length exact');

	# The partition the POD's ENCODING section singles out: text never
	# decoded, all below 0x100, is indistinguishable from bytes and is
	# printed as it is
	my $undecoded = "caf\x{e9}";
	my $out = printed { $logger->clear()->warn($undecoded) };
	is($logger->messages()->[0]->{'message'}, $undecoded, 'undecoded Latin-1: stored unchanged');
	is($out, "# caf\xe9\n", 'undecoded Latin-1: printed as its bytes, as documented');
};

subtest 'AUTOLOAD: method names' => sub {
	my $logger = quiet();
	foreach my $name ('', 'x', 'wran', 'WRAN', "caf\x{e9}", "\x{65e5}\x{672c}", 'n' x $MAX_REASON) {
		my $out = printed { $logger->clear()->$name('m') };
		(my $label = substr($name, 0, $MAX_LISTED)) =~ s/([^\x20-\x7e])/sprintf('\\x{%x}', ord($1))/ge;
		is($logger->count(lc($name)), 1, "'$label': stored under its lower-case name");
		my $expected = utf8::is_utf8($name) ? Encode::encode('UTF-8', $name) : $name;
		like($out, qr/\Q$CLASS: no method '$expected'\E/, "'$label': announced");
	}
};

# ===========================================================================
# is_*, count, level, verbose
# ===========================================================================

subtest 'is_*: every threshold, at and either side of each level' => sub {
	my $logger = quiet();
	foreach my $threshold ($MOST_SEVERE .. $LEAST_SEVERE) {
		$logger->level($NAME_FOR{$threshold});
		foreach my $level (@PREDICATES) {
			my $method = "is_$level";
			my $want = ($LEVEL{$level} <= $threshold) ? 1 : 0;
			is($logger->$method(), $want, "level $threshold, $method (severity $LEVEL{$level}): $want");
		}
	}
};

subtest 'count: level' => sub {
	my $logger = quiet();
	$logger->warn('a');
	$logger->warn('b');
	$logger->warning('c');
	$logger->info("\x{e9}");
	my %partition = ('undef: all' => [undef, 4], 'a name' => ['warn', 2], 'any case' => ['WARN', 2], 'an alias is another name' => ['warning', 1], 'unknown name' => ['bogus', 0], 'empty string' => ['', 0], "'0'" => ['0', 0]);
	foreach my $name (sort keys %partition) {
		my ($level, $want) = @{$partition{$name}};
		is($logger->count($level), $want, $name);
	}
	foreach my $bad ([], {}, sub { 1 }) {
		throws_ok { $logger->count($bad) } at_caller(q{invalid argument: Parameter 'level' must be a string}), 'invalid: ' . ref($bad);
	}
};

subtest 'level: name' => sub {
	my $logger = quiet();
	is($logger->level(undef), $LEAST_SEVERE, 'undef: get');
	foreach my $threshold ($MOST_SEVERE, $LEAST_SEVERE) {
		is($logger->level(uc($NAME_FOR{$threshold})), $logger, "boundary $threshold: set, any case");
		is($logger->level(), $threshold, "... now $threshold");
	}
	foreach my $bad ('', '0', '8', 'loud', "warn\n") {
		(my $label = $bad) =~ s/\n/\\n/g;
		# A control character is shown escaped, so it cannot start a line
		(my $shown = $bad) =~ s/\n/\\x0A/g;
		my $result = 'unset';
		like(warning { $result = $logger->level($bad) }, at_caller("invalid syslog level '$shown'"), "invalid '$label': documented warning");
		is($result, undef, "invalid '$label': undef");
	}
	is($logger->level(), $LEAST_SEVERE, 'unchanged by the invalid names');
};

subtest 'verbose: value' => sub {
	my $logger = quiet();
	my %partition = ('true' => [1, 1], "'0.0' is true" => ['0.0', 1], 'false' => [0, 0], 'empty string is false' => ['', 0], 'undef is false' => [undef, 0]);
	foreach my $name (sort keys %partition) {
		my ($value, $want) = @{$partition{$name}};
		is($logger->verbose($value), $want, $name);
	}
	is($logger->verbose(), 0, 'absent: get, unchanged');
};

# ===========================================================================
# like, unlike, has_level, empty: patterns and names
# ===========================================================================

subtest 'like and unlike: pattern' => sub {
	my $logger = quiet();
	$logger->info('price: $5 (net)');
	$logger->info($TEXT{'German umlauts and sharp s'});

	ok($logger->like(qr/\$5/, 'qr//'), 'qr// partition');
	ok($logger->like('price', 'plain string'), 'string partition');
	ok($logger->like('\(net\)', 'string with escaped metacharacters'), 'string with metacharacters');
	ok($logger->like('', 'empty string matches everything'), "boundary: '' matches");
	ok($logger->like(qr/Stra\x{df}e/, 'multibyte pattern'), 'multibyte pattern against multibyte text');
	ok($logger->unlike('zzz', 'unlike: no match'), 'unlike passes');
	my ($result) = failing(sub { $logger->unlike('') });
	ok(!$result, "unlike(''): fails, since '' matches everything");

	foreach my $method (qw(like unlike)) {
		throws_ok { $logger->$method(undef) } at_caller("$method() needs a pattern"), "$method: undef";
		throws_ok { $logger->$method([]) } at_caller(q{invalid argument: Parameter 'pattern' must be one of regex, string}), "$method: reference";
		throws_ok { $logger->$method('(') } qr/\A\Q$CLASS: invalid argument: Unmatched ( in regex\E/, "$method: malformed";
	}
};

subtest 'test names' => sub {
	my $logger = quiet();
	$logger->info('x');
	ok($logger->like(qr/x/), 'undef: no name');
	ok($logger->like(qr/x/, ''), 'empty name');
	ok($logger->like(qr/x/, $TEXT{'CJK'}), 'multibyte name');
	ok(quiet()->empty($TEXT{'emoji'}), 'empty() with a multibyte name');
	throws_ok { $logger->empty([]) } at_caller(q{invalid argument: Parameter 'name' must be a string}), 'empty: reference as name';
	foreach my $method (qw(like unlike)) {
		throws_ok { $logger->$method(qr/x/, []) } at_caller(q{invalid argument: Parameter 'name' must be a string}), "$method: reference as name";
	}
	throws_ok { $logger->has_level('info', {}) } at_caller(q{invalid argument: Parameter 'name' must be a string}), 'has_level: reference as name';
};

subtest 'has_level: level' => sub {
	my $logger = quiet();
	$logger->error('x');
	ok($logger->has_level('error', 'a name'), 'a name');
	ok($logger->has_level('ERROR', 'any case'), 'any case');
	my ($alias) = failing(sub { $logger->has_level('err') });
	ok(!$alias, 'an alias is another name');
	my ($empty) = failing(sub { $logger->has_level('') });
	ok(!$empty, "'' matches no level");
	throws_ok { $logger->has_level(undef) } at_caller('has_level() needs a level name'), 'undef';
	throws_ok { $logger->has_level([]) } at_caller(q{invalid argument: Parameter 'level' must be a string}), 'reference';
};

# ===========================================================================
# Boundaries of what the module prints
# ===========================================================================

# Strategy: a failing assertion lists the stored messages, up to a limit,
# with singular, plural and zero forms; test each side of every edge
subtest 'failure listing: counts at each boundary' => sub {
	my %rows = (
		0 => ["$CLASS: no messages were captured", 0, 0],
		1 => ["$CLASS: 1 message was captured:", 1, 0],
		2 => ["$CLASS: 2 messages were captured:", 2, 0],
		$MAX_LISTED => ["$CLASS: $MAX_LISTED messages were captured:", $MAX_LISTED, 0],
		$MAX_LISTED + 1 => ["$CLASS: @{[ $MAX_LISTED + 1 ]} messages were captured:", $MAX_LISTED, 1],
	);
	foreach my $count (sort { $a <=> $b } keys %rows) {
		my ($heading, $listed, $more) = @{$rows{$count}};
		my $logger = quiet();
		$logger->info("entry $_") foreach 1 .. $count;
		my (undef, $out) = failing(sub { $logger->like(qr/never/) });
		like($out, qr/^# \Q$heading\E$/m, "$count stored: heading");
		my @entries = ($out =~ /^#     \[info\] entry \d+$/mg);
		is(scalar(@entries), $listed, "$count stored: $listed listed");
		if($more) {
			like($out, qr/^#     \.\.\. and $more more$/m, "$count stored: the rest counted");
		} else {
			unlike($out, qr/\.\.\. and/, "$count stored: no summary line");
		}
	}
};

subtest 'failure listing: plural forms in each language' => sub {
	my %heading = (
		de => { 0 => qr/keine Meldungen/, 1 => qr/1 Meldung wurde/, 2 => qr/2 Meldungen wurden/ },
		fr => { 0 => qr/aucun message/, 1 => qr/1 message a/, 2 => qr/2 messages ont/ },
		zh => { 0 => qr/\x{6ca1}\x{6709}/, 1 => qr/1 \x{6761}/, 2 => qr/2 \x{6761}/ },
	);
	foreach my $lang (sort keys %heading) {
		foreach my $count (sort keys %{$heading{$lang}}) {
			my $logger = quiet(lang => $lang);
			$logger->info('x') foreach 1 .. $count;
			my (undef, $out) = failing(sub { $logger->like(qr/never/) });
			like(Encode::decode('UTF-8', $out), $heading{$lang}{$count}, "$lang, $count messages");
		}
	}
};

subtest 'invalid argument: explanation length boundary' => sub {
	# Find the explanation's length for one value, then size values so the
	# explanation is exactly at, and one past, the limit
	my $explanation = sub {
		my $value = shift;
		eval { quiet(lang => $value) };
		my ($text) = ($@ =~ /\Q$CLASS: invalid argument: \E(.*) at \Q$FILE\E line \d+/s);
		return $text;
	};
	my $base = length($explanation->('xxxx')) - length('xxxx');
	state_diag(explanation_overhead => $base);
	my $at_limit = $explanation->('x' x ($MAX_REASON - $base));
	is(length($at_limit), $MAX_REASON, "exactly $MAX_REASON characters: kept whole");
	unlike($at_limit, qr/\.\.\.\z/, '... with no ellipsis');
	my $over = $explanation->('x' x ($MAX_REASON - $base + 1));
	is(length($over), $MAX_REASON + length('...'), "$MAX_REASON + 1 characters: cut to $MAX_REASON");
	like($over, qr/\.\.\.\z/, '... and marked with an ellipsis');
};

done_testing();
