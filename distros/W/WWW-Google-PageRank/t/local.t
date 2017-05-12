#!perl -w

use WWW::Google::PageRank;

my @pattern =
  (
   'http://www.yahoo.com/' => 177402400,
   'http://search.cpan.org/src/YKAR/Google-PageRank-0.01/lib/Google/PageRank.pm' => 1307377535,
   'http://dmoz.org/Computers/Programming/Languages/Perl/Modules/' => 3293641932,
   'http://www.perlmonks.org/' => 182624977,
   'http://perl.apache.org/docs/1.0/guide/config.html#Stacked_Handlers' => 1362813805,
   'http://perl.apache.org/products/products.html' => 3915043874,
   'http://www.hotbot.com/' => 3028861670,
   'http://slashdot.org/' => 2405246232
  );

print ('1..' . (scalar(@pattern) / 2) . "\n");

my $test_nr = 1;

while (@pattern) {
  my $url = shift @pattern;
  my $vch = shift @pattern;
  my $ch = WWW::Google::PageRank::_compute_ch_new($url);
  print (($ch == $vch ? "ok" : "not ok") . " $test_nr\n");
  $test_nr ++;
}
