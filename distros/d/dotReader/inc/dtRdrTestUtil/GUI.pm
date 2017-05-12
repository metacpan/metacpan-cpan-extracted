package main;

# Copyright (C) 2006 OSoft, Inc.
# License: GPL

use Carp;

use warnings;
use strict;

local $Test::Builder::Level = $Test::Builder::Level + 1;

use Wx;
use Wx::Event qw(
  EVT_IDLE
  );

my $package = eval { require("./client/app.pl") };
sub the_package () { $package; }

my $testing = 0;
sub set_testing { $testing = $_[0]; }

my $dosub = sub {warn "no sub here"};
sub set_dosub { $dosub = $_[0]; }

# switch-out the anno_io object
# TODO do this more cleanly (i.e. with a temp full user directory)
my $anno_io;
sub anno_io {
  $anno_io and return($anno_io);

  my $bvm = the_package()->_main_frame->bv_manager;
  require File::Temp;
  my $anno_io_dir = File::Temp::tempdir(
    'dtrdr-test' . 'X'x8,
    TMPDIR => 1, CLEANUP => 1
  );
  return($bvm->{anno_io} = $anno_io =
    dtRdr::Annotation::IO::YAML->new(uri => $anno_io_dir)
  );
}

ok((not $@), "require ok") or
  BAIL_OUT("error: " . join('\n', split(/\n+/, $@)));
ok($package, $package || 'got a package') or
  BAIL_OUT("app.pl failed to load...STOP");

# NOTE: crash will typically happen here.  If it does, we're dead in
# the water (probably a syntax error.)
my $app = eval {$package->new(); };
ok((not $@), "$package constructor") or
  BAIL_OUT("error: " . join('\n', split(/\n+/, $@)));
ok($app, 'application');



sub run {
  my $idle_ok = 0;
  EVT_IDLE($app, sub {
    my ($foo, $event) = @_;
    $idle_ok++;
    #warn "idle $idle_ok\n";
    if($idle_ok >= 1) {
      ($idle_ok == 1) and $dosub->();
      $testing or $app->ExitMainLoop;
    }
    else {
    }
    $event->Skip;
    1;
  });
  eval { $app->MainLoop(); };
  ok((not $@), "MainLoop done") or
    BAIL_OUT("error: " . join('\n', split(/\n+/, $@)));
  ok(1, 'MainLoop');
  ok($idle_ok, 'exit');
}

1;
# vim:ts=2:sw=2:et:sta
