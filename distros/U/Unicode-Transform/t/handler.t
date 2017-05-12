
BEGIN { $| = 1; print "1..27\n"; }

use Unicode::Transform;

use strict;
use warnings;

our $IsEBCDIC = ord("A") != 0x41;
print "ok 1\n";

#####

our $sub = sub { sprintf "<%04X>", shift };
our $fbk = sub { sprintf "<%02X>", shift };

our $str = "\x{10fffd}\x{110000}A";

print unicode_to_utf16le($sub, $str) eq "\xff\xdb\xfd\xdf<110000>\x41\0"
   ? "ok" : "not ok", " 2\n";

print unicode_to_utf16be($sub, $str) eq "\xdb\xff\xdf\xfd<110000>\0\x41"
   ? "ok" : "not ok", " 3\n";

print unicode_to_utf32le($sub, $str) eq "\xfd\xff\x10\x00<110000>\x41\0\0\0"
   ? "ok" : "not ok", " 4\n";

print unicode_to_utf32be($sub, $str) eq "\x00\x10\xff\xfd<110000>\0\0\0\x41"
   ? "ok" : "not ok", " 5\n";

print unicode_to_utf8($sub, $str) eq "\xf4\x8f\xbf\xbd<110000>\x41"
   ? "ok" : "not ok", " 6\n";

print unicode_to_utf8mod($sub, $str) eq "\xf9\xa1\xbf\xbf\xbd<110000>\x41"
   ? "ok" : "not ok", " 7\n";

print unicode_to_utfcp1047($sub, $str) eq "\xEE\x42\x73\x73\x71<110000>\xC1"
   ? "ok" : "not ok", " 8\n";

print "ABcccc" eq utf16le_to_unicode(sub { chr(shift) x 4 }, "\x41\0\x42\0c")
   ? "ok" : "not ok", " 9\n";

print "ABcccc" eq utf16be_to_unicode(sub { chr(shift) x 4 }, "\0\x41\0\x42c")
   ? "ok" : "not ok", " 10\n";

print "Aqqrrss" eq utf32le_to_unicode(sub { chr(shift) x 2 }, "\x41\0\0\0qrs")
   ? "ok" : "not ok", " 11\n";

print "Aqqrrss" eq utf32be_to_unicode(sub { chr(shift) x 2 }, "\0\0\0\x41qrs")
   ? "ok" : "not ok", " 12\n";

print 'A± ' eq utf8_to_unicode("\x41\xC0\x80\xC2\xB1\xC2\x20\xff")
   ? "ok" : "not ok", " 13\n";

print 'A<C0><80>±<C2> <FF>' eq utf8_to_unicode($fbk,
	"\x41\xC0\x80\xC2\xB1\xC2\x20\xff")
   ? "ok" : "not ok", " 14\n";

our $c1_0 = chr($IsEBCDIC ? 32 : 128);

print "A${c1_0} " eq utf8_to_unicode(sub {""},
	"\x41\xC0\x80\xC2\x80\xC2\x20\xff")
   ? "ok" : "not ok", " 15\n";

print "A<C0><80>${c1_0}<C2> <FF>" eq utf8_to_unicode($fbk,
	"\x41\xC0\x80\xC2\x80\xC2\x20\xff")
   ? "ok" : "not ok", " 16\n";

eval { $a = utf16be_to_unicode(sub { die }, "\x30\x42") }; # even

print !$@ && $a eq "\x{3042}"
   ? "ok" : "not ok", " 17\n";

eval { $a = utf16be_to_unicode(sub { die }, "\x30\x42\x30") }; # odd

print $@
   ? "ok" : "not ok", " 18\n";

eval { $a = utf32be_to_unicode(sub { die }, "\x00\x00\x30\x42") };

print !$@ && $a eq "\x{3042}"
   ? "ok" : "not ok", " 19\n";

eval { $a = utf32be_to_unicode(sub { die }, "\x30\x42\x00\x00") };

print $@
   ? "ok" : "not ok", " 20\n";

print "\x{10FFFD}<110000><10000030><32><42>" eq utf32be_to_unicode($fbk,
    "\x00\x10\xff\xfd\x00\x11\x00\x00\x10\x00\x00\x30\x32\x42")
   ? "ok" : "not ok", " 21\n";

print "<110001>\x{10FFFD}\x{3042}<12345678><01>" eq utf32le_to_unicode($fbk,
    "\x01\x00\x11\x00\xfd\xff\x10\x00\x42\x30\x00\x00\x78\x56\x34\x12\x01")
   ? "ok" : "not ok", " 22\n";

print "\x{10FFFD}<EE>" eq utfcp1047_to_unicode($fbk,
    "\xEE\x42\x73\x73\x71\xEE")
   ? "ok" : "not ok", " 23\n";


print !defined Unicode::Transform::ord_utf8("\xC0\x80")
   ? "ok" : "not ok", " 24\n";

print !defined Unicode::Transform::ord_utf8("\x80")
   ? "ok" : "not ok", " 25\n";

print !defined Unicode::Transform::ord_utf8("\xFD")
   ? "ok" : "not ok", " 26\n";

print !defined Unicode::Transform::ord_utf8("\xFF")
   ? "ok" : "not ok", " 27\n";

