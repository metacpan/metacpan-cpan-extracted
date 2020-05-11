use strict;
use warnings;
use Carp::Assert;

sub f
{
  my($x,$y) = @_;
  ($y+1, $x+1);
}

use Wasm
  -api => 0,
  -wat => q{
    (module
      (func $f (import "main" "f") (param i32 i64) (result i64 i32))

      (func $g (export "g") (param i32 i64) (result i64 i32)
        (call $f (local.get 0) (local.get 1))
      )

      (func $round_trip_many
        (export "round_trip_many")
        (param i64 i64 i64 i64 i64 i64 i64 i64 i64 i64)
        (result i64 i64 i64 i64 i64 i64 i64 i64 i64 i64)

        local.get 0
        local.get 1
        local.get 2
        local.get 3
        local.get 4
        local.get 5
        local.get 6
        local.get 7
        local.get 8
        local.get 9)
    )
  },
;

print "Calling export \"g\"...\n";
my @results = g(1,3);
printf "> %d %d\n", @results;

assert($results[0] == 4);
assert($results[1] == 2);

print "Calling export \"round_trip_many\"...\n";
@results = round_trip_many(0,1,2,3,4,5,6,7,8,9);

print "Printing results...\n";
print "> @results\n";
assert(scalar @results == 10);
for my $i (0..9)
{
  assert($results[$i] == $i);
}
