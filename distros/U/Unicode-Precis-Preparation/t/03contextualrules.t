#-*- perl -*-
#-*- coding: utf-8 -*-

use strict;
use warnings;
use Test::More tests => 43;

use Unicode::Precis::Preparation qw(:all);

# Rule 1: ZERO WIDTH NON-JOINER

# CCC:Virama ZWNJ
ok(prepare("\x{1B44}\x{200C}", ValidUTF8, UnicodeVersion => '5.0'));
ok(prepare("\x{1B44}\x{200C}" => IdentifierClass, UnicodeVersion => '5.0'));
is_deeply(
    [   prepare(
            "\xE1\xAD\x84\xE2\x80\x8C" => IdentifierClass,
            UnicodeVersion             => 5.0
        )
    ],
    [result => PVALID, offset => 6]
);
is_deeply(
    [prepare("\x{1B44}\x{200C}" => IdentifierClass, UnicodeVersion => '5.0')],
    [result => PVALID, offset => 2]
);

# sos ZWNJ
ok(prepare("\x{200C}"));
ok(!prepare("\x{200C}" => IdentifierClass));
is_deeply([prepare("\xE2\x80\x8C" => IdentifierClass)],
    [result => CONTEXTJ, offset => 0, length => 3, ord => 0x200C]);
is_deeply([prepare("\x{200C}" => IdentifierClass)],
    [result => CONTEXTJ, offset => 0, length => 1, ord => 0x200C]);

# JT:D ZWNJ other
ok(!prepare("\x{0628}\x{200C}\x6C" => IdentifierClass));
is_deeply(
    [prepare("\xD8\xA8\xE2\x80\x8C\x6C" => IdentifierClass)],
    [result => CONTEXTJ, offset => 2, length => 3, ord => 0x200C]
);
is_deeply(
    [prepare("\x{0628}\x{200C}\x6C" => IdentifierClass)],
    [result => CONTEXTJ, offset => 1, length => 1, ord => 0x200C]
);

# JT:D JT:T * CCC:Virama ZWNJ other
ok(prepare("\x{0628}\x{094D}\x{200C}\x6C" => IdentifierClass));
is_deeply(
    [prepare("\xD8\xA8\xE0\xA5\x8D\xE2\x80\x8C\x6C" => IdentifierClass)],
    [result => PVALID, offset => 9]);
is_deeply([prepare("\x{0628}\x{094D}\x{200C}\x6C" => IdentifierClass)],
    [result => PVALID, offset => 4]);

# JT:D ZWNJ ZWNJ
ok(!prepare("\x{0628}\x{200C}\x{200C}" => IdentifierClass));
is_deeply(
    [prepare("\xD8\xA8\xE2\x80\x8C\xE2\x80\x8C" => IdentifierClass)],
    [result => CONTEXTJ, offset => 2, length => 3, ord => 0x200C]
);
is_deeply(
    [prepare("\x{0628}\x{200C}\x{200C}" => IdentifierClass)],
    [result => CONTEXTJ, offset => 1, length => 1, ord => 0x200C]
);

# JT:D ZWNJ eos
ok(!prepare("\x{0628}\x{200C}" => IdentifierClass));
is_deeply(
    [prepare("\xD8\xA8\xE2\x80\x8C" => IdentifierClass)],
    [result => CONTEXTJ, offset => 2, length => 3, ord => 0x200C]
);
is_deeply([prepare("\x{0628}\x{200C}" => IdentifierClass)],
    [result => CONTEXTJ, offset => 1, length => 1, ord => 0x200C]);

# JT:D ZWNJ JT:D ZWNJ eos
ok(!prepare("\x{0628}\x{200C}\x{0628}\x{200C}" => IdentifierClass));
is_deeply(
    [prepare("\xD8\xA8\xE2\x80\x8C\xD8\xA8\xE2\x80\x8C" => IdentifierClass)],
    [result => CONTEXTJ, offset => 7, length => 3, ord => 0x200C]
);
is_deeply(
    [prepare("\x{0628}\x{200C}\x{0628}\x{200C}" => IdentifierClass)],
    [result => CONTEXTJ, offset => 3, length => 1, ord => 0x200C]
);

# JT:D ZWNJ JT:D ZWNJ JT:R
ok(prepare("\x{0628}\x{200C}\x{0628}\x{200C}\x{0627}" => IdentifierClass));
is_deeply(
    [   prepare(
            "\xD8\xA8\xE2\x80\x8C\xD8\xA8\xE2\x80\x8C\xD8\xA7" =>
                IdentifierClass
        )
    ],
    [result => PVALID, offset => 12]
);
is_deeply(
    [prepare("\x{0628}\x{200C}\x{0628}\x{200C}\x{0627}" => IdentifierClass)],
    [result => PVALID, offset => 5]
);

# JT:D ZWNJ JT:R
ok(prepare("\x{0628}\x{200C}\x{0627}" => IdentifierClass));
is_deeply([prepare("\xD8\xA8\xE2\x80\x8C\xD8\xA7" => IdentifierClass)],
    [result => PVALID, offset => 7]);
is_deeply([prepare("\x{0628}\x{200C}\x{0627}" => IdentifierClass)],
    [result => PVALID, offset => 3]);

# JT:D ZWNJ JT:T JT:R
ok(prepare("\x{0628}\x{200C}\x{0652}\x{0627}" => IdentifierClass));
is_deeply(
    [prepare("\xD8\xA8\xE2\x80\x8C\xD9\x92\xD8\xA7" => IdentifierClass)],
    [result => PVALID, offset => 9]);
is_deeply([prepare("\x{0628}\x{200C}\x{0652}\x{0627}" => IdentifierClass)],
    [result => PVALID, offset => 4]);

# Rule 2: ZERO WIDTH JOINER

# CCC:Virama ZWJ
ok(prepare("\x{1B44}\x{200D}", ValidUTF8, UnicodeVersion => '5.0'));
ok(prepare("\x{1B44}\x{200D}" => IdentifierClass, UnicodeVersion => '5.0'));
is_deeply(
    [   prepare(
            "\xE1\xAD\x84\xE2\x80\x8D" => IdentifierClass,
            UnicodeVersion             => 5.0
        )
    ],
    [result => PVALID, offset => 6]
);
is_deeply(
    [prepare("\x{1B44}\x{200D}" => IdentifierClass, UnicodeVersion => '5.0')],
    [result => PVALID, offset => 2]
);

# sos ZWJ
ok(prepare("\x{200D}"));
ok(!prepare("\x{200D}" => IdentifierClass));
is_deeply([prepare("\xE2\x80\x8D" => IdentifierClass)],
    [result => CONTEXTJ, offset => 0, length => 3, ord => 0x200D]);
is_deeply([prepare("\x{200D}" => IdentifierClass)],
    [result => CONTEXTJ, offset => 0, length => 1, ord => 0x200D]);

# other ZWJ
ok(!prepare("\x6C\x{200D}" => IdentifierClass));
is_deeply([prepare("\x6C\xE2\x80\x8D" => IdentifierClass)],
    [result => CONTEXTJ, offset => 1, length => 3, ord => 0x200D]);
is_deeply([prepare("\x6C\x{200D}" => IdentifierClass)],
    [result => CONTEXTJ, offset => 1, length => 1, ord => 0x200D]);
