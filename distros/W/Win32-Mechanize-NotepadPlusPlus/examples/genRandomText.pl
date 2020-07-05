#!/usr/bin/env perl
##########################################
# adds a random number of lines (1..10)
#   of random text, each with 20..80 characters
#   starting at the current cursor position
# will be treated as a single undo action
##########################################
use warnings;
use strict;
use Win32::Mechanize::NotepadPlusPlus qw/:main/;

$/=("\r\n", "\r", "\n")[ editor->getEOLMode() ];
my @chars = ('a'..'z', 'A'..'Z', (' ')x18);
editor()->beginUndoAction();
for my $l ( 1 .. 1+rand 9) {
    my $txt = join '', @chars[ map rand @chars, 20 .. 20+rand 60], $/;
    editor->addText($txt);
}
editor()->endUndoAction();
