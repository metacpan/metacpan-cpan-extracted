#!/usr/bin/env perl

# Logic tests: each decision in the module is treated as a small proof.
# For every condition, one test per outcome - no more - and for compound
# conditions, one test showing each part can change the result on its own
# (so no part is dead code).  Each subtest states its premises.
#
# Values inside an already proven partition are deliberately not repeated:
# t/domain.t covers the partitions; this file proves the logic that
# separates them.

use strict;
use warnings;

use lib 't/lib';
use Test::Most;
use Test::Warnings qw(warning);
use Readonly;
use Capture qw(printed);
use Test::Mockingbird;
use Encode ();
use Scalar::Util qw(looks_like_number);
use Config;

use Test::Log::Abstraction;

# White-box: the private decisions are called directly

Readonly::Scalar my $CLASS => 'Test::Log::Abstraction';
Readonly::Scalar my $FILE => __FILE__;
Readonly::Scalar my $MOST_SEVERE => 0;
Readonly::Scalar my $LEAST_SEVERE => 7;
Readonly::Scalar my $MIDDLE => 3;	# error: a threshold with levels either side
Readonly::Scalar my $MAX_SHOWN => 200;	# characters of a caller's value repeated in a message
Readonly::Scalar my $IV_BYTES => 8;	# the integer-fit table is for 64-bit integers
Readonly::Scalar my $ENV_LOCALE => 'zh_CN.UTF-8';	# a locale whose language differs from every other input
Readonly::Hash my %NAME_FOR => (0 => 'emergency', 1 => 'alert', 2 => 'critical', 3 => 'error', 4 => 'warning', 5 => 'notice', 6 => 'info', 7 => 'debug');
Readonly::Array my @PREDICATES => qw(trace debug info notice warn error critical alert emergency);
Readonly::Hash my %SEVERITY => (
	emergency => 0, alert => 1, critical => 2, error => 3,
	warn => 4, notice => 5, info => 6, debug => 7, trace => 7,
);

{
	package Local::Sub;
	our @ISA = ('Test::Log::Abstraction');

	package Local::Other;
	sub new { return bless {}, shift }
}

sub quiet {
	return $CLASS->new(diag => 'none', verbose => 0, @_);
}

sub at_caller {
	my $text = shift;

	return qr/\A\Q$CLASS: $text\E at \Q$FILE\E line \d+\.?\n?\z/;
}

# ===========================================================================
# new(): which calling form?
#   Premise 1: an object means "clone".
#   Premise 2: otherwise, UNIVERSAL::isa() decides "class name" or "option".
#   Conclusion: four outcomes, one test each.
# ===========================================================================

subtest 'new: the calling form' => sub {
	my $original = quiet(lang => 'fr');
	my $clone = $original->new();
	is($clone->lang(), 'fr', 'object: a clone');
	isnt($clone, $original, '... a new object');

	isa_ok(Test::Log::Abstraction::new('Local::Sub', diag => 'none'), 'Local::Sub', 'a name that isa this class: used as the class');
	is(Test::Log::Abstraction::new(lang => 'de', diag => 'none')->lang(), 'de', 'a name that is not a class: the first option');
	is(ref(Test::Log::Abstraction::new()), $CLASS, 'undef: this class, nothing added to the options');
};

# ===========================================================================
# _args(): which argument shapes reach Params::Get?
#   Premise: Params::Get accepts one hash reference, or an even list with
#            defined keys; it croaks or warns on anything else.
#   Conclusion: two accepted shapes, and each way of failing them.
# ===========================================================================

subtest '_args: the two accepted shapes, and each way to miss them' => sub {
	is_deeply(Test::Log::Abstraction::_args([{ a => 1 }]), { a => 1 }, 'one hash reference: accepted');
	is_deeply(Test::Log::Abstraction::_args([a => 1]), { a => 1 }, 'even list, keys defined: accepted');
	is_deeply(Test::Log::Abstraction::_args([]), {}, 'empty: nothing to pass on');
	is_deeply(Test::Log::Abstraction::_args(['x']), {}, 'one value, not a hash: odd, refused');
	is_deeply(Test::Log::Abstraction::_args([undef, 1]), {}, 'even, but a key undefined: refused');
	is_deeply(Test::Log::Abstraction::_args([1, undef]), { 1 => undef }, 'even, a value undefined: accepted (only keys are checked)');
};

# ===========================================================================
# _diag_rule(): which kind of rule?
#   Premise 1: undef means $config{diag}.
#   Premise 2: 'undef' is not a level name.
#   Conclusion: an undefined default, or an undefined list element, is
#   rejected by the same test as any other bad name - and named 'undef'.
# ===========================================================================

