#!/usr/bin/env perl -w

use strict;

use lib::abs qw(. ../lib);
use MyPackage;
use MyAnother;

my $o = MyPackage->new( arg1 => 'some value' );
my $x = MyAnother->new( arg1 => 'another value', arg3 => 'something' );
print $o->field1,"\n";
print $x->field1, ', ', $x->field3 ,"\n";

for ($o->field_list) {
	printf "object %s have field %s with value %s\n", ref $o, $_, $o->$_;
}

for ($x->field_list) {
	printf "object %s have field %s with value %s\n", ref $x, $_, $x->$_;
}
