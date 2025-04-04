#!/usr/bin/env perl

use Test2::V0;
plan 16;

use Types::Music;

can_ok 'Types::Music', [
    map { ( $_, "is_$_", "assert_$_", "to_$_" ) } qw(
        PosInt
        Octave
        Signature
        Key
        Named_Note
        Named_Note_Octave
        Mode
    )
], 'type functions';

no Types::Music;
use Types::Music -all;

imported_ok
    map { ( $_, "is_$_", "assert_$_", "to_$_" ) } qw(
        PosInt
        Octave
        Signature
        Key
        Named_Note
        Named_Note_Octave
        Mode
    );

ok is_PosInt(120), 'is_PosInt';
is 120, assert_PosInt(120), 'assert_PosInt';

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
