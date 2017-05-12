#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 35;

my $m;

BEGIN { use_ok($m = "Test::TAP::Model") }

isa_ok(my $t = $m->new, $m);
isa_ok($t, "Test::Harness::Straps");

can_ok($t, "start_file");
my $e = $t->start_file("example");

$e->{results} = $t->analyze_fh("example", \*DATA);

isa_ok(my $s = $t->structure, "HASH");

is_deeply([ sort keys %$s ], [ "test_files" ], "keys of structure");

is(@{ $s->{test_files} }, 1, "one test file");

my $f = $s->{test_files}[0];
is_deeply([ sort keys %$f ], [ sort qw/file results events/ ], "keys of file hash");
is(my @e = @{$f->{events}}, 3, "three events");


# this compares the hash structures to the ones we expect to get
# from Test::Harness::Straps events
is($e[0]->{type}, "test", "first event is a test");
ok($e[0]->{ok}, "it passed");
ok(!$e[0]->{diag}, "no diagnosis");

is($e[1]{type}, "test", "second event is a test");
ok(!$e[1]->{ok}, "it failed");
like($e[1]->{diag}, qr/expected/, "it has diagnosis");

is($e[2]{type}, "test", "third event is a test");
ok($e[2]{todo}, "it's a todo test");
like($e[1]->{diag}, qr/expected/, "it has diagnosis");


is( scalar($t->test_files), 1, "one test file" );
my $f_obj = ($t->test_files)[0];

is( ( $f_obj->subtests )[0]->diag, "", "first subtest has no diag" );
like( ( $f_obj->subtests )[1]->diag, qr/expected/, "second subtest does have diag" );



# this is the return from analyze_foo
ok(exists($f->{results}), "file wide results also exist");
is($f->{results}{seen}, 3, "total of three tests");
is($f->{results}{ok}, 2, "two tests ok");
ok(!$f->{results}{passed}, "file did not pass");

# These will die in Test::TAP::Model
eval '$t->get_tests()';
ok($@, "Test::TAP::Model dies when calling get_tests()");
eval '$t->run()';
ok($@, "Test::TAP::Model dies when calling run()");


# Try new_with_struct
$s = $t->structure;
my $t2 = Test::TAP::Model->new_with_struct($s);
isa_ok($t2, $m);
isa_ok($t2, "Test::Harness::Straps"); 

# Try new_with_tests
my $t3 = Test::TAP::Model->new_with_tests($s->{test_files});
isa_ok($t3, $m);
isa_ok($t3, "Test::Harness::Straps");

# Call latest_event with a parameter
my $t4 = new $m;
isa_ok($t4, $m);
isa_ok($t4, "Test::Harness::Straps");
my %event = ();
$event{type} = 'test';
$event{todo} = 1;
$t4->latest_event(%event);
isa_ok(my $l = $t4->latest_event, "HASH");
is_deeply([ sort keys %$l], [ sort qw/type todo/], 
   "Test latest_event with parameters");

__DATA__
1..3
ok 1 - foo
not ok 2 - bar
#     Failed test (t/example.t at line 9)
#          got: '1'
#     expected: '2'
not ok 3 - gorch # TODO not yet
#     Failed (TODO) test (t/example.t at line 12)
#          got: '2'
#     expected: '4'
# Looks like you failed 1 test of 3.

