# https://notepad-plus-plus.org/community/topic/15100/regex-rounding-numbers
use warnings;
use strict;
use Win32::Mechanize::NotepadPlusPlus qw/:main :vars/;
use POSIX qw/round/;

notepad->newFile();
editor->beginUndoAction();

# populate a new file from the __DATA__ section -- not part of the original question, but
#   necessary to be able to show end users how to use the module
editor->addText($_) for <DATA>;

my $eol = ("\r\n", "\r", "\n")[editor->getEOLMode()];

my $start = 0;
my $end = editor->getLineEndPosition( editor->getLineCount()-1 );

while($start < $end) {
    my $position = editor->findText($scimsg{SCFIND_REGEXP}, $start, $end, "-*\\d+\\.\\d{4,}"); # find any that are at more than 3 digits after the decimal point
    unless( defined $position ) {
        printf STDERR "\teditor.position is %s => nothing found...\n", $position//'<undef>';
        last;
    }

    # grab the matched text
    my $matched_number = editor->getTextRange(@$position);

    # round it -- print to 3-digit
    my $rounded = sprintf '%.3f', $matched_number;

    # replace it with rounded
    editor->setSel(@$position);
    editor->replaceSel($rounded);

    # next
    $start = $position->[1];
        # this is what I had in the original python, but really, since position->[1] was
        # at the end of the original match, I should really back up to the end of the
        # current selection; yep, by changing 16.14999 to 16.14999999999, I was able
        # to get it to skip 16.19999
        # replace the above with getSelectionEnd() retval:
    $start = editor->getSelectionEnd();

    sleep(1); # allow the user to watch the replacements happen
}

# cleanup
editor->endUndoAction();
editor->undo();
notepad->close();

__DATA__
10.1.117.9
16.01217
16.01297
16.01949
16.01999
16.14999999999
16.19999
16.99999
19.99999
199.9999
10.1.117.9
