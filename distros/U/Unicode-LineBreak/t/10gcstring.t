use Test::More;
use Unicode::GCString;

BEGIN { plan tests => 37 }

($s, $r) = (pack('U*', 0x300, 0, 0x0D, 0x41, 0x300, 0x301, 0x3042, 0xD, 0xA,
		 0xAC00, 0x11A8),
	    pack('U*', 0xAC00, 0x11A8, 0xD, 0xA, 0x3042, 0x41, 0x300, 0x301,
		 0xD, 0, 0x300));
$string = Unicode::GCString->new($s);
is($string->length, 7);
is($string->columns, 5);
is($string->chars, 11);

is($r, Unicode::GCString->new(join '', reverse map {$_->[0]} @{$string})->as_string);

$string = Unicode::GCString->new(
    pack('U*', 0x1112, 0x1161, 0x11AB, 0x1100, 0x1173, 0x11AF));
is($string->length, 2);
is($string->columns, 4);
is($string->chars, 6);

is($string, $string->copy);

$s1 = pack('U*', 0x1112, 0x1161);
$s2 = pack('U*', 0x11AB, 0x1100, 0x1173, 0x11AF);
$g1 = Unicode::GCString->new($s1);
$g2 = Unicode::GCString->new($s2);
is($g1.$g2, $string);
is(($g1.$g2)->length, 2);
is(($g1.$g2)->columns, 4);
is($string->chars, 6);
is($g1.$s2, $string);
is(($g1.$s2)->length, 2);
is(($g1.$s2)->columns, 4);
is($string->chars, 6);
is($s1.$g2, $string);
is(($s1.$g2)->length, 2);
is(($s1.$g2)->columns, 4);
is($string->chars, 6);
$s1 .= $g2;
is($s1, $string);
$g1 .= $s2;
is($g1, $string);

is($string->substr(1), pack('U*', 0x1100, 0x1173, 0x11AF));
is($string->substr(-1), pack('U*', 0x1100, 0x1173, 0x11AF));
is($string->substr(0, -1), pack('U*', 0x1112, 0x1161, 0x11AB));
$string->substr(-1, 1, "A");
is($string, pack('U*', 0x1112, 0x1161, 0x11AB, 0x41));
$string->substr(2, 0, "B");
is($string, pack('U*', 0x1112, 0x1161, 0x11AB, 0x41, 0x42));
$string->substr(0, 0, "C");
is($string, pack('U*', 0x43, 0x1112, 0x1161, 0x11AB, 0x41, 0x42));

@s = (pack('U*', 0x300), pack('U*', 0), pack('U*', 0x0D),
      pack('U*', 0x41, 0x300, 0x301), pack('U*', 0x3042), pack('U*', 0xD, 0xA),
      pack('U*', 0xAC00, 0x11A8));
$string = Unicode::GCString->new(join '', @s);
while ($gc = <$string>) {
    is($gc, shift @s);
}

my $number = Unicode::GCString->new(5);
is($number->columns, 1, 'number "5"');
$number = Unicode::GCString->new(0);
is($number->columns, 1, 'number "0"');
