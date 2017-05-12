# Test the ord/chr functions

print "1..10\n";

use Unicode::String qw(latin1 uchr utf16);

$u = uchr(ord("å"));

print $u->ord, "\n", ord("å"), "\n";


print "not " unless $u->ord == ord("å");
print "ok 1\n";

print "not " unless latin1("\0")->ord == 0 && latin1("A")->ord == 65;
print "ok 2\n";

print "not " unless uchr(0xFFFF)->ord == 0xFFFF;
print "ok 3\n";

# Test surrogates

$u = uchr(0x10000);
print $u->hex, "\n";

print "not " unless $u->ord == 0x10000;
print "ok 4\n";

$u = uchr(0x10FFFF);
print $u->hex, "\n";
print "not " unless $u->ord == 0x10FFFF;
print "ok 5\n";

$u = utf16("\xd8\x01\xdc\01");
print $u->hex, "\n";
print "not " unless $u->ord == 0x10401;
print "ok 6\n";

# Try $u->ord in array context

@ord = latin1("perl")->ord;

print "not " unless "@ord" eq "112 101 114 108";
print "ok 7\n";

$u = utf16("\0a\xd8\x01\xdc\01\0b");
print $u->hex, "\n";
@ord = map { sprintf("U+%04x", $_) } $u->ord;
print "@ord\n";

print "not " unless "@ord" eq "U+0061 U+10401 U+0062";
print "ok 8\n";

# Try some illegal stuff
$u = utf16("\0a\xdc\01\xd8\x01\0b");  # reversed surrogate
print $u->hex, "\n";

print "not " unless $u->ord == ord("a");
print "ok 9\n";

{
   local($SIG{__WARN__}) = sub {};
   @ord = map { sprintf("U+%04x", $_) } $u->ord;
}

print "@ord\n";

print "not " unless "@ord" eq "U+0061 U+0062";
print "ok 10\n";