subtest '_diag_rule: every outcome' => sub {
	my $self = quiet();
	is_deeply($self->_diag_rule(['Info']), { levels => { info => 1 } }, 'list of names: a set');
	is_deeply($self->_diag_rule('NONE'), {}, "'none': empty rule");
	is_deeply($self->_diag_rule('All'), { all => 1 }, "'all': everything");
	is_deeply($self->_diag_rule('Error'), { threshold => $MIDDLE }, 'a level name: a threshold');
	is_deeply($self->_diag_rule(undef), { threshold => 4 }, 'undef: the default from %config');

	throws_ok { $self->_diag_rule([undef]) } at_caller(q{invalid diag level 'undef'}), 'undef in a list: rejected as the name undef';
	throws_ok { $self->_diag_rule(['UNDEF']) } at_caller(q{invalid diag level 'UNDEF'}), "the string 'UNDEF' fails the same test";
	throws_ok { $self->_diag_rule({}) } at_caller('diag must be a level name, "all", "none" or an array reference of level names'), 'not a list or a string';
	{
		local $Test::Log::Abstraction::config{'diag'} = undef;
		throws_ok { $self->_diag_rule(undef) } at_caller(q{invalid diag level 'undef'}), 'undef with an undefined default';
	}
	throws_ok { $self->_diag_rule('bogus') } at_caller(q{invalid diag level 'bogus'}), 'any other string';
};

# ===========================================================================
# _diags(): print this message?
#   It prints if ANY of four reasons holds:
#     V: verbose      A: rule 'all'      L: level listed
#     T: threshold rule, level known, severity <= threshold
#   Proof that each reason matters: each one alone gives 1, none gives 0.
#   T itself has three parts; each is shown to decide the result.
# ===========================================================================

subtest '_diags: each reason is enough on its own' => sub {
	my $self = quiet();
	my @rows = (
		[1, {}, 'error', 1, 'V alone'],
		[0, { all => 1 }, 'error', 1, 'A alone'],
		[0, { levels => { error => 1 } }, 'error', 1, 'L alone'],
		[0, { threshold => $MIDDLE }, 'error', 1, 'T alone'],
		[0, {}, 'error', 0, 'none of them'],
	);
	foreach my $row (@rows) {
		my ($verbose, $rule, $level, $want, $name) = @{$row};
		@{$self}{qw(verbose diag_rule)} = ($verbose, $rule);
		is($self->_diags($level), $want, $name);
	}
};

subtest '_diags: each part of the threshold reason decides it' => sub {
	my $self = quiet();
	$self->{'verbose'} = 0;
	$self->{'diag_rule'} = { threshold => $MIDDLE };
	is($self->_diags($NAME_FOR{$MIDDLE}), 1, 'severity == threshold: prints (the boundary is inclusive)');
	is($self->_diags($NAME_FOR{$MIDDLE + 1}), 0, 'severity == threshold + 1: does not print');
	is($self->_diags('nolevel'), 0, 'unknown level: does not print, whatever the threshold');
	$self->{'diag_rule'} = { levels => { error => 1 } };
	is($self->_diags($NAME_FOR{$MOST_SEVERE}), 0, 'no threshold: severity alone does not print');
};

# ===========================================================================
# count(): which messages?
#   Premise: undef means "all"; anything else must be a string.
#   Conclusion: three outcomes.
# ===========================================================================

subtest 'count: every outcome' => sub {
	my $logger = quiet();
	$logger->warn('a');
	$logger->info('b');
	is($logger->count(), 2, 'no level: all');
	is($logger->count('WARN'), 1, 'a level: those, any case');
	throws_ok { $logger->count([]) } at_caller(q{invalid argument: Parameter 'level' must be a string}), 'not a string: refused before anything is counted';
};

# ===========================================================================
# level(): get, set or warn - exactly one
# ===========================================================================

subtest 'level: exactly one of three paths' => sub {
	my $logger = quiet();
	is($logger->level(), $LEAST_SEVERE, 'no name: get');
	is($logger->level('ALERT'), $logger, 'a level name: set, and return the logger');
	is($logger->level(), 1, '... the level was set');
	my $result = 'unset';
	like(warning { $result = $logger->level('bogus') }, at_caller(q{invalid syslog level 'bogus'}), 'anything else: warn');
	ok(!defined($result), '... return undef');
	is($logger->level(), 1, '... and change nothing');
};

# ===========================================================================
# AUTOLOAD: the method name is always defined
#   Premise 1: $AUTOLOAD is always "Package::name".
#   Premise 2: the capture accepts any text after the last '::', even ''.
#   Conclusion: even an empty name is stored, as '' (not undef).
# ===========================================================================

subtest 'AUTOLOAD: the name is never undefined' => sub {
	my $logger = quiet();
	my $empty = '';
	my $out = printed { $logger->$empty('x') };
	is($logger->messages()->[0]->{'level'}, '', 'stored under the empty name');
	is($out, "# $CLASS: no method ''\n", 'announced, with no warning (Test::Warnings checks)');
};

# ===========================================================================
# Invariants from the formal specification, checked only at the boundaries
# ===========================================================================

