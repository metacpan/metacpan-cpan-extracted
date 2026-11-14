#!/usr/bin/env perl

# Destructive, pathological and security tests: every public method is fed
# the worst input that can be built, while its collaborators fail under it.
# What the POD promises must still hold: messages are stored exactly, no
# method warns or loses the caller's $@, $! or $_, the module never touches
# the filesystem or a shell, and what it prints cannot forge TAP.
#
# The module takes no file names, so the filesystem cases check that paths
# and file contents of every hostile kind are only ever data to it.

use strict;
use warnings;

use lib 't/lib';
use Test::Most;
use Test::Warnings;
use Test::Mockingbird;
use Test::Returns;
use Test::Permissions qw(:revoke :guard);
use Readonly;
use Encode ();
use Errno qw(ENOSPC EIO EMFILE);
use Cwd qw(getcwd);
use File::Spec;
use File::Temp qw(tempdir);
use Time::HiRes ();
use Capture qw(capture_diag run_perl_script);

use Test::Log::Abstraction;

Readonly::Scalar my $CLASS => 'Test::Log::Abstraction';
Readonly::Scalar my $FILE => __FILE__;
Readonly::Scalar my $SENTINEL => 'caller value';
Readonly::Scalar my $HUGE => 10_000_000;	# characters in one message
Readonly::Scalar my $MANY => 100_000;	# messages, arguments or list items
Readonly::Scalar my $MAX_LISTED => 20;	# entries a failing assertion lists
Readonly::Scalar my $MAX_REASON => 200;	# characters kept from a validator's error
Readonly::Scalar my $BUDGET => 5;	# seconds any single hostile call may take
Readonly::Scalar my $RANDOM_BYTES => 256;
Readonly::Scalar my $FD_SPARE => 32;	# descriptors left free above those already open
Readonly::Scalar my $BIG_NUMBER => 1e30;	# finite, but too big for any integer format
Readonly::Scalar my $DEEP => 100_000;	# levels of nesting in one logged structure
Readonly::Scalar my $ALARM => 60;	# seconds on a timer the module must leave alone
Readonly::Scalar my $LOWEST_LEVEL => 7;	# the syslog number of debug and trace
Readonly::Scalar my $SHOW_STATE => $ENV{'TEST_VERBOSE'};

# Paths that would do damage if anything opened or ran them
Readonly::Array my @HOSTILE_PATHS => (
	'/dev/urandom', '/dev/null', '/dev/zero', '/', '/etc/passwd', '../../../../etc/shadow',
	'| rm -rf /', 'rm -rf / |', '`id`', '$(id)', ';reboot', "name\nwith newline",
	'name with spaces', "nul\0byte", '-rf', '>/tmp/clobbered', '+<file', "\t",
);

# Show a value, only when asked to
sub state_diag {
	my ($label, $value) = @_;

	# Test::More's explain() returns the dump; Test::Most's prints it
	# and returns 0, which diag() then printed as a stray "# 0"
	diag(Test::More::explain({ $label => $value })) if($SHOW_STATE);
	return;
}

# A value made safe for a test name: control characters escaped, '' shown
sub printable {
	my $value = shift;

	return q{''} if(!length($value));
	(my $text = substr($value, 0, 20)) =~ s/([^\x20-\x7e])/sprintf('\\x%02X', ord($1))/ge;
	return $text;
}

# A logger that stores everything and prints nothing
sub quiet {
	return $CLASS->new(diag => 'none', verbose => 0, @_);
}

# The exact text of an error raised from this file
sub at_caller {
	my $text = shift;

	return qr/\A\Q$CLASS: $text\E at \Q$FILE\E line \d+\.?\n?\z/;
}

# What code printed, without the indentation Test::Builder adds in subtests
sub printed(&) {
	my $code = shift;

	(my $out = capture_diag(\&{$code})) =~ s/^[ ]+#/#/mg;
	return $out;
}

# Run a failing assertion as a TODO test; return its result and output
sub failing {
	my $code = shift;

	my $tb = Test::Builder->new();
	my $result;
	$tb->todo_start('expected to fail');
	my $out = printed { $result = $code->() };
	$tb->todo_end();
	return ($result, $out);
}

# Run code under a time limit, so a pathological input cannot hang the file
sub within_budget {
	my ($name, $code) = @_;

	my $started = Time::HiRes::time();
	my $ok = eval {
		local $SIG{'ALRM'} = sub { die "budget exceeded\n" };
		alarm($BUDGET);
		$code->();
		alarm(0);
		1;
	};
	alarm(0);
	ok($ok, sprintf('%s: finished in %.2fs', $name, Time::HiRes::time() - $started)) or diag($@);
	return;
}

# A character string whose bytes are not valid UTF-8, as Encode::_utf8_on()
# makes from bytes that were never UTF-8
sub malformed {
	my $text = shift;

	Encode::_utf8_on($text);
	return $text;
}

# The first captured message's text
sub first_message {
	return $_[0]->messages()->[0]->{'message'};
}

{
	package Local::Bomb;
	use overload '""' => sub { die "stringify exploded\n" }, 'bool' => sub { 1 }, fallback => 1;

	package Local::Other;
	sub new { return bless {}, shift }
}

# ===========================================================================
# Hostile scalars
# ===========================================================================

# Strategy: the values Perl code mishandles most often - false-but-defined
# values, NUL, whitespace, extreme numbers - must be stored exactly as given
subtest 'false, empty and extreme scalars are stored exactly' => sub {
	my $logger = quiet();
	my @values = ('0', '', ' ', "\0", "\n", '0.0', '0E0', '00', '-0', 1e308, -1e308, 9**9**9, -9**9**9, 'NaN', ~0, -(~0 >> 1) - 1);
	foreach my $value (@values) {
		$logger->clear()->info($value);
		(my $want = "$value") =~ s/\n\z//;
		is($logger->messages()->[0]->{'message'}, $want, 'stored: ' . printable($value));
	}
	$logger->clear()->info();
	is($logger->messages()->[0]->{'message'}, '', 'no arguments at all: an empty message');
	$logger->clear()->info(undef, undef);
	is($logger->messages()->[0]->{'message'}, 'undefundef', 'only undefs');
};

subtest 'false and empty values as levels, names and patterns' => sub {
	my $logger = quiet();
	$logger->info('anything');

	is($logger->count('0'), 0, "count('0') is a level name, not 'all'");
	is($logger->count(''), 0, "count('') matches no level");
	is($logger->count(undef), 1, 'count(undef) counts all, as documented');

	ok($logger->like('', 'empty pattern matches every message'), "like('') passes");
	my ($result) = failing(sub { $logger->unlike('') });
	ok(!$result, "unlike('') fails: the empty pattern matches");
	ok($logger->like(qr/anything/, '0'), "a test named '0' still passes");
	ok($logger->like(qr/anything/, ''), 'an empty test name still passes');

	my $out;
	warning_like { $out = $logger->level('') } at_caller(q{invalid syslog level ''}), "level('') warns";
	is($out, undef, '... and returns undef');
	warning_like { $logger->level('0') } at_caller(q{invalid syslog level '0'}), "level('0') warns: 0 is not a level name";
	is($logger->level(), 7, 'level unchanged');
};

