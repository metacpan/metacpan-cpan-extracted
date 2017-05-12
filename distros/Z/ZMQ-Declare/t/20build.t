use strict;
use warnings;
use ZMQ::Declare qw(:all);
use File::Spec;
use Test::More;

my $datadir = -d 't' ? File::Spec->catdir(qw(t data)) : "data";

# test the ZDCF v0.1 spec file first
SCOPE: {
  my $zdcf = make_zdcf("simple_v0.zdcf");

  # just the compat "" application
  my @applications = $zdcf->application_names;
  is(scalar(@applications), 1, 'Number of available applications');
  is($applications[0], "", "Contains only the compat app");

  my $app = $zdcf->application(); # default for compat
  isa_ok($app, "ZMQ::Declare::Application");
  $app = $zdcf->application(""); # using explicit name
  isa_ok($app, "ZMQ::Declare::Application");

  my @devices = $app->device_names;
  is(scalar(@devices), 2, 'Number of available devices');

  is_deeply([sort @devices], [qw(weather_client weather_server)]);

  foreach my $device_name (qw(weather_client weather_server)) {
    my $device = $app->device($device_name);
    isa_ok($device, "ZMQ::Declare::Device");
    is($device->name, $device_name);

    is("" . $device->application, "$app", "parent app is same ref");

    is($device->typename, $device_name =~ /client/ ? "myweatherclientdevice" : "myweatherserverdevice");
  }

  my $srv_device = $app->device("weather_server");
  SCOPE: {
    my $rt = $srv_device->make_runtime();
    isa_ok($rt, "ZMQ::Declare::Device::Runtime");
  }
  my $called = 0;
  $srv_device->implementation(sub {$called++});
  $srv_device->run();
  is($called, 1);
} # end SCOPE (ZDCF v0.1)

# test the ZDCF v1.0 spec file
SCOPE: {
  my $zdcf = make_zdcf("simple_v1.zdcf");

  my @applications = $zdcf->application_names;
  is(scalar(@applications), 1, 'Number of available applications');
  is($applications[0], "weather", "Contains only the weather app");

  ok(not(eval {$zdcf->application();1}), "invalid application dies");
  ok(not(eval {$zdcf->application("asdasd");1}), "invalid application dies (2)");

  my $app = $zdcf->application("weather");
  isa_ok($app, "ZMQ::Declare::Application");

  my @devices = $app->device_names;
  is(scalar(@devices), 2, 'Number of available devices');

  is_deeply([sort @devices], [qw(client server)]);

  foreach my $device_name (qw(client server)) {
    my $device = $app->device($device_name);
    isa_ok($device, "ZMQ::Declare::Device");
    is($device->name, $device_name);
    ok(not(eval {$app->device();1}), "invalid device dies");
    ok(not(eval {$app->device("asdasd");1}), "invalid device dies (2)");

    is("" . $device->application, "$app", "parent app is same ref");

    is($device->typename, $device_name =~ /client/ ? "myweatherclientdevice" : "myweatherserverdevice");
  }

  my $srv_device = $app->device("server");
  SCOPE: {
    my $rt = $srv_device->make_runtime();
    isa_ok($rt, "ZMQ::Declare::Device::Runtime");
  }
  my $called = 0;
  $srv_device->implementation(sub {$called++});
  $srv_device->run();
  is($called, 1);
}

done_testing();

sub make_zdcf {
  my $testfile = shift;
  my $testzdcf = File::Spec->catfile($datadir, $testfile);
  ok(-f $testzdcf)
    or die "Missing test file '$testzdcf'";

  my $zdcf = ZMQ::Declare::ZDCF->new(tree => $testzdcf);
  isa_ok($zdcf, "ZMQ::Declare::ZDCF");

  # Try a encoder roundtrip:
  my @encoders = qw(JSON DumpEval Storable);

  foreach my $encoder (@encoders) {
    my $class = "ZMQ::Declare::ZDCF::Encoder::$encoder";
    eval "use $class; 1"
      or die "Cannot load class '$class'";
    my $obj = new_ok($class);
    $zdcf->encoder($obj);
    my $out = $zdcf->encode;
    is(ref($out), 'SCALAR', "$encoder: encoded to scalar ref");
    ok(!ref($$out), "$encoder: encoded to scalar ref to string");
    my $back = $obj->decode($out);
    is_deeply($back, $zdcf->tree, "$encoder: roundtrip");
    my $zback = ZMQ::Declare::ZDCF->new(tree => $out, encoder => $obj);
    is_deeply($zback->tree, $zdcf->tree, "$encoder: roundtrip (2)");
  }

  return $zdcf;
}
