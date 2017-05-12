#!perl -w

use strict;
use Test qw(plan ok);

plan tests => 59;

use Unicode::String qw(latin1 ucs4 utf32le utf16 utf16le utf8 utf7);

#use Devel::Dump;

$SIG{__WARN__} = sub { print "$_[0]"; };

my $u = latin1("abcæøå");
#Dump($u);

#---- Test Latin1 encoding ----

ok($u->latin1, "abcæøå");
ok($u->length, 6);
ok($u->ucs4, "\0\0\0a\0\0\0b\0\0\0c\0\0\0æ\0\0\0ø\0\0\0å");
ok($u->utf32, "\0\0\0a\0\0\0b\0\0\0c\0\0\0æ\0\0\0ø\0\0\0å");
ok($u->utf32be, "\0\0\0a\0\0\0b\0\0\0c\0\0\0æ\0\0\0ø\0\0\0å");
ok($u->utf32le, "a\0\0\0b\0\0\0c\0\0\0æ\0\0\0ø\0\0\0å\0\0\0");
ok($u->utf16, "\0a\0b\0c\0æ\0ø\0å");
ok($u->utf16be, "\0a\0b\0c\0æ\0ø\0å");
ok($u->ucs2, "\0a\0b\0c\0æ\0ø\0å");
ok($u->utf16le, "a\0b\0c\0æ\0ø\0å\0");
ok($u->utf8, "abcÃ¦Ã¸Ã¥");
ok($u->utf7, "abc+AOYA+ADl-");
ok($u->hex, "U+0061 U+0062 U+0063 U+00e6 U+00f8 U+00e5");

$u = latin1("abc");
$a = $u->latin1("def");
$b = $u->latin1;
$u->latin1("ghi");

ok($a, "abc");
ok($b, "def");
ok($u->latin1, "ghi");


$u = utf16("aa\0bcc\0d");

print "Expect 2 lines of warnings...\n";
my $x = $u->latin1;

ok($x, "bd");

#---- Test UCS4 encoding ----

$x = "\0\0\0a\0\0bb\0\3cc\0\1\0\2\0\0\0\0";
$u = ucs4($x);

ok($u->length, 7);
ok($u->hex, "U+0061 U+6262 U+d898 U+df63 U+d800 U+dc02 U+0000");
ok($u->ucs4, $x);

$a = $u->ucs4("");
ok($a, $x);
ok($u->length, 0);

$u = utf32le("a\0\0\0" . "bb\0\0" . "cc\3\0" . "\2\0\1\0" . "\0\0\0\0");
ok($u->length, 7);
ok($u->hex, "U+0061 U+6262 U+d898 U+df63 U+d800 U+dc02 U+0000");
ok($u->ucs4, $x);

print "Expect 2 lines of warnings...\n";
$u->ucs4("    \0\x10\xff\xff\0\x11\0\0\0\0\0\0");
ok($u->hex, "U+dbff U+dfff U+0000");

#--- Test UTF8 encoding ---

$u = utf8("");
ok($u->length, 0);
ok($u->utf8, "");

$u = utf8("abc");
my $old = $u->utf8("def");
ok($old, "abc");
ok($u->latin1, "def");

$u = utf16("\0a\0å\1\0\7a\0aa");
$x = unpack("H*", $u->utf8);
ok($x, "61c3a5c480dda161e68480");

my $u2 = utf8($u->utf8);
ok($u->utf16, $u2->utf16);

# Test surrogates and utf8
print "Surrogates...\n";

$u = ucs4("\0\1\0\0\0\x10\xFF\xFF");
$x = unpack("H*", $u->utf8);
ok($x, "f0908080f48fbfbf");

$u->utf8(pack("H*", $x));
ok($u->ucs4, "\0\1\0\0\0\x10\xFF\xFF");

print "Expect a warning with this incomplete surrogate pair...\n";
$u = utf16("\xd8\x00");
$u2 = utf8($u->utf8);
ok($u2->hex, "U+d800");

print "...and lots of noice from this...\n";
$u = utf8("¤¤a\xf7¤¤¤b\xf8¤¤¤¤c\xfc¤¤¤¤¤d\xfd\xfe\xffef");
print $u->hex, "\n";

ok($u->utf8, "abcdef");


#--- Test UTF7 encoding ---

# Examples from RFC 1642...
#
#      Example. The Unicode sequence "A<NOT IDENTICAL TO><ALPHA>."
#      (hexadecimal 0041,2262,0391,002E) may be encoded as follows:
#
#            A+ImIDkQ.
#
#      Example. The Unicode sequence "Hi Mom <WHITE SMILING FACE>!"
#      (hexadecimal 0048, 0069, 0020, 004D, 006F, 004D, 0020, 263A, 0021)
#      may be encoded as follows:
#
#            Hi Mom +Jjo-!

