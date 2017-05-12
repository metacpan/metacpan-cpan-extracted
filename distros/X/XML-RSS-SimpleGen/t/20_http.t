
require 5;
use strict;
use Test;
BEGIN { plan tests => 8 }

print "# Starting ", __FILE__ , " ...\n";
ok 1;

#sub XML::RSS::SimpleGen::DEBUG () {20}

use XML::RSS::SimpleGen;

sub g ($) {
  print "# Test-getting $_[0] at ", scalar(localtime), "...\n";
  return defined(eval { get_url $_[0]}), 1, "getting $_[0]";
}

&ok(g 'http://www.perl.com/');
&ok(g 'http://www.yahoo.com/');
&ok(g 'http://www.google.com/');

print "# Now trying with LWP...\n";
if( eval "require LWP::Simple; 1;"  and  $LWP::Simple::VERSION ) {
  print "# Using LWP::Simple v$LWP::Simple::VERSION\n";
  &ok(g 'http://www.perl.com/');
  &ok(g 'http://www.yahoo.com/');
  &ok(g 'http://www.google.com/');
} else {
  skip "skipping because LWP not available", 1,1;
  skip "skipping because LWP not available", 1,1;
  skip "skipping because LWP not available", 1,1;
}

print "# Done at ", scalar(localtime), ".\n";
ok 1;

