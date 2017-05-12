BEGIN {
    if (ord("A") == 193) {
        print "1..0 # Skip: UTF-EBCDIC can't allow to encode 32bit.\n";
        exit 0;
    }
}
BEGIN { $| = 1; print "1..12\n"; }

use strict;
use warnings;
no warnings 'uninitialized';

use Unicode::Transform qw(:all);

### tests extension of UTF-8 to 32bit values (not by standard)

print chr_unicode(0x80000000) eq "\x{80000000}"
  ? "ok" : "not ok", " 1\n";
print chr_unicode(0xFFFFFFFD) eq "\x{fffffffd}"
  ? "ok" : "not ok", " 2\n";
print 0x80000000 == ord_unicode("\x{80000000}")
  ? "ok" : "not ok", " 3\n";
print 0xFFFFFFFD == ord_unicode("\x{fffffffd}")
  ? "ok" : "not ok", " 4\n";

my $unicode = "\x{80000001} \x{fffffffd}";
my $utf32be = "\x80\x00\x00\x01\x00\x00\x00\x20\xff\xff\xff\xfd";
my $utf32le = "\x01\x00\x00\x80\x20\x00\x00\x00\xfd\xff\xff\xff";

print utf32be_to_unicode(\&chr_unicode, $utf32be) eq $unicode
   ? "ok" : "not ok", " 5\n";
print utf32le_to_unicode(\&chr_unicode, $utf32le) eq $unicode
   ? "ok" : "not ok", " 6\n";
print unicode_to_utf32be(\&chr_utf32be, $unicode) eq $utf32be
   ? "ok" : "not ok", " 7\n";
print unicode_to_utf32le(\&chr_utf32le, $unicode) eq $utf32le
   ? "ok" : "not ok", " 8\n";

my $spunicode = " ";
my $sputf32be = "\x00\x00\x00\x20";
my $sputf32le = "\x20\x00\x00\x00";

print utf32be_to_unicode($utf32be) eq $spunicode
   ? "ok" : "not ok", " 9\n";
print utf32le_to_unicode($utf32le) eq $spunicode
   ? "ok" : "not ok", " 10\n";
print unicode_to_utf32be($unicode) eq $sputf32be
   ? "ok" : "not ok", " 11\n";
print unicode_to_utf32le($unicode) eq $sputf32le
   ? "ok" : "not ok", " 12\n";

