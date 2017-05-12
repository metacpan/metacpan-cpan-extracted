
BEGIN { $| = 1; print "1..56\n"; }

use Unicode::Transform;
use strict;
use warnings;

####

print "" eq unicode_to_utf16le("")
  ? "ok" : "not ok", " 1\n";
print "\x41\0\x42\0\x43\0" eq unicode_to_utf16le("ABC")
  ? "ok" : "not ok", " 2\n";
print "" eq unicode_to_utf16be("")
  ? "ok" : "not ok", " 3\n";
print "\0\x41\0\x42\0\x43" eq unicode_to_utf16be("ABC")
  ? "ok" : "not ok", " 4\n";

print "" eq utf16be_to_unicode("")
  ? "ok" : "not ok", " 5\n";
print "ABC" eq utf16be_to_unicode("\0\x41\0\x42\0\x43")
  ? "ok" : "not ok", " 6\n";
print "" eq utf16le_to_unicode("")
  ? "ok" : "not ok", " 7\n";
print "ABC" eq utf16le_to_unicode("\x41\0\x42\0\x43\0")
  ? "ok" : "not ok", " 8\n";

print "" eq unicode_to_utf16le(sub {""}, "")
  ? "ok" : "not ok", " 9\n";
print "\x41\0\x42\0\x43\0" eq unicode_to_utf16le(sub {""}, "ABC")
  ? "ok" : "not ok", " 10\n";
print "" eq unicode_to_utf16be(sub {""}, "")
  ? "ok" : "not ok", " 11\n";
print "\0\x41\0\x42\0\x43" eq unicode_to_utf16be(sub {""}, "ABC")
  ? "ok" : "not ok", " 12\n";

print "" eq utf16be_to_unicode(sub {""}, "")
  ? "ok" : "not ok", " 13\n";
print "ABC" eq utf16be_to_unicode(sub {""}, "\0\x41\0\x42\0\x43")
  ? "ok" : "not ok", " 14\n";
print"" eq utf16le_to_unicode(sub {""}, "")
  ? "ok" : "not ok", " 15\n";
print "ABC" eq utf16le_to_unicode(sub {""}, "\x41\0\x42\0\x43\0")
  ? "ok" : "not ok", " 16\n";

our $unicode = "\x{10000}a\x{12345}z\x{10fffc}\x{4E00}";

our $utf16be = pack 'n*',
    0xd800, 0xdc00, 0x61, 0xD808, 0xDF45, 0x7a, 0xdbff, 0xdffc, 0x4E00;
our $utf16le = pack 'v*',
    0xd800, 0xdc00, 0x61, 0xD808, 0xDF45, 0x7a, 0xdbff, 0xdffc, 0x4E00;
our $utf32be = pack 'N*', 0x10000, 0x61, 0x12345, 0x7a, 0x10fffc, 0x4E00;
our $utf32le = pack 'V*', 0x10000, 0x61, 0x12345, 0x7a, 0x10fffc, 0x4E00;

print $unicode eq utf16be_to_unicode($utf16be)
  ? "ok" : "not ok", " 17\n";
print $unicode eq utf16le_to_unicode($utf16le)
  ? "ok" : "not ok", " 18\n";
print $utf16be eq unicode_to_utf16be($unicode)
  ? "ok" : "not ok", " 19\n";
print $utf16le eq unicode_to_utf16le($unicode)
  ? "ok" : "not ok", " 20\n";

print $unicode eq utf32be_to_unicode($utf32be)
  ? "ok" : "not ok", " 21\n";
print $unicode eq utf32le_to_unicode($utf32le)
  ? "ok" : "not ok", " 22\n";
print $utf32be eq unicode_to_utf32be($unicode)
  ? "ok" : "not ok", " 23\n";
print $utf32le eq unicode_to_utf32le($unicode)
  ? "ok" : "not ok", " 24\n";

our $u8_long = "\x00" x 5000;
our $u32long = "\x00" x 20000;

print $u8_long eq utf32be_to_unicode($u32long)
  ? "ok" : "not ok", " 25\n";
print $u32long eq unicode_to_utf32be($u8_long)
  ? "ok" : "not ok", " 26\n";

print "\xef\xbb\xbf" eq unicode_to_utf8("\x{feff}")
  ? "ok" : "not ok", " 27\n";
