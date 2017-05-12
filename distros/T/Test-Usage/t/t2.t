use strict;
use Test::More qw(no_plan);
use IO::Capture::Stdout;

my $TM_ok = *Test::More::ok;
my $capture_stdout = IO::Capture::Stdout->new();

    # Pass any command line argument to have this test print the
    # Test::Usage output.
my $show_examples_output = $ARGV[0];

# --------------------------------------------------------------------
package test1;
use Test::Usage;

# Test that the proper data appears on screen.

example('a1', sub {ok(1, 'Exp_a1', 'Got_a1')});
example('a2', sub {ok(0, 'Exp_a2', 'Got_a2')});

my $got_labels = join ' ', @{t()->labels()};
my $exp_labels = 'a1 a2';
$TM_ok->(
    $got_labels eq $exp_labels,
    "Expecting labels() to be '$exp_labels'"
) or diag("But got '$got_labels'.");

# --------------------------------------------------------------------
sub try {
    my ($test_args_ref, %exp) = @_;
    $capture_stdout->start();
        # Color may interfere with parsing of captured IO.
    t()->options()->{c} = 0;
    t()->test(%$test_args_ref);
    $capture_stdout->stop();
    my $stdout = join '', $capture_stdout->read();
    print "$stdout\n" if $show_examples_output;
    for my $exp_str (keys %exp) {
        my $exp_nb = $exp{$exp_str};
        my $got_nb = () = $stdout =~ /\Q$exp_str/g;
        $TM_ok->(
            $got_nb == $exp_nb,
            sprintf("Expecting '$exp_str' to be %s.",
              $got_nb ? 'present' : 'absent')
        );
    }
};

try({},
    Exp_a1   => 0,
    Got_a1   => 0,
    Exp_a2   => 1,
    Got_a2   => 1,
    '+1 -1' => 1,
);

try({v => 2},
    Exp_a1   => 1,
    Got_a1   => 0,
    Exp_a2   => 1,
    Got_a2   => 1,
    '+1 -1' => 1,
);

try({v => 0, s => 0},
    Exp_a1   => 0,
    Got_a1   => 0,
    Exp_a2   => 0,
    Got_a2   => 0,
    '+1 -1' => 0,
);

try({v => 1, s => 0, f => 1},
    Exp_a1   => 1,
    Got_a1   => 1,
    Exp_a2   => 1,
    Got_a2   => 1,
    '+1 -1' => 0,
);

