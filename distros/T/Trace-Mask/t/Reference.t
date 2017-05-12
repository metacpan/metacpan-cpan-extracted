use Test2::Bundle::Extended -target => 'Trace::Mask::Reference';
use Test2::Tools::Spec -rand => 0;

use Trace::Mask;
use Trace::Mask::Util qw/mask_frame mask_sub/;

use Trace::Mask::Test qw{
    test_stack_hide test_stack_shift test_stack_stop test_stack_no_start
    test_stack_alter test_stack_shift_and_hide test_stack_shift_short
    test_stack_hide_short test_stack_shift_and_alter test_stack_full_combo
    test_stack_restart test_stack_special test_stack_lock
};

use Trace::Mask::Reference qw{
    trace trace_string trace_mask_caller try_example
};

imported_ok qw{
    trace trace_string trace_mask_caller try_example
};

BEGIN {
    *_do_shift     = Trace::Mask::Reference->can('_do_shift')     or die "no _do_shift";
    *render_arg    = Trace::Mask::Reference->can('render_arg')    or die "no render_args";
    *_call_details = Trace::Mask::Reference->can('_call_details') or die "no _call_details";
}

subtest render_arg => sub {
    is(render_arg(), "undef", "undef as string");

    is(render_arg(1), 1, "numbers are not quoted");
    is(render_arg(1.5), 1.5, "numbers are not quoted");

    is(render_arg('a'), "'a'", "quote strings");

    like(
        render_arg({}),
        qr/^HASH\(0x.*\)$/,
        "hashref rendered"
    );

    like(
        render_arg(bless({}, 'foo')),
        qr/^foo=HASH\(0x.*\)$/,
        "object rendered"
    );
};

sub do_trace { trace_string(1) }
subtest try_example => sub {
    is(try_example { die "xxx\n" }, "xxx\n", "got exception");
    is(try_example { 1 },           undef,   "No exception");

    # Make sure we stop before this frame so it looks like try was called at
    # the root level.
    mask_frame(stop => 1, hide => 1);

    my $trace;
    my $file = __FILE__;
    my $line = __LINE__ + 1;
    my $error = try_example { $trace = do_trace() };
    die $error if $error;

    is($trace, "main::do_trace() called at $file line $line\n", "hid try frames")
        || print STDERR $trace;
};

sub details { _call_details(@_) };
subtest _call_details => sub {
    my $line = __LINE__ + 1;
    my @details = details(0,1,2,3);
    is(
        [@{$details[0]}[0,1,2,3]],
        [ __PACKAGE__, __FILE__, $line, 'main::details' ],
        "Got first 4 details from caller"
    );
    is($details[1], [0,1,2,3], "got args for caller");

    @details = details(10000);
    ok(!@details, "no details for bad level");
};

subtest _do_shift => sub {
    my $shift = [
        ['a1', 'b1', 1, 'foo1', 'x1', 'y1', 'z1'],
        [qw/a b c/],
        {hide => 1, 1 => 'a', 3 => 'x'},
    ];
    my $frame = [
        ['a2', 'b2', 2, 'foo2', 'x2', 'y2', 'z2'],
        [qw/x y z apple/],
        {hide => 2, 2 => 'b', 3 => 'y'},
    ];
    _do_shift($shift, $frame);

    is(
        $frame,
        [
            ['a2', 'b2', 2, 'foo1', 'x1', 'y1', 'z1'],    # All but first 3 come from shift
            [qw/a b c/],                                  # Directly from shift
            {hide => 2, 1 => 'a', 2 => 'b', 3 => 'x'},    # merged, shift wins, but only for numerics.
        ],
        "Merged shift into frame"
    );
};

