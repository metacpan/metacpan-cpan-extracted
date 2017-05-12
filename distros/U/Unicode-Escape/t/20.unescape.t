use Test::More tests => 6;

use Unicode::Escape;

is(Unicode::Escape::unescape('\\u3042\\u3044\\u3046\\u3048\\u304a'), "\x{e3}\x{81}\x{82}\x{e3}\x{81}\x{84}\x{e3}\x{81}\x{86}\x{e3}\x{81}\x{88}\x{e3}\x{81}\x{8a}", 'default');

is(Unicode::Escape::unescape('\\u3042\\u3044\\u3046\\u3048\\u304a', 'utf8'), "\x{e3}\x{81}\x{82}\x{e3}\x{81}\x{84}\x{e3}\x{81}\x{86}\x{e3}\x{81}\x{88}\x{e3}\x{81}\x{8a}", 'utf8');

is(Unicode::Escape::unescape('\\u3042\\u3044\\u3046\\u3048\\u304a', 'shiftjis'), "\x{82}\x{a0}\x{82}\x{a2}\x{82}\x{a4}\x{82}\x{a6}\x{82}\x{a8}", 'shiftjis');

is(Unicode::Escape::unescape('\\u3042\\u3044\\u3046\\u3048\\u304a', 'euc-jp'), "\x{a4}\x{a2}\x{a4}\x{a4}\x{a4}\x{a6}\x{a4}\x{a8}\x{a4}\x{aa}", 'euc-jp');

is(Unicode::Escape::unescape('abscefghijklmnoparstuvwxyz1234567890-^\\_:;!\\u3042abscefghijklmnoparstuvwxyz1234567890-^\\_:;!\\u3044\\u3046\\u3048\\u304aabscefghijklmnoparstuvwxyz1234567890-^\\_:;!', 'euc-jp'), "abscefghijklmnoparstuvwxyz1234567890-^\\_:;!\x{a4}\x{a2}abscefghijklmnoparstuvwxyz1234567890-^\\_:;!\x{a4}\x{a4}\x{a4}\x{a6}\x{a4}\x{a8}\x{a4}\x{aa}abscefghijklmnoparstuvwxyz1234567890-^\\_:;!", 'euc-jp');

is(Unicode::Escape::unescape('\\u3042\\u304\\u3046\\u3048\\u304a', 'shiftjis'), "\x{82}\x{a0}u304\x{82}\x{a4}\x{82}\x{a6}\x{82}\x{a8}", 'shiftjis');