subtest 'enormous values' => sub {
	my $logger = quiet();
	within_budget('a 10-million-character message', sub { $logger->info('x' x $HUGE) });
	is(length($logger->messages()->[0]->{'message'}), $HUGE, 'stored whole');

	within_budget("$MANY arguments", sub { $logger->clear()->info(('a') x $MANY) });
	is(length($logger->messages()->[0]->{'message'}), $MANY, 'all joined');

	within_budget("$MANY messages", sub { $logger->clear(); $logger->debug($_) foreach 1 .. $MANY });
	is($logger->count(), $MANY, 'all stored');
	my $out;
	within_budget('failing assertion over all of them', sub { (undef, $out) = failing(sub { $logger->empty() }) });
	my @listed = ($out =~ /^#     \[debug\]/mg);
	is(scalar(@listed), $MAX_LISTED, "only $MAX_LISTED listed");
	like($out, qr/^#     \.\.\. and \Q@{[ $MANY - $MAX_LISTED ]}\E more$/m, 'the rest summarised');

	within_budget("a diag list of $MANY level names", sub { quiet(diag => [('error') x $MANY]) });
	within_budget('a pattern longer than any message', sub {
		my ($result) = failing(sub { $logger->like('z' x $HUGE) });
		ok(!$result, 'no match, no crash');
	});
};

# ===========================================================================
# Hostile references
# ===========================================================================

# Strategy: every kind of reference Perl has, as a message part, as fields,
# and as an argument where a string is expected
subtest 'every reference type as a message' => sub {
	my $logger = quiet();
	my $scalar = 'v';
	my %parts = (
		glob => *STDOUT,
		glob_ref => \*STDOUT,
		io => *STDOUT{IO},
		code => sub { die "never called\n" },
		regex => qr/a(b)c/,
		ref_ref => \\'deep',
		lvalue => \substr($scalar, 0, 1),
		vstring => v1.2.3,
		object => Local::Other->new(),
		logger => $logger,
	);
	foreach my $kind (sort keys %parts) {
		lives_ok { $logger->clear()->info($parts{$kind}) } "$kind: logged";
		ok(length($logger->messages()->[0]->{'message'}), "$kind: rendered to text");
		state_diag($kind => $logger->messages()->[0]->{'message'});
	}
	like($logger->clear()->info($logger)->messages()->[0]->{'message'}, qr/\A\Q$CLASS\E=HASH\(0x[0-9a-f]+\)\z/, 'the logger itself is just text, not a recursion');
};

subtest 'references where strings are required are refused, exactly' => sub {
	my $logger = quiet();
	foreach my $bad (\*STDOUT, sub { 1 }, \'x', [], {}, Local::Other->new()) {
		my $kind = ref($bad);
		throws_ok { $logger->count($bad) } at_caller(q{invalid argument: Parameter 'level' must be a string}), "count($kind)";
		throws_ok { $logger->has_level($bad) } at_caller(q{invalid argument: Parameter 'level' must be a string}), "has_level($kind)";
	}
	throws_ok { $logger->like(*STDOUT) } qr/\A\Q$CLASS: invalid argument: Quantifier follows nothing in regex\E/, 'a glob is a string, and not a valid pattern';
	throws_ok { $CLASS->new(diag => *STDOUT) } at_caller(q{invalid diag level '*main::STDOUT'}), 'glob as diag';
	throws_ok { $CLASS->new(diag => \*STDOUT) } at_caller('diag must be a level name, "all", "none" or an array reference of level names'), 'glob reference as diag';
	throws_ok { $CLASS->new(lang => \*STDOUT) } qr/\A\Q$CLASS: invalid argument: \E.*lang/, 'glob reference as lang';
};

subtest 'circular references in every position' => sub {
	my $logger = quiet();
	my $loop = { name => 'loop' };
	$loop->{'self'} = $loop;
	my @list = ('x');
	push @list, \@list;

	$logger->info($loop);
	is($logger->messages()->[0]->{'message'}, '{name => loop, self => (cycle)}', 'cyclic hash as the message');
	$logger->clear()->info([\@list]);
	is($logger->messages()->[0]->{'message'}, '[x, (cycle)]', 'cyclic array inside a lone array reference');
	$logger->clear()->info('fields', $loop);
	is($logger->messages()->[0]->{'fields'}->{'self'}, $loop, 'cyclic fields are kept by reference (shallow copy, as documented)');

	my @diag_loop;
	push @diag_loop, \@diag_loop;
	throws_ok { quiet(diag => \@diag_loop) } qr/\A\Q$CLASS: invalid diag level 'ARRAY(0x\E/, 'a self-containing diag list';

	my %i18n_loop;
	$i18n_loop{'en'}{'k'}{'other'} = $i18n_loop{'en'}{'k'};
	is(quiet(i18n => \%i18n_loop)->clear()->count(), 0, 'a self-containing i18n option is accepted');
	delete $loop->{'self'};
	@list = ();
	@diag_loop = ();
};

subtest 'duplicate and conflicting keys' => sub {
	is($CLASS->new(lang => 'de', lang => 'fr', diag => 'none')->lang(), 'fr', 'a repeated option: the last one wins');
	my $logger = quiet();
	$logger->info('real message', { level => 'emergency', message => 'forged', fields => 'x' });
	my $entry = $logger->messages()->[0];
	is($entry->{'level'}, 'info', 'fields cannot overwrite the level');
	is($entry->{'message'}, 'real message', 'fields cannot overwrite the message');
	is($logger->count('emergency'), 0, 'and cannot add a message at another level');
	is_deeply($entry->{'fields'}, { level => 'emergency', message => 'forged', fields => 'x' }, 'they are only fields');
};

# ===========================================================================
# Encodings
# ===========================================================================

# Strategy: bytes that are not UTF-8, strings marked as text that are not
# valid, and characters UTF-8 forbids, all the way through storage,
# matching and printing, with no warnings anywhere (Test::Warnings)
subtest 'invalid and forbidden UTF-8' => sub {
	my $malformed = "\xff\xfe\xc0\xaf tail";
	Encode::_utf8_on($malformed);
	my %strings = (
		'invalid bytes' => "\xff\xfe\xfd tail",
		'overlong encoding' => "\xc0\xaf tail",
		'truncated sequence' => "\xe2\x82 tail",
		'malformed text string' => $malformed,
		'surrogate' => "\x{D800} tail",
		'non-Unicode code point' => "\x{7FFFFFFF} tail",
		'byte order mark' => "\x{FEFF} tail",
		'NUL bytes' => "a\0b\0 tail",
		'right-to-left override' => "\x{202E} tail",
	);
	my $logger = $CLASS->new(diag => 'all', verbose => 0);
	foreach my $kind (sort keys %strings) {
		my $out = printed { $logger->clear()->warn($strings{$kind}) };
		is($logger->messages()->[0]->{'message'}, $strings{$kind}, "$kind: stored unchanged");
		ok($logger->like(qr/tail\z/, "$kind: matchable"), "$kind: like() works");
		like($out, qr/tail$/m, "$kind: printed");
		state_diag($kind => $out);
	}
};

subtest 'random bytes from /dev/urandom' => sub {
	plan(skip_all => '/dev/urandom is not available') if(!-c '/dev/urandom');
	open(my $fh, '<:raw', '/dev/urandom') or plan(skip_all => "cannot read /dev/urandom: $!");
	my $read = read($fh, my $bytes, $RANDOM_BYTES);
	close($fh);
	is($read, $RANDOM_BYTES, 'read the random bytes');

	my $logger = $CLASS->new(diag => 'all', verbose => 0);
	printed { $logger->error($bytes, { raw => $bytes }) };
	(my $want = $bytes) =~ s/\n\z//;
	is($logger->messages()->[0]->{'message'}, $want, 'stored byte for byte');
	is($logger->messages()->[0]->{'fields'}->{'raw'}, $bytes, 'fields byte for byte');
	ok($logger->like(qr/\Q$want\E/, 'random bytes match themselves'), 'matchable');
};

# ===========================================================================
# Security
# ===========================================================================

# Strategy: logged text reaches TAP output and message templates.  Neither
# may let it forge test results or be treated as a format.
subtest 'logged text cannot forge TAP output' => sub {
	my $logger = $CLASS->new(diag => 'all', verbose => 0);
	my @forgeries = ("x\nok 99 - forged pass", "x\nnot ok 98 - forged failure", "x\n1..1", "x\nBail out! forged", "x\r\nok 97 - forged");
	my $out = printed {
		$logger->error($_) foreach @forgeries;
		my $name = "y\nok 96 - forged";
		$logger->$name('z');
	};
	my (undef, $explained) = failing(sub { $logger->like(qr/never/) });
	foreach my $line (split(/\n/, $out . $explained)) {
		like($line, qr/\A#|\A(?:not )?ok \d+ # TODO|\Anot ok \d+$/, 'every printed line is a comment or our own TODO result: ' . substr($line, 0, 40));
	}
	unlike($out . $explained, qr/^(?:ok 9[6-9]|not ok 98|1\.\.1|Bail out!)/m, 'no forged line starts a line');
};

subtest 'logged text is never used as a format' => sub {
	my $logger = $CLASS->new(diag => 'all', verbose => 0);
	my $format = '%{class}s %{count}d %n %s %d %% %x %999999999s';
	my $out = printed { $logger->error($format) };
	is($logger->messages()->[0]->{'message'}, $format, 'stored literally');
	is($out, "# $format\n", 'printed literally');

	my (undef, $explained) = failing(sub { $logger->like(qr/never/) });
	like($explained, qr/^#     \[error\] \Q$format\E$/m, 'listed literally in a failure explanation');

	# A quiet logger: with diag => 'all' the empty message would print too
	my $method = '%{class}s%n';
	my $quiet = quiet();
	$out = printed { $quiet->$method() };
	is($out, "# $CLASS: no method '$method'\n", 'a method name is not a format either');
};

subtest 'errors do not echo hostile values unbounded' => sub {
	# A rejected option value appears in the error; it must not be able to
	# add lines to the output or make the error enormous
	my $value = "en\nok 1 - forged\r" . ('x' x $HUGE);
	ok(!eval { $CLASS->new(lang => $value); 1 }, 'refused');
	my $error = $@;
	# Length first, and the shape with ok() rather than throws_ok: if the cap
	# ever breaks, throws_ok's failure report would repeat the whole
	# multi-megabyte error, which looks like a hung test (it did, under
	# mutation testing)
	ok(length($error) < $MAX_REASON * 2, 'bounded length (' . length($error) . ' characters)');
	ok($error =~ /\A\Q$CLASS: invalid argument: \E[^\n]*\.\.\. at \Q$FILE\E line \d+\.?\n?\z/, 'one line, cut short')
		or diag('starts: ', substr($error, 0, $MAX_REASON * 2));
	unlike($error, qr/Params\/Validate\/Strict\.pm|Params::Validate::Strict line/, "no internal file names from the validator");
};

subtest 'errors that repeat a name escape it and cut it short' => sub {
	# Level names, diag names and method names are repeated in errors and
	# warnings too.  Each is a separate path to the output, so each is tried
	# with a forged TAP line, a terminal escape sequence, and a huge name.
	my %repeats = (
		'new(level)' => sub { $CLASS->new(level => $_[0]) },
		'new(diag)' => sub { $CLASS->new(diag => $_[0]) },
		'new(diag list)' => sub { $CLASS->new(diag => [$_[0]]) },
		'level()' => sub { my $logger = quiet(); local $SIG{__WARN__} = sub { die @_ }; $logger->level($_[0]) },
		'class method' => sub { my $method = $_[0]; $CLASS->$method() },
	);
	foreach my $how (sort keys %repeats) {
		foreach my $hostile ("x\nok 1 - forged", "x\e[2Jcleared", 'x' x $HUGE) {
			ok(!eval { $repeats{$how}->($hostile); 1 }, "$how: refused");
			my $error = $@;
			# ok() rather than like(): a failure must not print the huge name
			ok(length($error) < $MAX_REASON * 2, "$how: bounded (" . length($error) . ' characters)');
			ok($error !~ /[\x00-\x09\x0B-\x1F\x7F]/ && $error =~ /\A[^\n]*\n?\z/, "$how: one line, no control characters")
				or diag('starts: ', substr($error, 0, $MAX_REASON * 2));
		}
	}
	throws_ok { $CLASS->new(level => "x\ny") } qr/\Q'x\x0Ay'\E/, 'the escape shows what the character was';
};

subtest 'printed messages cannot control the terminal' => sub {
	# A logged message may hold text the test did not write.  It is printed
	# when verbose, and listed under a failing assertion; both must show
	# terminal controls as escapes.  Tab and newline lay the message out,
	# and Test::Builder starts every line with '#', so they are kept
	my $hostile = "a\tb\nc\e]52;c;cHduZWQ=\a\e[2J\rd";
	# The tab and the line break are real; the rest is the escapes' text
	my $escaped = "a\tb\n# c" . q{\x1B]52;c;cHduZWQ=\x07\x1B[2J\x0Dd};
	my $logger = quiet(verbose => 1);
	my $out = printed { $logger->warn($hostile) };
	ok(index($out, "# $escaped") >= 0, 'verbose: controls escaped, tab and newline kept') or state_diag(verbose => $out);
	is($logger->messages()->[0]->{'message'}, $hostile, '... and the stored message is unchanged');

	$logger->verbose(0);
	my $method = "lvl\e[31m";	# AUTOLOAD stores any method name as the level
	printed { $logger->$method('m') };
	(undef, $out) = failing(sub { $logger->unlike(qr/./) });
	ok(index($out, "[warn] $escaped") >= 0, 'a failing assertion: the listed message is escaped') or state_diag(listed => $out);
	ok(index($out, '[lvl\x1B[31m] m') >= 0, '... and so is a level made from a method name') or state_diag(listed => $out);
	ok($out !~ /[\x00-\x08\x0B-\x1F\x7F]/, '... and nothing in the output is a control but tab and newline');

	# The C1 controls are escaped in a character string, and kept in a byte
	# string, where they are usually part of UTF-8 text
	$out = Encode::decode('UTF-8', printed { quiet(verbose => 1)->warn("x\x{9b}2J\x{263a}") });
	ok(index($out, "x\\x9B2J\x{263a}") >= 0, 'a C1 control in a character string: escaped') or state_diag(c1 => $out);
	my $euro = Encode::encode('UTF-8', "\x{20ac}");	# its bytes include 0x82
	$out = printed { quiet(verbose => 1)->warn("x$euro") };
	ok(index($out, "x$euro") >= 0, 'UTF-8 bytes in a byte string: kept');

	# A character string whose bytes are not valid UTF-8 cannot be read as
	# characters; it must still be logged, printed and escaped, never die
	my $malformed = "\e[2J\xff\xfe tail";
	Encode::_utf8_on($malformed);
	my $lived = eval { $out = printed { quiet(verbose => 1)->warn($malformed) }; 1 };
	ok($lived, 'malformed UTF-8: logging does not die') or diag($@);
	ok(index($out, '\x1B[2J') >= 0 && $out =~ /tail$/m, '... and its C0 controls are escaped') or state_diag(malformed => $out);
	# A value repeated in an error goes through _shown(), which also looks
	# for bidi controls and measures the length; it must not die or warn
	# there either (Test::Warnings checks the warnings).  (Called directly,
	# to test _shown() alone; the public paths that repeat a name are
	# tested under 'names and patterns that are not valid UTF-8')
	my $shown;
	$lived = eval { $shown = Test::Log::Abstraction::_shown($malformed); 1 };
	ok($lived, 'malformed UTF-8 repeated in an error: does not die') or diag($@);
	ok(defined($shown) && (index($shown, '\x1B[2J') == 0), '... and its C0 controls are escaped');
};

subtest 'patterns cannot run code' => sub {
	my $logger = quiet();
	$logger->info('x');
	our $ran = 0;
	foreach my $pattern ('(?{ $main::ran = 1 })', '(??{ $main::ran = 1; "x" })', '(?{ system("id") })') {
		throws_ok { $logger->like($pattern) } qr/\A\Q$CLASS: invalid argument: Eval-group not allowed at runtime\E/, "refused: $pattern";
	}
	is($ran, 0, 'no code in a pattern string ran');
};

# The module takes no paths and should never touch the filesystem or a
# shell, or read a clock or set a timer, whatever it is given.  Prove it in a child process with the
# builtins that could do so replaced by spies: they must be installed
# before the module is compiled, which a child process allows.  (The child
# itself opens nothing after installing them: Test::Mockingbird 0.14's
# mock_core('open') cannot create a lexical filehandle.)
subtest 'no filesystem or shell access, whatever the input' => sub {
	require B;
	my $paths = join(', ', map { B::perlstring($_) } @HOSTILE_PATHS);
	my $script = <<"SCRIPT";
use strict;
use warnings;
# Dependencies first, so that only Test::Log::Abstraction itself is
# compiled under the spies (they break open(my \$fh, ...) elsewhere)
use Test::Builder;
use Params::Get;
use Params::Validate::Strict;
use Readonly;
use Encode;
use autodie ();
use Test::Mockingbird;
my \%touched;
BEGIN {
	foreach my \$name (qw(open sysopen opendir unlink mkdir rmdir rename system exec readpipe chdir symlink link chmod truncate time sleep alarm localtime gmtime)) {
		mock_core \$name => sub {
			my (\$call, \@args) = \@_;
			foreach my \$depth (0 .. 5) {
				my \$package = (caller(\$depth))[0];
				last if(!defined(\$package));
				\$touched{\$name}++ if(\$package eq 'Test::Log::Abstraction');
			}
			return \$call->(\@args);
		};
	}
}
use Test::Log::Abstraction;

# Positive control: a call made from the module's package must be caught,
# or an empty result below would prove nothing
eval q{package Test::Log::Abstraction; unlink('/nonexistent/control/file'); 1} or die \$\@;
print STDOUT 'CONTROL: ', join(',', sort keys \%touched), "\\n";
\%touched = ();

my \@paths = ($paths);
foreach my \$lang (qw(en de fr zh)) {
	my \$logger = Test::Log::Abstraction->new(diag => 'all', verbose => 1, lang => \$lang);
	foreach my \$path (\@paths) {
		\$logger->error(\$path, { path => \$path });
		\$logger->\$path(\$path);
		eval { \$logger->like(\$path, \$path) };
		eval { \$logger->count(\$path) };
		eval { \$logger->level(\$path) };
		eval { Test::Log::Abstraction->new(diag => \$path, lang => \$path, country => \$path) };
	}
	\$logger->new()->clear()->flush();
}
print STDOUT 'TOUCHED: ', join(',', sort keys \%touched), "\\n";
SCRIPT
	my $output = run_perl_script($script);
	state_diag(child => $output);
	like($output, qr/^CONTROL: unlink$/m, 'the spies do catch a call from the module (control)');
	like($output, qr/^TOUCHED: $/m, 'no file, directory, shell, clock or timer builtin was called by the module');
};

# ===========================================================================
# Filesystem: hostile paths and contents are only data
# ===========================================================================

# Strategy: run a whole logging session from inside a directory that cannot
# be written to or searched.  A module that needed the filesystem would
# fail; this one must not notice.
subtest 'a working directory that refuses access' => sub {
	my $base = tempdir(CLEANUP => 1);
	my $dir = File::Spec->catdir($base, 'locked');
	mkdir($dir) or die "mkdir: $!";
	my $home = getcwd();
	foreach my $kind ('create', 'search') {
		SKIP: {
			skip(why_not($kind, $base), 3) if(!(($kind eq 'create') ? can_revoke_create($base) : can_revoke_search($base)));
			chdir($dir) or die "chdir: $!";
			my ($logger, $result);
			lives_ok {
				with_revoked($kind => $dir, sub {
					$logger = $CLASS->new(diag => 'all', verbose => 0, lang => 'auto');
					printed { $logger->error('in a locked directory')->wran('x') };
					$result = $logger->like(qr/locked/, "assertion inside a directory without $kind access");
				});
			} "whole session without $kind access";
			chdir($home) or die "chdir back: $!";
			ok($result, 'the assertion worked');
			is($logger->count(), 2, 'both messages stored');
		}
	}
};

subtest 'hostile paths and file contents are stored as data' => sub {
	my $dir = tempdir(CLEANUP => 1);
	my %file = (
		'zero bytes' => '',
		'whitespace only' => " \t\n \n",
		'shell metacharacters in the name' => 'contents',
	);
	# Windows forbids < > : " / \ | ? * in names, so it gets the shell
	# metacharacters it does allow
	my $hostile_name = ($^O eq 'MSWin32') ? "a b;c&d\$e`f'g^h%i!j(k)" : "a b;c|d\$e`f'g\"h&i<j>k*l?m";
	my %name = ('zero bytes' => 'empty', 'whitespace only' => 'blank', 'shell metacharacters in the name' => $hostile_name);
	my $logger = quiet();
	foreach my $kind (sort keys %file) {
		my $path = File::Spec->catfile($dir, $name{$kind});
		open(my $out, '>', $path) or die "write $path: $!";
		print {$out} $file{$kind};
		close($out);
		open(my $in, '<', $path) or die "read $path: $!";
		my $contents = do { local $/; <$in> };
		close($in);

		$logger->clear()->info($path, ': ', $contents);
		(my $want = "$path: $file{$kind}") =~ s/\n\z//;
		is($logger->messages()->[0]->{'message'}, $want, "$kind: path and contents stored exactly");
		ok(-e $path, "$kind: the file is untouched");
	}

	my $link = File::Spec->catfile($dir, 'dangling');
	SKIP: {
		skip('symlinks are not supported here', 2) if(!eval { symlink(File::Spec->catfile($dir, 'nowhere'), $link) });
		$logger->clear()->warn($link, { link => $link });
		is($logger->messages()->[0]->{'message'}, $link, 'a dangling symlink path is only text');
		ok(-l $link && !-e $link, 'the link is still dangling: nothing followed or created it');
	}
	foreach my $special (grep { -e $_ } ('/dev/null', '/dev/zero', '/dev/urandom', $dir)) {
		$logger->clear()->info($special, { path => $special });
		is($logger->messages()->[0]->{'message'}, $special, "special path '$special' is only text");
	}
};

# ===========================================================================
# Upstream failures
# ===========================================================================

# Strategy: the module's only collaborators are Test::Builder, PerlIO,
# Encode and its validators.  Make each return the classic failure values
# (undef, 0, '') or set errno, and check what reaches the caller.
subtest 'Test::Builder::ok() returning failure values' => sub {
	my $logger = quiet();
	$logger->info('match me');
	my %returned;
	foreach my $failure (undef, 0, '') {
		my $label = defined($failure) ? "'$failure'" : 'undef';
		mock 'Test::Builder::ok' => sub { return $failure };
		mock "${CLASS}::_emit" => sub { return $_[0] };
		$returned{$label} = [$logger->like(qr/match/, 'x')];
		restore_all();
	}
	foreach my $label (sort keys %returned) {
		is(scalar(@{$returned{$label}}), 1, "ok() returning $label: like() returns exactly one value");
		ok(!$returned{$label}->[0], "ok() returning $label: like() reports it, not a pass of its own");
	}
};

subtest 'output that fails with ENOSPC or EIO' => sub {
	my $logger = $CLASS->new(diag => 'all', verbose => 0);
	my @results;
	foreach my $errno (ENOSPC, EIO) {
		foreach my $failure (undef, 0, '') {
			mock 'Test::Builder::diag' => sub { $! = $errno; return $failure };
			$! = 0;
			$@ = $SENTINEL;
			my $returned = $logger->error('disk full?');
			my $notice = $logger->nosuch('x');
			my ($assert) = do {
				my $tb = Test::Builder->new();
				$tb->todo_start('expected');
				my $r = $logger->like(qr/never/);
				$tb->todo_end();
				$r;
			};
			push @results, [$errno, $! + 0, $@, $returned, $notice];
			restore_all();
		}
	}
	foreach my $result (@results) {
		my ($errno, $after, $error, $returned, $notice) = @{$result};
		is($after, 0, "output failing with errno $errno: \$! not leaked to the caller");
		is($error, $SENTINEL, '... $@ untouched');
		is($returned, $logger, '... the level method still returns the logger');
		is($notice, $logger, '... so does AUTOLOAD');
	}
	is($logger->count('error'), 6, 'every message stored despite the failing output');
};

subtest 'a real full disk: output to /dev/full' => sub {
	plan(skip_all => '/dev/full is not available') if(!-c '/dev/full');
	open(my $full, '>', '/dev/full') or plan(skip_all => "cannot open /dev/full: $!");
	$full->autoflush(1);
	my $tb = Test::Builder->new();
	my $original = $tb->failure_output();
	my $logger = $CLASS->new(diag => 'all', verbose => 0);
	$! = 0;
	my $ok = eval {
		$tb->failure_output($full);
		$logger->error('written to a full disk');
		$logger->nosuch('x');
		1;
	};
	my $errno = $! + 0;
	$tb->failure_output($original);
	close($full);
	ok($ok, 'logging to a full disk does not die') or diag($@);
	is($errno, 0, '$! not leaked');
	is($logger->count(), 2, 'both messages stored');
};

subtest 'PerlIO and Encode returning failure values' => sub {
	my $logger = Test::Log::Abstraction->new(diag => 'all', verbose => 0);
	my @printed;
	foreach my $layers ([undef], [0], [''], [], [undef, 'utf8']) {
		mock 'PerlIO::get_layers' => sub { return @{$layers} };
		mock 'Test::Builder::diag' => sub { push @printed, $_[1]; return 1 };
		$logger->warn("snow \x{2603}");
		restore_all();
	}
	is(scalar(@printed), 5, 'printed every time, with no warnings about odd layers');
	is($printed[0], "snow \xe2\x98\x83", 'no layer: encoded');
	is($printed[4], "snow \x{2603}", 'an encoding layer among undefined ones: not encoded');

	foreach my $failure (undef, 0, '') {
		my $label = defined($failure) ? "'$failure'" : 'undef';
		my @got;
		mock 'Encode::encode' => sub { return $failure };
		mock 'Test::Builder::diag' => sub { push @got, $_[1]; return 1 };
		lives_ok { $logger->warn("wide \x{2603}") } "Encode returning $label: no die";
		restore_all();
		is_deeply(\@got, [$failure], "Encode returning $label: what it returned is passed on, not invented");
	}
	mock_exception 'Encode::encode' => 'encoder exploded';
	throws_ok { $logger->warn("wide \x{2603}") } qr/encoder exploded/, 'an encoder that dies: reported, not hidden';
	restore_all();
	is($logger->count('warn'), 9, 'every message was stored before printing was tried');
};

subtest 'validators returning failure values' => sub {
	foreach my $failure (undef, 0, '') {
		my $label = defined($failure) ? "'$failure'" : 'undef';
		mock_return "Params::Validate::Strict::validate_strict" => $failure;
		my $logger = eval { $CLASS->new(diag => 'none', lang => 'fr') };
		restore_all();
		isa_ok($logger, $CLASS, "validate_strict returning $label: still a logger");
		is($logger->lang(), 'en', '... with the validated options treated as empty, not trusted');
	}
	foreach my $failure (undef, 0, '') {
		my $label = defined($failure) ? "'$failure'" : 'undef';
		mock_return "Params::Get::get_params" => $failure;
		my $logger = eval { $CLASS->new(diag => 'none') };
		restore_all();
		isa_ok($logger, $CLASS, "get_params returning $label: still a logger, with defaults");
	}
	mock_exception "Params::Validate::Strict::validate_strict" => 'validator crashed';
	throws_ok { $CLASS->new() } qr/\A\Q$CLASS: invalid argument: validator crashed\E/, 'a validator that dies becomes our documented error';
	restore_all();
};

# ===========================================================================
# Context, aliasing and global state
# ===========================================================================

# Strategy: every public method, in list context, must return exactly the
# one documented value - never an empty list for "undef", never extras
subtest 'list context returns exactly one value' => sub {
	my $logger = quiet();
	$logger->info('x');
	my %calls = (
		new => sub { $CLASS->new(diag => 'none') },
		info => sub { $logger->info('y') },
		is_debug => sub { $logger->is_debug() },
		messages => sub { $logger->messages() },
		count => sub { $logger->count() },
		count_level => sub { $logger->count('none') },
		like => sub { $logger->like(qr/x/, 'list context like') },
		has_level => sub { $logger->has_level('info', 'list context has_level') },
		verbose => sub { $logger->verbose() },
		level_get => sub { $logger->level() },
		level_set => sub { $logger->level('debug') },
		flush => sub { $logger->flush() },
		reopen => sub { $logger->reopen() },
		lang => sub { $logger->lang() },
		autoload => sub { my $returned; printed { $returned = $logger->nosuch() }; $returned },
	);
	foreach my $name (sort keys %calls) {
		my @list = $calls{$name}->();
		is(scalar(@list), 1, "$name: one value in list context");
	}
	my @undef;
	warning_like { @undef = $logger->level('bogus') } qr/invalid syslog level 'bogus'/, 'level(bogus) in list context warns';
	is(scalar(@undef), 1, '... and returns one value, undef, not an empty list');
	ok(!defined($undef[0]), '... which is undef');
	my ($first, $second) = $logger->messages();
	ok(ref($first) eq 'ARRAY' && !defined($second), 'messages() is one array reference, not a list of entries');
};

subtest '$_ aliasing a read-only value, and aliased arguments' => sub {
	my $logger = quiet();
	lives_ok {
		for (1) {	# $_ is now a read-only constant
			$logger->info('a', $_)->warn($_);
			$logger->count();
			$logger->like(qr/a/, 'like with a read-only $_');
			$logger->unlike(qr/zzz/, 'unlike with a read-only $_');
			$logger->has_level('info', 'has_level with a read-only $_');
			$logger->messages();
			$logger->level('info');
			$logger->new()->clear();
		}
	} 'no method writes to $_';

	my @values = ('one', 'two');
	$logger->info($_) foreach @values;
	is_deeply(\@values, ['one', 'two'], 'aliased arguments are not changed');
	my @fields = ({ k => 'v' });
	$logger->info('m', $fields[0]);
	is_deeply(\@fields, [{ k => 'v' }], 'the fields hash given is not changed');
};

subtest 're-entrant logging from signal handlers' => sub {
	my $logger = quiet();
	{
		# A __DIE__ handler that logs: it fires inside the module, while a
		# message is being built, and must not corrupt it
		local $SIG{'__DIE__'} = sub { $logger->error('handler: ', $_[0]) };
		$logger->info('outer ', bless({}, 'Local::Bomb'));
	}
	is($logger->count(), 2, 'both the inner and the outer message stored');
	like($logger->messages()->[1]->{'message'}, qr/\Aouter Local::Bomb=HASH/, 'the outer message is intact');
	{
		# A __WARN__ handler that logs the module's own warning
		local $SIG{'__WARN__'} = sub { $logger->warn(@_) };
		$logger->level('bogus');
	}
	$logger->like(qr/invalid syslog level 'bogus'/, "the module's own warning was logged through it");
};

subtest 'a broken %config' => sub {
	my %cases = (
		lang => ["\0", '../../etc', [], 'x' x $MANY],
		diag => ['', 'BOGUS', {}],
		level => ['', 'BOGUS', []],
	);
	foreach my $key (sort keys %cases) {
		foreach my $value (@{$cases{$key}}) {
			local $Test::Log::Abstraction::config{$key} = $value;
			my $logger = eval { $CLASS->new() };
			my $error = $@;
			ok($logger || ($error =~ /\A\Q$CLASS: \E/), "\$config{$key} = " . printable(ref($value) || $value) . ': a logger or our own error, never a crash');
			is($logger->lang(), 'en', '... and an unusable language falls back to English') if($logger && ($key eq 'lang'));
		}
	}
};

subtest "the caller's punctuation variables" => sub {
	# Strategy: code under test may have changed $/, $, $\ $" or $; when it
	# logs.  The stored message must not depend on any of them, and each
	# must be as the caller left it afterwards.  Results are collected
	# first and checked outside the block, so that Test::Builder's own
	# printing is not run with them changed
	my $logger = quiet();
	my %got;
	{
		local $/ = 'c';
		local $, = '<ofs>';
		local $\ = '<ors>';
		local $" = '<sep>';
		local $; = '<subsep>';
		$logger->info('abc', [1, 2], "\n");
		$got{'joined'} = first_message($logger);
		$logger->clear()->info('ends in c');
		$got{'record separator'} = first_message($logger);
		$got{'after'} = join('|', $/, $,, $\, $", $;);
	}
	is($got{'joined'}, 'abc[1, 2]', 'parts joined with nothing, lists with ", ", whatever $, and $" say');
	is($got{'record separator'}, 'ends in c', '$/ = "c": only a trailing newline is removed, never a "c"');
	is($got{'after'}, 'c|<ofs>|<ors>|<sep>|<subsep>', 'all five variables as the caller set them');

	foreach my $separator (undef, \2, '') {
		my ($message, $after);
		{
			local $/ = $separator;
			$logger->clear()->info("x\n");
			($message, $after) = (first_message($logger), $/);
		}
		my $label = defined($separator) ? (ref($separator) ? 'a record length' : 'paragraph mode') : 'slurp mode';
		is($message, 'x', "\$/ in $label: the newline is still removed");
		is($after, $separator, "\$/ in $label: left as it was");
	}
};

# ===========================================================================
# Unreadable and lying references
# ===========================================================================

# Strategy: a value can die merely by being read.  A tied scalar or array
# whose FETCH dies is the plainest case; an argument list is read when it
# is copied, so this attacks the very first line of every log call.  The
# message must still be stored, with the unreadable part shown in a form
# that says what it was, and the caller's $@ and $! must survive
subtest 'arguments that die when read' => sub {
	my $logger = quiet();
	tie my $scalar, 'Local::DyingScalar';
	tie my @size, 'Local::DyingArray';
	tie my @elements, 'Local::DyingElements';
	my %calls = (
		'alone' => sub { $logger->info($scalar) },
		'between parts' => sub { $logger->info('a', $scalar, 'b') },
		'before fields' => sub { $logger->info('m', $scalar, { k => 'v' }) },
		'array whose size dies' => sub { $logger->info(\@size) },
		'array whose elements die' => sub { $logger->info(\@elements) },
		'inside a hash' => sub { $logger->info({ list => \@elements }) },
		'level method with a dying name' => sub { $logger->debug($scalar, $scalar) },
	);
	my %result;
	foreach my $name (sort keys %calls) {
		$logger->clear();
		$@ = $SENTINEL;
		$! = EIO;
		my $lived = eval { $calls{$name}->(); 1 };
		$result{$name} = { lived => $lived, error => $@, errno => $! + 0, entry => $logger->messages()->[0] };
	}
	# eval {} itself clears $@ on success, so whether the call kept it is
	# measured with $! only; the 'keeps $@' cases elsewhere check $@
	foreach my $name (sort keys %result) {
		ok($result{$name}->{'lived'}, "$name: the log call lives") or diag($result{$name}->{'error'});
		is($result{$name}->{'errno'}, EIO, "$name: \$! as the caller left it");
		state_diag($name => $result{$name}->{'entry'});
	}
	my $tie = qr/Local::DyingScalar=HASH\(0x[0-9a-f]+\)/;
	like($result{'alone'}->{'entry'}->{'message'}, qr/\A$tie\z/, 'a dying scalar is shown as its tie object');
	like($result{'between parts'}->{'entry'}->{'message'}, qr/\Aa${tie}b\z/, '... in its place among the readable parts');
	like($result{'before fields'}->{'entry'}->{'message'}, qr/\Am$tie\z/, '... and before fields');
	is_deeply($result{'before fields'}->{'entry'}->{'fields'}, { k => 'v' }, '... which are still stored as fields');
	like($result{'level method with a dying name'}->{'entry'}->{'message'}, qr/\A$tie$tie\z/, 'two dying scalars: both shown');
	foreach my $name ('array whose size dies', 'array whose elements die') {
		like($result{$name}->{'entry'}->{'message'}, qr/\AARRAY\(0x[0-9a-f]+\)\z/, "$name: the whole array is shown in Perl's plain form");
	}
	like($result{'inside a hash'}->{'entry'}->{'message'}, qr/\AHASH\(0x[0-9a-f]+\)\z/, 'one inside a hash: the whole part is shown in plain form');
};

# Strategy: ref() reports an object's class, and a class may be called
# ARRAY or HASH.  bless({}, 'ARRAY') passes every "ref() eq 'ARRAY'" test
# and then dies with "Not an ARRAY reference" when used as one.  Put such
# liars everywhere the module walks a hash or an array
subtest 'references that are not what ref() says' => sub {
	my $logger = quiet();
	my $fake_array = bless({ k => 'v' }, 'ARRAY');
	my $fake_hash = bless(['x'], 'HASH');
	my $address = qr/\(0x[0-9a-f]+\)/;

	lives_ok { $logger->info($fake_array) } 'a hash blessed into ARRAY, alone: logged';
	like(first_message($logger), qr/\AARRAY=HASH$address\z/, '... as Perl writes it, not as a list of parts');
	lives_ok { $logger->clear()->info('m', $fake_hash) } 'an array blessed into HASH, where fields go: logged';
	like(first_message($logger), qr/\AmHASH=ARRAY$address\z/, '... as a message part');
	ok(!exists($logger->messages()->[0]->{'fields'}), '... not as fields');
	$logger->clear()->info({ inner => $fake_array, list => [$fake_hash] });
	like(first_message($logger), qr/\A\{inner => ARRAY=HASH$address, list => \[HASH=ARRAY$address\]\}\z/,
		'nested liars are shown in plain form, and the structure around them is still rendered');

	throws_ok { $CLASS->new(diag => $fake_array) } at_caller('diag must be a level name, "all", "none" or an array reference of level names'),
		'a hash blessed into ARRAY as diag: the usual diag error';
	my $real = $CLASS->new(diag => bless(['error'], 'ARRAY'), verbose => 0);
	is(printed { $real->error('shown')->warn('hidden') }, "# shown\n", 'an array that is blessed into ARRAY is still a diag list');

	my $default = "$CLASS: m() needs a level name";
	my %tables = (
		'the i18n option' => $fake_hash,
		'a language table' => { xx => $fake_hash, en => $fake_hash },
	);
	foreach my $where (sort keys %tables) {
		my $translated;
		lives_ok { $translated = quiet(lang => 'xx', i18n => $tables{$where}) } "an array blessed into HASH as $where: new() lives";
		is($translated->lang(), ($where eq 'the i18n option') ? 'en' : 'xx', '... the language is chosen as for any table');
		is($translated->i18n('needs_level', { method => 'm' }), $default, '... and the liar is ignored');
	}
	my $template = quiet(i18n => { en => { needs_level => $fake_hash } });
	like($template->i18n('needs_level'), qr/\AHASH=ARRAY$address\z/, 'one as a template: shown as text, as any other non-string template');
};

# Strategy: names and patterns come from the caller, and may be character
# strings that are not valid UTF-8.  lc() dies on those, a regex panics,
# and Carp dies formatting them as arguments.  Every public path that
# takes a name must answer with this module's own error or warning
subtest 'names and patterns that are not valid UTF-8' => sub {
	my $bad = malformed("\xff\xfe abc");
	my $repaired = qr/\x{FFFD}+ abc/;
	my $logger = quiet();
	my $returned = 'not called';

	warning_like { $returned = $logger->level($bad) } qr/\A\Q$CLASS: invalid syslog level '\E$repaired' at \Q$FILE\E line \d+\.?\n?\z/,
		'level(): our warning, at the caller';
	is($returned, undef, '... and undef');
	is($logger->level(), $LOWEST_LEVEL, '... and the level unchanged');
	is($logger->count($bad), 0, 'count(): no messages at that level');
	my ($result) = failing(sub { $logger->has_level($bad, 'has_level with a malformed name') });
	ok(!$result, 'has_level(): fails, as for any level with no messages');

	throws_ok { $CLASS->new(level => $bad) } qr/\A\Q$CLASS: invalid syslog level '\E$repaired' at \Q$FILE\E/, 'new(level): our error';
	throws_ok { $CLASS->new(diag => $bad) } qr/\A\Q$CLASS: invalid diag level '\E$repaired' at \Q$FILE\E/, 'new(diag): our error';
	throws_ok { $CLASS->new(diag => ['error', $bad]) } qr/\A\Q$CLASS: invalid diag level '\E$repaired' at \Q$FILE\E/, 'new(diag list): our error';
	foreach my $method ('like', 'unlike') {
		throws_ok { $logger->$method($bad) } qr/\A\Q$CLASS: invalid argument: Malformed UTF-8 character\E[^\n]* at \Q$FILE\E/,
			"$method(): a malformed pattern is an invalid argument";
	}

	my $out = printed { $logger->$bad('x') };
	is($logger->count($bad), 1, 'a malformed method name: the message is stored, and found by the same name');
	ok($logger->has_level($bad, 'has_level finds it too'), '... by has_level() as well');
	is(scalar($out =~ tr/\n//), 1, '... with a one-line notice');
	state_diag(notice => $out);
};

subtest 'surrogates in names and patterns' => sub {
	# A UTF-16 surrogate is valid in a Perl string, but lc() warns on it;
	# Test::Warnings fails this file on any warning
	my $logger = quiet();
	my $name = "lvl\x{D800}";
	printed { $logger->$name('x') };
	is($logger->count($name), 1, 'stored under a surrogate method name, with no warning');
	ok($logger->has_level("LVL\x{D800}", 'has_level with a surrogate, any case'), 'found by has_level()');
	warning_like { $logger->level($name) } qr/\A\Q$CLASS: invalid syslog level 'lvl\E/, 'level(): only our warning';
	throws_ok { $CLASS->new(level => $name) } qr/\A\Q$CLASS: invalid syslog level 'lvl\E/, 'new(level): our error';
	$logger->clear()->info("x\x{D800}y");
	ok($logger->like("\x{D800}", 'a surrogate as a pattern'), 'a valid pattern with a surrogate still compiles and matches');
};

# Strategy: templates and their arguments come from the test writer
# through the i18n option, and i18n() promises always to return a string.
# Attack it with objects that die when made text, sprintf conversions
# that write memory (%n) or read extra arguments (*, vectors), and
# character codes that are not characters
subtest 'hostile i18n templates and arguments' => sub {
	my $bomb = bless({}, 'Local::Bomb');
	my $plain = qr/\ALocal::Bomb=HASH\(0x[0-9a-f]+\)\z/;
	my $spec = '%{v}n|%{v}*d|%{v}vd|%{v}9999s|%{v}.9999f|%{v}|%{}s|%{v v}s';
	my $logger = quiet(i18n => { en => {
		bomb => $bomb,
		forms => { male => 'male form', other => 'other form', one => { other => $bomb } },
		spec => $spec,
	} });

	like($logger->i18n('bomb'), $plain, 'a template whose "" dies: shown in plain form');
	is($logger->i18n('forms', { gender => $bomb }), 'other form', 'a gender whose "" dies: matches no form, so the plural form is used');
	like($logger->i18n('forms', { count => 1 }), $plain, 'a nested form whose "" dies: plain form');
	is($logger->i18n('spec', { v => 5 }), $spec, '%n, *, vectors, over-long widths and bad names are left as text');

	my $chars = quiet(i18n => { en => { c => '%{v}c' } });
	foreach my $value (-1, 0xD800, 0x110000, 2**31, $BIG_NUMBER, 'NaN', 9**9**9, -9**9**9) {
		my $text;
		lives_ok { $text = $chars->i18n('c', { v => $value }) } "%c of $value: no death (and Test::Warnings: no warning)";
		ok(defined($text), '... and a string');
	}

	my $broken = $CLASS->new(diag => 'none', verbose => 0, i18n => { en => { captured => $bomb, entry => $bomb } });
	$broken->info('x');
	my ($result, $out) = failing(sub { $broken->empty() });
	ok(!$result, 'a failing assertion whose explanation templates die: still fails');
	like($out, qr/Local::Bomb=HASH/, '... and explains itself in plain form');
};

# Strategy: the readable rendering of a structure is recursive.  Built by
# returning strings, each level copied all the text below it: quadratic,
# 11 seconds for a hash 80,000 deep.  Logging must stay linear
subtest 'deep nesting is rendered in linear time' => sub {
	my $logger = quiet();
	my (%hash, @array);
	my ($hash_tip, $array_tip) = (\%hash, \@array);
	foreach (1 .. $DEEP) {
		$hash_tip = $hash_tip->{'k'} = {};
		push @{$array_tip}, [];
		$array_tip = $array_tip->[0];
	}

	within_budget("a hash nested $DEEP deep", sub { $logger->info(\%hash) });
	# ok() with eq: a failing is() would print a megabyte
	ok(first_message($logger) eq ('{k => ' x $DEEP) . '{}' . ('}' x $DEEP), 'rendered exactly');
	within_budget("an array nested $DEEP deep", sub { $logger->clear()->info('a', \@array) });
	ok(first_message($logger) eq 'a' . ('[' x ($DEEP + 1)) . (']' x ($DEEP + 1)), 'rendered exactly');
	within_budget("an i18n option nested $DEEP deep", sub { quiet(i18n => { en => \%hash }) });
	within_budget("a template nested $DEEP deep", sub { quiet(i18n => { en => { k => \%hash } })->i18n('k') });
};

subtest 'loggers are freed: no reference cycles' => sub {
	# Strategy: a logger that is never freed holds every message for the
	# rest of the run.  Weaken a reference to each, drop the strong one,
	# and the weak one must be gone
	my %cases = (
		'plain' => sub { quiet()->info('x') },
		'cyclic i18n option' => sub {
			my %loop = (other => 'x');
			$loop{'self'} = \%loop;
			my $logger = quiet(i18n => { en => { k => \%loop } });
			delete $loop{'self'};	# the caller's own cycle is the caller's
			return $logger;
		},
		'after a failing assertion' => sub {
			my $logger = quiet()->info('x');
			failing(sub { $logger->empty() });
			return $logger;
		},
		'a clone' => sub { quiet()->info('x')->new(lang => 'de') },
		'fields holding the logger, then clear()' => sub {
			my $logger = quiet();
			$logger->info('m', { logger => $logger });
			return $logger->clear();
		},
		'after an error' => sub {
			my $logger = quiet();
			eval { $logger->like('(') };
			return $logger;
		},
	);
	foreach my $name (sort keys %cases) {
		my $logger = $cases{$name}->();
		Scalar::Util::weaken(my $weak = $logger);
		undef $logger;
		ok(!defined($weak), "$name: freed");
	}
};

subtest 'forged invocants' => sub {
	# Strategy: a hash shaped like a logger, another class's object, and
	# false values, as the invocant of every kind of method.  None may be
	# treated as a logger, and each must get the documented error
	my @fakes = ({ messages => [], options => {}, lang => 'en' }, Local::Other->new(), undef, 0, '');
	my %calls = (
		info => sub { Test::Log::Abstraction::info($_[0], 'x') },
		count => sub { Test::Log::Abstraction::count($_[0]) },
		like => sub { Test::Log::Abstraction::like($_[0], qr/x/) },
		messages => sub { Test::Log::Abstraction::messages($_[0]) },
		level => sub { Test::Log::Abstraction::level($_[0], 'error') },
	);
	foreach my $method (sort keys %calls) {
		foreach my $fake (@fakes) {
			throws_ok { $calls{$method}->($fake) } at_caller("$method() must be called on an object, not on the class"),
				"$method() on " . (ref($fake) || printable(defined($fake) ? $fake : 'undef'));
		}
	}
	is_deeply($fakes[0], { messages => [], options => {}, lang => 'en' }, 'the forged hash was not written to');
};

# ===========================================================================
# Time: the module reads no clock and touches no timer
# ===========================================================================

# Strategy: nothing in this module expires, so there is no timeout to
# trigger and no cache to go stale; what can go wrong is that it reads or
# resets a timer that belongs to the test.  The child-process spies above
# show it calls no clock builtin; here a live alarm() must survive a whole
# session, untouched
subtest "the caller's alarm() timer is left alone" => sub {
	plan(skip_all => 'alarm(0) cannot report the time left on Windows') if($^O eq 'MSWin32');
	my $fired = 0;
	local $SIG{'ALRM'} = sub { $fired++ };
	alarm($ALARM);
	my $logger = $CLASS->new(diag => 'all', verbose => 0, lang => 'fr');
	printed { $logger->error('x')->nosuch('y') };
	$logger->like(qr/x/, 'an assertion while a timer runs');
	failing(sub { $logger->empty() });
	$logger->i18n('captured', { count => 2 });
	eval { $logger->like('(') };
	my $left = alarm(0);
	ok(($left > 0) && ($left <= $ALARM), "the timer still runs ($left of $ALARM seconds left)");
	is($fired, 0, '... and has not fired');
};

# ===========================================================================
# Return values under hostile input
# ===========================================================================

subtest 'return values keep their documented shape' => sub {
	# Strategy: after every attack above, what comes back must still match
	# the API SPECIFICATION's return schemas
	my $bomb = bless({}, 'Local::Bomb');
	my $logger = quiet(i18n => { en => { k => $bomb } });
	tie my $scalar, 'Local::DyingScalar';
	my $bad = malformed("\xff\xfe");

	returns_ok($logger->info($scalar), { type => 'object', isa => $CLASS }, 'info() of a dying argument: the logger');
	returns_ok($logger->count($bad), { type => 'integer', min => 0 }, 'count() of a malformed name: a count');
	returns_ok($logger->count(), { type => 'integer', min => 1 }, 'count(): the message was stored');
	returns_ok($logger->i18n('k'), { type => 'string' }, 'i18n() of a dying template: a string');
	returns_ok($logger->i18n($bomb), { type => 'string' }, 'i18n() of a dying key: a string');
	returns_ok($logger->i18n('captured', { count => $bomb }), { type => 'string' }, 'i18n() of a dying count: a string');
	returns_ok($logger->messages(), { type => 'arrayref' }, 'messages(): an array reference');
	returns_ok($logger->lang(), { type => 'string', matches => qr/\A[a-z]{2,3}\z/ }, 'lang(): a language tag');
	{
		local $SIG{'__WARN__'} = sub { };	# level($bad) warns; that is tested above
		$logger->level($bad);
	}
	returns_ok($logger->level(), { type => 'integer', min => 0, max => $LOWEST_LEVEL }, 'level(): a syslog number, unchanged by a bad name');
	returns_ok(quiet(lang => 'xx', i18n => bless([], 'HASH'))->lang(), { type => 'string', matches => qr/\Aen\z/ }, 'a lying i18n option: English');
};

# ===========================================================================
# Resource exhaustion: no file descriptors left
# ===========================================================================

# How many descriptors this process has open, where the system can say
sub open_descriptors {
	my $dir = '/proc/self/fd';
	return if(!-d $dir);
	opendir(my $dh, $dir) or return;
	my $count = grep { /\A\d+\z/ } readdir($dh);
	closedir($dh);
	return $count - 1;	# not the handle used to count them
}

# Strategy: lower the descriptor limit, then open handles until the system
# says EMFILE.  With nothing left, the whole API must still work - logging,
# printing (including the encoding path), passing and failing assertions,
# translated messages and errors - because none of it may need a new file
# or a module loaded on demand.  Afterwards the limit and every handle are
# given back, and the module must not have kept any of its own.
subtest 'no file descriptors left (EMFILE)' => sub {
	plan(skip_all => 'BSD::Resource is needed to lower the descriptor limit') if(!eval { require BSD::Resource; 1 });
	my $limit = BSD::Resource::RLIMIT_NOFILE();
	my ($soft, $hard) = BSD::Resource::getrlimit($limit);
	my $before = open_descriptors();
	# Warm up the paths under test once, so that what is checked is the
	# module itself, not Perl loading something for the first time
	printed { quiet(diag => 'all', lang => 'fr')->error("caf\x{e9}") };

	my (@handles, $errno);
	{
		my $in_use = defined($before) ? $before : $FD_SPARE;
		BSD::Resource::setrlimit($limit, $in_use + $FD_SPARE, $hard) or plan(skip_all => "cannot lower the descriptor limit: $!");
		while(open(my $fh, '<', File::Spec->devnull())) {
			push @handles, $fh;
		}
		$errno = $! + 0;
	}
	state_diag(opened => scalar(@handles));
	is($errno, EMFILE, 'the process really is out of descriptors') or diag("stopped with errno $errno");

	# Everything that follows runs with no descriptor free
	my $logger;
	lives_ok { $logger = $CLASS->new(diag => 'all', verbose => 0, lang => 'fr') } 'new() works';
	$! = EMFILE;
	my $out = printed { $logger->error("caf\x{e9} \x{263A}", { k => 'v' }) };
	is($! + 0, EMFILE, 'logging leaves $! as it was');
	like($out, qr/caf/, 'the message was printed, through the encoding path');
	is($logger->count(), 1, 'and stored');
	ok($logger->like(qr/caf/, 'a passing assertion with no descriptors'), 'like() passes');
	my ($result, $explained) = failing(sub { $logger->unlike(qr/caf/) });
	ok(!$result, 'a failing assertion still fails ...');
	like($explained, qr/1 message correspond/, '... and explains itself in French');
	throws_ok { $logger->has_level() } qr/\A\Q$CLASS : has_level() n\E\x{e9}\Qcessite un nom de niveau\E/, 'a translated error is still raised';

	# Give everything back, then check nothing was kept
	@handles = ();
	BSD::Resource::setrlimit($limit, $soft, $hard);
	undef $logger;
	SKIP: {
		skip('this system cannot count open descriptors', 1) if(!defined($before));
		is(open_descriptors(), $before, 'every descriptor was released: the module kept none');
	}
};

# ===========================================================================
# Regressions
# ===========================================================================

# Strategy: one check for each bug fixed in 0.002.1, through the public
# API, so that none of them can come back unnoticed
subtest 'regressions fixed in 0.002.1' => sub {
	my $logger = quiet(i18n => { en => { n => '%{v}d|%{v}x' } });
	my $bomb = bless({}, 'Local::Bomb');
	my $plain = qr/Local::Bomb=HASH\(0x[0-9a-f]+\)/;

	# GitHub#1: a number too big for %d was printed as -1, and the test of
	# it only passed on perls without long doubles
	is($logger->i18n('n', { v => $BIG_NUMBER }), "$BIG_NUMBER|$BIG_NUMBER", 'GitHub#1: a huge number is shown as written, not as -1');
	is($logger->i18n('n', { v => '9' x 400 }), ('9' x 400) . '|' . ('9' x 400), 'GitHub#1: so is a 400-digit one');

	# The "no method" notice repeated the method name raw
	my $name = "a\nok 1\e[2J";
	is(scalar(printed { $logger->$name() } =~ tr/\n//), 1, 'a method name with a newline gives a one-line notice');

	# new() reported an invalid level in lower case, unlike every other error
	throws_ok { $CLASS->new(level => 'LOUD') } at_caller(q{invalid syslog level 'LOUD'}), 'new() repeats the level as given';

	# An object whose text form dies crashed these with its own error
	throws_ok { $CLASS->new(diag => [$bomb]) } qr/\A\Q$CLASS: invalid diag level '\E$plain'/, 'as a diag level: this module\'s error';
	warning_like { is($logger->level($bomb), undef, 'level() returns undef') } qr/\A\Q$CLASS: invalid syslog level '\E$plain'/, 'as a level: a warning';
	like($logger->i18n($bomb), qr/\A$plain\z/, 'as an i18n key: the plain form');
	like($logger->i18n('n', { v => $bomb }), qr/\A$plain\|$plain\z/, 'in a number placeholder: the plain form');

	# Trailing fields were copied outside any eval, so a tied hash that dies
	# when read killed the log call
	tie my %unreadable, 'Local::UnreadableHash';
	lives_ok { $logger->clear()->info('m', \%unreadable) } 'tied fields that die when read: the log call lives';
	like($logger->messages()->[0]->{'message'}, qr/\AmHASH\(0x[0-9a-f]+\)\z/, '... and the hash is shown in plain form');

	# Log::Abstraction 0.41 added reopen(); without it, the call was stored
	my $out = printed { $logger->clear()->reopen() };
	is($logger->count(), 0, 'reopen() is not stored as a message');
	is($out, '', '... and prints no "no method" notice');
};

# Strategy: the exact call that showed each bug fixed in 0.002.2, found by
# this file; the subtests above try the variations
subtest 'regressions fixed in 0.002.2' => sub {
	my $logger = quiet();

	# A tied scalar whose FETCH dies killed the log call
	tie my $scalar, 'Local::DyingScalar';
	lives_ok { $logger->info($scalar) } 'a tied argument that dies when read';

	# bless({}, 'ARRAY') died with "Not an ARRAY reference" at three places
	lives_ok { $logger->info(bless({}, 'ARRAY')) } 'bless({}, "ARRAY") as a message';
	throws_ok { $CLASS->new(diag => bless({}, 'ARRAY')) } qr/\A\Q$CLASS: diag must be\E/, '... as diag';
	lives_ok { $CLASS->new(lang => 'xx', i18n => bless([], 'HASH')) } 'bless([], "HASH") as i18n';

	# lc() died with "Malformed UTF-8 character (fatal)", then Carp did
	my $bad = malformed("\xff\xfe abc");
	warning_like { $logger->level($bad) } qr/\A\Q$CLASS: invalid syslog level\E/, 'level() of a malformed name';
	# The match on $AUTOLOAD panicked: "pp_match start/end pointers"
	lives_ok { printed { $logger->$bad() } } 'a malformed method name';

	# i18n() died with the object's own error
	lives_ok { quiet(i18n => { en => { k => bless({}, 'Local::Bomb') } })->i18n('k') } 'a template whose "" dies';

	# Quadratic rendering: 11 seconds at 80,000 deep
	my $deep = {};
	my $tip = $deep;
	$tip = $tip->{'k'} = {} foreach 1 .. $DEEP;
	within_budget('a deeply nested hash', sub { $logger->info($deep) });
};

# Each of these was a real bug, found in the wild or by this suite
subtest 'regressions' => sub {
	my $logger = quiet();

	# Old t/lib/MyLogger.pm: sub error { error(@_) } recursed forever
	within_budget('error(undef)', sub { $logger->error(undef) });
	is($logger->count('error'), 1, 'error(undef) recorded once');

	# A template that contains itself looped forever; a failing assertion
	# uses the 'captured' template, so override that one
	my %loop;
	$loop{'other'} = \%loop;
	my $cyclic = quiet(i18n => { en => { captured => \%loop } });
	within_budget('cyclic i18n template', sub { failing(sub { $cyclic->empty() }) if($cyclic->info('x')) });
	delete $loop{'other'};

	# $logger->$name() with an empty name gave level undef and a warning
	my $empty = '';
	my $out = printed { $logger->$empty('x') };
	is($logger->count(''), 1, 'an empty method name is stored under the empty name');
	is($out, "# $CLASS: no method ''\n", 'and announced without a warning');

	# like(), count() and new() cleared the caller's $@
	$@ = $SENTINEL;
	$logger->like(qr/./, 'like keeps $@');
	$logger->count('error');
	$CLASS->new(diag => 'none');
	is($@, $SENTINEL, '$@ survives like(), count() and new()');

	# Failing output leaked ENOSPC into $!
	mock 'Test::Builder::diag' => sub { $! = ENOSPC; return 0 };
	$! = 0;
	$CLASS->new(diag => 'all')->error('x');
	my $errno = $! + 0;
	restore_all();
	is($errno, 0, 'failing output does not set $!');

	# An undefined layer from PerlIO made _emit warn
	mock 'PerlIO::get_layers' => sub { return (undef) };
	printed { $CLASS->new(diag => 'all')->error('x') };
	restore_all();
	pass('an undefined layer is ignored without a warning (Test::Warnings checks)');
};

done_testing();

# A tied hash that dies as soon as it is read
package Local::UnreadableHash;

sub TIEHASH { return bless {}, shift }
sub FIRSTKEY { die "unreadable\n" }
sub SCALAR { die "unreadable\n" }

# A tied scalar that dies as soon as it is read
package Local::DyingScalar;

sub TIESCALAR { return bless {}, shift }
sub FETCH { die "unreadable\n" }

# A tied array that dies when asked its size
package Local::DyingArray;

sub TIEARRAY { return bless {}, shift }
sub FETCHSIZE { die "unreadable\n" }

# A tied array with two elements, each of which dies when read
package Local::DyingElements;

sub TIEARRAY { return bless {}, shift }
sub FETCHSIZE { return 2 }
sub FETCH { die "unreadable\n" }
