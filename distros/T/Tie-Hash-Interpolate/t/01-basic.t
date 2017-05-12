use strict;
use warnings;
use Test::More 'no_plan';

BEGIN { use_ok('Tie::Hash::Interpolate') }

tie my %lut, 'Tie::Hash::Interpolate', one_key => 'constant';

eval { undef = $lut{2} };
ok($@, "too few keys");

## fetch-store non-numbers

eval { $lut{foo} = 1 };
ok($@, "STORE non-number key");

eval { $lut{1} = 'bar' };
ok($@, "STORE non-number value");

eval { my $foo = $lut{'foo'} };
ok($@, "FETCH non-number key");

## fetch-store numbers

$lut{1} = 2;
ok(1, "STORE number key-value");

is($lut{1}, 2, "FETCH number key");

## constant tests

is($lut{1.5}, 2, "extrapolate constant 1.5");
is($lut{0.5}, 2, "extrapolate constant 0.5");

$lut{3} = 4;

is($lut{2}, 3,  "interpolate 2 -> 3");
is($lut{0}, 1,  "extrapolate 0 -> 1");
is($lut{-0}, 1, "extrapolate -0 -> 1");
is($lut{-1}, 0, "extrapolate -1 -> 0");
is($lut{4}, 5,  "extrapolate 4 -> 5");

$lut{-1} = 1;

is($lut{2}, 3,  "interpolate 2 -> 3");
is($lut{0}, 1.5,  "extrapolate 0 -> 1.5");
is($lut{-0}, 1.5, "extrapolate -0 -> 1.5");
is($lut{-1}, 1, "extrapolate -1 -> 1");
is($lut{-2}, 0.5, "extrapolate -2 -> 0.5");
is($lut{4}, 5,  "extrapolate 4 -> 5");

my @keys = sort keys %lut;
is_deeply(\@keys, [-1, 1, 3], "keys - deeply");

ok(exists $lut{1}, "exists - ok");
ok(!exists $lut{2}, "exists - not ok");

delete $lut{-1};

is($lut{2}, 3,  "interpolate 2 -> 3");
is($lut{0}, 1,  "extrapolate 0 -> 1");
is($lut{-0}, 1, "extrapolate -0 -> 1");
is($lut{-1}, 0, "extrapolate -1 -> 0");
is($lut{4}, 5,  "extrapolate 4 -> 5");

undef %lut;
@keys = sort keys %lut;
is_deeply(\@keys, [], "clear");

## flip the slope

$lut{2} = 0;
$lut{1} = 1;

is($lut{0}, 2,  "extrapolate 0 -> 2");
is($lut{3}, -1,  "extrapolate 3 -> -1");

## option passing

my %lut2;

eval { tie %lut2, 'Tie::Hash::Interpolate', foo => 1 };
ok(!$@, 'opts: foo => 1');

eval { tie %lut2, 'Tie::Hash::Interpolate', extrapolate => 'foo' };
ok($@, 'opts: extrapolate => "foo"');

eval { tie %lut2, 'Tie::Hash::Interpolate', extrapolate => 'linear' };
ok(!$@, 'opts: extrapolate => "linear"');

%lut2 = ( 4 => 5, 6 => 7 );
is($lut2{3}, 4, 'opts: extrapolate => "linear", 3 -> 4');
is($lut2{5}, 6, 'opts: extrapolate => "linear", 5 -> 6');
is($lut2{7}, 8, 'opts: extrapolate => "linear", 7 -> 8');

eval { tie %lut2, 'Tie::Hash::Interpolate', extrapolate => 'fatal' };
ok(!$@, 'opts: extrapolate => "fatal"');

%lut2 = ( 4 => 5, 6 => 7 );
eval { my $foo = $lut2{3} };
ok($@, 'opts: extrapolate => "fatal", 3 -> croak');
is($lut2{5}, 6, 'opts: extrapolate => "fatal", 5 -> 6');
eval { my $foo = $lut2{7} };
ok($@, 'opts: extrapolate => "fatal", 7 -> croak');

eval { tie %lut2, 'Tie::Hash::Interpolate', extrapolate => 'constant' };
ok(!$@, 'opts: extrapolate => "constant"');

%lut2 = ( 4 => 5, 6 => 7 );
is($lut2{3}, 5, 'opts: extrapolate => "constant", 3 -> 5');
is($lut2{5}, 6, 'opts: extrapolate => "constant", 5 -> 6');
is($lut2{7}, 7, 'opts: extrapolate => "constant", 7 -> 7');

eval { tie %lut2, 'Tie::Hash::Interpolate', extrapolate => 'undef' };
ok(!$@, 'opts: extrapolate => "undef"');

%lut2 = ( 4 => 5, 6 => 7 );
is($lut2{3}, undef, 'opts: extrapolate => "undef", 3 -> undef');
is($lut2{5}, 6, 'opts: extrapolate => "undef", 5 -> 6');
is($lut2{7}, undef, 'opts: extrapolate => "undef", 7 -> undef');

## test constructor

my $lut = Tie::Hash::Interpolate->new(one_key => 'constant');

eval { undef = $lut->{2} };
ok($@, "too few keys");

## fetch-store non-numbers

eval { $lut->{foo} = 1 };
ok($@, "STORE non-number key");

eval { $lut->{1} = 'bar' };
ok($@, "STORE non-number value");

eval { my $foo = $lut->{'foo'} };
ok($@, "FETCH non-number key");

## fetch-store numbers

$lut->{1} = 2;
ok(1, "STORE number key-value");

is($lut->{1}, 2, "FETCH number key");

## constant tests

is($lut->{1.5}, 2, "extrapolate constant 1.5");
is($lut->{0.5}, 2, "extrapolate constant 0.5");

$lut->{3} = 4;

is($lut->{2}, 3,  "interpolate 2 -> 3");
is($lut->{0}, 1,  "extrapolate 0 -> 1");
is($lut->{-0}, 1, "extrapolate -0 -> 1");
is($lut->{-1}, 0, "extrapolate -1 -> 0");
is($lut->{4}, 5,  "extrapolate 4 -> 5");

