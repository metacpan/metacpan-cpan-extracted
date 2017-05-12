use Test::More tests => 10;

use Unicode::Escape;

my $escaper;

$escaper = Unicode::Escape->new("\x{e3}\x{81}\x{82}\x{e3}\x{81}\x{84}\x{e3}\x{81}\x{86}\x{e3}\x{81}\x{88}\x{e3}\x{81}\x{8a}");
is('\\u3042\\u3044\\u3046\\u3048\\u304a', $escaper->escape, 'default');
is('\\u3042\\u3044\\u3046\\u3048\\u304a', $escaper->escape, 'default');

$escaper = Unicode::Escape->new("\x{e3}\x{81}\x{82}\x{e3}\x{81}\x{84}\x{e3}\x{81}\x{86}\x{e3}\x{81}\x{88}\x{e3}\x{81}\x{8a}", 'utf8');
is('\\u3042\\u3044\\u3046\\u3048\\u304a', $escaper->escape, 'utf8');
is('\\u3042\\u3044\\u3046\\u3048\\u304a', $escaper->escape, 'utf8');

$escaper = Unicode::Escape->new("\x{82}\x{a0}\x{82}\x{a2}\x{82}\x{a4}\x{82}\x{a6}\x{82}\x{a8}", 'shiftjis');
is('\\u3042\\u3044\\u3046\\u3048\\u304a', $escaper->escape, 'shiftjis');
is('\\u3042\\u3044\\u3046\\u3048\\u304a', $escaper->escape, 'shiftjis');

$escaper = Unicode::Escape->new("\x{a4}\x{a2}\x{a4}\x{a4}\x{a4}\x{a6}\x{a4}\x{a8}\x{a4}\x{aa}", 'euc-jp');
is('\\u3042\\u3044\\u3046\\u3048\\u304a', $escaper->escape, 'euc-jp');
is('\\u3042\\u3044\\u3046\\u3048\\u304a', $escaper->escape, 'euc-jp');

$escaper = Unicode::Escape->new("abscefghijklmnoparstuvwxyz1234567890-^\\_:;!\x{a4}\x{a2}abscefghijklmnoparstuvwxyz1234567890-^\\_:;!\x{a4}\x{a4}\x{a4}\x{a6}\x{a4}\x{a8}\x{a4}\x{aa}abscefghijklmnoparstuvwxyz1234567890-^\\_:;!", 'euc-jp');
is('abscefghijklmnoparstuvwxyz1234567890-^\\_:;!\\u3042abscefghijklmnoparstuvwxyz1234567890-^\\_:;!\\u3044\\u3046\\u3048\\u304aabscefghijklmnoparstuvwxyz1234567890-^\\_:;!', $escaper->escape, 'euc-jp');
is('abscefghijklmnoparstuvwxyz1234567890-^\\_:;!\\u3042abscefghijklmnoparstuvwxyz1234567890-^\\_:;!\\u3044\\u3046\\u3048\\u304aabscefghijklmnoparstuvwxyz1234567890-^\\_:;!', $escaper->escape, 'euc-jp');
