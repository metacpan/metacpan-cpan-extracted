
require 5;
use strict;
use Test;
BEGIN { plan tests => 4 }

print "# Starting ", __FILE__ , " ...\n";
ok 1;
use XML::RSS::SimpleGen;

rss_new( 'http://blar.int' );
rss_item("http://blar.int#a", "About A");
rss_item("http://blar.int#b", "About B");
rss_item("http://blar.int#c", "About C");

ok rss_item_count(), 3;

rss_item("http://blar.int#b", "About B");

my $string = rss_as_string();
my $count = 0;
while( $string =~ m/(\#\w)\b/g ) {
  print "#  Good, found \"$1\"\n";
  ++$count;
}
ok $count, 3;

print "# bye\n";
ok 1;

