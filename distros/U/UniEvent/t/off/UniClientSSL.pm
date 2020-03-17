use strict;
use warnings;

package UniClientSSL;
use lib 't';
use UniClient;
use IO::Socket::SSL;

sub connect {
  my ($sub, @ssl_params) = @_;
  return UniClient::connect(
    sub {
      my $s = $_[0];
      IO::Socket::SSL->start_SSL($s, @ssl_params);
      my $res = $sub->($s);
      $s->stop_SSL();
      return $res;
    });
}

1;
