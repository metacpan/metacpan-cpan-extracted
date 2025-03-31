#!/usr/bin/env perl

use Test2::V0;
plan 2;

use Types::MIDI;

can_ok 'Types::MIDI', [
    map { ( $_, "is_$_", "assert_$_", "to_$_" ) }
        qw(
        Channel
        Velocity
        Note
        PercussionNote
        )
    ],
    'types and their Type::Library functions';

no Types::MIDI;
use Types::MIDI -all;

imported_ok
    map { ( $_, "is_$_", "assert_$_", "to_$_" ) }
    qw(
    Channel
    Velocity
    Note
    PercussionNote
    );
