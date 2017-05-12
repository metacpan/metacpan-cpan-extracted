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

is( title('http://st.pimg.net/perlweb/images/camel_head.v25e738a.png'), "png (60 x 65)"  );
