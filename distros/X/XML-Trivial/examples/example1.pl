# This is only basic example.
# To know all functionality, see pod documentation included in XML::Trivial.
# If XML::Trivial is properly installed, you can launch 'man XML::Trivial'
# on *nix systems...

use XML::Trivial;

use strict;
use warnings;

#how to parse string
my $doc = XML::Trivial::parse("
<nature>
  <animals>
    <cow legs='4'>BOO</cow>
    <snake>TSSS</snake>
  </animals>
</nature>
");

#traversing through elements, ts means _t_ext _s_erialized

print "cows voice: ".$$doc{nature}{animals}{cow}->ts."\n";
print "snakes voice: ".$$doc{nature}{animals}{snake}->ts."\n";

#traversing through elements using its position

print "cows voice: ".$$doc{0}{0}{0}->ts."\n";
print "snakes voice: ".$$doc{0}{0}{1}->ts."\n";

#attributes

print "cows legs: ".$$doc{0}{0}{0}->ah('legs')."\n";
print "snakes legs: ".$$doc{0}{0}{1}->ah('legs')."\n";

#serialization
print "cow: ".$$doc{nature}{animals}{cow}->sr."\n";
print "snake: ".$$doc{nature}{animals}{snake}->sr."\n";


