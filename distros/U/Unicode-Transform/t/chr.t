
BEGIN { $| = 1; print "1..100\n"; }

use Unicode::Transform ':chr';
use strict;
use warnings;

print "ok 1\n";

##### U+0000, 2..9

print chr_unicode(0) eq "\x00"
   ? "ok" : "not ok", " 2\n";

print chr_utf16le(0) eq "\x00\x00"
   ? "ok" : "not ok", " 3\n";

print chr_utf16be(0) eq "\x00\x00"
   ? "ok" : "not ok", " 4\n";

print chr_utf32le(0) eq "\0\0\0\0"
   ? "ok" : "not ok", " 5\n";

print chr_utf32be(0) eq "\0\0\0\0"
   ? "ok" : "not ok", " 6\n";

print chr_utf8(0) eq "\x00"
   ? "ok" : "not ok", " 7\n";

print chr_utf8mod(0) eq "\x00"
   ? "ok" : "not ok", " 8\n";

print chr_utfcp1047(0) eq "\x00"
   ? "ok" : "not ok", " 9\n";

##### U+D800, 10..16

print chr_utf16le(0xD800) eq "\x00\xD8"
   ? "ok" : "not ok", " 10\n";

print chr_utf16be(0xD800) eq "\xD8\x00"
   ? "ok" : "not ok", " 11\n";

print chr_utf32le(0xD800) eq "\x00\xD8\0\0"
   ? "ok" : "not ok", " 12\n";

print chr_utf32be(0xD800) eq "\0\0\xD8\x00"
   ? "ok" : "not ok", " 13\n";

print chr_utf8(0xD800) eq "\xED\xA0\x80"
   ? "ok" : "not ok", " 14\n";

print chr_utf8mod(0xD800) eq "\xF1\xB6\xA0\xA0"
   ? "ok" : "not ok", " 15\n";

print chr_utfcp1047(0xD800) eq "\xDD\x65\x41\x41"
   ? "ok" : "not ok", " 16\n";

##### U+DFFF, 17..23

print chr_utf16le(0xDFFF) eq "\xFF\xDF"
   ? "ok" : "not ok", " 17\n";

print chr_utf16be(0xDFFF) eq "\xDF\xFF"
   ? "ok" : "not ok", " 18\n";

print chr_utf32le(0xDFFF) eq "\xFF\xDF\0\0"
   ? "ok" : "not ok", " 19\n";

print chr_utf32be(0xDFFF) eq "\0\0\xDF\xFF"
   ? "ok" : "not ok", " 20\n";

print chr_utf8(0xDFFF) eq "\xED\xBF\xBF"
   ? "ok" : "not ok", " 21\n";

print chr_utf8mod(0xDFFF) eq "\xF1\xB7\xBF\xBF"
   ? "ok" : "not ok", " 22\n";

print chr_utfcp1047(0xDFFF) eq "\xDD\x66\x73\x73"
   ? "ok" : "not ok", " 23\n";

##### U+FEFF, 24..31

print chr_unicode(0xFEFF) eq "\x{feff}"
   ? "ok" : "not ok", " 24\n";

print chr_utf16le(0xFEFF) eq "\xFF\xFE"
   ? "ok" : "not ok", " 25\n";

print chr_utf16be(0xFEFF) eq "\xFE\xFF"
   ? "ok" : "not ok", " 26\n";

print chr_utf32le(0xFEFF) eq "\xFF\xFE\0\0"
   ? "ok" : "not ok", " 27\n";

print chr_utf32be(0xFEFF) eq "\0\0\xFE\xFF"
   ? "ok" : "not ok", " 28\n";

print chr_utf8(0xFEFF) eq "\xEF\xBB\xBF"
   ? "ok" : "not ok", " 29\n";

print chr_utf8mod(0xFEFF) eq "\xF1\xBF\xB7\xBF"
   ? "ok" : "not ok", " 30\n";

print chr_utfcp1047(0xFEFF) eq "\xDD\x73\x66\x73"
   ? "ok" : "not ok", " 31\n";

##### U+12345, 32..39

print chr_unicode(0x12345) eq "\x{12345}"
   ? "ok" : "not ok", " 32\n";

print chr_utf16le(0x12345) eq "\x08\xD8\x45\xDF"
   ? "ok" : "not ok", " 33\n";

print chr_utf16be(0x12345) eq "\xD8\x08\xDF\x45"
   ? "ok" : "not ok", " 34\n";

print chr_utf32le(0x12345) eq "\x45\x23\x01\x00"
   ? "ok" : "not ok", " 35\n";

