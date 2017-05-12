use strict;
use warnings;
use Test::More qw(no_plan);
use IO::Capture::Stdout;

my $capture_stdout = IO::Capture::Stdout->new();

    # Pass any command line argument to have this test print the
    # Test::Usage output.
my $show_examples_output = defined $ARGV[0];

# --------------------------------------------------------------------
package test1;
use Test::Usage;

sub try {
    my ($exp_lines, $expr_to_eval, $options) = @_;
    t()->reset_options();
    while (my($key, $val) = each %$options) {
        t()->options()->{$key} = $val;
    }
        # Color may interfere with parsing of captured IO.
    t()->options()->{c} = 0;

    $capture_stdout->start();
    eval $expr_to_eval;
    $capture_stdout->stop();
    my $got_text = join '', $capture_stdout->read();
    print($got_text), return if $show_examples_output;
    my ($exp_Ok, $exp_NotOk, $exp_Exp, $exp_Got, $exp_label) = @$exp_lines;
    $exp_label = '-' unless defined $exp_label;
        # There will be a label only if there is an 'ok' or 'not ok' line.
    if ($exp_Ok || $exp_NotOk) {
        Test::More::ok(
            scalar($got_text =~ /^.*$exp_label/),
            "Expecting label to match '$exp_label'."
        ) or Test::More::diag("But it didn't:\n$got_text");
    }
    my $exp_nb_lines = $exp_Ok + $exp_NotOk + $exp_Exp + $exp_Got;
    my $got_nb_lines = @{[split /\n/, $got_text]};
    Test::More::ok(
        $got_nb_lines == $exp_nb_lines,
        "Expecting output to have $exp_nb_lines lines."
        ) or Test::More::diag("But got $got_nb_lines:\n$got_text");
    foo($got_text, $exp_Ok,    '(?<!not )ok');
    foo($got_text, $exp_NotOk, 'not ok');
    foo($got_text, $exp_Exp,   'Exp');
    foo($got_text, $exp_Got,   'Got');
};

sub foo {
    my ($got_text, $exp_matched, $patt) = @_;
    my $got_matched = $got_text =~ /$patt/;
    Test::More::ok(
        $got_matched == $exp_matched,
        sprintf("Expecting '$patt' %sto match.", $exp_matched ? '' : 'not ')
    ) or Test::More::diag("But it didn't:\n$got_text");
}

# --------------------------------------------------------------------
# The actual tests.

  # Expressions we want to test.
my $ok_1 = q.ok(1).;
my $ok_2 = q.ok(1, 'Exp').;
my $ok_3 = q.ok(1, 'Exp', 'Got').;
my $ok_4 = q.ok(0).;
my $ok_5 = q.ok(0, 'Exp').;
my $ok_6 = q.ok(0, 'Exp', 'Got').;
my $ok_7 = q.ok_labeled('a', 1).;

  # Expected results associated to expressions and option values.
my @tries = (
    # Expected counts of
    # [[notOk, Ok, Exp, Got], $expr, test_options],

    [[0, 0, 0, 0], $ok_1 , {v => 0}],
    [[0, 0, 0, 0], $ok_1 , {v => 1}],
    [[1, 0, 0, 0], $ok_1 , {v => 2}],

    [[0, 0, 0, 0], $ok_2 , {v => 0}],
    [[0, 0, 0, 0], $ok_2 , {v => 1}],
    [[1, 0, 1, 0], $ok_2 , {v => 2}],

    [[0, 0, 0, 0], $ok_3 , {v => 0}],
    [[0, 0, 0, 0], $ok_3 , {v => 1}],
    [[1, 0, 1, 0], $ok_3 , {v => 2}],

    [[0, 0, 0, 0], $ok_4 , {v => 0}],
    [[0, 1, 0, 0], $ok_4 , {v => 1}],
    [[0, 1, 0, 0], $ok_4 , {v => 2}],

    [[0, 0, 0, 0], $ok_5 , {v => 0}],
    [[0, 1, 1, 0], $ok_5 , {v => 1}],
    [[0, 1, 1, 0], $ok_5 , {v => 2}],

    [[0, 0, 0, 0], $ok_6 , {v => 0}],
    [[0, 1, 1, 1], $ok_6 , {v => 1}],
    [[0, 1, 1, 1], $ok_6 , {v => 2}],

    [[0, 1, 0, 0], $ok_1 , {v => 2, f => 1}],
    [[0, 1, 0, 0, '-.a'], $ok_7 , {v => 2, f => 1}],
);

try(@$_) for @tries;