# Log: log' = log ^ <<entry>>, and nothing else changes
subtest 'Log: one entry added, nothing else changed' => sub {
	my $logger = quiet(level => $NAME_FOR{$MIDDLE});
	my %before = (verbose => $logger->verbose(), level => $logger->level(), lang => $logger->lang());
	foreach my $level (qw(emergency trace)) {	# the most and least severe
		my $count = $logger->count();
		$logger->$level('m');
		is($logger->count(), $count + 1, "$level: exactly one more entry");
		is($logger->messages()->[-1]->{'level'}, $level, "$level: added at the end");
	}
	is_deeply({ verbose => $logger->verbose(), level => $logger->level(), lang => $logger->lang() }, \%before, 'verbose, level and lang unchanged');
};

# Clear: log' = <>, and nothing else changes
subtest 'Clear: log emptied, nothing else changed' => sub {
	my $logger = quiet(lang => 'de', level => $NAME_FOR{$MOST_SEVERE});
	$logger->info('m');
	my %before = (verbose => $logger->verbose(), level => $logger->level(), lang => $logger->lang());
	$logger->clear();
	is($logger->count(), 0, 'empty');
	is_deeply({ verbose => $logger->verbose(), level => $logger->level(), lang => $logger->lang() }, \%before, 'settings unchanged');
};

# IsLevel: result = true <=> severity <= threshold; only the two values
# either side of each edge can tell <= from < or from >=
subtest 'IsLevel: true exactly when severity <= threshold' => sub {
	my $logger = quiet();
	foreach my $threshold ($MOST_SEVERE, $MIDDLE, $LEAST_SEVERE) {
		$logger->level($NAME_FOR{$threshold});
		foreach my $level (grep { abs($SEVERITY{$_} - $threshold) <= 1 } @PREDICATES) {
			my $method = "is_$level";
			my $want = ($SEVERITY{$level} <= $threshold) ? 1 : 0;
			is($logger->$method(), $want, "threshold $threshold, severity $SEVERITY{$level}: $want");
		}
	}
};

# ===========================================================================
# Truth tables: every combination of every compound condition
#
# For each, the expected value is computed twice - as the OR of its parts,
# and through De Morgan's law as NOT (all parts false) - and both must
# equal what the code does.
# ===========================================================================

# Expected value of an OR, computed both ways; dies if they disagree, which
# would mean the table itself is wrong
sub any_of {
	my @parts = @_;

	my $or = (grep { $_ } @parts) ? 1 : 0;
	my $de_morgan = (!grep { $_ } @parts) ? 0 : 1;	# !(a || b) == (!a && !b)
	die "truth table error\n" if($or != $de_morgan);
	return $or;
}

# Print = V || A || L || (T && K && S): verbose, rule 'all', level listed,
# and a threshold (T) with the level known (K) and severe enough (S).
# 2 x 2 x 2 x 2 rules, times three kinds of level: 48 rows.
subtest 'truth table: _diags, all 48 rows' => sub {
	my $self = quiet();
	my %level = (at => $NAME_FOR{$MIDDLE}, over => $NAME_FOR{$MIDDLE + 1}, unknown => 'nolevel');
	foreach my $verbose (0, 1) { foreach my $all (0, 1) { foreach my $listed (0, 1) { foreach my $threshold (0, 1) {
		foreach my $kind (sort keys %level) {
			my $name = $level{$kind};
			$self->{'verbose'} = $verbose;
			$self->{'diag_rule'} = { ($all ? (all => 1) : ()), ($listed ? (levels => { $name => 1 }) : ()), ($threshold ? (threshold => $MIDDLE) : ()) };
			my $want = any_of($verbose, $all, $listed, ($threshold && ($kind eq 'at')));
			is($self->_diags($name), $want, "V=$verbose A=$all L=$listed T=$threshold level $kind: $want");
		}
	} } } }
};

# Language = lang if a code; else country's; else the environment's if
# 'auto' (given, or the default); else the default.  3 x 2 x 2 x 2 = 24 rows.
subtest 'truth table: _resolve_lang, all 24 rows' => sub {
	foreach my $lang (undef, 'auto', 'fr') { foreach my $country (undef, 'DE') {
		foreach my $default ('en', 'auto') { foreach my $env (undef, $ENV_LOCALE) {
			local $Test::Log::Abstraction::config{'lang'} = $default;
			local @ENV{qw(LC_ALL LC_MESSAGES LANG)} = ($env, undef, undef);
			delete @ENV{qw(LC_MESSAGES LANG)};
			delete $ENV{'LC_ALL'} if(!defined($env));
			my $auto = (defined($lang) && ($lang eq 'auto')) || (!defined($lang) && ($default eq 'auto'));
			my $want = (defined($lang) && ($lang ne 'auto')) ? 'fr'
				: defined($country) ? 'de'
				: ($auto && defined($env)) ? 'zh'
				: 'en';
			my %options = ((defined($lang) ? (lang => $lang) : ()), (defined($country) ? (country => $country) : ()));
			my $label = join(' ', map { defined($_) ? $_ : '-' } $lang, $country, $default, $env);
			is(Test::Log::Abstraction::_resolve_lang(\%options), $want, "lang/country/default/env = $label: $want");
		} }
	} }
};

