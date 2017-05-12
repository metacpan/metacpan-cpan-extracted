
require 5;
use strict;
use Test;
BEGIN { plan tests => 13 }

#sub XML::RSS::Timing::DEBUG () {10}

use XML::RSS::Timing;
print "# I'm testing XML::RSS::Timing version $XML::RSS::Timing::VERSION\n";

ok 1;
print "# Required OK.\n";

use Time::Local;
my $E1970 = timegm(0,0,0,1,0,70);
ok 1;
print "# E1970 = $E1970 s  (", scalar(gmtime($E1970)), ")\n";

my $t;
$t = XML::RSS::Timing->new;
$t->lastPolled( 10_000 );
ok $t->nextUpdate(), 10_000;

$t->ttl(100); # = 6,000 seconds

ok $t->nextUpdate(), 16_000;
$t->minAge( 0 );
ok $t->nextUpdate(), 16_000;
$t->minAge( 7_123 );
ok $t->nextUpdate(), 17_123;
ok $t->nextUpdate(), 17_123;

$t->maxAge( 97_123 ); # should be irrelevent

$t->minAge( 0 );
ok $t->nextUpdate(), 16_000;
$t->minAge( 7_123 );
ok $t->nextUpdate(), 17_123;
ok $t->nextUpdate(), 17_123;

$t->maxAge( 1234 );
$t->minAge( 0 );
ok $t->nextUpdate(), 11_234;
$t->ttl(1_000); # = 60,000 seconds
ok $t->nextUpdate(), 11_234;

print "# that's it!\n";
ok 1
__END__

