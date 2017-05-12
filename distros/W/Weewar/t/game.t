#!/usr/bin/env perl
# Copyright (c) 2007 Jonathan Rockway <jrockway@cpan.org>

use strict;
use warnings;

use t::lib::WeewarTest;
use Test::TableDriven (
  scalars => { name              => 'nonamegame',
               round             => 15,
               state             => 'finished',
               pending_invites   => undef,
               pace              => 86400,
               url               => 'http://weewar.com/game/25828',
               map               => 'tragictriangle1187105175786',
               map_url           => 
                         'http://weewar.com/map/tragictriangle1187105175786',
               credits_per_base  => 100,
               initial_credits   => 300,
               playing_since     => '2007-09-16T12:55:24',
             },
   lists  => { players => [ { name => 'jrockway', result => 'surrendered' },
                            { name => 'marcusramberg', result => 'victory' },
                          ],
             },
);

my $nonamegame = Weewar->game('25828');

sub scalars {
    my $method = shift;
    return $nonamegame->$method;
}

sub lists {
    my $method = shift;
    return [$nonamegame->$method];
}

runtests;