# Usable = S || (N && E && K): a single hash; or a non-empty, even list
# whose keys are all defined.  Of the 16 rows, only these 6 can exist:
# S implies one defined argument (N=1, E=0, K=1), and an empty list is
# even with no keys (N=0 implies E=1, K=1).
subtest 'truth table: _args, every possible row' => sub {
	my @rows = (
		[1, 1, 0, 1, [{ a => 1 }]],
		[0, 0, 1, 1, []],
		[0, 1, 0, 1, ['x']],
		[0, 1, 0, 0, [undef]],
		[0, 1, 1, 1, [a => 1]],
		[0, 1, 1, 0, [undef, 1]],
	);
	foreach my $row (@rows) {
		my ($s, $n, $e, $k, $args) = @{$row};
		my $want = any_of($s, ($n && $e && $k));
		my $got = %{Test::Log::Abstraction::_args($args)} ? 1 : 0;
		is($got, $want, "S=$s N=$n E=$e K=$k: " . ($want ? 'passed on' : 'refused'));
	}
};

# Form = 'other' unless numeric; 'zero' if the count is 0 and the form
# exists; else the language's category if it exists; else 'other'.
# numeric x zero x has-zero x has-one = 16 rows.
subtest 'truth table: _plural, all 16 rows' => sub {
	foreach my $numeric (0, 1) { foreach my $is_zero (0, 1) { foreach my $has_zero (0, 1) { foreach my $has_one (0, 1) {
		my $count = !$numeric ? 'many' : $is_zero ? 0 : 1;
		my $template = { other => 1, ($has_zero ? (zero => 1) : ()), ($has_one ? (one => 1) : ()) };
		my $category = ($numeric && ($count == 1)) ? 'one' : 'other';	# English
		my $want = !$numeric ? 'other'
			: ($is_zero && $has_zero) ? 'zero'
			: exists($template->{$category}) ? $category
			: 'other';
		is(Test::Log::Abstraction::_plural($template, $count, 'en'), $want, "numeric=$numeric zero=$is_zero has-zero=$has_zero has-one=$has_one: $want");
	} } } }
};

# Text = '%' for %%; 'undef' for no value; sprintf when the value is a
# plain finite number or the conversion is %s; the value itself otherwise.
# 2 x 5 x 2 = 20 rows.
subtest 'truth table: _format, all 20 rows' => sub {
	my %value = (undef => undef, reference => [1], number => 42, text => 'abc', infinite => 9**9**9);
	foreach my $percent (undef, '%') { foreach my $kind (sort keys %value) { foreach my $conversion ('s', 'd') {
		my $v = $value{$kind};
		my $finite_number = ($kind eq 'number');
		my $want = defined($percent) ? '%'
			: !defined($v) ? 'undef'
			: ($finite_number || ($conversion eq 's')) ? sprintf("%$conversion", $v)
			: $v;
		my $got = Test::Log::Abstraction::_format($percent, $conversion, $v);
		is($got, $want, (defined($percent) ? '%%' : 'value') . " $kind %$conversion");
	} } }
};

# Encode = NOT layered AND character string.  2 x 2 = 4 rows.
subtest 'truth table: _emit encoding, all 4 rows' => sub {
	my $self = quiet();
	my %got;
	foreach my $layered (0, 1) { foreach my $flagged (0, 1) {
		my $text = $flagged ? "\x{2603}" : "\xe2\x98\x83";
		mock 'PerlIO::get_layers' => sub { return $layered ? ('unix', 'utf8') : ('unix') };
		mock 'Test::Builder::diag' => sub { $got{"$layered$flagged"} = $_[1]; return 1 };
		$self->_emit($text);
		restore_all();
	} }
	foreach my $layered (0, 1) { foreach my $flagged (0, 1) {
		my $encode = (!$layered && $flagged) ? 1 : 0;
		# Encoded or already bytes: UTF-8 bytes; left alone as characters: the character
		my $want = ($encode || !$flagged) ? "\xe2\x98\x83" : "\x{2603}";
		is($got{"$layered$flagged"}, $want, "layered=$layered character string=$flagged: " . ($encode ? 'encoded' : 'unchanged'));
	} }
};

