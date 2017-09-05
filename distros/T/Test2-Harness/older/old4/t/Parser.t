use Test2::Bundle::Extended -target => 'Test2::Harness::Parser';

use ok $CLASS;

my @TAP = (
    "ok 1 - pass 1",
    "ok 2 - pass 2",

    "ok 3 - buffered subtest {",
    "    ok 1 - pass 1",
    "    ok 2 - pass 2",
    "    ok 3 - nested buffered subtest {",
    "        ok 1 - pass 1",
    "        ok 2 - pass 2",
    "        1..2",
    "    }",
    "    1..3",
    "}",

    "    ok 1 - pass 1",
    "    ok 2 - pass 2",
    "        ok 1 - pass 1",
    "        ok 2 - pass 2",
    "        1..2",
    "    ok 3 - nested unbuffered subtest",
    "    1..3",
    "ok 4 - unbuffered subtest",

    "1..4",
);

my $one = bless({}, $CLASS);

my @facets;
for my $line (@TAP) {
    my $f = $one->parse_tap_line($line);
    use Data::Dumper;
    print Dumper($f);
    push @facets => $f if $f;
}

done_testing;
