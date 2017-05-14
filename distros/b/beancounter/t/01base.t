#!/usr/bin/perl 

print "1..$tests\n";

require Finance::BeanCounter;
print "ok 1\n";

import Finance::BeanCounter;
print "ok 2\n";

BEGIN{$tests = 2;}
exit(0);
