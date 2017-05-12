use Test::Roo;

sub _build_description { "Testing get_weather interface" }

{ no warnings 'redefine'; no strict 'refs';
  require LWP::UserAgent;
  *{ 'LWP::UserAgent::request' } = sub { die "Should not have been called" };
}

use lib 't/inc';
with 'Testing::OpenWeatherMap';
run_me;

done_testing
