use strict;
use warnings FATAL => qw(all);

use Test::More tests => 3;

my $class = qw(WebService::UrbanAirship);

use_ok($class);

{
  my $o = $class->new;

  my $uri = $o->_api_uri;

  isa_ok ($uri, 'URI');

  is ($uri->canonical,
      'https://go.urbanairship.com/',
      'default api url set');
}

