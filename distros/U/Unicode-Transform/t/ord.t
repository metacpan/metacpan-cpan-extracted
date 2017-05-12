
BEGIN { $| = 1; print "1..100\n"; }

use Unicode::Transform ':ord';
use strict;
use warnings;

print "ok 1\n";

##### U+0000, 2..9

print ord_unicode("\x00") == 0
   ? "ok" : "not ok", " 2\n";

print ord_utf16le("\x00\x00") == 0
   ? "ok" : "not ok", " 3\n";

print ord_utf16be("\x00\x00") == 0
   ? "ok" : "not ok", " 4\n";

print ord_utf32le("\0\0\0\0") == 0
   ? "ok" : "not ok", " 5\n";

print ord_utf32be("\0\0\0\0") == 0
   ? "ok" : "not ok", " 6\n";

print ord_utf8("\x00") == 0
   ? "ok" : "not ok", " 7\n";

print ord_utf8mod("\x00") == 0
   ? "ok" : "not ok", " 8\n";

print ord_utfcp1047("\x00") == 0
   ? "ok" : "not ok", " 9\n";

##### undef, 10..17

print !defined ord_unicode("")
   ? "ok" : "not ok", " 10\n";

print !defined ord_utf16le("")
   ? "ok" : "not ok", " 11\n";

print !defined ord_utf16be("")
   ? "ok" : "not ok", " 12\n";

print !defined ord_utf32le("")
   ? "ok" : "not ok", " 13\n";

print !defined ord_utf32be("")
   ? "ok" : "not ok", " 14\n";

print !defined ord_utf8("")
   ? "ok" : "not ok", " 15\n";

print !defined ord_utf8mod("")
   ? "ok" : "not ok", " 16\n";

print !defined ord_utfcp1047("")
   ? "ok" : "not ok", " 17\n";

##### U+DFFF, 18..24

print ord_utf16le("\xFF\xDF") == 0xDFFF
   ? "ok" : "not ok", " 18\n";

print ord_utf16be("\xDF\xFF") == 0xDFFF
   ? "ok" : "not ok", " 19\n";

print ord_utf32le("\xFF\xDF\0\0") == 0xDFFF
   ? "ok" : "not ok", " 20\n";

print ord_utf32be("\0\0\xDF\xFF") == 0xDFFF
   ? "ok" : "not ok", " 21\n";

print ord_utf8("\xED\xBF\xBF") == 0xDFFF
   ? "ok" : "not ok", " 22\n";

print ord_utf8mod("\xF1\xB7\xBF\xBF") == 0xDFFF
   ? "ok" : "not ok", " 23\n";

print ord_utfcp1047("\xDD\x66\x73\x73") == 0xDFFF
   ? "ok" : "not ok", " 24\n";

##### U+FEFF, 25..32

print ord_unicode("\x{feff}") == 0xFEFF
   ? "ok" : "not ok", " 25\n";

print ord_utf16le("\xFF\xFE") == 0xFEFF
   ? "ok" : "not ok", " 26\n";

print ord_utf16be("\xFE\xFF") == 0xFEFF
   ? "ok" : "not ok", " 27\n";

print ord_utf32le("\xFF\xFE\0\0") == 0xFEFF
   ? "ok" : "not ok", " 28\n";

print ord_utf32be("\0\0\xFE\xFF") == 0xFEFF
   ? "ok" : "not ok", " 29\n";

print ord_utf8("\xEF\xBB\xBF") == 0xFEFF
   ? "ok" : "not ok", " 30\n";

print ord_utf8mod("\xF1\xBF\xB7\xBF") == 0xFEFF
   ? "ok" : "not ok", " 31\n";

print ord_utfcp1047("\xDD\x73\x66\x73") == 0xFEFF
   ? "ok" : "not ok", " 32\n";

##### U+12345, 33..40

print ord_unicode("\x{12345}") == 0x12345
   ? "ok" : "not ok", " 33\n";

print ord_utf16le("\x08\xD8\x45\xDF") == 0x12345
   ? "ok" : "not ok", " 34\n";

print ord_utf16be("\xD8\x08\xDF\x45") == 0x12345
   ? "ok" : "not ok", " 35\n";

print ord_utf32le("\x45\x23\x01\x00") == 0x12345
   ? "ok" : "not ok", " 36\n";

print ord_utf32be("\x00\x01\x23\x45") == 0x12345
   ? "ok" : "not ok", " 37\n";