print "\x{feff}" eq utf8_to_unicode("\xef\xbb\xbf")
  ? "ok" : "not ok", " 28\n";
print "\xf1\xbf\xb7\xbf" eq unicode_to_utf8mod("\x{feff}")
  ? "ok" : "not ok", " 29\n";
print "\x{feff}" eq utf8mod_to_unicode("\xf1\xbf\xb7\xbf")
  ? "ok" : "not ok", " 30\n";
print "\xdd\x73\x66\x73" eq unicode_to_utfcp1047("\x{feff}")
  ? "ok" : "not ok", " 31\n";
print "\x{feff}" eq utfcp1047_to_unicode("\xdd\x73\x66\x73")
  ? "ok" : "not ok", " 32\n";

# 33..48 are from Perl 5.8.0 lib/charnames.t
print "\320\261" eq unicode_to_utf8("\x{0431}")
  ? "ok" : "not ok", " 33\n";
print "\316\261" eq unicode_to_utf8("\x{03B1}")
  ? "ok" : "not ok", " 34\n";
print "\327\221" eq unicode_to_utf8("\x{05D1}")
  ? "ok" : "not ok", " 35\n";
print "\360\220\221\215" eq unicode_to_utf8("\x{1044D}")
  ? "ok" : "not ok", " 36\n";

print "\x{0431}" eq utf8_to_unicode("\320\261")
  ? "ok" : "not ok", " 37\n";
print "\x{03B1}" eq utf8_to_unicode("\316\261")
  ? "ok" : "not ok", " 38\n";
print "\x{05D1}" eq utf8_to_unicode("\327\221")
  ? "ok" : "not ok", " 39\n";
print "\x{1044D}" eq utf8_to_unicode("\360\220\221\215")
  ? "ok" : "not ok", " 40\n";

print "\270\102\130" eq unicode_to_utfcp1047("\x{0431}")
  ? "ok" : "not ok", " 41\n";
print "\264\130" eq unicode_to_utfcp1047("\x{03B1}")
  ? "ok" : "not ok", " 42\n";
print "\270\125\130" eq unicode_to_utfcp1047("\x{05D1}")
  ? "ok" : "not ok", " 43\n";
print "\336\102\103\124" eq unicode_to_utfcp1047("\x{1044D}")
  ? "ok" : "not ok", " 44\n";

print "\x{0431}" eq utfcp1047_to_unicode("\270\102\130")
  ? "ok" : "not ok", " 45\n";
print "\x{03B1}" eq utfcp1047_to_unicode("\264\130")
  ? "ok" : "not ok", " 46\n";
print "\x{05D1}" eq utfcp1047_to_unicode("\270\125\130")
  ? "ok" : "not ok", " 47\n";
print "\x{1044D}" eq utfcp1047_to_unicode("\336\102\103\124")
  ? "ok" : "not ok", " 48\n";

# a UTF8-on string as a byte string is to be downgraded...

our $utf8_fe7f_upgraded = (ord("A") != 0x41)
     ? pack('U*', 213, 190, 215)  # EBCDIC "\xef\xb9\xbf"
     : pack('U*', 239, 185, 191); # ASCII  "\xef\xb9\xbf"

our $utf8_fe7f_bytes = pack('C*', 239, 185, 191);

print "\x{fe7f}" eq utf8_to_unicode($utf8_fe7f_upgraded)
  ? "ok" : "not ok", " 49\n";
print "\x{fe7f}" eq utf8_to_unicode($utf8_fe7f_bytes)
  ? "ok" : "not ok", " 50\n";
print  $utf8_fe7f_upgraded eq unicode_to_utf8("\x{fe7f}")
  ? "ok" : "not ok", " 51\n";
print  $utf8_fe7f_bytes eq unicode_to_utf8("\x{fe7f}")
  ? "ok" : "not ok", " 52\n";

print "\x41\xC2\xB1\x20" eq unicode_to_utf8('A± ')
  ? "ok" : "not ok", " 53\n";
print "\x41\xC5\xB1\x20" eq unicode_to_utf8mod('A± ')
  ? "ok" : "not ok", " 54\n";
print "\0\x41\0\xB1\0\x20" eq unicode_to_utf16be('A± ')
  ? "ok" : "not ok", " 55\n";
print "\x41\0\xB1\0\x20\0" eq unicode_to_utf16le('A± ')
  ? "ok" : "not ok", " 56\n";

###
1;
