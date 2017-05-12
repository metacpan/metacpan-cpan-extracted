use strict;
use warnings FATAL => qw(all);

use lib qw(t/lib);

use Test::More tests => 5;

my $class = qw(My::Subclass);

use_ok($class);

{
  my $o = $class->new(application_key         => 'key',
                      application_secret      => 'secret',
                      application_push_secret => 'push secret');


  isa_ok($o, $class);
  isa_ok($o, 'WebService::UrbanAirship');
  isa_ok($o, 'WebService::UrbanAirship::APNS');

}

{
  my $called = 0;

  no warnings qw(redefine);

  local *WebService::UrbanAirship::APNS::_init = sub { $called++ };

  my $o = $class->new(application_key         => 'key',
                      application_secret      => 'secret',
                      application_push_secret => 'push secret');


  is ($called,
      1,
      '_init() called');
}
