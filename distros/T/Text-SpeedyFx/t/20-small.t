#!perl
use strict;
use utf8;
use warnings;

use Data::Dumper;
use List::MoreUtils qw(distinct);
use Scalar::Util qw(looks_like_number);
use Test::More;

use Text::SpeedyFx;

my $sfx = Text::SpeedyFx->new(42);

# https://en.wikipedia.org/wiki/Pangram
my $str = q(
    The quick brown fox jumps over the lazy dog
    Pójdźże, kiń tę chmurność w głąb flaszy!
    Victor jagt zwölf Boxkämpfer quer über den großen Sylter Deich
    Любя, съешь щипцы, — вздохнёт мэр, — кайф жгуч
    أبجد هوَّز حُطّي كلَمُن سَعْفَص قُرِشَت ثَخَدٌ ضَظَغ
);
ok(utf8::is_utf8($str), q(is UTF-8 internally));

my $r = $sfx->hash($str);
isa_ok($r, q(HASH));

my $expect = {
    233612673   => 1,
    361173977   => 1,
    375571324   => 1,
    450365086   => 1,
    476041838   => 1,
    790081558   => 1,
    1055501457  => 1,
    1074402441  => 1,
    1455383497  => 1,
    1701518593  => 1,
    1802708649  => 1,
    1925711018  => 1,
    1942900801  => 1,
    2214686158  => 1,
    2300677314  => 1,
    2433942921  => 1,
    2462159897  => 1,
    2580649289  => 2,
    2871362774  => 1,
    2936382694  => 1,
    2960821342  => 1,
    2992615658  => 1,
    3032176301  => 1,
    3080456286  => 1,
    3288792329  => 1,
    3354234718  => 1,
    3395048046  => 1,
    3496632745  => 1,
    3567353219  => 1,
    3579496017  => 1,
    3579582238  => 1,
    3587762007  => 1,
    3588287806  => 1,
    3609843391  => 1,
    3825793069  => 1,
    3831083534  => 1,
    3888432779  => 1,
    3950120601  => 1,
    3969676878  => 1,
    4281426825  => 1
};
my $n = scalar keys %$expect;

my $m = scalar distinct map { lc } ($str =~ /(\w+)/gx);
is($m, $n, qq(tokenization via regexp gave us $m tokens));

ok(
    scalar keys %$r == $n,
    qq(same # of tokens ($n))
);

my $err = 0;
ok(
    $r->{$_} == $expect->{$_},
    qq(key $_ match)
) or ++$err for keys %$expect;

$Data::Dumper::Sortkeys = sub { [ sort { $a <=> $b } keys %{$_[0]} ] };
$err and diag(Dumper $r);

$r = $sfx->hash_fv($str, 64);

ok(
    length $r == 8,
    qq(same feature vector length (@{[ length $r ]}))
);

ok(
    unpack(q(b*), $r) eq q(0111000001010010010000110100001000000010011001100000000000001011),
    q(feature vector match)
);

$r = $sfx->hash_min($str);
ok(
    looks_like_number($r),
    qq(hash_min is number ($r))
);

ok(
    $r == 233612673,
    qq(hash_min match ($r))
);

done_testing(8 + $n);
