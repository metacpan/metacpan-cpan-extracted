use Test::More tests => 2;

use Unicode::Escape;
my $str = '\\u3042\\u3044\\u3046\\u3048\\u304a';
my $escaper = Unicode::Escape->new($str); # $str contains escaped Unicode character.
my $unescaped1 = $escaper->unescape('shiftjis');
my $unescaped2 = $escaper->unescape;      # default is utf8.

is($unescaped1, "\x{82}\x{a0}\x{82}\x{a2}\x{82}\x{a4}\x{82}\x{a6}\x{82}\x{a8}", 'unencoded');
is($unescaped2, "\x{e3}\x{81}\x{82}\x{e3}\x{81}\x{84}\x{e3}\x{81}\x{86}\x{e3}\x{81}\x{88}\x{e3}\x{81}\x{8a}", 'unencoded');
