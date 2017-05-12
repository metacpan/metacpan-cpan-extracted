use strict;
use warnings;

use Test::Most;
use Data::Dump;
use Class::Load;

my $class = 'Config::INI::Reader::LibIni';
use_ok $class;

my %inis = (
    '01 single section' => [
        "[Foo]",
        [["Foo", {}]],
    ],
    '02 two sections' => [
        "[Foo]\n[Bar]",
        [["Foo", {}], ["Bar", {}]],
    ],
    '03 section with args' => [
        "[Foo]\nbar = baz",
        [["Foo", { bar => "baz" }]],
    ],
    '04 duplicates' => [
        "[Foo]\n[Foo]",
        [["Foo", {}], ["Foo", {}]],
    ],
    '05 duplicates with args' => [
        "[Foo]\nbar = baz\n[Foo]\nqux = quux",
        [["Foo", { bar => "baz" }], ["Foo", { qux => "quux" }]],
    ],
    '06 duplicate args' => [
        "[Foo]\nbar = baz\nbar = quz",
        [["Foo", { bar => ["baz", "quz"] }]],
    ],
);

foreach my $test ( sort keys %inis ) {
    my $ini = $class->read_string($inis{$test}[0]);
    cmp_deeply $ini, $inis{$test}[1], $test;
}

done_testing;
