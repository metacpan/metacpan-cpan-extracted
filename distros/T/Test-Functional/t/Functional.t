#!/usr/bin/perl
package Foo;
sub new {}
1;

package Bar;
sub new {}
1;

package Bar2;
use base qw(Bar);
sub new {}
1;

package FooBar;
use base qw(Foo Bar);
sub new {}
1;

package main;

use warnings FATAL => 'all';
use strict;

use Test::Functional tests => 377;

# make sure an empty (or noop), non-dying test does not die
test { undef } "empty1";
test { undef } noop(), "empty2";

# basic sanity checks on same/diff
my %data = (
    num1     => 1,
    num2     => 0,
    num3     => 1.5,
    undef    => undef,
    three    => 3,
    str1     => '',
    str2     => 'foo',
    str3     => 'undef',
    array1   => [1,2,3],
    array2   => [],
    hash1    => {foo => 123},
    code1    => sub { print "something\n" },
    complex1 => {abc => [1,2,3], def => 45},
    complex2 => {a => 99, b => sub {}, c => [19]},
    # anonymous subs only compare to themselves
    complex3 => {a => 99, b => sub {}, c => [19]},
);

# make sure we're honestly following refs
$data{str4} = "$data{array1}";

# make sure we can handle circular refs
my @a = (1,2,3);
push(@a, \@a);
$data{array3} = \@a;

# make a slightly different complex structure
my %c = %{$data{complex2}};
$c{c} = [19, 20];
$data{complex4} = \%c;

# ok, so let's make sure things are the same (or different)
foreach my $key1 (keys(%data)) {
    foreach my $key2 (keys(%data)) {
        if($key1 eq $key2) {
            test { $data{$key1} } eqv($data{$key2}), "eqv($key1, $key2)";
            test { $data{$key1} } $data{$key2}, "implicit($key1, $key2)";
        } else {
            test { $data{$key1} } ineqv($data{$key2}), "ineqv($key1, $key2)";
        }
    }
}

# now let's check types
my @values = (
    [\33, qw(SCALAR)],
    [[], qw(ARRAY)],
    [{}, qw(HASH)],
    [sub {}, qw(CODE)],
    [\*STDIN, qw(GLOB)],
    [bless([], 'Foo'), qw(ARRAY Foo)],
    [bless({}, 'Foo'), qw(HASH Foo)],
    [bless({}, 'Bar'), qw(HASH Bar)],
    [bless({}, 'Bar2'), qw(HASH Bar Bar2)],
    [bless({}, 'FooBar'), qw(HASH Foo Bar FooBar)],
);

foreach my $tuple (@values) {
    my ($value, @types) = @$tuple;
    foreach my $type (@types) {
        test { $value } typeqv($type), "typeqv($value, $type)";
    }
}

# now let's try to die
test { die } dies(), "dies1";
test { my $i = 0; 4 / $i } dies(), "dies2";
test { require DoesNotExist } dies(), "dies3";
use Carp;
test { croak } dies(), "dies4";
test { confess } dies(), "dies5";

# test true and false
test { [] } true(), "true1";
test { 1 } true(), "true2";
test { 'foo' } true(), "true3";
test { undef } false(), "false1";
test { 0 } false(), "false2";
test { '' } false(), "false3";

# definedness
test { 13 } isdef(), "def1";
test { [] } isdef(), "def2";
test { '' } isdef(), "def3";
test { 0 } isdef(), "def4";
test { undef } isundef(), "undef1";
