package WebService::Freshservice::Test;

use strict;
use warnings;
use WebService::Freshservice::API;
use Method::Signatures;
use Test::Most;
use Moo;
use namespace::clean;

has 'config' => (
  is => 'ro',
  lazy => 1,
  builder => 1,
);

method _build_config() {
  use Config::Tiny;
  my $config = Config::Tiny->read( "$ENV{HOME}/.freshservicetest" );
  return $config;
}

method test_with_auth($test, $number_tests) {
  SKIP: {
    skip "Live testing not implemented.", $number_tests;
    #skip "No auth credentials found.", $number_tests unless ( -e "$ENV{HOME}/.freshervicetest" );

    eval {  
      require Config::Tiny;
    };

    skip 'These tests are for online testing and require Config::Tiny.', $number_tests if ($@);

    my $api = WebService::Freshservice::API->new(
      apikey => $self->config->{auth}{key}, 
      apiurl => $self->config->{auth}{url}, 
    );

    $test->($api,"Testing Live Freshservice API");
  }
}

method test_with_dancer($test, $number_tests) {
  SKIP: {
    if ($^O eq 'MSWin32') {
      eval {  
        require Win32::Process;
        require Win32;
      };
      skip 'These tests are for cached testing and require Win32::Process on Windows.', $number_tests if ($@);
    }
    eval {  
      require Dancer2;
      require Storable;
      require Scalar::Util;
    };

    skip 'These tests are for cached testing and require Dancer2, Storable + Scalar::Util.', $number_tests if ($@);
    skip 'Dancer2 >= 0.200000 required for these tests.', $number_tests unless $Dancer2::VERSION >= 0.200000;

    my ($win32_processobj, $pid);
    if ($^O eq 'MSWin32') {
        Win32::Process::Create($win32_processobj,
            "$^X",
            "$^X t/bin/cached_api.pl",
            0,
            32 + 134217728, #NORMAL_PRIORITY_CLASS + CREATE_NO_WINDOW
            ".") || die $^E;
        $pid = $win32_processobj->GetProcessID();
    } else {
        $pid = fork();

        if (!$pid) {
          exec($^X,"t/bin/cached_api.pl");
        }
    }

    # Allow some time for the instance to spawn. TODO: Make this smarter
    sleep 5;

    my $api = WebService::Freshservice::API->new(
      apikey => 'aReallyGoodone..', 
      apiurl => "http://localhost:3001",
    );

    $test->($api, "Testing Cached Freshservice API");
  
    # Kill Dancer
    kill 9, $pid;
  }
}

1;
