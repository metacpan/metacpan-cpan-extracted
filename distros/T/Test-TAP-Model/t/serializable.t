#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 6;

use Data::Dumper;

my $m;
BEGIN { use_ok($m = "Test::TAP::Model") }

isa_ok(my $x = $m->new, $m);

$x->start_file("blah");
$x->log_event(type => "test", "ok" => 1);

can_ok($x, "structure");
my $str = Dumper($x->structure);

my $y;

{
	my $VAR1;
	isa_ok($y = $m->new_with_struct(eval $str), $m);
}

is_deeply($y->structure, $x->structure, "structures are the same");

is($y->test_files, $x->test_files, "test file count is too");


