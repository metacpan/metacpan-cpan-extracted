#!/usr/bin/env perl
use strict;
use warnings;
use Test::More tests => 16;
use autobox::Closure::Attributes;

sub create_closure {
    my ($scalar, @array, %hash);

    return sub {
        my $want = shift;
        return $scalar if $want eq '$';
        return \@array if $want eq '@';
        return \%hash  if $want eq '%';

        die "Please pass a sigil to the closure!";
    };
}

my $scalar = '$scalar';
my $array  = '@array';
my $hash   = '%hash';

my $code = create_closure;
is($code->scalar, undef, "no value in the scalar yet");
$code->scalar(10);
is($code->scalar, 10, "scalar has a 10 in it now");

is($code->$scalar, 10, "can still stick a \$ on the method name and have it work");
is($code->${\'$scalar'}, $code->('$'), q{$code->${\\'$scalar} works!});

is_deeply($code->$array, [], "no elements in the array yet");
$code->$array(1, 2, 3);
is_deeply($code->$array, [1, 2, 3], "set the elements of the array");
is($code->$array, $code->('@'), '$code->$array returns exactly the same ref');
is($code->${\'@array'}, $code->('@'), q{$code->${\\'@array} works!});

is_deeply($code->$hash, {}, "no elements in the hash yet");
$code->$hash(foo => 1, bar => 2);
is_deeply($code->$hash, {foo => 1, bar => 2}, "set the elements of the hash");
is($code->$hash, $code->('%'), '$code->$array returns exactly the same ref');
is($code->${\'%hash'}, $code->('%'), q{$code->${\\'%hash} works!});

my $code2 = create_closure;
is($code2->$array, $code2->('@'), '$code->$array returns exactly the same ref');
is($code2->$hash, $code2->('%'), '$code->$hash returns exactly the same ref');

isnt($code->$array, $code2->$array, "different instances of the ref");
isnt($code->$hash, $code2->$hash, "different instances of the ref");
