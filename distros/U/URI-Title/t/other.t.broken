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
#  title('http://jerakeen.org/images/thoth.gif'),
#  "gif (144 x 99)",
#  "got title for jerakeen.org/images/thoth.gif");

is(
  title('http://jerakeen.org/test/uri-title-test.mp3'),
  "Ashley Pomeroy - Sand",
  "got title for jerakeen.org/test/uri-title-test.mp3");

