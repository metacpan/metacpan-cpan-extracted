print "1..13\n";

use Unicode::CharName qw(ublock uname);

#print uname(ord("å")), "\n";
#print ublock(ord("å")), "\n";

# Test a few simple names
print "not " unless uname(ord("\$")) eq "DOLLAR SIGN";
print "ok 1\n";

print "not " unless uname(ord("å")) eq "LATIN SMALL LETTER A WITH RING ABOVE";
print "ok 2\n";

# Test ideograph name generation
print "not " unless uname(0x7C80) eq "CJK UNIFIED IDEOGRAPH 7C80";
print "ok 3\n";

# Test Hangul Syllable name generation
print "not " unless uname(0x1111) eq "HANGUL CHOSEONG PHIEUPH";
print "ok 4\n";

print "not " unless uname(0xD4DB) eq "HANGUL SYLLABLE PWILH";
print "ok 5\n";

# Some various stuff
print "not " unless uname(0xF000) eq "<private>";
print "ok 6\n";
print "not " unless uname(0) eq "<control>";
print "ok 7\n";
print "not " unless uname(0xD800) eq "<surrogate>";
print "ok 8\n";

# Test ublock function

print "not " unless ublock(ord("a")) eq "Basic Latin";
print "ok 9\n";

print "not " unless ublock(0x2190) eq "Arrows" and ublock(0x21FF) eq "Arrows";
print "ok 10\n";

print "not " unless ublock(0xFFFF) eq "Specials";
print "ok 11\n";

print "not " if defined ublock(0x30000);
print "ok 12\n";

print "not " unless uname(0x1d1cf) eq "MUSICAL SYMBOL CROIX";
print "ok 13\n";
