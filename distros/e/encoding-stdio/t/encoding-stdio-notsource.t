print "1..1\n";
use encoding::stdio 'greek';
#warn "\n", ord "\xdf";
print 'not ' if ord("\xdf") != 223;
print "ok 1\n";