$u = utf7("A+ImIDkQ.");
ok($u->hex, "U+0041 U+2262 U+0391 U+002e");

my $utf7 = $u->utf7("Hi Mom +Jjo-!");
ok($utf7, qr/^A\+ImIDkQ-?\.$/);

ok($u->hex, "U+0048 U+0069 U+0020 U+004d U+006f U+006d U+0020 U+263a U+0021");
ok($u->utf7 eq "Hi Mom +Jjo-!" || $u->utf7 eq "Hi Mom +JjoAIQ-");

#      Example. The Unicode sequence representing the Han characters for
#      the Japanese word "nihongo" (hexadecimal 65E5,672C,8A9E) may be
#      encoded as follows:

$u = utf7("+ZeVnLIqe-");
ok($u->hex, "U+65e5 U+672c U+8a9e");
ok($u->utf7, "+ZeVnLIqe-");

# Appendix A -- Examples
#
#   Here is a longer example, taken from a document originally in Big5
#   code. It has been condensed for brevity. There are two versions: the
#   first uses optional characters from set O (and thus may not pass
#   through some mail gateways), and the second uses no optional
#   characters.

my $text = <<'EOT';
   Below is the full Chinese text of the Analects (+itaKng-).

   The sources for the text are:

   "The sayings of Confucius," James R. Ware, trans.  +U/BTFw-:
   +ZYeB9FH6ckh5Pg-, 1980.  (Chinese text with English translation)

   +Vttm+E6UfZM-, +W4tRQ066bOg-, +UxdOrA-:  +Ti1XC2b4Xpc-, 1990.

   "The Chinese Classics with a Translation, Critical and
   Exegetical Notes, Prolegomena, and Copius Indexes," James
   Legge, trans., Taipei:  Southern Materials Center Publishing,
   Inc., 1991.  (Chinese text with English translation)

   Big Five and GB versions of the text are being made available
   separately.

   Neither the Big Five nor GB contain all the characters used in
   this text.  Missing characters have been indicated using their
   Unicode/ISO 10646 code points.  "U+-" followed by four
   hexadecimal digits indicates a Unicode/10646 code (e.g.,
   U+-9F08).  There is no good solution to the problem of the small
   size of the Big Five/GB character sets; this represents the
   solution I find personally most satisfactory.

   (omitted...)

   I have tried to minimize this problem by using variant
   characters where they were available and the character
   actually in the text was not.  Only variants listed as such in
   the +XrdxmVtXUXg- were used.

   (omitted...)

   John H. Jenkins
   +TpVPXGBG-
   John_Jenkins@taligent.com
   5 January 1993
EOT

$u = utf7($text);
my $utf = $u->utf7;

unless ($utf eq $text) {
   print $u->length, " $utf\n";
   open(F, ">utf7-$$.orig"); print F $text;
   open(F, ">utf7-$$.enc");  print F $utf;
   close(F);
   system("diff -u0 utf7-$$.orig utf7-$$.enc");
   unlink("utf7-$$.orig", "utf7-$$.enc");
}

ok($utf, $text);

# Test encoding of different encoding byte lengths
for my $len (1 .. 6) {
   $u = Unicode::String->new;
   $u->pack(map {1000 + $_} 1 .. $len);
   $u2 = utf7($u->utf7);
   ok($u->utf16, $u2->utf16);
}

$Unicode::String::UTF7_OPTIONAL_DIRECT_CHARS = 0;

$u = latin1("a=4!æøå");
$utf = $u->utf7;

ok($utf7 !~ /[=!]/);
ok(utf7($utf)->latin1, "a=4!æøå");

#--- Swapped bytes ---

$u = utf16("ÿþa\0b\0c\0");
ok($u->hex, "U+feff U+0061 U+0062 U+0063");
ok($u->latin1, "abc");

$u = utf16("þÿ\0a\0b\0c");
ok($u->hex, "U+feff U+0061 U+0062 U+0063");
ok($u->latin1, "abc");

$u = utf16le("ÿþa\0b\0c\0");
ok($u->hex, "U+feff U+0061 U+0062 U+0063");
ok($u->latin1, "abc");

$u = utf16le("þÿ\0a\0b\0c");
ok($u->hex, "U+feff U+0061 U+0062 U+0063");
ok($u->latin1, "abc");

