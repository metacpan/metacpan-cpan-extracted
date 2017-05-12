#!/usr/local/bin/perl
use Test::More tests=>1;

@output = `examples/simple_scan<examples/ss_blank.in`;
@expected = map {"$_\n"} split /\n/,<<EOF;
1..1
ok 1 - Blank lines were ignored [http://perl.org/] [/perl/ should match]
EOF
is_deeply(\@output, \@expected, "working output as expected");
