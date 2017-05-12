use warnings;
use strict;
use Test::More;
use lib 'lib';
use URI::Title qw(title);

require IO::Socket;
my $s = IO::Socket::INET->new(
  PeerAddr => "www.yahoo.com:80",
  Timeout  => 10,
);

if ($s) {
  close($s);
  plan tests => 1;
} else {
  plan skip_all => "no net connection available";
  exit;
}

#is(
#  title('http://jerakeen.org/test/uri-title.html'),
#  "URI::Title test",
#  "got title for jerakeen.org");

ok(
  title('http://www.theregister.co.uk/2003/12/16/warning_lack_of_technology_may/') =~ /lack of technology may harm your prospects/,
  "got register title");

# ok(
#   title('http://twitter.com/al3x/status/1039647490') eq 'twitter - Arianna Huffington: not a good saleswoman for blogging.',
#   "got Twitter status");
