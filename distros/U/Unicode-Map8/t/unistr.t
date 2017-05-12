
use Unicode::Map8;
$greek = Unicode::Map8->new("WinGreek") || die;

# This might fail if if the Unicode::String module is not installed
eval {
   $u = $greek->tou("זרו");
};
if ($@) {
    if ($@ =~ /^Can't locate Unicode\/String/) {
        print "1..0\n";
    }
    print $@;
    exit;
}

Unicode::String->stringify_as("hex");

# here we go
print "1..2\n";

print "not " unless UNIVERSAL::isa($u, "Unicode::String");
print "ok 1\n";

print $u, "\n";

$names = join(" ", map "<$_>", $u->name);

print "$names\n";
print "not " unless $names eq "<GREEK SMALL LETTER ZETA> <GREEK SMALL LETTER PSI> <GREEK SMALL LETTER EPSILON>";
print "ok 2\n";


