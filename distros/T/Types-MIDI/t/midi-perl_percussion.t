#!/usr/bin/env perl

use Test2::V0;
use MIDI;
use Types::MIDI;

plan 1 + keys %MIDI::notenum2percussion;    ## no critic (Variables::ProhibitPackageVars)

can_ok( 'Types::MIDI', ['to_PercussionNote'],
    'can test PercussionNote' )
    or bail_out('Types::MIDI lacks to_PercussionNote function');

no Types::MIDI;
use Types::MIDI 'to_PercussionNote';

for ( values %MIDI::notenum2percussion ) {    ## no critic (Variables::ProhibitPackageVars)
    ok to_PercussionNote($_), "$_ from MIDI-Perl";
}
