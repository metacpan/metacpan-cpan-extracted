# encoding: Windows1258
# This file is encoded in Windows-1258.
die "This file is not encoded in Windows-1258.\n" if q{‚ } ne "\x82\xa0";

use Windows1258;
print "1..2\n";

my $__FILE__ = __FILE__;

my $s = "The black cat climbed the green tree";
my $z = Windows1258::substr $s, 14, 7, "jumped from"; # climbed

if ($z eq 'climbed') {
    print "ok - 1 $^X $__FILE__\n";
}
else {
    print "not ok - 1 $^X $__FILE__\n";
}

if ($s eq 'The black cat jumped from the green tree') {
    print "ok - 2 $^X $__FILE__\n";
}
else {
    print "not ok - 2 $^X $__FILE__\n";
}

__END__
http://perldoc.perl.org/functions/substr.html

1.    my $s = "The black cat climbed the green tree";
2.    my $z = substr $s, 14, 7, "jumped from";    # climbed
3.    # $s is now "The black cat jumped from the green tree"
