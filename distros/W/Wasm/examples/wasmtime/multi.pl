use strict;
use warnings;
use Wasm::Wasmtime;
use Carp::Assert;
use Path::Tiny qw( path );

# This is an example of working with mulit-value modules and dealing with
# multi-value functions.

# Configure our `Store`, but be sure to use a `Config` that enables the
# wasm multi-value feature since it's not stable yet.
print "Initializing...\n";
my $store = Wasm::Wasmtime::Store->new(
  Wasm::Wasmtime::Engine->new(
    Wasm::Wasmtime::Config->new
                          ->wasm_multi_value(1),
  )
);

print "Compiling module...\n";
my $module = Wasm::Wasmtime::Module->new( $store, file => path(__FILE__)->parent->child('multi.wat') );

print "Creating callback...\n";
sub callback_func
{
  my($x,$y) = @_;
  return ($y+1, $x+1);
}

print "Instantiating module...\n";
my $instance = Wasm::Wasmtime::Instance->new(
  $module, [\&callback_func],
);

print "Extracting export...\n";
my $g = $instance->exports->g;

print "Calling export \"g\"...\n";
my @results = $g->(1,3);
printf "> %d %d\n", @results;

assert($results[0] == 4);
assert($results[1] == 2);

print "Calling export \"round_trip_many\"...\n";
my $round_trip_many = $instance->exports->round_trip_many;
@results = $round_trip_many->(0,1,2,3,4,5,6,7,8,9);

print "Printing results...\n";
print "> @results\n";
assert(scalar @results == 10);
for my $i (0..9)
{
  assert($results[$i] == $i);
}
