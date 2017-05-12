use Test::More tests => 4;

use Unicode::Escape;
my $str1 = "\x{a4}\x{a2}\x{a4}\x{a4}\x{a4}\x{a6}\x{a4}\x{a8}\x{a4}\x{aa}";
my $str2 = "\x{e3}\x{81}\x{82}\x{e3}\x{81}\x{84}\x{e3}\x{81}\x{86}\x{e3}\x{81}\x{88}\x{e3}\x{81}\x{8a}";
my $str3 = '\\u3042\\u3044\\u3046\\u3048\\u304a';
my $str4 = '\\u3042\\u3044\\u3046\\u3048\\u304a';
my $escaped1 = Unicode::Escape::escape($str1, 'euc-jp');             # $str1 contains charactor that is not ASCII. $str1 is encoded by euc-jp.
my $escaped2 = Unicode::Escape::escape($str2);     # default is utf8 # $str2 contains charactor that is not ASCII.
my $unescaped1 = Unicode::Escape::unescape($str3, 'shiftjis');       # $str3 contains escaped Unicode character. return value is encoded by shiftjis.
my $unescaped2 = Unicode::Escape::unescape($str4); # default is utf8 # $str4 contains escaped Unicode character.

is($escaped1, '\\u3042\\u3044\\u3046\\u3048\\u304a', 'encoded');
is($escaped2, '\\u3042\\u3044\\u3046\\u3048\\u304a', 'encoded');
is($unescaped1, "\x{82}\x{a0}\x{82}\x{a2}\x{82}\x{a4}\x{82}\x{a6}\x{82}\x{a8}", 'unencoded');
is($unescaped2, "\x{e3}\x{81}\x{82}\x{e3}\x{81}\x{84}\x{e3}\x{81}\x{86}\x{e3}\x{81}\x{88}\x{e3}\x{81}\x{8a}", 'unencoded');
