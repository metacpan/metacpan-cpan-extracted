use strict;
use warnings;
use Test::More;
use Test::Steering::Wheel;
use IO::CaptureOutput qw(capture);
use File::Spec;

my @schedule = (
    {
        args   => ['t/sample-tests/simple'],
        stdout => [
            "TAP version 13",
            "ok 1", "ok 2", "ok 3", "ok 4", "ok 5",
            "ok 6 t/sample-tests/simple done", "1..6"
        ],
        stderr => []
    },
    {
        options => { announce => 1 },
        args    => ['t/sample-tests/simple'],
        stdout  => [
            "TAP version 13",
            "ok 1", "ok 2", "ok 3", "ok 4", "ok 5",
            "ok 6 t/sample-tests/simple done", "1..6"
        ],
        stderr => ["# Running t/sample-tests/simple"]
    },
    {
        options => { add_prefix => 1 },
        args    => ['t/sample-tests/simple'],
        stdout  => [
            "TAP version 13",
            "ok 1 t/sample-tests/simple",
            "ok 2 t/sample-tests/simple",
            "ok 3 t/sample-tests/simple",
            "ok 4 t/sample-tests/simple",
            "ok 5 t/sample-tests/simple",
            "ok 6 t/sample-tests/simple done",
            "1..6"
        ],
        stderr => []
    },
    {
        args   => ['t/sample-tests/descriptive'],
        stdout => [
            "TAP version 13",
            "ok 1 Interlock activated",
            "ok 2 Megathrusters are go",
            "ok 3 Head formed",
            "ok 4 Blazing sword formed",
            "ok 5 Robeast destroyed",
            "ok 6 t/sample-tests/descriptive done",
            "1..6"
        ],
        stderr => []
    },
    {
        options => { add_prefix => 1 },
        args    => ['t/sample-tests/descriptive'],
        stdout  => [
            "TAP version 13",
            "ok 1 t/sample-tests/descriptive: Interlock activated",
            "ok 2 t/sample-tests/descriptive: Megathrusters are go",
            "ok 3 t/sample-tests/descriptive: Head formed",
            "ok 4 t/sample-tests/descriptive: Blazing sword formed",
            "ok 5 t/sample-tests/descriptive: Robeast destroyed",
            "ok 6 t/sample-tests/descriptive done",
            "1..6"
        ],
        stderr => []
    },
    {
        args =>
          [ 't/sample-tests/simple', 't/sample-tests/simple_fail' ],
        stdout => [
            "TAP version 13",
            "ok 1",
            "ok 2",
            "ok 3",
            "ok 4",
            "ok 5",
            "ok 6 t/sample-tests/simple done",
            "ok 7",
            "not ok 8",
            "ok 9",
            "ok 10",
            "not ok 11",
            "ok 12 t/sample-tests/simple_fail done",
            "1..12"
        ],
        stderr => []
    },
    {
        args   => ['t/sample-tests/die'],
        stdout => [
            "not ok 1 t/sample-tests/die: Parse error: No plan found in TAP output",
            "not ok 2 t/sample-tests/die: Non-zero status: exit=1, wait=256",
            "1..2"
        ],
        stderr => []
    },
    {
        args   => ['t/sample-tests/simple_yaml'],
        stdout => [
            "TAP version 13",
            "ok 1",
            "ok 2",
            "  ---",
            "  -",
            "    fnurk: skib",
            "    ponk: gleeb",
            "  -",
            "    bar: krup",
            "    foo: plink",
            "  ...",
            "ok 3",
            "ok 4",
            "  ---",
            "  expected:",
            "    - 1",
            "    - 2",
            "    - 4",
            "  got:",
            "    - 1",
            "    - pong",
            "    - 4",
            "  ...",
            "ok 5",
            "ok 6 t/sample-tests/simple_yaml done",
            "1..6"
        ],
        stderr => []
    },
    {
        args   => ['t/sample-tests/no_nums'],
        stdout => [
            "TAP version 13",
            "ok 1", "ok 2", "not ok 3", "ok 4", "ok 5",
            "ok 6 t/sample-tests/no_nums done", "1..6"
        ],
        stderr => []
    },
    {
        args => [
            't/sample-tests/simple', 't/sample-tests/simple_fail',
            't/sample-tests/die',    't/sample-tests/simple_yaml',
            't/sample-tests/no_nums'
        ],
        stdout => [
            "TAP version 13",
            "ok 1",
            "ok 2",
            "ok 3",
            "ok 4",
            "ok 5",
            "ok 6 t/sample-tests/simple done",
            "ok 7",
            "not ok 8",
            "ok 9",
            "ok 10",
            "not ok 11",
            "ok 12 t/sample-tests/simple_fail done",
            "not ok 13 t/sample-tests/die: Parse error: No plan found in TAP output",
            "not ok 14 t/sample-tests/die: Non-zero status: exit=1, wait=256",
            "ok 15",
            "ok 16",
            "  ---",
            "  -",
            "    fnurk: skib",
            "    ponk: gleeb",
            "  -",
            "    bar: krup",
            "    foo: plink",
            "  ...",
            "ok 17",
            "ok 18",
            "  ---",
            "  expected:",
            "    - 1",
            "    - 2",
            "    - 4",
            "  got:",
            "    - 1",
            "    - pong",
            "    - 4",
            "  ...",
            "ok 19",
            "ok 20 t/sample-tests/simple_yaml done",
            "ok 21",
            "ok 22",
            "not ok 23",
            "ok 24",
            "ok 25",
            "ok 26 t/sample-tests/no_nums done",
            "1..26"
        ],
        stderr => []
    },
    {
        args   => [ 't/sample-tests/simple', 't/sample-tests/simple' ],
        stdout => [
            "TAP version 13",
            "ok 1", "ok 2", "ok 3", "ok 4", "ok 5",
            "ok 6 t/sample-tests/simple done", "1..6"
        ],
        stderr => []
    },
    {
        args => [
            [ 't/sample-tests/simple', 'Simple 1' ],
            [ 't/sample-tests/simple', 'Simple 2' ]
        ],
        stdout => [
            "TAP version 13",
            "ok 1",
            "ok 2",
            "ok 3",
            "ok 4",
            "ok 5",
            "ok 6 Simple 1 done",
            "ok 7",
            "ok 8",
            "ok 9",
            "ok 10",
            "ok 11",
            "ok 12 Simple 2 done",
            "1..12"
        ],
        stderr => []
    },
);

plan tests => @schedule * 3;

sub are_lines($$$) {
    my ( $lines, $want, $desc ) = @_;
    my @lines = split /\n/, $lines;
    unless ( is_deeply( \@lines, $want, $desc ) ) {
        use Data::Dumper;
        diag(
            Data::Dumper->new(
                [
                    {
                        got  => \@lines,
                        want => $want,
                    }
                ]
              )->Terse( 1 )->Purity( 1 )->Useqq( 1 )->Dump
        );
    }
}

for my $test ( @schedule ) {
    my %options = %{ $test->{options} || {} };
    my $wheel = Test::Steering::Wheel->new( %options );
    isa_ok $wheel, 'Test::Steering::Wheel';

    my @args = @{ $test->{args} };
    my $desc = join( ', ', grep { !ref $_ } @args );

    capture(
        sub {
            $wheel->include_tests( @args );
            $wheel->end_plan;
        },
        \my $stdout,
        \my $stderr
    );

    are_lines $stdout, $test->{stdout}, "$desc: stdout OK";
    are_lines $stderr, $test->{stderr}, "$desc: stderr OK";
}
