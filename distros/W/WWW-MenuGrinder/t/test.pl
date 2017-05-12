#!/usr/bin/perl 

use strict;
use warnings;

use Data::Dumper;
use Benchmark;

my $grinder;

use lib 't/lib';

timethis(1, sub {
    require Test::MenuGrinder;
    $grinder = Test::MenuGrinder->new(
      config => {
        plugins => {
          loader => 'XMLLoader',
          on_load => [
            'DefaultTarget',
            'Hotkey',
          ],
          per_request => [
            'FileReloader',
            'Variables',
            'ActivePath',
          ],
        },
        filename => 't/menu.xml',
      },
    );

    print Dumper $grinder->get_menu;
  }
);

timethese(-5, {
  get_menu => sub { $a = $grinder->get_menu },
  get_menu_reload => sub { utime undef, undef, "t/menu.xml"; $a = $grinder->get_menu },
});

