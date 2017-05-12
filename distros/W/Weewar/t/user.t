#!/usr/bin/env perl
# Copyright (c) 2007 Jonathan Rockway <jrockway@cpan.org>

use strict;
use warnings;

use t::lib::WeewarTest;
use Test::TableDriven (
  scalars => { points          => 1502,
               rating          => 1502,
               profile         => 'http://weewar.com/user/jrockway',
               draws           => 0,
               victories       => 1,
               losses          => 2,
               account_type    => 'Basic',
               ready_to_play   => undef,
               last_login      => '2007-09-16T07:28:35',
               bases_captured  => 12,
               credits_spent   => 38225,
             },
   lists  => { favorite_units    => [qw/lightInfantry lighttank heavyInfantry/],
               preferred_players => [{ name => 'marcusramberg' },
                                     { name => 'chumphries'    },
                                     { name => 'jshirley'      },
                                     { name => 'nick.rockway'  },
                                    ],
               preferred_by      => [{ name => 'jshirley'   },
                                     { name => 'chumphries' },
                                    ],
               games             => [ map {+{ id => $_ }}
                                      (qw/25828 27008 27054 27055/) ],
             },
);

my $jrock = Weewar->user('jrockway');

sub scalars {
    my $method = shift;
    return $jrock->$method;
}

sub lists {
    my $method = shift;
    return [$jrock->$method];
}

runtests;
