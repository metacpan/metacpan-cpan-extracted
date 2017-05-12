print "1..3\n";

use Unicode::String qw(latin1);

Unicode::String::stringify_as("hex");

$u = latin1("gj¯k");

print $u->hex, "\n";

print "not " unless "$u" eq "U+0067 U+006a U+00f8 U+006b";
print "ok 1\n";

Unicode::String::stringify_as("utf8");

print $u->hex, "\n";
$str = "$u";


print "$str\n";

print "not " unless "$u" eq "gj√∏k";
print "ok 2\n";

eval {
  Unicode::String::stringify_as("xyzzy");
};

print $@;
print "not " unless $@;
print "ok 3\n";