print chr_utf32be(0x12345) eq "\x00\x01\x23\x45"
   ? "ok" : "not ok", " 36\n";

print chr_utf8(0x12345) eq "\xF0\x92\x8D\x85"
   ? "ok" : "not ok", " 37\n";

print chr_utf8mod(0x12345) eq "\xF2\xA8\xBA\xA5"
   ? "ok" : "not ok", " 38\n";

print chr_utfcp1047(0x12345) eq "\xDE\x49\x69\x46"
   ? "ok" : "not ok", " 39\n";

##### U+10FFFF, 40..46

print chr_utf16le(0x10FFFF) eq "\xFF\xDB\xFF\xDF"
   ? "ok" : "not ok", " 40\n";

print chr_utf16be(0x10FFFF) eq "\xDB\xFF\xDF\xFF"
   ? "ok" : "not ok", " 41\n";

print chr_utf32le(0x10FFFF) eq "\xFF\xFF\x10\x00"
   ? "ok" : "not ok", " 42\n";

print chr_utf32be(0x10FFFF) eq "\x00\x10\xFF\xFF"
   ? "ok" : "not ok", " 43\n";

print chr_utf8(0x10FFFF) eq "\xF4\x8F\xBF\xBF"
   ? "ok" : "not ok", " 44\n";

print chr_utf8mod(0x10FFFF) eq "\xF9\xA1\xBF\xBF\xBF"
   ? "ok" : "not ok", " 45\n";

print chr_utfcp1047(0x10FFFF) eq "\xEE\x42\x73\x73\x73"
   ? "ok" : "not ok", " 46\n";

##### misc., 47..55

print chr_utf8(0x0431) eq "\320\261"
   ? "ok" : "not ok", " 47\n";

print chr_utf8(0x03B1) eq "\316\261"
   ? "ok" : "not ok", " 48\n";

print chr_utf8(0x05D1) eq "\327\221"
   ? "ok" : "not ok", " 49\n";

print chr_utf8(0x1044D) eq "\360\220\221\215"
   ? "ok" : "not ok", " 50\n";

print chr_utfcp1047(0x41) eq "\301"
   ? "ok" : "not ok", " 51\n";

print chr_utfcp1047(0x0431) eq "\270\102\130"
   ? "ok" : "not ok", " 52\n";

print chr_utfcp1047(0x03B1) eq "\264\130"
   ? "ok" : "not ok", " 53\n";

print chr_utfcp1047(0x05D1) eq "\270\125\130"
   ? "ok" : "not ok", " 54\n";

print chr_utfcp1047(0x1044D) eq "\336\102\103\124"
   ? "ok" : "not ok", " 55\n";

##### U+110000, 56..63

print chr_unicode(0x110000) eq "\x{110000}"
   ? "ok" : "not ok", " 56\n";

print !defined chr_utf16le(0x110000)
   ? "ok" : "not ok", " 57\n";

print !defined chr_utf16be(0x110000)
   ? "ok" : "not ok", " 58\n";

print chr_utf32le(0x110000) eq "\x00\x00\x11\x00"
   ? "ok" : "not ok", " 59\n";

print chr_utf32be(0x110000) eq "\x00\x11\x00\x00"
   ? "ok" : "not ok", " 60\n";

print chr_utf8(0x110000) eq "\xF4\x90\x80\x80"
   ? "ok" : "not ok", " 61\n";

print chr_utf8mod(0x110000) eq "\xF9\xA2\xA0\xA0\xA0"
   ? "ok" : "not ok", " 62\n";

print chr_utfcp1047(0x110000) eq "\xEE\x43\x41\x41\x41"
   ? "ok" : "not ok", " 63\n";

##### unicode 64..69

print chr_unicode(0x2080A0) eq "\x{2080A0}"
   ? "ok" : "not ok", " 64\n";

print chr_unicode(0xABCDEF) eq "\x{abcdef}"
   ? "ok" : "not ok", " 65\n";

print chr_unicode(0x1000000) eq "\x{1000000}"
   ? "ok" : "not ok", " 66\n";

print chr_unicode(0x1234567) eq "\x{1234567}"
   ? "ok" : "not ok", " 67\n";

print chr_unicode(0x12345678) eq "\x{12345678}"
   ? "ok" : "not ok", " 68\n";

print chr_unicode(0x7FFFFFFD) eq "\x{7ffffffd}"
   ? "ok" : "not ok", " 69\n";

##### utf32le 70..75

print chr_utf32le(0x2080A0) eq "\xA0\x80\x20\x00"
   ? "ok" : "not ok", " 70\n";

