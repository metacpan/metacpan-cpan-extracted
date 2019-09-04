# encoding: Windows1254
# This file is encoded in Windows-1254.
die "This file is not encoded in Windows-1254.\n" if q{‚ } ne "\x82\xa0";

use strict;
use Windows1254;
print "1..1\n";

my $__FILE__ = __FILE__;

my $a = 'aaa_123';
$a =~ s/[a-z]+_([0-9]+)/$1/g;
if ($a eq '123') {
    print "ok - 1 ($a) s///g (with 'use strict') $^X $__FILE__\n";
}
else {
    print "not ok - 1 ($a) s///g (with 'use strict') $^X $__FILE__\n";
}

__END__
