use strict;
use warnings;
use Test::More;

use ZMQ::Declare::DSL;
my $zdcf = declare_zdcf {

  app {
    name 'weather';

    context { iothreads 1 };

    device {
      name 'client';
      sock {
        name 'weather_stream';
        type 'sub';
        conn qw(tcp://localhost:12345);
        option subscribe => "70123"; # ZIP code in this example
      };
    };

    device {
      name 'server';
      sock {
        name 'weather_publisher';
        type 'pub';
        bnd qw(tcp://*:12345);
      };
    };
  };

};
isa_ok($zdcf, "ZMQ::Declare::ZDCF");

# elsewhere
my $server = $zdcf->application("weather")->device('server');
my $called;
$server->implementation(sub {
  my ($runtime) = @_;
  isa_ok($runtime, "ZMQ::Declare::Device::Runtime");
  ok(ref( $runtime->get_socket_by_name("weather_publisher") ) =~ /^Z(?:ero)?MQ::Socket$/);
  $called = 1;
  return();
});

ok(!$called);
$server->run();
ok($called);

foreach my $func (@ZMQ::Declare::DSL::EXPORT) {
  ok(__PACKAGE__->can($func), "$func available");
}

done_testing();