print chr_utf32le(0xFFFFFF) eq "\xFF\xFF\xFF\x00"
   ? "ok" : "not ok", " 71\n";

print chr_utf32le(0x1000000) eq "\x00\x00\x00\x01"
   ? "ok" : "not ok", " 72\n";

print chr_utf32le(0x1234567) eq "\x67\x45\x23\x01"
   ? "ok" : "not ok", " 73\n";

print chr_utf32le(0x12345678) eq "\x78\x56\x34\x12"
   ? "ok" : "not ok", " 74\n";

print chr_utf32le(0x7FFFFFFF) eq "\xFF\xFF\xFF\x7F"
   ? "ok" : "not ok", " 75\n";

##### utf32be 76..80

print chr_utf32be(0x2080A0) eq "\x00\x20\x80\xA0"
   ? "ok" : "not ok", " 76\n";

print chr_utf32be(0xFFFFFF) eq "\x00\xFF\xFF\xFF"
   ? "ok" : "not ok", " 77\n";

print chr_utf32be(0x1234567) eq "\x01\x23\x45\x67"
   ? "ok" : "not ok", " 78\n";

print chr_utf32be(0x12345678) eq "\x12\x34\x56\x78"
   ? "ok" : "not ok", " 79\n";

print chr_utf32be(0x7FFFFFFF) eq "\x7F\xFF\xFF\xFF"
   ? "ok" : "not ok", " 80\n";

##### utf8 81..90

print chr_utf8(0x123456) eq "\xF4\xA3\x91\x96"
   ? "ok" : "not ok", " 81\n";

print chr_utf8(0x200000) eq "\xF8\x88\x80\x80\x80"
   ? "ok" : "not ok", " 82\n";

print chr_utf8(0x1000000) eq "\xF9\x80\x80\x80\x80"
   ? "ok" : "not ok", " 83\n";

print chr_utf8(0x1234567) eq "\xF9\x88\xB4\x95\xA7"
   ? "ok" : "not ok", " 84\n";

print chr_utf8(0x3FFFFFF) eq "\xFB\xBF\xBF\xBF\xBF"
   ? "ok" : "not ok", " 85\n";

print chr_utf8(0x4000000) eq "\xFC\x84\x80\x80\x80\x80"
   ? "ok" : "not ok", " 86\n";

print chr_utf8(0xFFFFFFF) eq "\xFC\x8F\xBF\xBF\xBF\xBF"
   ? "ok" : "not ok", " 87\n";

print chr_utf8(0x10000000) eq "\xFC\x90\x80\x80\x80\x80"
   ? "ok" : "not ok", " 88\n";

print chr_utf8(0x12345678) eq "\xFC\x92\x8D\x85\x99\xB8"
   ? "ok" : "not ok", " 89\n";

print chr_utf8(0x7FFFFFFF) eq "\xFD\xBF\xBF\xBF\xBF\xBF"
   ? "ok" : "not ok", " 90\n";

##### utf8mod 91..100

print chr_utf8mod(0x40000) eq "\xF8\xA8\xA0\xA0\xA0"
   ? "ok" : "not ok", " 91\n";

print chr_utf8mod(0x3FFFFF) eq "\xFB\xBF\xBF\xBF\xBF"
   ? "ok" : "not ok", " 92\n";

print chr_utf8mod(0x400000) eq "\xFC\xA4\xA0\xA0\xA0\xA0"
   ? "ok" : "not ok", " 93\n";

print chr_utf8mod(0x1234567) eq "\xFC\xB2\xA6\xB1\xAB\xA7"
   ? "ok" : "not ok", " 94\n";

print chr_utf8mod(0x3FFFFFF) eq "\xFD\xBF\xBF\xBF\xBF\xBF"
   ? "ok" : "not ok", " 95\n";

print chr_utf8mod(0x4000000) eq "\xFE\xA2\xA0\xA0\xA0\xA0\xA0"
   ? "ok" : "not ok", " 96\n";

print chr_utf8mod(0x12345678) eq "\xFE\xA9\xA3\xA8\xB5\xB3\xB8"
   ? "ok" : "not ok", " 97\n";

print chr_utf8mod(0x3FFFFFFF) eq "\xFE\xBF\xBF\xBF\xBF\xBF\xBF"
   ? "ok" : "not ok", " 98\n";

print chr_utf8mod(0x40000000) eq "\xFF\xA0\xA0\xA0\xA0\xA0\xA0"
   ? "ok" : "not ok", " 99\n";

print chr_utf8mod(0x7FFFFFFF) eq "\xFF\xBF\xBF\xBF\xBF\xBF\xBF"
   ? "ok" : "not ok", " 100\n";

