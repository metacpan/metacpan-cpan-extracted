#!/usr/bin/env perl
##########################################
# based on my final PythonScript reply
#   to https://community.notepad-plus-plus.org/topic/14944/macro-complex-instructions
# this Perl version creates both example files,
# then runs the algorithm I originally posted
# It will be treated as a single undo action
##########################################
use warnings;
use strict;
use Win32::Mechanize::NotepadPlusPlus qw/:main :vars/;

$/=("\r\n", "\r", "\n")[ editor->getEOLMode() ];

##########################################
# create data
##########################################

# go to first view, whichever file is currently active in that view
notepad->activateIndex( 0, notepad()->getCurrentDocIndex(0));

# populate "file1" with aaa, bbb, ccc, ...
notepad->newFile();
editor1->addText("aaa$/bbb$/ccc$/ddd$/");

# populate "file2" with the twoline xxx replacement text
notepad->newFile();
notepad->moveCurrentToOtherView();
editor->addText($_.$/) for (
    "Blue Box xxx$/It contains grapes and xxx",
    "Red Box xxx$/It contains tomatoes and xxx",
    "Green Box xxx$/It contains oranges and xxx",
    "Yellow Box xxx$/It contains lemons and xxx"
);

##########################################
# perform algorithm
##########################################
editor1->beginUndoAction();
my $nLines = editor1->getLineCount();
for my $l ( 0 .. $nLines-1 ) {
    my $newValue = editor1->getLine($l);
    chomp $newValue;
    $newValue =~ s/\0//g;
    next unless length($newValue);
    print STDERR "editor1: #$l = \"$newValue\"\n";

    editor2->documentEnd();
    my $end2 = editor2->getCurrentPos();
    editor2->documentStart();
    my $start2 = editor2->getCurrentPos();

    for my $time ( 0, 1) {
        print STDERR "editor2: searching @ $start2:$end2\n";
        print STDERR "\ttime#$time!!!\n";
        my $position = editor2->findText( $scimsg{SCFIND_MATCHCASE}, $start2, $end2, "xxx");
        unless( defined $position ) {
            printf STDERR "\teditor2.position is %s, so skipping...\n", $position//'<undef>';
            last;
        }
        printf STDERR "\tfound \@ %s:%s\n", @$position;

        # select the "xxx"
        editor2->setSelectionStart($position->[0]);
        editor2->setSelectionEnd($position->[1]);
        # yes, I now know it could be editor2->setSel(@$position), but I didn't know that in Dec 2017

        # replace the selection with newValue
        editor2->replaceSel($newValue);

        # the cursor is now at the end of the replaced value, and we want to
        $start2 = editor2->getCurrentPos();
    }

}
editor1->endUndoAction();