print ord_utf8("\xF0\x92\x8D\x85") == 0x12345
   ? "ok" : "not ok", " 38\n";

print ord_utf8mod("\xF2\xA8\xBA\xA5") == 0x12345
   ? "ok" : "not ok", " 39\n";

print ord_utfcp1047("\xDE\x49\x69\x46") == 0x12345
   ? "ok" : "not ok", " 40\n";

##### U+10FFFF, 41..47

print ord_utf16le("\xFF\xDB\xFF\xDF") == 0x10FFFF
   ? "ok" : "not ok", " 41\n";

print ord_utf16be("\xDB\xFF\xDF\xFF") == 0x10FFFF
   ? "ok" : "not ok", " 42\n";

print ord_utf32le("\xFF\xFF\x10\x00") == 0x10FFFF
   ? "ok" : "not ok", " 43\n";

print ord_utf32be("\x00\x10\xFF\xFF") == 0x10FFFF
   ? "ok" : "not ok", " 44\n";

print ord_utf8("\xF4\x8F\xBF\xBF") == 0x10FFFF
   ? "ok" : "not ok", " 45\n";

print ord_utf8mod("\xF9\xA1\xBF\xBF\xBF") == 0x10FFFF
   ? "ok" : "not ok", " 46\n";

print ord_utfcp1047("\xEE\x42\x73\x73\x73") == 0x10FFFF
   ? "ok" : "not ok", " 47\n";

##### misc., 48..58

print ord_unicode("Perl") == 0x50
   ? "ok" : "not ok", " 48\n";

print ord_utf8("\x50\x65\x72\x6C") == 0x50
   ? "ok" : "not ok", " 49\n";

print ord_utf8("\320\261") == 0x0431
   ? "ok" : "not ok", " 50\n";

print ord_utf8("\316\261") == 0x03B1
   ? "ok" : "not ok", " 51\n";

print ord_utf8("\327\221") == 0x05D1
   ? "ok" : "not ok", " 52\n";

print ord_utf8("\360\220\221\215") == 0x1044D
   ? "ok" : "not ok", " 53\n";

print ord_utfcp1047("\301") == 0x41
   ? "ok" : "not ok", " 54\n";

print ord_utfcp1047("\270\102\130") == 0x0431
   ? "ok" : "not ok", " 55\n";

print ord_utfcp1047("\264\130") == 0x03B1
   ? "ok" : "not ok", " 56\n";

print ord_utfcp1047("\270\125\130") == 0x05D1
   ? "ok" : "not ok", " 57\n";

print ord_utfcp1047("\336\102\103\124") == 0x1044D
   ? "ok" : "not ok", " 58\n";

##### U+D800, 59..65

print ord_utf16le("\x00\xD8") == 0xD800
   ? "ok" : "not ok", " 59\n";

print ord_utf16be("\xD8\x00") == 0xD800
   ? "ok" : "not ok", " 60\n";

print ord_utf32le("\x00\xD8\0\0") == 0xD800
   ? "ok" : "not ok", " 61\n";

print ord_utf32be("\0\0\xD8\x00") == 0xD800
   ? "ok" : "not ok", " 62\n";

print ord_utf8("\xED\xA0\x80") == 0xD800
   ? "ok" : "not ok", " 63\n";

print ord_utf8mod("\xF1\xB6\xA0\xA0") == 0xD800
   ? "ok" : "not ok", " 64\n";

print ord_utfcp1047("\xDD\x65\x41\x41") == 0xD800
   ? "ok" : "not ok", " 65\n";

##### U+110000, 66..71

print ord_unicode("\x{110000}") == 0x110000
   ? "ok" : "not ok", " 66\n";

print ord_utf32le("\x00\x00\x11\x00") == 0x110000
   ? "ok" : "not ok", " 67\n";

print ord_utf32be("\x00\x11\x00\x00") == 0x110000
   ? "ok" : "not ok", " 68\n";

print ord_utf8("\xF4\x90\x80\x80") == 0x110000
   ? "ok" : "not ok", " 69\n";

print ord_utf8mod("\xF9\xA2\xA0\xA0\xA0") == 0x110000
   ? "ok" : "not ok", " 70\n";

print ord_utfcp1047("\xEE\x43\x41\x41\x41") == 0x110000
   ? "ok" : "not ok", " 71\n";

