use Test::More tests => 1;

use Unicode::Escape;
my $str = "\x{82}\x{a0}\x{82}\x{a2}\x{82}\x{a4}\x{82}\x{a6}\x{82}\x{a8}";
my $escaper = Unicode::Escape->new($str, 'shiftjis'); # $str contains charactor that is not ASCII. $str is encoded by shiftjis.(default is utf8)
my $escaped = $escaper->escape;

is($escaped, '\\u3042\\u3044\\u3046\\u3048\\u304a', 'encoded');
