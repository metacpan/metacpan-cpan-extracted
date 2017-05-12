use strict;
use warnings FATAL => qw(all);

use Test::More tests => 2;

my $class = qw(WebService::UrbanAirship);

use_ok($class);

{
  my $o = $class->new;

  isa_ok($o, $class);
}

