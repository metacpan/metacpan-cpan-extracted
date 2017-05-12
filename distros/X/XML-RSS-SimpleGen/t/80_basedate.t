
require 5;
use strict;
use Test;
BEGIN { plan tests => 9 }

print "# Starting ", __FILE__ , " ...\n";
ok 1;
use XML::RSS::SimpleGen;

rss_new( 'http://blar.int' );
sub r {defined eval { rss_updateBase($_[0]) }; }

# ok r('1997'); nevermind that case

ok r('1997-07');
ok r('1997-07-16');
ok r('1994-11-05T13:15:30Z');
ok r('1997-07-16T19:20+01:00');
ok r('1994-11-05T08:15:30-05:00');
ok r('1997-07-16T19:20:30+01:00');
ok r('1997-07-16T19:20:30.45+01:00');

print "# bye\n";
ok 1;



