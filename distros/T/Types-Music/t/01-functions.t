#!/usr/bin/env perl

use Test2::V0;
plan 22;

use Types::Music;

can_ok 'Types::Music', [
    map { ( $_, "is_$_", "assert_$_", "to_$_" ) } qw(
        Octave
        Named_Note_Octave
    )
], 'type functions';

no Types::Music;
use Types::Music -all;

imported_ok
    map { ( $_, "is_$_", "assert_$_", "to_$_" ) } qw(
        Octave
        Named_Note_Octave
    );

ok is_BPM(120), 'is_BPM';
is 120, assert_BPM(120), 'assert_BPM';

ok is_Bars(8), 'is_Bars';
is 8, assert_Bars(8), 'assert_Bars';

ok is_Beats(4), 'is_Beats';
is 4, assert_Beats(4), 'assert_Beats';

ok is_Divisions(4), 'is_Divisions';
is 4, assert_Divisions(4), 'assert_Divisions';

ok is_Octave(4), 'is_Octave';
is 4, assert_Octave(4), 'assert_Octave';

ok is_Signature('3/4'), 'is_Signature';
is '3/4', assert_Signature('3/4'), 'assert_Signature';

ok is_Key('C#'), 'is_Key';
is 'C#', assert_Key('C#'), 'assert_Key';

ok is_Named_Note('Bf'), 'is_Named_Note';
is 'Bf', assert_Named_Note('Bf'), 'assert_Named_Note';

ok is_Named_Note_Octave('C4'), 'is_Named_Note_Octave';
is 'C4', assert_Named_Note_Octave('C4'), 'assert_Named_Note_Octave';

ok is_Mode('ionian'), 'is_Mode';
is 'ionian', assert_Mode('ionian'), 'assert_Mode';