##### unicode 72..74

print ord_unicode("\x{1234567}") == 0x1234567
   ? "ok" : "not ok", " 72\n";

print ord_unicode("\x{12345678}") == 0x12345678
   ? "ok" : "not ok", " 73\n";

print ord_unicode("\x{7FFFFFFD}") == 0x7FFFFFFD
   ? "ok" : "not ok", " 74\n";

##### utf32le 75..77

print ord_utf32le("\x67\x45\x23\x01") == 0x1234567
   ? "ok" : "not ok", " 75\n";

print ord_utf32le("\x78\x56\x34\x12") == 0x12345678
   ? "ok" : "not ok", " 76\n";

print ord_utf32le("\xFF\xFF\xFF\x7F") == 0x7FFFFFFF
   ? "ok" : "not ok", " 77\n";

##### utf32be 78..80

print ord_utf32be("\x01\x23\x45\x67") == 0x1234567
   ? "ok" : "not ok", " 78\n";

print ord_utf32be("\x12\x34\x56\x78") == 0x12345678
   ? "ok" : "not ok", " 79\n";

print ord_utf32be("\x7F\xFF\xFF\xFF") == 0x7FFFFFFF
   ? "ok" : "not ok", " 80\n";

##### utf8 81..90

print ord_utf8("\xF4\xA3\x91\x96") == 0x123456
   ? "ok" : "not ok", " 81\n";

print ord_utf8("\xF8\x88\x80\x80\x80") == 0x200000
   ? "ok" : "not ok", " 82\n";

print ord_utf8("\xF9\x80\x80\x80\x80") == 0x1000000
   ? "ok" : "not ok", " 83\n";

print ord_utf8("\xF9\x88\xB4\x95\xA7") == 0x1234567
   ? "ok" : "not ok", " 84\n";

print ord_utf8("\xFB\xBF\xBF\xBF\xBF") == 0x3FFFFFF
   ? "ok" : "not ok", " 85\n";

print ord_utf8("\xFC\x84\x80\x80\x80\x80") == 0x4000000
   ? "ok" : "not ok", " 86\n";

print ord_utf8("\xFC\x8F\xBF\xBF\xBF\xBF") == 0xFFFFFFF
   ? "ok" : "not ok", " 87\n";

print ord_utf8("\xFC\x90\x80\x80\x80\x80") == 0x10000000
   ? "ok" : "not ok", " 88\n";

print ord_utf8("\xFC\x92\x8D\x85\x99\xB8") == 0x12345678
   ? "ok" : "not ok", " 89\n";

print ord_utf8("\xFD\xBF\xBF\xBF\xBF\xBF") == 0x7FFFFFFF
   ? "ok" : "not ok", " 90\n";

##### utf8mod 91..100

print ord_utf8mod("\xF8\xA8\xA0\xA0\xA0") == 0x40000
   ? "ok" : "not ok", " 91\n";

print ord_utf8mod("\xFB\xBF\xBF\xBF\xBF") == 0x3FFFFF
   ? "ok" : "not ok", " 92\n";

print ord_utf8mod("\xFC\xA4\xA0\xA0\xA0\xA0") == 0x400000
   ? "ok" : "not ok", " 93\n";

print ord_utf8mod("\xFC\xB2\xA6\xB1\xAB\xA7") == 0x1234567
   ? "ok" : "not ok", " 94\n";

print ord_utf8mod("\xFD\xBF\xBF\xBF\xBF\xBF") == 0x3FFFFFF
   ? "ok" : "not ok", " 95\n";

print ord_utf8mod("\xFE\xA2\xA0\xA0\xA0\xA0\xA0") == 0x4000000
   ? "ok" : "not ok", " 96\n";

print ord_utf8mod("\xFE\xA9\xA3\xA8\xB5\xB3\xB8") == 0x12345678
   ? "ok" : "not ok", " 97\n";

print ord_utf8mod("\xFE\xBF\xBF\xBF\xBF\xBF\xBF") == 0x3FFFFFFF
   ? "ok" : "not ok", " 98\n";

print ord_utf8mod("\xFF\xA0\xA0\xA0\xA0\xA0\xA0") == 0x40000000
   ? "ok" : "not ok", " 99\n";

print ord_utf8mod("\xFF\xBF\xBF\xBF\xBF\xBF\xBF") == 0x7FFFFFFF
   ? "ok" : "not ok", " 100\n";

