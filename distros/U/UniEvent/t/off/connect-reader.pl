use strict;
use warnings;
use lib 't';
use UniClient;

my $line = shift;

exit UniClient::connect(
  sub {
    my $sock = $_[0];
    local $/;
    my $data = <$sock>;
    return 0+($data ne $line);
  });
