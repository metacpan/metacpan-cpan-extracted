#!/usr/bin/perl
use strict;
use warnings;
use Test::More tests => 4;

BEGIN { use_ok('WWW::Gazetteer'); }

my $g = WWW::Gazetteer->new('getty');
is_deeply(
    $g->find( "London", "United Kingdom" )->[0],
    {   longitude => "-0.0833",
        latitude  => "51.5000",
        city      => 'London',
        country   => 'United Kingdom',
    }
);
is_deeply(
    $g->find( "London", "UK" )->[0],
    {   longitude => "-0.0833",
        latitude  => "51.5000",
        city      => 'London',
        country   => 'United Kingdom',
    }
);
my $nice = $g->find( "Nice", "France" )->[0];
is_deeply(
    $nice,
    {   longitude => "7.2667",
        latitude  => "43.7000",
        city      => 'Nice',
        country   => 'France',
    }
);
