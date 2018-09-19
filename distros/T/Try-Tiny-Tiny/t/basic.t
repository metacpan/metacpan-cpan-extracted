use strict; use warnings;

use Try::Tiny::Tiny;
use Try::Tiny 'try';

#
#
#

print "1..1\n";

my $cb = sub { (caller 0)[3] };
my $name = &$cb;

$name eq &try($cb) or print 'not '; print "ok 1 - Try::Tiny is prevented from renaming its callback\n";
