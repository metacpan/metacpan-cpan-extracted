
require 5;
use strict;
use Test;
BEGIN { plan tests => 6 }

print "# Starting ", __FILE__ , " ...\n";
ok 1;

#sub XML::RSS::SimpleGen::DEBUG () {20}

use XML::RSS::SimpleGen;

my $rss     = 'test.rss';
my $history = 'test.hst';

my $last;
{
  my @curr;
  foreach my $to_add ( qw( morning noon night ) ) {
    rss_new( 'http://blar.int' );
    rss_history_file( $history );
    push @curr, $to_add;
    foreach my $c ( sort @curr ) {   # yes, sort!!
      rss_item("http://blar.int#$c", "About $c");
    }
    rss_save($rss);
    $last = rss_as_string();
    ok 1;
    sleep 2;
  }
}

unlink $rss, $history;
$last =~ s/\n/ /g;
ok $last, '/night.+noon.+morning/';

print "# bye\n";
ok 1;

