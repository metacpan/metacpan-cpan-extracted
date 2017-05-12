use strict;

use Win32::MIDI;

my $midi_obj = Win32::MIDI->new();

$midi_obj->openDevice(1);


my $note64 = $midi_obj->value_of('note',64);

print("(character) Note Value for 64 is $note64\n");


$midi_obj->play_note('B#',2,127,1,1,4) || print $midi_obj->error() . "\n" and $midi_obj->reset_error();
$midi_obj->play_note('100',2.5,127,1,1) || print $midi_obj->error() . "\n" and $midi_obj->reset_error();

