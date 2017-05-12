
BEGIN { $| = 1; print "1..19\n"; }

use Unicode::Transform qw(chr_unicode ord_unicode);
use strict;
use warnings;

no warnings qw(utf8);

print "ok 1\n";

print "\x{D800}" ne "\0"
   ? "ok" : "not ok", " 2\n";

print "\x{DFFF}" ne "\0"
   ? "ok" : "not ok", " 3\n";

print "\x{FFFE}" ne "\0"
   ? "ok" : "not ok", " 4\n";

print "\x{FFFF}" ne "\0"
   ? "ok" : "not ok", " 5\n";

print "\x{10FFFF}" ne "\0"
   ? "ok" : "not ok", " 6\n";

print "\x{110000}" ne "\0"
   ? "ok" : "not ok", " 7\n";

print ord_unicode("\x{D800}") == 0xD800
   ? "ok" : "not ok", " 8\n";

print ord_unicode("\x{DFFF}") == 0xDFFF
   ? "ok" : "not ok", " 9\n";

print ord_unicode("\x{FFFE}") == 0xFFFE
   ? "ok" : "not ok", " 10\n";

print ord_unicode("\x{FFFF}") == 0xFFFF
   ? "ok" : "not ok", " 11\n";

print ord_unicode("\x{10FFFF}") == 0x10FFFF
   ? "ok" : "not ok", " 12\n";

print ord_unicode("\x{110000}") == 0x110000
   ? "ok" : "not ok", " 13\n";

print chr_unicode(0xD800) eq "\x{D800}"
   ? "ok" : "not ok", " 14\n";

print chr_unicode(0xDFFF) eq "\x{DFFF}"
   ? "ok" : "not ok", " 15\n";

print chr_unicode(0xFFFE) eq "\x{FFFE}"
   ? "ok" : "not ok", " 16\n";

print chr_unicode(0xFFFF) eq "\x{FFFF}"
   ? "ok" : "not ok", " 17\n";

print chr_unicode(0x10FFFF) eq "\x{10FFFF}"
   ? "ok" : "not ok", " 18\n";

print chr_unicode(0x110000) eq "\x{110000}"
   ? "ok" : "not ok", " 19\n";

