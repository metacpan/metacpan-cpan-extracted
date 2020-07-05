#!/usr/bin/env perl
##########################################
# looks for integers on each line of the
#   active file, and replaces them with
#   integer+1
# will group all the replacements as a
#   single undo action
##########################################
use warnings;
use strict;
use Win32::Mechanize::NotepadPlusPlus qw/:main/;

# for chomping purposes
$/=("\r\n", "\r", "\n")[ editor->getEOLMode() ];

editor()->beginUndoAction();
my $nLines = editor()->getLineCount();
for my $l ( 0 .. $nLines-1 ) {
    local $_ = editor()->getLine($l);
    chomp;
    next unless /\d+/;
    s/([-+]?\d+)/$1+1/ge;
    my $psol = editor()->positionFromLine($l);
    my $peol = editor()->getLineEndPosition($l);
    editor()->setSel($psol, $peol);
    editor()->replaceSel($_);
}
editor()->endUndoAction();
