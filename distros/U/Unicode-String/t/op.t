# Test string operations

print "1..22\n";

use Unicode::String qw(utf8 utf16);

$u = utf8("abc");
$u->append(utf8("def"));

print "not " unless $u->utf8 eq "abcdef";
print "ok 1\n";

$x = $u->copy;
print "not " unless overload::StrVal($x) ne overload::StrVal($u);
print "ok 2\n";

print $u->hex, "\n";
print $x->hex, "\n";

print "not " unless $x->hex eq $u->hex;
print "ok 3\n";

$x->append(utf8("g"));

print "not " unless $x->utf8 eq "abcdefg";
print "ok 4\n";

$y = $x->repeat(3);
print $u->hex, "\n";
print $x->hex, "\n";
print $y->utf8, "\n";

print "not " unless $y->utf8 eq ("abcdefg" x 3);
print "ok 5\n";

$y = $x->concat($u);
print "not " unless $y->utf8 eq "abcdefgabcdef" &&
                    $x->utf8 eq "abcdefg" && $u->utf8 eq "abcdef";
print "ok 6\n";

$x = utf8("123");
print "not " unless $x->as_num == 123;
print "ok 7\n";

$x = utf8("");
print "not " if $x->as_bool;
print "ok 8\n";

$x = utf8("0");
print "not " if !$x->as_bool;
print "ok 9\n";

$x = utf8("abc");
print "not " if !$x->as_bool;
print "ok 10\n";

#--- substr ---

$y = $x->substr(0,1);
print "not " unless $y->utf8 eq "a" && $x->utf8 eq "abc";
print "ok 11\n";

$y = $x->substr(1);
print "not " unless $y->utf8 eq "bc" && $x->utf8 eq "abc";
print "ok 12\n";

$x = utf8("0123456789");
print "not " unless $x->substr(2,3)->utf8 eq "234";
print "ok 13\n";

print "not " unless $x->substr->utf8 eq $x->utf8;
print "ok 14\n";

print "not " unless $x->substr(3,0)->length == 0;
print "ok 15\n";

print "not " unless $x->substr(8, 100)->utf8 eq "89";
print "ok 16\n";

#--- index/rindex ---

print "not " unless $x->index(utf8("345")) == 3;
print "ok 17\n";

print "not " unless $x->index(utf8("356")) == -1;
print "ok 18\n";

print "not " unless $x->index(utf8("0")) == 0;
print "ok 19\n";

print "not " unless $x->index(utf8("0"), 1) == -1;
print "ok 20\n";

# Test some more interresting patterns
$x = utf16("abbaabbbaa");
print "not " unless $x->index(utf16("bb")) == 3;
print "ok 21\n";

#--- overload -->
print "not " unless (utf8("a") . utf8("b"))->utf8 eq "ab" &&
	            ("a" . utf8("b"))->utf8 eq "ab" &&
                    (utf8("a") . "b")->utf8 eq "ab";
print "ok 22\n";
