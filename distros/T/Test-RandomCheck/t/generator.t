use strict;
use warnings;
use Scalar::Util ();
use Test::RandomCheck;
use Test::RandomCheck::Generator;
use Test::More;

random_ok { ! grep { $_ < 20 || 30 < $_  } @_ } list (integer 20, 30);
random_ok { $_[0] =~ /^[a-zA-Z]$/ } char;
random_ok { $_[0] =~ /^[a-zA-Z]{30,40}$/ } string 30, 40;
random_ok {
    my ($string, @list) = @_;
    $string =~ /^[a-zA-Z]*$/ && ! grep { $_ < 1 || 5 < $_ } @list;
} string, list (integer 1, 5);

random_ok {
    my $hash = shift;
    ref $hash eq 'HASH' && ! grep { $_ < 50 || 60 < $_ } values %$hash;
} hash_ref string(10, 15), integer(50, 60), 5, 10;

random_ok {
    my $array = shift;
    ref $array eq 'ARRAY' && ! grep { ! /^[a-z]$/ } @$array;
} array_ref(enum('a' .. 'z'), 5, 10);

random_ok {
    my $data = shift;
    ref $data eq 'ARRAY' && ! grep { ! ref $_ eq 'HASH' } @$data;
} array_ref(
    hash_ref(
        string() => array_ref(enum qw(True False))
    ), 5, 10
);

random_ok {
    my ($f, $x) = @_;
    Scalar::Util::looks_like_number($f->($x)) && $f->($x) == $f->($x);
} function (integer, integer), integer;

random_ok {
    my ($f, $x, $y) = @_;
    Scalar::Util::looks_like_number($f->($x)->($y))
                                           && $f->($x)->($y) == $f->($x)->($y);
} function (integer, function (integer, integer)), integer, integer;

random_ok {
    my ($f, $g) = @_;
    Scalar::Util::looks_like_number($f->($g)) && $f->($g) == $f->($g);
} function (function (integer, integer), integer), function (integer, integer);

random_ok {
    my ($f, @x) = @_;
    Scalar::Util::looks_like_number($f->(@x)) && $f->(@x) == $f->(@x);
} function(list(integer), integer), list integer;

random_ok {
    my ($f, $c) = @_;
    length $f->($c) == 1 && $f->($c) eq $f->($c);
} function(char, char), char;

random_ok {
    my ($f, $item) = @_;
    $f->($item) =~ /^[xyz]$/ && $f->($item) eq $f->($item);
} function (enum (qw[a b c]), enum (qw[x y z])), enum (qw[a b c]);

random_ok {
    my ($f, $n) = @_;
    length $f->($n) == 1 && $f->($n) eq $f->($n);
} function (integer (10, 20), char), integer (10, 20);

my $type_int_char = concat (integer, char);
random_ok {
    my ($f, $n, $c) = @_;
    Scalar::Util::looks_like_number($f->($n, $c))
                                               && $f->($n, $c) == $f->($n, $c);
} function ($type_int_char, integer), $type_int_char;

my $type_int_char_enum = concat (integer, char, enum qw[True False]);
random_ok {
    my ($f, $n, $c, $e) = @_;
    Scalar::Util::looks_like_number($f->($n, $c, $e))
                                       && $f->($n, $c, $e) == $f->($n, $c, $e);
} function ($type_int_char_enum, integer), $type_int_char_enum;

random_ok {
    my ($f, $array_ref) = @_;
    ref $f->($array_ref) eq 'HASH'
                                 && eq_hash $f->($array_ref), $f->($array_ref);
} function (array_ref (char), hash_ref (char, char)), array_ref char;

random_ok {
    my ($f, $str) = @_;
    Scalar::Util::looks_like_number($f->($str)) && $f->($str) == $f->($str);
} function (string, integer), string;

random_ok {
    my ($f, $hash_ref) = @_;
    ref $f->($hash_ref) eq 'ARRAY'
                                  && eq_array $f->($hash_ref), $f->($hash_ref);
} function (hash_ref (char, char), array_ref (integer)), hash_ref (char, char);

ok Scalar::Util::looks_like_number $_->[0] for integer->sample;

done_testing;
