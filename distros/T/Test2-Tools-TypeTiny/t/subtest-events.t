#!/usr/bin/perl

use v5.18;
use strict;
use warnings;

use lib 't/lib';
use StrTest;

use Test2::API            qw< intercept >;
use Test2::Tools::Basic;
use Test2::Tools::Compare qw< is like >;
use Test2::Tools::Subtest qw< subtest_buffered >;

use List::Util   qw< first >;
use Scalar::Util qw< blessed >;

###################################################################################################

my $events = intercept { StrTest::string_test(1); };

# Analysis of finished test
is(
    $events->state,
    {
        count      => 4,
        failed     => 2,
        is_passing => 0,

        plan         => 4,
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
    [qw< Subtest Diag Subtest Subtest Diag Subtest Plan >],
    'Order of events are correct',
);

my @subtest_events = grep { blessed $_ eq 'Test2::Event::Subtest' } $events->event_list;

is( $subtest_events[0]->pass, 0, 'StrMatch subtest failed');
is( $subtest_events[1]->pass, 1, 'First Enum subtest passed');
is( $subtest_events[2]->pass, 0, 'Second Enum subtest failed');

subtest_buffered 'Failed StrMatch subtest' => sub {
    my $event_tester_tree = events_tester_tree($subtest_events[0]);
    my $test_name         = 'Type Test: StrMatch[(?^:^(\S+) (\S+)$),Tuple[Num,Enum["mm","cm","m","km"]]]';

    my $subtype_compare = [
        { 'should pass (without coercions)' => [qw< Plan Ok Ok Ok >] },
        { 'should fail (without coercions)' => [qw< Plan Ok Ok Ok >] },
        { 'should pass'                     => [qw< Plan Ok Ok Ok >] },
        { 'should fail'                     => [qw< Plan Ok Ok Ok >] },
        { 'should sort into'                => [qw< Plan Ok >] },
        { 'should pass' => [
            'Plan',
            '(fail in Ok)',
            qr<Diag: Failed test .+\nat t/lib/StrTest\.pm line 48\.>,
            '(fail in Ok)',
            qr<Diag: Failed test .+\nat t/lib/StrTest\.pm line 48\.>,
            '(fail in Ok)',
            qr<Diag: Failed test .+\nat t/lib/StrTest\.pm line 48\.>,
        ] },
        qr<Diag: Failed test .+\nat t/lib/StrTest\.pm line 48\.>,
        {'should fail' => [
            'Plan',
            '(fail in Ok)',
            qr<Diag: Failed test .+\nat t/lib/StrTest\.pm line 49\.>,
            '(fail in Ok)',
            qr<Diag: Failed test .+\nat t/lib/StrTest\.pm line 49\.>,
            '(fail in Ok)',
            qr<Diag: Failed test .+\nat t/lib/StrTest\.pm line 49\.>,
        ] },
        qr<Diag: Failed test .+\nat t/lib/StrTest\.pm line 49\.>,
        'Plan'
    ];

    like(
        $event_tester_tree,
        { $test_name, [
            'Plan',
            { 'original type'    => $subtype_compare },
            qr<Diag: Failed test .+\nat t/lib/StrTest\.pm line 51\.>,
            { 'inline-less type' => $subtype_compare },
            qr<Diag: Failed test .+\nat t/lib/StrTest\.pm line 51\.>,
        ] },
        'StrMatch pass/fail order is correct',
    );

    my $orig_pass_subtest = $event_tester_tree->{$test_name}[1]{'original type'}[5]{'should pass'};
    my $strmatch_diags    = join "\n", grep { /Diag: / } @$orig_pass_subtest;

    note "=== FULL DEBUG MAP OUTPUT ===\n\n$strmatch_diags";
    like $strmatch_diags, qr<StrMatch\[.+\] constraint map:>,      'Failed test includes constraint map diag';
    like $strmatch_diags, qr<message:>,                            'Constraint map diag includes failed message';
    like $strmatch_diags, qr<is defined as:>,                      'Constraint map diag includes type definitions';
    like $strmatch_diags, qr{\QStr->check("xyz km") ==> PASSED\E}, 'Constraint map diag passed Str check';
};

subtest_buffered 'Failed Enum subtest' => sub {
    my $event_tester_tree = events_tester_tree($subtest_events[2]);
    my $test_name         = 'Type Test: Enum["FOO","BAR","BAZ"]';

    like(
        $event_tester_tree,
        { $test_name, [
            { 'should coerce into' => [
                'Plan',
                '(fail in Ok)',
                qr<Diag: Failed test .+\nat t/lib/StrTest\.pm line 93\.>,
                qw< Fail Ok Ok >, '(fail in Ok)',
                qr<Diag: Failed test .+\nat t/lib/StrTest\.pm line 93\.>,
                'Fail',
                '(fail in Ok)',
                qr<Diag: Failed test .+\nat t/lib/StrTest\.pm line 93\.>,
            ] },
            qr<Diag: Failed test .+\nat t/lib/StrTest\.pm line 93\.>,
            'Plan',
        ] },
        'StrMatch pass/fail order is correct',
    );

    my $coerce_subtest = $event_tester_tree->{$test_name}[0]{'should coerce into'};
    my $enum_diags    = join "\n", grep { /Diag: / } @$coerce_subtest;

    note "=== FULL DEBUG MAP OUTPUT ===\n\n$enum_diags";
    like $enum_diags, qr<Enum\[.+\] constraint map:>,          'Failed test includes constraint map diag';
    like $enum_diags, qr<message:>,                            'Constraint map diag includes failed message';
    like $enum_diags, qr<is defined as:>,                      'Constraint map diag includes type definitions';
    like $enum_diags, qr{\QStr->check("XYZ") ==> PASSED\E},    'Constraint map diag passed Str check';
    like $enum_diags, qr<Enum\[.+\] coercion map:>,            'Failed test includes coercion map diag';
    like $enum_diags, qr{\QStr->check("XYZ") ==> PASSED (coerced into "XYZ")\E}, 'Coercion map diag passed Str check';
};

done_testing;

###################################################################################################

sub events_tester_tree {
    my ($event) = @_;

    if    ($event->isa('Test2::API::InterceptResult')) {
        my @tree;
        foreach my $subevent ($event->event_list) {
            push @tree, events_tester_tree($subevent);
        }
        return \@tree;
    }
    elsif ($event->isa('Test2::Event::Subtest')) {
        my @tree;
        foreach my $subevent (@{ $event->subevents }) {
            push @tree, events_tester_tree($subevent);
        }

        # Flatten the diag messages
        for (my $i = 0; $i <= $#tree; $i++) {
            my $subevent = $tree[$i];
            if (!ref $subevent && $subevent =~ s/Diag: //) {
                my $string = $subevent;
                my $j;
                for ($j = $i+1; $j <= $#tree; $j++) {
                    my $next_string = $tree[$j];
                    unless (!ref $next_string && $next_string =~ s/Diag: //) {
                        $j--;
                        last;
                    }
                    $next_string .= "\n" unless $next_string =~ /\n$/;
                    $string .= $next_string;
                }

                splice @tree, $i, $j-$i+1, "Diag: $string";
                next;
            }
        }

        return { $event->name, \@tree };
    }
    elsif ($event->isa('Test2::Event::Ok')) {
        return $event->effective_pass ? 'Ok' : '(fail in Ok)';
    }
    elsif ($event->isa('Test2::Event::Diag')) {
        return "Diag: ".$event->message;
    }

    my $event_type = blessed $event;
    $event_type =~ s/Test2::Event:://;
    return $event_type;
}