subtest trace => sub {
    subtest hide => sub {
        local $ENV{NO_TRACE_MASK} = 1;
        my $trace = test_stack_hide(\&trace);
        like(
            $trace,
            [
                [['Trace::Mask::Test', 'mask_test_hide.pl', 11, 'Trace::Mask::Reference::trace'], []],
                [['Trace::Mask::Test', 'mask_test_hide.pl', 10, 'Trace::Mask::Test::hide_5'], ['e']],
                [['Trace::Mask::Test', 'mask_test_hide.pl', 9,  'Trace::Mask::Test::hide_4'], ['d']],
                [['Trace::Mask::Test', 'mask_test_hide.pl', 8,  'Trace::Mask::Test::hide_3'], ['c']],
                [['Trace::Mask::Test', 'mask_test_hide.pl', 7,  'Trace::Mask::Test::hide_2'], ['b']],
                [['Trace::Mask::Test', 'mask_test_hide.pl', 4,  'Trace::Mask::Test::hide_1'], ['a']],
            ],
            "Got all frames"
        );

        $ENV{NO_TRACE_MASK} = 0;
        $trace = test_stack_hide(\&trace);
        like(
            $trace,
            [
                [['Trace::Mask::Test', 'mask_test_hide.pl', 11, 'Trace::Mask::Reference::trace'], []],
                [['Trace::Mask::Test', 'mask_test_hide.pl', 10, 'Trace::Mask::Test::hide_5'], ['e']],
                [['Trace::Mask::Test', 'mask_test_hide.pl', 9,  'Trace::Mask::Test::hide_4'], ['d']],
                [['Trace::Mask::Test', 'mask_test_hide.pl', 4,  'Trace::Mask::Test::hide_1'], ['a']],
                DNE(),
            ],
            "Masked the calls to hide_2 and hide_3"
        );
    };

    subtest shift => sub {
        local $ENV{NO_TRACE_MASK} = 1;
        my $trace = test_stack_shift(\&trace);
        like(
            $trace,
            [
                [['Trace::Mask::Test', 'mask_test_shift.pl', 11, 'Trace::Mask::Reference::trace'], []],
                [['Trace::Mask::Test', 'mask_test_shift.pl', 10, 'Trace::Mask::Test::shift_5'], ['e']],
                [['Trace::Mask::Test', 'mask_test_shift.pl', 9,  'Trace::Mask::Test::shift_4'], ['d']],
                [['Trace::Mask::Test', 'mask_test_shift.pl', 8,  'Trace::Mask::Test::shift_3'], ['c']],
                [['Trace::Mask::Test', 'mask_test_shift.pl', 7,  'Trace::Mask::Test::shift_2'], ['b']],
                [['Trace::Mask::Test', 'mask_test_shift.pl', 4,  'Trace::Mask::Test::shift_1'], ['a']],
            ],
            "Got all frames"
        );

        $ENV{NO_TRACE_MASK} = 0;
        $trace = test_stack_shift(\&trace);
        like(
            $trace,
            [
                [['Trace::Mask::Test', 'mask_test_shift.pl', 11, 'Trace::Mask::Reference::trace'], []],
                [['Trace::Mask::Test', 'mask_test_shift.pl', 10, 'Trace::Mask::Test::shift_5'], ['e']],
                [['Trace::Mask::Test', 'mask_test_shift.pl', 7,  'Trace::Mask::Test::shift_4'], ['d']],
                [['Trace::Mask::Test', 'mask_test_shift.pl', 4,  'Trace::Mask::Test::shift_1'], ['a']],
                DNE(),
            ],
            "Hid the calls to shift_2 and shift_3, changed line for shift_4"
        );
    };

    subtest stop => sub {
        local $ENV{NO_TRACE_MASK} = 1;
        my $trace = test_stack_stop(\&trace);
        like(
            $trace,
            [
                [['Trace::Mask::Test', 'mask_test_stop.pl', 11, 'Trace::Mask::Reference::trace'], []],
                [['Trace::Mask::Test', 'mask_test_stop.pl', 10, 'Trace::Mask::Test::stop_5'], ['e']],
                [['Trace::Mask::Test', 'mask_test_stop.pl', 9,  'Trace::Mask::Test::stop_4'], ['d']],
                [['Trace::Mask::Test', 'mask_test_stop.pl', 8,  'Trace::Mask::Test::stop_3'], ['c']],
                [['Trace::Mask::Test', 'mask_test_stop.pl', 7,  'Trace::Mask::Test::stop_2'], ['b']],
                [['Trace::Mask::Test', 'mask_test_stop.pl', 4,  'Trace::Mask::Test::stop_1'], ['a']],
            ],
            "Got all frames"
        );

        $ENV{NO_TRACE_MASK} = 0;
        $trace = test_stack_stop(\&trace);
        like(
            $trace,
            [
                [['Trace::Mask::Test', 'mask_test_stop.pl', 11, 'Trace::Mask::Reference::trace'], []],
                [['Trace::Mask::Test', 'mask_test_stop.pl', 10, 'Trace::Mask::Test::stop_5'], ['e']],
                [['Trace::Mask::Test', 'mask_test_stop.pl', 9,  'Trace::Mask::Test::stop_4'], ['d']],
                [['Trace::Mask::Test', 'mask_test_stop.pl', 8,  'Trace::Mask::Test::stop_3'], ['c']],
                [['Trace::Mask::Test', 'mask_test_stop.pl', 7,  'Trace::Mask::Test::stop_2'], ['b']],
                DNE(),
            ],
            "Stoped at, but showed, stop_2"
        );
    };

    subtest no_start => sub {
        local $ENV{NO_TRACE_MASK} = 1;
        my $trace = test_stack_no_start(\&trace);
        like(
            $trace,
            [
                [['Trace::Mask::Test', 'mask_test_no_start.pl', 11, 'Trace::Mask::Reference::trace'], []],
                [['Trace::Mask::Test', 'mask_test_no_start.pl', 10, 'Trace::Mask::Test::no_start_5'], ['e']],
                [['Trace::Mask::Test', 'mask_test_no_start.pl', 9,  'Trace::Mask::Test::no_start_4'], ['d']],
                [['Trace::Mask::Test', 'mask_test_no_start.pl', 8,  'Trace::Mask::Test::no_start_3'], ['c']],
                [['Trace::Mask::Test', 'mask_test_no_start.pl', 7,  'Trace::Mask::Test::no_start_2'], ['b']],
                [['Trace::Mask::Test', 'mask_test_no_start.pl', 4,  'Trace::Mask::Test::no_start_1'], ['a']],
            ],
            "Got all frames"
        );

        $ENV{NO_TRACE_MASK} = 0;
        $trace = test_stack_no_start(\&trace);
        like(
            $trace,
            [
                [['Trace::Mask::Test', 'mask_test_no_start.pl', 8,  'Trace::Mask::Test::no_start_3'], ['c']],
                [['Trace::Mask::Test', 'mask_test_no_start.pl', 7,  'Trace::Mask::Test::no_start_2'], ['b']],
                [['Trace::Mask::Test', 'mask_test_no_start.pl', 4,  'Trace::Mask::Test::no_start_1'], ['a']],
                DNE(),
            ],
            "Started the trace at the call to no_start_3"
        );

        $ENV{NO_TRACE_MASK} = 1;
        my $line = __LINE__ + 1;
        $trace = test_stack_no_start(sub { trace() });
        like(
            $trace,
            [
                [[__PACKAGE__, __FILE__, $line, 'Trace::Mask::Reference::trace'], []],
                [['Trace::Mask::Test', 'mask_test_no_start.pl', 11, __PACKAGE__ . '::__ANON__'], []],
                [['Trace::Mask::Test', 'mask_test_no_start.pl', 10, 'Trace::Mask::Test::no_start_5'], ['e']],
                [['Trace::Mask::Test', 'mask_test_no_start.pl', 9,  'Trace::Mask::Test::no_start_4'], ['d']],
                [['Trace::Mask::Test', 'mask_test_no_start.pl', 8,  'Trace::Mask::Test::no_start_3'], ['c']],
                [['Trace::Mask::Test', 'mask_test_no_start.pl', 7,  'Trace::Mask::Test::no_start_2'], ['b']],
                [['Trace::Mask::Test', 'mask_test_no_start.pl', 4,  'Trace::Mask::Test::no_start_1'], ['a']],
            ],
            "Got all frames"
        );

        $ENV{NO_TRACE_MASK} = 0;
        $line = __LINE__ + 1;
        $trace = test_stack_no_start(sub { trace() });
        like(
            $trace,
            [
                [[__PACKAGE__, __FILE__, $line, 'Trace::Mask::Reference::trace'], []],
                [['Trace::Mask::Test', 'mask_test_no_start.pl', 11, __PACKAGE__ . '::__ANON__'], []],
                [['Trace::Mask::Test', 'mask_test_no_start.pl', 10, 'Trace::Mask::Test::no_start_5'], ['e']],
                [['Trace::Mask::Test', 'mask_test_no_start.pl', 9,  'Trace::Mask::Test::no_start_4'], ['d']],
                [['Trace::Mask::Test', 'mask_test_no_start.pl', 8,  'Trace::Mask::Test::no_start_3'], ['c']],
                [['Trace::Mask::Test', 'mask_test_no_start.pl', 7,  'Trace::Mask::Test::no_start_2'], ['b']],
                [['Trace::Mask::Test', 'mask_test_no_start.pl', 4,  'Trace::Mask::Test::no_start_1'], ['a']],
                DNE(),
            ],
            "Did not hide the no_starts when they are not the start"
        );
    };

    subtest alter => sub {
        local $ENV{NO_TRACE_MASK} = 1;
        my $trace = test_stack_alter(\&trace);
        like(
            $trace,
            [
                [['Trace::Mask::Test', 'mask_test_alter.pl', 22, 'Trace::Mask::Reference::trace'], []],
                [['Trace::Mask::Test', 'mask_test_alter.pl', 20, 'Trace::Mask::Test::alter_5'], ['e']],
                [['Trace::Mask::Test', 'mask_test_alter.pl', 9,  'Trace::Mask::Test::alter_4'], ['d']],
                [['Trace::Mask::Test', 'mask_test_alter.pl', 8,  'Trace::Mask::Test::alter_3'], ['c']],
                [['Trace::Mask::Test', 'mask_test_alter.pl', 7,  'Trace::Mask::Test::alter_2'], ['b']],
                [['Trace::Mask::Test', 'mask_test_alter.pl', 4,  'Trace::Mask::Test::alter_1'], ['a']],
            ],
            "Got all frames"
        );

        $ENV{NO_TRACE_MASK} = 0;
        $trace = test_stack_alter(\&trace);
        like(
            $trace,
            [
                [['Trace::Mask::Test', 'mask_test_alter.pl', 22, 'Trace::Mask::Reference::trace'], []],
                [['Trace::Mask::Test', 'mask_test_alter.pl', 20, 'Trace::Mask::Test::alter_5'], ['e']],
                [['Foo::Bar', 'Foo/Bar.pm', 42,  'Foo::Bar::foobar'], ['d']],
                [['Trace::Mask::Test', 'mask_test_alter.pl', 8,  'Trace::Mask::Test::alter_3'], ['c']],
                [['Trace::Mask::Test', 'mask_test_alter.pl', 7,  'Trace::Mask::Test::alter_2'], ['b']],
                [['Trace::Mask::Test', 'mask_test_alter.pl', 4,  'Trace::Mask::Test::alter_1'], ['a']],
                DNE(),
            ],
            "Stoped at, but showed, alter_2"
        );
        my $altered = $trace->[2]->[0];
        ok(@$altered > 3, "Sane number of items");
        ok(@$altered < 900, "Did not add to args");
    };

    subtest shift_and_hide => sub {
        local $ENV{NO_TRACE_MASK} = 1;
        my $trace = test_stack_shift_and_hide(\&trace);
        like(
            $trace,
            [
                [['Trace::Mask::Test', 'mask_test_s_and_h.pl', 11, 'Trace::Mask::Reference::trace'], []],
                [['Trace::Mask::Test', 'mask_test_s_and_h.pl', 10, 'Trace::Mask::Test::s_and_h_5'], ['e']],
                [['Trace::Mask::Test', 'mask_test_s_and_h.pl', 9,  'Trace::Mask::Test::s_and_h_4'], ['d']],
                [['Trace::Mask::Test', 'mask_test_s_and_h.pl', 8,  'Trace::Mask::Test::s_and_h_3'], ['c']],
                [['Trace::Mask::Test', 'mask_test_s_and_h.pl', 7,  'Trace::Mask::Test::s_and_h_2'], ['b']],
                [['Trace::Mask::Test', 'mask_test_s_and_h.pl', 4,  'Trace::Mask::Test::s_and_h_1'], ['a']],
            ],
            "Got all frames"
        );

        $ENV{NO_TRACE_MASK} = 0;
        $trace = test_stack_shift_and_hide(\&trace);
        like(
            $trace,
            [
                [['Trace::Mask::Test', 'mask_test_s_and_h.pl', 11, 'Trace::Mask::Reference::trace'], []],
                [['Trace::Mask::Test', 'mask_test_s_and_h.pl', 10, 'Trace::Mask::Test::s_and_h_5'], ['e']],
                [['Trace::Mask::Test', 'mask_test_s_and_h.pl', 7,  'Trace::Mask::Test::s_and_h_4'], ['d']],
                [['Trace::Mask::Test', 'mask_test_s_and_h.pl', 4,  'Trace::Mask::Test::s_and_h_1'], ['a']],
                DNE(),
            ],
            "Shifted to a hide, so effectively a shift => 2"
        );
    };

    subtest shift_short => sub {
        local $ENV{NO_TRACE_MASK} = 1;
        my $trace = test_stack_shift_short(\&trace);
        like(
            $trace,
            [
                [['Trace::Mask::Test', 'mask_test_shift_short.pl', 11, 'Trace::Mask::Reference::trace'], []],
                [['Trace::Mask::Test', 'mask_test_shift_short.pl', 10, 'Trace::Mask::Test::shift_short_5'], ['e']],
                [['Trace::Mask::Test', 'mask_test_shift_short.pl', 9,  'Trace::Mask::Test::shift_short_4'], ['d']],
                [['Trace::Mask::Test', 'mask_test_shift_short.pl', 8,  'Trace::Mask::Test::shift_short_3'], ['c']],
                [['Trace::Mask::Test', 'mask_test_shift_short.pl', 7,  'Trace::Mask::Test::shift_short_2'], ['b']],
                [['Trace::Mask::Test', 'mask_test_shift_short.pl', 4,  'Trace::Mask::Test::shift_short_1'], ['a']],
            ],
            "Got all frames"
        );

        $ENV{NO_TRACE_MASK} = 0;
        $trace = test_stack_shift_short(\&trace);
        like(
            $trace,
            [
                [['Trace::Mask::Test', 'mask_test_shift_short.pl', 11, 'Trace::Mask::Reference::trace'], []],
                [['Trace::Mask::Test', 'mask_test_shift_short.pl', 10, 'Trace::Mask::Test::shift_short_5'], ['e']],
                [['Trace::Mask::Test', 'mask_test_shift_short.pl', 4,  'Trace::Mask::Test::shift_short_4'], ['d']],

                DNE(),
            ],
            "Shifted to the bottom, then ran out"
        );
    };

    subtest hide_short => sub {
        local $ENV{NO_TRACE_MASK} = 1;
        my $trace = test_stack_hide_short(\&trace);
        like(
            $trace,
            [
                [['Trace::Mask::Test', 'mask_test_hide_short.pl', 11, 'Trace::Mask::Reference::trace'], []],
                [['Trace::Mask::Test', 'mask_test_hide_short.pl', 10, 'Trace::Mask::Test::hide_short_5'], ['e']],
                [['Trace::Mask::Test', 'mask_test_hide_short.pl', 9,  'Trace::Mask::Test::hide_short_4'], ['d']],
                [['Trace::Mask::Test', 'mask_test_hide_short.pl', 8,  'Trace::Mask::Test::hide_short_3'], ['c']],
                [['Trace::Mask::Test', 'mask_test_hide_short.pl', 7,  'Trace::Mask::Test::hide_short_2'], ['b']],
                [['Trace::Mask::Test', 'mask_test_hide_short.pl', 4,  'Trace::Mask::Test::hide_short_1'], ['a']],
            ],
            "Got all frames"
        );

        $ENV{NO_TRACE_MASK} = 0;
        $trace = test_stack_hide_short(\&trace);
        like(
            $trace,
            [
                [['Trace::Mask::Test', 'mask_test_hide_short.pl', 11, 'Trace::Mask::Reference::trace'], []],
                [['Trace::Mask::Test', 'mask_test_hide_short.pl', 10, 'Trace::Mask::Test::hide_short_5'], ['e']],
                DNE(),
            ],
            "hid to the bottom, then ran out"
        );
    };

    subtest shift_and_alter => sub {
        local $ENV{NO_TRACE_MASK} = 1;
        my $trace = test_stack_shift_and_alter(\&trace);
        like(
            $trace,
            [
                [['Trace::Mask::Test', 'mask_test_s_and_a.pl', 21, 'Trace::Mask::Reference::trace'], []],
                [['Trace::Mask::Test', 'mask_test_s_and_a.pl', 19, 'Trace::Mask::Test::s_and_a_5'], ['e']],
                [['Trace::Mask::Test', 'mask_test_s_and_a.pl', 13, 'Trace::Mask::Test::s_and_a_4'], ['d']],
                [['Trace::Mask::Test', 'mask_test_s_and_a.pl', 8,  'Trace::Mask::Test::s_and_a_3'], ['c']],
                [['Trace::Mask::Test', 'mask_test_s_and_a.pl', 7,  'Trace::Mask::Test::s_and_a_2'], ['b']],
                [['Trace::Mask::Test', 'mask_test_s_and_a.pl', 4,  'Trace::Mask::Test::s_and_a_1'], ['a']],
            ],
            "Got all frames"
        );

        $ENV{NO_TRACE_MASK} = 0;
        $trace = test_stack_shift_and_alter(\&trace);
        like(
            $trace,
            [
                [['Trace::Mask::Test', 'mask_test_s_and_a.pl', 21, 'Trace::Mask::Reference::trace'], []],
                [['Trace::Mask::Test', 'mask_test_s_and_a.pl', 19, 'Trace::Mask::Test::s_and_a_5'],  ['e']],
                [['x', 'x', 100, 'y', 'y'], ['d']],
                [['Trace::Mask::Test', 'mask_test_s_and_a.pl', 7, 'Trace::Mask::Test::s_and_a_2'], ['b']],
                [['Trace::Mask::Test', 'mask_test_s_and_a.pl', 4, 'Trace::Mask::Test::s_and_a_1'], ['a']],
                DNE(),
            ],
            "Shifted all caller details except the first 3"
        );
    };

    subtest test_stack_full_combo => sub {
        local $ENV{NO_TRACE_MASK} = 1;
        my $trace = test_stack_full_combo(\&trace);
        like(
            $trace,
            [
                [['Trace::Mask::Test', 'mask_test_full_combo.pl', 26, 'Trace::Mask::Reference::trace',],    []],
                [['Trace::Mask::Test', 'mask_test_full_combo.pl', 25, 'Trace::Mask::Test::full_combo_20',], ['t']],
                [['Trace::Mask::Test', 'mask_test_full_combo.pl', 24, 'Trace::Mask::Test::full_combo_19',], ['s']],
                [['Trace::Mask::Test', 'mask_test_full_combo.pl', 23, 'Trace::Mask::Test::full_combo_18',], ['r']],
                [['Trace::Mask::Test', 'mask_test_full_combo.pl', 22, 'Trace::Mask::Test::full_combo_17',], ['q']],
                [['Trace::Mask::Test', 'mask_test_full_combo.pl', 21, 'Trace::Mask::Test::full_combo_16',], ['p']],
                [['Trace::Mask::Test', 'mask_test_full_combo.pl', 20, 'Trace::Mask::Test::full_combo_15',], ['o']],
                [['Trace::Mask::Test', 'mask_test_full_combo.pl', 19, 'Trace::Mask::Test::full_combo_14',], ['n']],
                [['Trace::Mask::Test', 'mask_test_full_combo.pl', 18, 'Trace::Mask::Test::full_combo_13',], ['m']],
                [['Trace::Mask::Test', 'mask_test_full_combo.pl', 17, 'Trace::Mask::Test::full_combo_12',], ['l']],
                [['Trace::Mask::Test', 'mask_test_full_combo.pl', 16, 'Trace::Mask::Test::full_combo_11',], ['k']],
                [['Trace::Mask::Test', 'mask_test_full_combo.pl', 15, 'Trace::Mask::Test::full_combo_10',], ['j']],
                [['Trace::Mask::Test', 'mask_test_full_combo.pl', 14, 'Trace::Mask::Test::full_combo_9',],  ['i']],
                [['Trace::Mask::Test', 'mask_test_full_combo.pl', 13, 'Trace::Mask::Test::full_combo_8',],  ['h']],
                [['Trace::Mask::Test', 'mask_test_full_combo.pl', 12, 'Trace::Mask::Test::full_combo_7',],  ['g']],
                [['Trace::Mask::Test', 'mask_test_full_combo.pl', 11, 'Trace::Mask::Test::full_combo_6',],  ['f']],
                [['Trace::Mask::Test', 'mask_test_full_combo.pl', 10, 'Trace::Mask::Test::full_combo_5',],  ['e']],
                [['Trace::Mask::Test', 'mask_test_full_combo.pl', 9,  'Trace::Mask::Test::full_combo_4',],  ['d']],
                [['Trace::Mask::Test', 'mask_test_full_combo.pl', 8,  'Trace::Mask::Test::full_combo_3',],  ['c']],
                [['Trace::Mask::Test', 'mask_test_full_combo.pl', 7,  'Trace::Mask::Test::full_combo_2',],  ['b']],
                [['Trace::Mask::Test', 'mask_test_full_combo.pl', 4,  'Trace::Mask::Test::full_combo_1',],  ['a']],
            ],
            "Got all frames"
        );

        $ENV{NO_TRACE_MASK} = 0;
        $trace = test_stack_full_combo(\&trace);
        like(
            $trace,
            [
                [['Trace::Mask::Test', 'mask_test_full_combo.pl', 24, 'Trace::Mask::Test::full_combo_19',], ['s']],
                [['Trace::Mask::Test', 'mask_test_full_combo.pl', 23, 'Trace::Mask::Test::full_combo_18',], ['r']],
                [['foo', 'mask_test_full_combo.pl', 18, 'Trace::Mask::Test::full_combo_17', sub{1}, 'bar'], ['q']],
                [['Trace::Mask::Test', 'mask_test_full_combo.pl', 17, 'Trace::Mask::Test::full_combo_12',], ['l']],
                [['Trace::Mask::Test', 'mask_test_full_combo.pl', 16, 'Trace::Mask::Test::full_combo_11',], ['k']],
                [['Trace::Mask::Test', 'mask_test_full_combo.pl', 15, 'Trace::Mask::Test::full_combo_10',], ['j']],
                [['xxx', 'mask_test_full_combo.pl', 14, 'Trace::Mask::Test::full_combo_9',],  ['i']],
                [['Trace::Mask::Test', 'mask_test_full_combo.pl', 13, 'Trace::Mask::Test::full_combo_8',],  ['h']],
                [['Trace::Mask::Test', 'mask_test_full_combo.pl', 12, 'Trace::Mask::Test::full_combo_7',],  ['g']],
                [['Trace::Mask::Test', 'mask_test_full_combo.pl', 11, 'Trace::Mask::Test::full_combo_6',],  ['f']],
                [['Trace::Mask::Test', 'mask_test_full_combo.pl', 10, 'Trace::Mask::Test::full_combo_5',],  ['e']],
                [['Trace::Mask::Test', 'mask_test_full_combo.pl', 9,  'Trace::Mask::Test::full_combo_4',],  ['d']],
                [['Trace::Mask::Test', 'mask_test_full_combo.pl', 7,  'Trace::Mask::Test::full_combo_2',],  ['b']],
                DNE(),
            ],
            "Combination stack looks right"
        );
    };

    subtest test_stack_restart => sub {
        local $ENV{NO_TRACE_MASK} = 1;
        my $trace = test_stack_restart(\&trace);
        like(
            $trace,
            [
                [['Trace::Mask::Test', 'mask_test_restart.pl', 12, 'Trace::Mask::Reference::trace',],    []],
                [['Trace::Mask::Test', 'mask_test_restart.pl', 11, 'Trace::Mask::Test::restart_6',],  ['f']],
                [['Trace::Mask::Test', 'mask_test_restart.pl', 10, 'Trace::Mask::Test::restart_5',],  ['e']],
                [['Trace::Mask::Test', 'mask_test_restart.pl', 9,  'Trace::Mask::Test::restart_4',],  ['d']],
                [['Trace::Mask::Test', 'mask_test_restart.pl', 8,  'Trace::Mask::Test::restart_3',],  ['c']],
                [['Trace::Mask::Test', 'mask_test_restart.pl', 7,  'Trace::Mask::Test::restart_2',],  ['b']],
                [['Trace::Mask::Test', 'mask_test_restart.pl', 4,  'Trace::Mask::Test::restart_1',],  ['a']],
            ],
            "Got all frames"
        );

        $ENV{NO_TRACE_MASK} = 0;
        $trace = test_stack_restart(\&trace);
        like(
            $trace,
            [
                [['Trace::Mask::Test', 'mask_test_restart.pl', 11, 'Trace::Mask::Test::restart_6',],  ['f']],
                [['Trace::Mask::Test', 'mask_test_restart.pl', 10, 'Trace::Mask::Test::restart_5',],  ['e']],
                [['Trace::Mask::Test', 'mask_test_restart.pl', 9,  'Trace::Mask::Test::restart_4',],  ['d']],
                [['Trace::Mask::Test', 'mask_test_restart.pl', 7,  'Trace::Mask::Test::restart_2',],  ['b']],
                [['Trace::Mask::Test', 'mask_test_restart.pl', 4,  'Trace::Mask::Test::restart_1',],  ['a']],
                DNE(),
            ],
            "Combination stack looks right"
        );
    };

    subtest test_stack_special => sub {
        local $ENV{NO_TRACE_MASK} = 1;
        my $trace = test_stack_special(\&trace);
        like(
            $trace,
            [
                [['Trace::Mask::Test', 'mask_test_special.pl', 13, 'Trace::Mask::Reference::trace',], []],
                [['Trace::Mask::Test', 'mask_test_special.pl', 12, 'Trace::Mask::Test::special_6',],  ['g']],
                [['Trace::Mask::Test', 'mask_test_special.pl', 11, 'Trace::Mask::Test::special_5',],  ['f']],
                [['Trace::Mask::Test', 'mask_test_special.pl', 10, 'Trace::Mask::Test::special_4',],  ['e']],
                [['Trace::Mask::Test', 'mask_test_special.pl', 9,  'Trace::Mask::Test::special_3',],  ['d']],
                [['Trace::Mask::Test', 'mask_test_special.pl', 8,  'Trace::Mask::Test::unimport',],   ['c']],
                [['Trace::Mask::Test', 'mask_test_special.pl', 7,  'Trace::Mask::Test::special_2',],  ['b']],
                [['Trace::Mask::Test', 'mask_test_special.pl', 4,  'Trace::Mask::Test::special_1',],  ['a']],
            ],
            "Got all frames"
        );

        $ENV{NO_TRACE_MASK} = 0;
        $trace = test_stack_special(\&trace);
        like(
            $trace,
            [
                [['Trace::Mask::Test', 'mask_test_special.pl', 13, 'Trace::Mask::Reference::trace',], []],
                [['Trace::Mask::Test', 'mask_test_special.pl', 12, 'Trace::Mask::Test::special_6',],  ['g']],
                [['Trace::Mask::Test', 'mask_test_special.pl', 11, 'Trace::Mask::Test::special_5',],  ['f']],
                [['Trace::Mask::Test', 'mask_test_special.pl', 8,  'Trace::Mask::Test::unimport',],   ['c']],
                DNE(),
            ],
            "did not mask unimport, and list it even after a stop"
        );
    };

    subtest test_stack_lock => sub {
        local $ENV{NO_TRACE_MASK} = 1;
        my $trace = test_stack_lock(\&trace);
        like(
            $trace,
            [
                [['Trace::Mask::Test', 'mask_test_lock.pl', 13, 'Trace::Mask::Reference::trace',], []],
                [['Trace::Mask::Test', 'mask_test_lock.pl', 12, 'Trace::Mask::Test::lock_6',],     ['g']],
                [['Trace::Mask::Test', 'mask_test_lock.pl', 11, 'Trace::Mask::Test::lock_5',],     ['f']],
                [['Trace::Mask::Test', 'mask_test_lock.pl', 10, 'Trace::Mask::Test::lock_4',],     ['e']],
                [['Trace::Mask::Test', 'mask_test_lock.pl', 9,  'Trace::Mask::Test::lock_3',],     ['d']],
                [['Trace::Mask::Test', 'mask_test_lock.pl', 8,  'Trace::Mask::Test::lock_x',],     ['c']],
                [['Trace::Mask::Test', 'mask_test_lock.pl', 7,  'Trace::Mask::Test::lock_2',],     ['b']],
                [['Trace::Mask::Test', 'mask_test_lock.pl', 4,  'Trace::Mask::Test::lock_1',],     ['a']],
            ],
            "Got all frames"
        );

        $ENV{NO_TRACE_MASK} = 0;
        $trace = test_stack_lock(\&trace);
        like(
            $trace,
            [
                [['Trace::Mask::Test', 'mask_test_lock.pl', 13, 'Trace::Mask::Reference::trace',], []],
                [['Trace::Mask::Test', 'mask_test_lock.pl', 12, 'Trace::Mask::Test::lock_6',],     ['g']],
                [['Trace::Mask::Test', 'mask_test_lock.pl', 11, 'Trace::Mask::Test::lock_5',],     ['f']],
                [['Trace::Mask::Test', 'mask_test_lock.pl', 8,  'Trace::Mask::Test::lock_x',],     ['c']],
                DNE(),
            ],
            "did not mask lock_x, and list it even after a stop"
        );
    };
};

