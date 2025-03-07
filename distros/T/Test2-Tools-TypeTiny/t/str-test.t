#!/usr/bin/perl

use Test2::Tools::TypeTiny;

use Test2::API            qw< intercept >;
use Test2::Tools::Basic;
use Test2::Tools::Compare qw< is like >;
use Test2::Tools::Subtest qw< subtest_buffered >;

use Types::Standard qw< StrMatch Num Enum Tuple >;

use List::Util   qw< first >;
use Scalar::Util qw< blessed >;

###################################################################################################

# Example type test
my $events = intercept {
    type_subtest StrMatch[qr/^(\S+) (\S+)$/, Tuple[Num, Enum[qw< mm cm m km >]]], sub {
        my $type = shift;

        my @pass_list = (
            '1 km',
            '-1.6 cm',
            '+1.6 m',
        );
        my @fail_list = (
            'xyz km',
            '7 miles',
            '7 km    ',
        );

        should_pass_initially($type, @pass_list);
        should_fail_initially($type, @fail_list);
        should_pass($type, @pass_list);
        should_fail($type, @fail_list);

        should_sort_into(
            $type,
            [qw< aaa bbb qqq rrr sss ttt >],
        );

        # Intentional failures
        should_pass($type, @fail_list);   # XXX: exact line number captured in tests below
        should_fail($type, @pass_list);
    };

    # Fully passes
    my $enum_type = Enum[\1, qw< FOO BAR BAZ >];
    type_subtest $enum_type, sub {
        my $type = shift;

        should_pass_initially(
            $type,
            qw< FOO BAR BAZ >,
        );
        should_fail_initially(
            $type,
            qw< foo bar baz f b 0 1 2 3 XYZ >,
        );
        should_pass(
            $type,
            qw< FOO BAR BAZ foo f ba baz 0 1 2 -1 >,
        );
        should_fail(
            $type,
            undef, sub {}, \'string', qw< XYZ 3 4 5 6 -99 >,
        );
        should_coerce_into(
            $type,
            qw<
                foo   FOO
                f     FOO
                ba    BAR
                baz   BAZ
                0     FOO
                1     BAR
                2     BAZ
                -1    BAZ
            >,
        );
    };

    # Coercion failures
    type_subtest $enum_type, sub {
        my $type = shift;

        should_coerce_into(   # XXX: exact line number captured in tests below
            $type,
            # NOTE: Bad coercions, but will produce known failures.  Also, undef/'' should be different to
            # validate that the checks are not getting merged together (previous bug).
            undef,  '',
            '',     'blank',
            qw<
                foo   FOO
                f     FOO
                XYZ   XYZ
                -99   FOO
                q     BAR
            >,
        );
    };

    done_testing;
};

# Analysis of finished test
is(
    $events->state,
    {
        count      => 3,
        failed     => 2,
        is_passing => 0,

        plan         => 3,
        follows_plan => 1,

        bailed_out  => undef,
        skip_reason => undef,
    },
    'Event summary is correct',
);

is(
    [
        map { s/Test2::Event:://; $_ }
        map { blessed $_ }
        $events->event_list
    ],
    [qw< Subtest Diag Subtest Subtest Diag Plan >],
    'Order of events are correct',
);

my @subtest_events = grep { blessed $_ eq 'Test2::Event::Subtest' } $events->event_list;

is( $subtest_events[0]->pass, 0, 'StrMatch subtest failed');
is( $subtest_events[1]->pass, 1, 'First Enum subtest passed');
is( $subtest_events[2]->pass, 0, 'Second Enum subtest failed');

subtest_buffered 'Failed StrMatch subtest' => sub {
    my @strmatch_subtest_events = grep { blessed $_ eq 'Test2::Event::Subtest' } @{ $subtest_events[0]->subevents };

    is(
        [ map { $_->effective_pass } @strmatch_subtest_events ],
        [qw< 1 1 1 1 1 0 0 >],
        'StrMatch pass/fail order is correct',
    );

    my $failed_strmatch_subtest = first { !$_->effective_pass } @strmatch_subtest_events;

    my $strmatch_diags = join("\n",
        map  { $_->message }
        grep { blessed $_ eq 'Test2::Event::Diag' }
        @{ $failed_strmatch_subtest->subevents }
    );

    like $strmatch_diags, qr<at t/str-test.t line 44>,             'Failed test includes line numbers';
    like $strmatch_diags, qr<StrMatch\[.+\] constraint map:>,      'Failed test includes constraint map diag';
    like $strmatch_diags, qr<is defined as:>,                      'Constraint map diag includes type definitions';
    like $strmatch_diags, qr{\QStr->check("xyz km") ==> PASSED\E}, 'Constraint map diag passed Str check';
};

subtest_buffered 'Failed Enum subtest' => sub {
    my @enum_subtest_events =
        map  { @{ $_->subevents } }
        grep { blessed $_ eq 'Test2::Event::Subtest' }
        @{ $subtest_events[2]->subevents }
    ;

    is(
        [
            map  { $_->isa('Test2::Event::Fail') ? 0 : $_->effective_pass }
            grep { $_->isa('Test2::Event::Ok') || $_->isa('Test2::Event::Fail') }
            @enum_subtest_events
        ],
        [qw< 0 0 1 1 0 0 0 >],
        'Enum->should_coerce_into pass/fail order is correct',
    );

    my $enum_diags = join("\n",
        map   { $_->message }
        grep  { blessed $_ eq 'Test2::Event::Diag' }
        @enum_subtest_events
    );

    like $enum_diags, qr<at t/str-test.t line 88>,             'Failed test includes line numbers';
    like $enum_diags, qr<Enum\[.+\] constraint map:>,          'Failed test includes constraint map diag';
    like $enum_diags, qr<is defined as:>,                      'Constraint map diag includes type definitions';
    like $enum_diags, qr{\QStr->check("XYZ") ==> PASSED\E},    'Constraint map diag passed Str check';
    like $enum_diags, qr<Enum\[.+\] coercion map:>,            'Failed test includes coercion map diag';
    like $enum_diags, qr{\QStr->check("XYZ") ==> PASSED (coerced into "XYZ")\E}, 'Coercion map diag passed Str check';
};

done_testing;
