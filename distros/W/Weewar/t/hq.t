#!/usr/bin/env perl
# Copyright (c) 2007 Jonathan Rockway <jrockway@cpan.org>

use strict;
use warnings;

use t::lib::WeewarTest;
use Test::TableDriven (
  lists   => { games => [map +{ id => $_ }, qw/27093 25828 27008 27054 27055/],
               in_need_of_attention => [{ id => 27093 }],
             },
);

my $hq = Weewar->hq(jrockway => 'some made up API key what do i care');

sub lists {
    my $method = shift;
    return [$hq->$method];
}

runtests;
