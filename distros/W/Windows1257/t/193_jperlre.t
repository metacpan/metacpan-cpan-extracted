# encoding: Windows1257
# This file is encoded in Windows-1257.
die "This file is not encoded in Windows-1257.\n" if q{��} ne "\x82\xa0";

use Windows1257;
print "1..1\n";

my $__FILE__ = __FILE__;

eval q!'AAA' =~ /[]/!;
if ($@) {
    print "ok - 1 $^X $__FILE__ (!'AAA' =~ /[]/!)\n";
}
else {
    print "not ok - 1 $^X $__FILE__ (!'AAA' =~ /[]/!)\n";
}

__END__