subtest trace_string => sub {
    local $ENV{NO_TRACE_MASK};
    my $trace = test_stack_full_combo(\&trace_string);
    is($trace, <<'    EOT', "Got trace");
Trace::Mask::Test::full_combo_19('s') called at mask_test_full_combo.pl line 24
Trace::Mask::Test::full_combo_18('r') called at mask_test_full_combo.pl line 23
Trace::Mask::Test::full_combo_17('q') called at mask_test_full_combo.pl line 18
Trace::Mask::Test::full_combo_12('l') called at mask_test_full_combo.pl line 17
Trace::Mask::Test::full_combo_11('k') called at mask_test_full_combo.pl line 16
Trace::Mask::Test::full_combo_10('j') called at mask_test_full_combo.pl line 15
Trace::Mask::Test::full_combo_9('i') called at mask_test_full_combo.pl line 14
Trace::Mask::Test::full_combo_8('h') called at mask_test_full_combo.pl line 13
Trace::Mask::Test::full_combo_7('g') called at mask_test_full_combo.pl line 12
Trace::Mask::Test::full_combo_6('f') called at mask_test_full_combo.pl line 11
Trace::Mask::Test::full_combo_5('e') called at mask_test_full_combo.pl line 10
Trace::Mask::Test::full_combo_4('d') called at mask_test_full_combo.pl line 9
Trace::Mask::Test::full_combo_2('b') called at mask_test_full_combo.pl line 7
    EOT

    my $file = __FILE__;
    mask_frame(stop => 1, hide => 1);
    my $x = sub { trace_string()  };            my $line1 = __LINE__;
    my $y = sub { eval { $x->() } || die $@ };  my $line2 = __LINE__;

    $trace = $y->(); my $line3 = __LINE__;
    is($trace, <<"    EOT", "Got trace with eval");
Trace::Mask::Reference::trace_string() called at $file line $line1
main::__ANON__() called at $file line $line2
eval { ... } called at $file line $line2
main::__ANON__() called at $file line $line3
    EOT
};

