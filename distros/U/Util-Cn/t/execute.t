#!/usr/bin/env perl
# execute(): run a shell command, returning exit code, stdout, stderr, or all.
#
# execute() takes a shell command line, so this test has to build one, which
# the rest of the suite never does.  Each command runs this perl ($^X) with a
# double-quoted -e program, which both sh and cmd.exe read the same way: no
# single quotes (cmd.exe does not treat them as quotes), no "$" inside the
# program (sh would interpolate it), and a backslash only before a letter,
# which sh leaves alone inside double quotes.
require 5.010001;
use strict;
use warnings FATAL => 'all';
use Test::More;
use Test::Exception;
use Capture::Tiny 'capture';
use Util::Cn;

sub perl_cmd {
	my ($program) = @_;
	return qq{"$^X" -e "$program"};
}

is( execute(perl_cmd('exit 0')), 0, 'exit code of a passing command' );
is( execute(perl_cmd('print qq{hello}'), 'stdout'), 'hello', 'stdout is captured' );
is( execute(perl_cmd('print STDERR qq{oops}'), 'stderr'), 'oops', 'stderr is captured' );
SKIP: {
	# The child writes "\r\n" through a text-mode STDOUT on Windows, and chomp
	# removes only the "\n".
	skip "a newline is \"\\r\\n\" on $^O", 1 if $^O eq 'MSWin32';
	is( execute(perl_cmd('print qq{hello\n}'), 'stdout'), 'hello', 'stdout is chomped' );
}

my $all = execute(perl_cmd('print qq{out}; print STDERR qq{err}'), 'all');
is( ref $all, 'HASH', 'return => all yields a hashref' );
is( $all->{stdout}, 'out', 'all: stdout field' );
is( $all->{stderr}, 'err', 'all: stderr field' );
is( $all->{exit},   0,     'all: exit field' );

# A failing command with $die disabled returns the raw wait-status ($?),
# which for exit(1) is 256 (1 << 8).
my $code;
capture { $code = execute(perl_cmd('exit 1'), 'exit', 0) };
is( $code, 256, 'non-zero command with die disabled returns raw wait status' );

# $die defaults to 1: a failing command is fatal.
throws_ok { capture { execute(perl_cmd('exit 1')) } } qr/failed/,
	'failing command dies by default';

# Invalid $return value is rejected up front.
throws_ok { execute(perl_cmd('exit 0'), 'nonsense') }
	qr/only accepts/, 'rejects an unknown return mode';

done_testing;