# Accept = blessed AND isa; so, by De Morgan, refuse = NOT blessed OR NOT isa.
# 2 x 2 = 4 rows.
subtest 'truth table: _object, all 4 rows' => sub {
	my %invocant = ('11' => quiet(), '10' => bless({}, 'Local::Other'), '01' => $CLASS, '00' => {});
	foreach my $key (sort keys %invocant) {
		my ($blessed, $isa) = split(//, $key);
		my $accept = ($blessed && $isa) ? 1 : 0;
		my $refuse = (!$blessed || !$isa) ? 1 : 0;
		is($accept, 1 - $refuse, "blessed=$blessed isa=$isa: De Morgan holds");
		my $got = eval { Test::Log::Abstraction::_object($invocant{$key}, 'm'); 1 } ? 1 : 0;
		is($got, $accept, "blessed=$blessed isa=$isa: " . ($accept ? 'accepted' : 'refused'));
	}
};

# Fields = two or more arguments AND the last a plain hash AND it is not
# empty.  2 x 2 x 2 = 8 rows.
subtest 'truth table: _entry fields, all 8 rows' => sub {
	foreach my $several (0, 1) { foreach my $plain (0, 1) { foreach my $full (0, 1) {
		my $last = $plain ? ($full ? { k => 1 } : {}) : bless(($full ? { k => 1 } : {}), 'Local::Other');
		my @args = (($several ? ('m') : ()), $last);
		my $want = ($several && $plain && $full) ? 1 : 0;
		my $entry = Test::Log::Abstraction::_entry('info', \@args);
		is(exists($entry->{'fields'}) ? 1 : 0, $want, "several=$several plain=$plain non-empty=$full: " . ($want ? 'fields' : 'no fields'));
	} } }
};

# Parts = exactly one argument AND it is an array reference.  2 x 2 = 4 rows.
subtest 'truth table: _entry message parts, all 4 rows' => sub {
	foreach my $one (0, 1) { foreach my $array (0, 1) {
		my $arg = $array ? ['p', 'q'] : 'pq';
		my @args = $one ? ($arg) : ($arg, '!');
		my $flatten = ($one && $array) ? 1 : 0;
		my $want = !$one ? ($array ? '[p, q]!' : 'pq!') : 'pq';	# one argument: 'pq' either way, by different routes
		is(Test::Log::Abstraction::_entry('info', \@args)->{'message'}, $want, "one=$one array=$array: " . ($flatten ? 'flattened' : 'as written'));
	} }
};

# ===========================================================================
# The logger invariant: before, during and after every operation
#
#   messages is an array of entries, each with a defined level and message
#   (and a hash of fields if any); level is a whole number 0 to 7; verbose
#   is 0 or 1; lang is a language code; the diag rule has one of its four
#   shapes.
# ===========================================================================

# Every way the invariant is broken, as text; an empty list means it holds
sub violations {
	my $self = shift;

	my @broken;
	push @broken, 'messages is not an array' if(ref($self->{'messages'}) ne 'ARRAY');
	foreach my $entry (@{$self->{'messages'} || []}) {
		push @broken, 'entry without level or message' if(!defined($entry->{'level'}) || !defined($entry->{'message'}));
		push @broken, 'fields is not a hash' if(exists($entry->{'fields'}) && (ref($entry->{'fields'}) ne 'HASH'));
	}
	push @broken, 'level out of range' if(!defined($self->{'level'}) || ($self->{'level'} !~ /\A[0-7]\z/));
	push @broken, 'verbose is not 0 or 1' if(!defined($self->{'verbose'}) || ($self->{'verbose'} !~ /\A[01]\z/));
	push @broken, 'lang is not a code' if(!defined($self->{'lang'}) || ($self->{'lang'} !~ /\A[a-z]{2,3}\z/));
	my $rule = $self->{'diag_rule'};
	my $shape = join(',', sort keys %{$rule || {}});
	push @broken, "diag rule has shape '$shape'" if(!grep { $shape eq $_ } ('', 'all', 'levels', 'threshold'));
	return \@broken;
}

{
	package Local::Inspector;
	# Logged as a message part: checks the logger while it is mid-log
	use overload '""' => sub { my $self = shift; push @{$self->{'seen'}}, main::violations($self->{'logger'}); return 'inspected' }, fallback => 1;
}

subtest 'invariant: before, during and after each operation' => sub {
	my $logger = $CLASS->new(diag => ['error'], verbose => 0, level => 'warn');
	my %operation = (
		'log' => sub { $logger->info('x', { k => 1 }) },
		'log, printed' => sub { printed { $logger->error('x') } },
		'unknown method' => sub { printed { $logger->wran('x') } },
		'set level' => sub { $logger->level('alert') },
		'rejected level' => sub { warning { $logger->level('bogus') } },
		'set verbose' => sub { $logger->verbose(1); $logger->verbose(0) },
		'clone' => sub { $logger = $logger->new(lang => 'de') },
		'failing assertion' => sub { my $tb = Test::Builder->new(); $tb->todo_start('expected'); printed { $logger->like(qr/never/) }; $tb->todo_end() },
		'clear' => sub { $logger->clear() },
	);
	foreach my $name (sort keys %operation) {
		is_deeply(violations($logger), [], "$name: holds before");

		# During: an object logged mid-operation inspects the logger, and so
		# does the output channel while the message is being printed
		my $inspector = bless { logger => $logger, seen => [] }, 'Local::Inspector';
		my @at_output;
		mock 'Test::Builder::diag' => sub { push @at_output, violations($logger); return 1 };
		printed { $logger->debug($inspector) };
		$operation{$name}->();
		restore_all();
		is_deeply($inspector->{'seen'}, [[]], "$name: holds while a message is being built");
		is_deeply([grep { @{$_} } @at_output], [], "$name: holds while output is printed");

		is_deeply(violations($logger), [], "$name: holds after");
	}
};

# ===========================================================================
# Contradictions: inputs that break a documented rule are refused at once,
# before anything changes or is printed
# ===========================================================================

subtest 'contradictions are refused before any effect' => sub {
	my $logger = $CLASS->new(diag => 'all', verbose => 0);
	$logger->clear();
	my @cases = (
		["'all' means every level, so it cannot be one level in a list", sub { $CLASS->new(diag => ['info', 'all']) }, q{invalid diag level 'all'}],
		['a severity number is not a level name', sub { $CLASS->new(level => '3') }, q{invalid syslog level '3'}],
		['a country code is two letters', sub { $CLASS->new(country => 'DEU') }, undef],
		['a level to count is a name, not a list', sub { $logger->count(['warn']) }, q{invalid argument: Parameter 'level' must be a string}],
		['a pattern must compile', sub { $logger->like('[') }, undef],
		['a pattern is required', sub { $logger->unlike() }, 'unlike() needs a pattern'],
		['a level is required', sub { $logger->has_level() }, 'has_level() needs a level name'],
		['logging needs a logger, not the class', sub { $CLASS->error('x') }, 'error() must be called on an object, not on the class'],
		['a test name is text', sub { $logger->empty({}) }, q{invalid argument: Parameter 'name' must be a string}],
		['a clone obeys the rules of new()', sub { $logger->new(level => 'LOUD') }, q{invalid syslog level 'LOUD'}],
		['undef is not a level name, even in a list', sub { $CLASS->new(diag => [undef]) }, q{invalid diag level 'undef'}],
	);
	my $test = Test::Builder->new();
	foreach my $case (@cases) {
		my ($premise, $code, $message) = @{$case};
		my $tests_before = $test->current_test();
		my $out = printed { throws_ok { $code->() } ($message ? at_caller($message) : qr/\A\Q$CLASS: invalid argument: \E/), "$premise: refused" };
		my $reported = $test->current_test() - $tests_before;	# read before any other test is counted
		is($out =~ /\Q$CLASS\E/ ? 1 : 0, 0, "$premise: no message printed by the logger");
		is($reported, 1, "$premise: only throws_ok itself reported a test");
		is($logger->count(), 0, "$premise: nothing stored");
		is_deeply(violations($logger), [], "$premise: invariant intact");
	}
};

# ===========================================================================
# More truth tables: the remaining compound conditions
# ===========================================================================

# Verbose = G ? g : (TV || V): an explicit option (G) decides alone;
# otherwise either environment variable is enough.  3 x 2 x 2 = 12 rows.
subtest 'truth table: _build verbose, all 12 rows' => sub {
	foreach my $given (undef, 0, 1) { foreach my $test_verbose (0, 1) { foreach my $verbose (0, 1) {
		local $ENV{'TEST_VERBOSE'} = $test_verbose;
		local $ENV{'VERBOSE'} = $verbose;
		my $want = defined($given) ? $given : any_of($test_verbose, $verbose);
		my $logger = $CLASS->new(diag => 'none', (defined($given) ? (verbose => $given) : ()));
		is($logger->verbose(), $want, 'option=' . (defined($given) ? $given : '-') . " TEST_VERBOSE=$test_verbose VERBOSE=$verbose: $want");
	} } }
};

# A clone keeps a runtime change to verbose (or level) unless that option is
# overridden: Keep = NOT overridden.  Each is decided on its own: 2 x 2 rows.
subtest 'truth table: _clone carry-over, all 4 rows' => sub {
	foreach my $override_verbose (0, 1) { foreach my $override_level (0, 1) {
		my $original = quiet();
		$original->verbose(1);
		$original->level($NAME_FOR{1});	# changed at run time, away from the options
		my $clone = $original->new(($override_verbose ? (verbose => 0) : ()), ($override_level ? (level => $NAME_FOR{$MIDDLE}) : ()));
		is($clone->verbose(), $override_verbose ? 0 : 1, "override verbose=$override_verbose level=$override_level: verbose " . ($override_verbose ? 'from the override' : 'carried over'));
		is($clone->level(), $override_level ? $MIDDLE : 1, "override verbose=$override_verbose level=$override_level: level " . ($override_level ? 'from the override' : 'carried over'));
	} }
};

# A level method stores unless the level is warn or more serious (I) AND it
# was given no arguments (E).  Store = NOT (I AND E) = (NOT I) OR (NOT E),
# by De Morgan.  warn and notice are the two levels either side of the
# edge.  2 x 2 = 4 rows.
subtest 'truth table: level methods with no arguments, all 4 rows' => sub {
	foreach my $level ('warn', 'notice') { foreach my $empty (0, 1) {
		my $ignore = ($SEVERITY{$level} <= $SEVERITY{'warn'}) ? 1 : 0;
		my $store = any_of(!$ignore, !$empty);
		is($store, ($ignore && $empty) ? 0 : 1, "$level empty=$empty: De Morgan holds");
		my $logger = quiet();
		$logger->$level($empty ? () : ('m'));
		is($logger->count(), $store, "$level empty=$empty: " . ($store ? 'stored' : 'ignored'));
	} }
};

# An integer conversion formats a number only if sprintf reads it back as
# itself: Format = fits, where fits depends on the conversion (signed or
# unsigned), the sign (an unsigned format reads a negative as signed, in
# two's complement), and is tested on two forms of number (a string of
# digits, compared digit by digit, and a float).  2 x 2 x 2 x 2 = 16 rows.
subtest 'truth table: _format integer fit, all 16 rows' => sub {
	plan(skip_all => 'the limits are for 64-bit integers') if($Config{'ivsize'} < $IV_BYTES);
	# conversion => sign => fits => [digit string, float]
	my %value = (
		d => {
			'+' => { 1 => ['42', 42.0], 0 => ['9223372036854775808', 1e19] },
			'-' => { 1 => ['-42', -42.0], 0 => ['-9223372036854775809', -1e19] },
		},
		u => {
			'+' => { 1 => ['18446744073709551615', 42.0], 0 => ['18446744073709551616', 1e20] },
			'-' => { 1 => ['-1', -1.0], 0 => ['-9223372036854775809', -1e19] },
		},
	);
	foreach my $conversion (sort keys %value) { foreach my $sign ('+', '-') { foreach my $fits (0, 1) {
		foreach my $form (0, 1) {
			my $v = $value{$conversion}{$sign}{$fits}[$form];
			my $want = $fits ? sprintf("%$conversion", $v) : "$v";
			is(Test::Log::Abstraction::_format(undef, $conversion, $v), $want, "%$conversion sign=$sign fits=$fits " . ($form ? 'float' : 'digits') . ': ' . ($fits ? 'formatted' : 'as written'));
		}
	} } }
};

# Escaped = C0 OR (C1 AND character string); printable characters never
# are.  3 kinds x 2 string types = 6 rows.  Then: Cut = length > limit,
# measured after escaping, so one control character at the end can push a
# value over the limit.
subtest 'truth table: _shown escaping and cutting' => sub {
	my %char = (C0 => "\x{1b}", C1 => "\x{9b}", printable => "\x{e9}");
	foreach my $kind (sort keys %char) { foreach my $flagged (0, 1) {
		my $text = "a$char{$kind}";
		$flagged ? utf8::upgrade($text) : utf8::downgrade($text);
		my $escape = any_of(($kind eq 'C0'), (($kind eq 'C1') && $flagged));
		my $want = $escape ? sprintf('a\\x%02X', ord($char{$kind})) : $text;
		is(Test::Log::Abstraction::_shown($text), $want, "$kind character string=$flagged: " . ($escape ? 'escaped' : 'kept'));
	} }
	my $at_limit = 'x' x $MAX_SHOWN;
	is(Test::Log::Abstraction::_shown($at_limit), $at_limit, "$MAX_SHOWN characters: not cut");
	is(Test::Log::Abstraction::_shown('x' x ($MAX_SHOWN + 1)), "$at_limit...", ($MAX_SHOWN + 1) . ' characters: cut');
	# 199 characters and a newline: 200 as given, 203 once escaped
	is(Test::Log::Abstraction::_shown(('x' x ($MAX_SHOWN - 1)) . "\n"), ('x' x ($MAX_SHOWN - 1)) . "\\...", 'the cut counts the escaped form');
};

# The first template found wins, in this order: the logger's override in its
# own language (O_l), the built-in in its language (B_l), the English
# override (O_e), the built-in English (B_e); with none, there is no
# template.  The built-in catalogue is fixed, so it is controlled by the
# choice of key: one in both languages, one in English only, or neither.
# 2 x 3 x 2 = 12 rows, for a German logger.
subtest 'truth table: _template search order, all 12 rows' => sub {
	my %builtin = ('in German and English' => 'needs_level', 'in English only' => 'entry', 'nowhere' => 'no_such_key');
	my $plain = quiet();
	foreach my $own (0, 1) { foreach my $kind (sort keys %builtin) { foreach my $english (0, 1) {
		my $key = $builtin{$kind};
		my %i18n = (($own ? (de => { $key => 'override de' }) : ()), ($english ? (en => { $key => 'override en' }) : ()));
		my $logger = quiet(lang => 'de', i18n => \%i18n);
		my $builtin_de = ($kind eq 'in German and English');
		my $builtin_en = ($kind ne 'nowhere');
		my $want = $own ? 'override de'
			: $builtin_de ? Test::Log::Abstraction::_template($plain, 'de', $key)
			: $english ? 'override en'
			: $builtin_en ? Test::Log::Abstraction::_template($plain, 'en', $key)
			: undef;
		is(Test::Log::Abstraction::_template($logger, 'de', $key), $want, "O_l=$own built-in $kind O_e=$english");
	} } }
	isnt(Test::Log::Abstraction::_template($plain, 'de', 'needs_level'), Test::Log::Abstraction::_template($plain, 'en', 'needs_level'), 'premise: the German and English built-ins differ, so the table can tell them apart');
};

# Gender is used when given AND the template has it; otherwise the plural
# form decides.  3 genders x 2 counts = 6 rows.
subtest 'truth table: _variant gender or plural, all 6 rows' => sub {
	my $template = { female => 'she', one => 'one', other => 'many' };
	foreach my $gender (undef, 'male', 'female') { foreach my $count (1, 2) {
		my $by_gender = defined($gender) && exists($template->{$gender});
		my $want = $by_gender ? $template->{$gender} : ($count == 1) ? 'one' : 'many';
		is(Test::Log::Abstraction::_variant($template, { gender => $gender, count => $count }, 'en'), $want, 'gender ' . (defined($gender) ? $gender : 'undef') . " count $count: $want");
	} }
};

# Text = Perl's form, unless a reference's overloaded "" dies; then the
# plain form.  An overload that gives undef does not die: Perl's form of
# undef is '', so that is the text.  5 rows: a plain value can never fail.
subtest 'truth table: _string, all 5 rows' => sub {
	my %value = (
		'plain value' => ['text', 'text'],
		'reference, no overloading' => [[], undef],
		'overloading that works' => [Local::Text->new('shown'), 'shown'],
		'overloading that dies' => [Local::Text->new(undef, 1), undef],
		'overloading that gives undef' => [Local::Text->new(undef), ''],
	);
	foreach my $name (sort keys %value) {
		my ($v, $want) = @{$value{$name}};
		$want = overload::StrVal($v) if(!defined($want));
		is(Test::Log::Abstraction::_string($v), $want, $name);
	}
};

{
	package Local::Text;
	use overload '""' => sub { die "no text\n" if($_[0]->{'dies'}); return $_[0]->{'text'} }, fallback => 1;
	sub new { my ($class, $text, $dies) = @_; return bless { text => $text, dies => $dies }, $class }
}

# ===========================================================================
# Reductions: checks removed because an earlier step already proved them.
# Each subtest tests the premise the removal relies on, then the outcome.
# ===========================================================================

# _diag_rule() compares the name with 'none' and 'all' without first asking
# whether it is defined.
#   Premise 1: undef is compared as '', and '' is neither word.
#   Premise 2: so both undef and '' go on to the level-name check.
#   Conclusion: '' is refused under its own name, and undef as 'undef'.
subtest 'reduction: _diag_rule needs no defined() before the words' => sub {
	my $self = quiet();
	throws_ok { $self->_diag_rule('') } at_caller(q{invalid diag level ''}), "'': neither word, so checked as a level name";
	{
		local $Test::Log::Abstraction::config{'diag'} = undef;
		throws_ok { $self->_diag_rule(undef) } at_caller(q{invalid diag level 'undef'}), 'undef: neither word, so checked as a level name';
	}
	# The boundary on each side of the words: changed case still matches,
	# one letter more or less does not
	is_deeply($self->_diag_rule('nONE'), {}, "'nONE': the word none");
	is_deeply($self->_diag_rule('ALL'), { all => 1 }, "'ALL': the word all");
	throws_ok { $self->_diag_rule('non') } at_caller(q{invalid diag level 'non'}), "'non': not a word, not a level";
	throws_ok { $self->_diag_rule('alll') } at_caller(q{invalid diag level 'alll'}), "'alll': not a word, not a level";
};

# _object() names a class in its error only when the invocant is a class
# name, and tests that with UNIVERSAL::isa() alone.
#   Premise 1: an object of this class, or a subclass, never reaches it.
#   Premise 2: isa() is false, without a warning, for everything else that
#              is not a class name: undef, '', unblessed references and
#              other classes' objects.
#   Conclusion: the class named is the invocant exactly when it is the name
#   of this class or a subclass; Test::Warnings proves no warning was given.
subtest 'reduction: _object needs no defined() or ref() before isa()' => sub {
	my %invocant = (
		'undef' => [undef, $CLASS],
		'empty string' => ['', $CLASS],
		'unblessed hash' => [{}, $CLASS],
		'unblessed array' => [[], $CLASS],
		'reference to this class name' => [\$CLASS, $CLASS],
		'another class object' => [Local::Other->new(), $CLASS],
		'another class name' => ['Local::Other', $CLASS],
		'this class name' => [$CLASS, $CLASS],
		'a subclass name' => ['Local::Sub', 'Local::Sub'],
	);
	foreach my $name (sort keys %invocant) {
		my ($self, $named) = @{$invocant{$name}};
		my $is_name = UNIVERSAL::isa($self, $CLASS) ? 1 : 0;
		is($is_name, ($named ne $CLASS) || (defined($self) && ($self eq $CLASS)) ? 1 : 0, "$name: premise 2 holds");
		throws_ok { Test::Log::Abstraction::_object($self, 'm') } qr/\A\Q$named: m() must be called on an object, not on the class\E at /, "$name: names $named";
	}
};

done_testing();
