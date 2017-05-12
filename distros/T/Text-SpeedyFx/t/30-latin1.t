#!perl
use strict;
no utf8;
use warnings;

use Test::More;

use Data::Dumper;
use Text::SpeedyFx;

my $sfx = Text::SpeedyFx->new(42, 8);
binmode \*DATA => q(:raw);
local $/ = undef;
my $data = <DATA>;

is(utf8::is_utf8($data), '', q(is not UTF-8 internally));

my $r = $sfx->hash($data);

my $expect = {
    106041279   => 2,
    446277518   => 1,
    567119914   => 1,
    692962479   => 1,
    1060523967  => 1,
    1068328043  => 1,
    1310293311  => 2,
    1481219519  => 1,
    1707943522  => 1,
    1752231868  => 1,
    1779264938  => 1,
    2172581055  => 1,
    2193894889  => 1,
    2765318993  => 1,
    2793878206  => 1,
    2931454150  => 1,
    2963223177  => 1,
    3114580310  => 1,
    3337863185  => 1,
    3980716046  => 1,
    4007692458  => 1,
    4068256105  => 1,
};
my $n = scalar keys %$expect;

my $err = 0;
ok(
    $r->{$_} == $expect->{$_},
    qq(key $_ match)
) or ++$err for keys %$expect;

$Data::Dumper::Sortkeys = sub { [ sort { $a <=> $b } keys %{$_[0]} ] };
$err and diag(Dumper $r);

done_testing(1 + $n);

__DATA__
##############################################################################
À NOITE, VOVÔ KOWALSKY VÊ O ÍMÃ CAIR NO PÉ DO PINGÜIM
QUEIXOSO E VOVÓ PÕE AÇÚCAR NO CHÁ DE TÂMARAS DO JABUTI FELIZ.
##############################################################################
