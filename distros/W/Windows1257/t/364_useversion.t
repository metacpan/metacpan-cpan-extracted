# encoding: Windows1257
# This file is encoded in Windows-1257.
die "This file is not encoded in Windows-1257.\n" if q{‚ } ne "\x82\xa0";

my $__FILE__ = __FILE__;

use 5.005;
use Windows1257;
print "1..1\n";

print "ok - 1 $^X $__FILE__\n";

__END__