sub my_call { trace_mask_caller(@_) }
sub my_wrap { my_call(@_)           }
subtest trace_string => sub {
    local $ENV{NO_TRACE_MASK};

    my @call = my_call();
    is(\@call, [__PACKAGE__, __FILE__, __LINE__ - 1], "got immediate caller" );

    @call = my_call(0);
    like(\@call, [__PACKAGE__, __FILE__, __LINE__ - 1, 'main::my_call'], "got immediate caller + details" );
    ok(@call > 3, "got extra fields");

    @call = my_wrap(1);
    like(\@call, [__PACKAGE__, __FILE__, __LINE__ - 1, 'main::my_wrap'], "got level 1 caller" );

    like(
        [test_stack_full_combo(sub { trace_mask_caller(2) })],
        ['Trace::Mask::Test', 'mask_test_full_combo.pl', 24, 'Trace::Mask::Test::full_combo_19'],
        "Got call details 2",
    );

    like(
        [test_stack_full_combo(sub { trace_mask_caller(3) })],
        ['Trace::Mask::Test', 'mask_test_full_combo.pl', 23, 'Trace::Mask::Test::full_combo_18'],
        "Got call details 3",
    );

    like(
        [test_stack_full_combo(sub { trace_mask_caller(4) })],
        ['foo', 'mask_test_full_combo.pl', 18, 'Trace::Mask::Test::full_combo_17', sub{1}, 'bar'],
        "Got call details 4",
    );

    like(
        [test_stack_full_combo(sub { trace_mask_caller(5) })],
        ['Trace::Mask::Test', 'mask_test_full_combo.pl', 17, 'Trace::Mask::Test::full_combo_12'],
        "Got call details 5",
    );

    like(
        [test_stack_full_combo(sub { trace_mask_caller(6) })],
        ['Trace::Mask::Test', 'mask_test_full_combo.pl', 16, 'Trace::Mask::Test::full_combo_11'],
        "Got call details 6",
    );

    like(
        [test_stack_full_combo(sub { trace_mask_caller(7) })],
        ['Trace::Mask::Test', 'mask_test_full_combo.pl', 15, 'Trace::Mask::Test::full_combo_10'],
        "Got call details 7",
    );

    like(
        [test_stack_full_combo(sub { trace_mask_caller(8) })],
        ['xxx', 'mask_test_full_combo.pl', 14, 'Trace::Mask::Test::full_combo_9'],
        "Got call details 8",
    );

    like(
        [test_stack_full_combo(sub { trace_mask_caller(9) })],
        ['Trace::Mask::Test', 'mask_test_full_combo.pl', 13, 'Trace::Mask::Test::full_combo_8'],
        "Got call details 9",
    );

    like(
        [test_stack_full_combo(sub { trace_mask_caller(10) })],
        ['Trace::Mask::Test', 'mask_test_full_combo.pl', 12, 'Trace::Mask::Test::full_combo_7'],
        "Got call details 10",
    );

    like(
        [test_stack_full_combo(sub { trace_mask_caller(11) })],
        ['Trace::Mask::Test', 'mask_test_full_combo.pl', 11, 'Trace::Mask::Test::full_combo_6'],
        "Got call details 11",
    );

    like(
        [test_stack_full_combo(sub { trace_mask_caller(12) })],
        ['Trace::Mask::Test', 'mask_test_full_combo.pl', 10, 'Trace::Mask::Test::full_combo_5'],
        "Got call details 12",
    );

    like(
        [test_stack_full_combo(sub { trace_mask_caller(13) })],
        ['Trace::Mask::Test', 'mask_test_full_combo.pl', 9,  'Trace::Mask::Test::full_combo_4'],
        "Got call details 13",
    );
};

done_testing;
