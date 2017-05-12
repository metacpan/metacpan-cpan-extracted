#!/usr/local/bin/perl
use Test::More tests=>2;

@output = `examples/simple_scan<examples/ss_garbage1.in`;
@expected = ();
is_deeply(\@output, \@expected, "working output as expected");

@output = `examples/simple_scan<examples/ss_garbage2.in`;
@expected = map {"$_\n"} split /\n/,<<EOF;
1..1
ok 1 - Garbage lines were ignored [http://perl.org/] [/perl/ should match]
EOF
is_deeply(\@output, \@expected, "working output as expected");

