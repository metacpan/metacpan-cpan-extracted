
BEGIN { $| = 1; print "1..17\n"; }

use Unicode::Transform ':all';
use strict;
use warnings;

print "ok 1\n";

#####

our %under = (
    uv => 0x1234ABCD,
    utf32le => "\xCD\xAB\x34\x12",
    utf32be => "\x12\x34\xAB\xCD",
);
our %above = (
    uv => 0xABCD1234,
    utf32le => "\x34\x12\xCD\xAB",
    utf32be => "\xAB\xCD\x12\x34",
);


#### conv : 2..9

print utf32le_to_utf32le(\&chr_utf32le, $under{utf32le}) eq $under{utf32le}
    ? "ok" : "not ok", " 2\n";

print utf32le_to_utf32be(\&chr_utf32be, $under{utf32le}) eq $under{utf32be}
    ? "ok" : "not ok", " 3\n";

print utf32be_to_utf32le(\&chr_utf32le, $under{utf32be}) eq $under{utf32le}
    ? "ok" : "not ok", " 4\n";

print utf32be_to_utf32be(\&chr_utf32be, $under{utf32be}) eq $under{utf32be}
    ? "ok" : "not ok", " 5\n";

print utf32le_to_utf32le(\&chr_utf32le, $above{utf32le}) eq $above{utf32le}
    ? "ok" : "not ok", " 6\n";

print utf32le_to_utf32be(\&chr_utf32be, $above{utf32le}) eq $above{utf32be}
    ? "ok" : "not ok", " 7\n";

print utf32be_to_utf32le(\&chr_utf32le, $above{utf32be}) eq $above{utf32le}
    ? "ok" : "not ok", " 8\n";

print utf32be_to_utf32be(\&chr_utf32be, $above{utf32be}) eq $above{utf32be}
    ? "ok" : "not ok", " 9\n";

#### chr : 10..13

print ord_utf32le($under{utf32le}) == $under{uv}
    ? "ok" : "not ok", " 10\n";

print ord_utf32be($under{utf32be}) == $under{uv}
    ? "ok" : "not ok", " 11\n";

print ord_utf32le($above{utf32le}) == $above{uv}
    ? "ok" : "not ok", " 12\n";

print ord_utf32be($above{utf32be}) == $above{uv}
    ? "ok" : "not ok", " 13\n";

#### chr : 14..17

print chr_utf32le($under{uv}) eq $under{utf32le}
    ? "ok" : "not ok", " 14\n";

print chr_utf32be($under{uv}) eq $under{utf32be}
    ? "ok" : "not ok", " 15\n";

print chr_utf32le($above{uv}) eq $above{utf32le}
    ? "ok" : "not ok", " 16\n";

print chr_utf32be($above{uv}) eq $above{utf32be}
    ? "ok" : "not ok", " 17\n";

####
1;
