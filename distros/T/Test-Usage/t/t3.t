use strict;
use Test::More qw(no_plan);
use IO::Capture::Stdout;

my $TM_ok = *Test::More::ok;
my $TM_diag = *Test::More::diag;

    # Pass any command line argument to have this test print the
    # Test::Usage output.
my $g_show_invoc = $ARGV[0];

# --------------------------------------------------------------------
# We will run these tests using Test::Usage and see if we get the
# expected output.

package lets_test;
use Test::Usage;

my $t = t();

example('aa', sub {
    ok(1, q|'1' should succeed.|, 'But it failed.');
    ok(0, q|'0' should fail.|,    'And it did.');
});

example('b1', sub { ok(1, q|'1' should succeed.|, 'But it failed.') });
example('b2', sub { ok(1, q|'1' should succeed.|, 'But it failed.') });
example('b3', sub { ok(0, q|'0' should fail.|,    'And it did.') });
example('b4', sub { ok(1, q|'1' should succeed.|, 'But it failed.') });
example('b5', sub { ok(0, q|'0' should fail.|,    'And it did.') });

example('a2', sub {
    ok(1, q|'1' should succeed.|, 'But it failed.');
    ok(0, q|'0' should fail.|,    'And it did.');
    ok(2, q|'2' should succeed.|, 'But it failed.');
});

example('__d', sub { ok(die, q|Should die.|,    'And it did.') });
example('__w', sub { ok(warn, q|Should warn.|,    'And it did.') });

# --------------------------------------------------------------------
package main;

# These subs take as arguments a string and an expected number of
# occurences of something the sub will search for in the string. The
# sub will invoke Test::More's ok() to test whether the expected
# number of occurrences were found in the output produced by
# Test::Usage.

my %counting_subs = (
    ok => sub {
        my ($str, $nb_exp) = @_;
        return _what_lines($str, '(?<!not )ok', $nb_exp);
    },
    not_ok => sub {
        my ($str, $nb_exp) = @_;
        return _what_lines($str, 'not ok', $nb_exp);
    },
    nb_succ => sub {
        my ($str, $nb_exp) = @_;
        return _summary_what($str, "+$nb_exp");
    },
    nb_fail => sub {
        my ($str, $nb_exp) = @_;
        return _summary_what($str, "-$nb_exp");
    },
    died => sub {
        my ($str, $exp) = @_;
        my $sign = $exp == 1 ? '+' : '-';
        return _summary_what($str, "${sign}d");
    },
    warned => sub {
        my ($str, $exp) = @_;
        my $sign = $exp == 1 ? '+' : '-';
        return _summary_what($str, "${sign}w");
    },
);

sub _what_lines {
        # $what is one of '(?<!not )ok' or 'not ok'.
    my ($str, $what, $nb_exp) = @_;
    my $nb_got = () = $str =~ /$what /mg;
    ok($nb_got == $nb_exp, "Expecting $nb_exp $what.")
      or diag("$str : But got $nb_got.");
}

sub _summary_what {
        # $exp is like '+2', '-1', '-d', or '+w'.
    my ($str, $exp) = @_;
        # It contains something like '(00h:00m:01s).
    my ($summary_line) = $str =~ /^(.*\(\d\dh:\d\dm:\d\ds\).*)$/m;;
    ok(
        scalar($summary_line =~ / \Q$exp /),
        "Expecting summary to show '$exp'."
    ) or diag("But it did not: '$summary_line'\n");
}

# --------------------------------------------------------------------
my $capture_stdout = IO::Capture::Stdout->new();

sub try {
        # Expected counts for data appearing in the output.
    my (
            # A string representing arguments to pass to $t->test(...),
        $test_args,
            # Keys are a %counting_subs and values are expected return of
            # applying .
        %exp
    ) = @{$_[0]};
    my $args_str = join ', ',
      map { "$_ => '$test_args->{$_}'" } keys %$test_args;
        # Color may interfere with parsing of captured IO.
    t()->{options}{c} = 0;
    my %got;
    my $invoc = '@got{qw(name time_took nb_succ nb_fail died warned)} '
      . "= test($args_str)";
    if ($g_show_invoc) {
        $DB::single = 1;
        print "---------- $invoc\n";
        eval $invoc;
    }
    else {
        $capture_stdout->start();
        eval $invoc;
        $capture_stdout->stop();
        $DB::single = 1;
        for my $what (qw(nb_fail nb_succ died warned)) {
            my $exp = $exp{$what} || 0;
            my $got = $got{$what};
            $TM_ok->(
                $got == $exp,
                "Expecting $what to be $exp."
            ) or $TM_diag->("But got $got.");
        }
        my $stdout = join '', $capture_stdout->read();
        $counting_subs{$_}->($stdout, $exp{$_}) for keys %exp;
    }
};

# --------------------------------------------------------------------
# Here are the tests.

try($_) for (
    [
        {a => 'aa', v => 0},
        ok      => 0,
        not_ok  => 0,
        nb_succ => 1,
        nb_fail => 1,
    ],
    [
        {a => 'aa', v => 0},
        ok      => 0,
        not_ok  => 0,
        nb_succ => 1,
        nb_fail => 1,
    ],
    [ {v => 0},
        ok      => 0,
        not_ok  => 0,
        nb_succ => 6,
        nb_fail => 4,
    ],
    [ {},
        ok      => 0,
        not_ok  => 4,
        nb_succ => 6,
        nb_fail => 4,
    ],
    [ {v => 2},
        ok      => 6,
        not_ok  => 4,
        nb_succ => 6,
        nb_fail => 4,
    ],
    [ {a => 'aa'},
        ok      => 0,
        not_ok  => 1,
        nb_succ => 1,
        nb_fail => 1,
    ],
    [ {a => 'a*'},
        ok      => 0,
        not_ok  => 2,
        nb_succ => 3,
        nb_fail => 2,
    ],
    [ {a => 'b*', v => 0},
        ok      => 0,
        not_ok  => 0,
        nb_succ => 3,
        nb_fail => 2,
    ],
    [ {f => 1},
        ok      => 0,
        not_ok  => 10,
        nb_succ => 0,
        nb_fail => 10,
    ],
    [ {a => '__d', e => '', v => 0},
        died    => 1,
    ],
    [ {a => '__w', e => '', v => 0},
        warned  => 1,
        nb_succ => 1,
    ],
);

