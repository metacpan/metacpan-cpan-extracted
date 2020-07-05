########################################################################
# these tests cover the scintilla helper functions
# https://github.com/pryrt/Win32-Mechanize-NotepadPlusPlus/issues/15
########################################################################
use 5.010;
use strict;
use warnings;
use Test::More;
use Win32;

use FindBin;
use lib $FindBin::Bin;
use myTestHelpers qw/:userSession dumper/;

use Path::Tiny 0.018 qw/path tempfile/;

use Win32::Mechanize::NotepadPlusPlus qw/:main :vars/;

#   if any unsaved buffers, HALT test and prompt user to save any critical
#       files, then re-run test suite.
my $EmergencySessionHash;
BEGIN { $EmergencySessionHash = saveUserSession(); }
END { restoreUserSession( $EmergencySessionHash ); }

BEGIN {
    notepad()->closeAll();
}

# HELPER: editor->flash();
#   cannot test if it flashes, but at least test that it warns
{
    my $warnmsg;

    # 1sec flash _without_ force: since warnings are fatal for this test, it won't actually flash for the 1sec
    undef $warnmsg;
    eval { use warnings FATAL => qw/Win32::Mechanize::NotepadPlusPlus::Editor/; editor->flash(1); 1; };
    $warnmsg = $@ // '<undef>';
    like $warnmsg, qr/\Qlong flash-time/, 'editor->flash(): warn on sec>=1';

    # 5sec flash _with_ force; also make sure elapsed time is ~5s
    my $t0 = time();
    undef $warnmsg;
    eval { use warnings FATAL => qw/Win32::Mechanize::NotepadPlusPlus::Editor/; editor->flash(5,1); 1; };
    $warnmsg = $@ // '<undef>';
    is $warnmsg, '', 'editor->flash(): no warn on forced sec>=1';
    my $dt = time() - $t0;
    cmp_ok $dt, '>', 3, 'editor->flash(5) took more than 3 sec';
    # For better accuracy, I would need Time::HiRes both here and to replace select() with Time::HiRes::sleep() in Editor.pm

    # default flash
    undef $warnmsg;
    eval { use warnings FATAL => qw/Win32::Mechanize::NotepadPlusPlus::Editor/; editor->flash(); 1; };
    $warnmsg = $@ // '<undef>';
    is $warnmsg, '', 'editor->flash(): no warn on default';
}

# HELPER: editor->forEachLine
#   file:///C:/usr/local/apps/notepad++/plugins/PythonScript/doc/scintilla.html#editor.forEachLine
#   Need to test that it can iterate thorugh all the lines normally
#   And try one where it the return value will make it increment 0
# do two tests: the first (here) where I test 1, 2, 0, and undef retvals
#   the second (below) where I test the example code
{
    editor->addText("$_\r\n") for 0..5;

    my @state;
    my $callback = sub {
        my ($contents, $lineNumber, $totalLines) = @_;
        #diag sprintf "callback(\"%s\",%s,%s)\n", dumper($contents), $lineNumber, $totalLines;
        push @state, $lineNumber;
        # will return 1 for line0, 2 for line1, 0 for the first line 5, and undef for any other line
        # this tests all the conditions described in the PythonScript docs on forEachLine()
        if(0 == $lineNumber) {
            return 1;
        } elsif(1 == $lineNumber) {
            return 2;
        } elsif (5==$lineNumber and $state[-2]!=$lineNumber) {
            return 0;
        }
        return;
    };

    editor->forEachLine( $callback );
    is_deeply \@state, [0,1,3,4,5,5,6], 'editor->forEachLine state';
    #note sprintf "\tstate = (%s)\n", join ',', @state;

    # cleanup
    editor->setText("");
    notepad->closeAll();
}

# HELPER: editor->forEachLine: implement the example code
#   HELPER: editor->deleteLine
#   HELPER: editor->replaceWholeLine [called by deleteLine]
#   HELPER: editor->replaceLine
#       ALSO COVERS: editor->replaceTarget
{
    # setup
    my $txt = "keep\nrubbish\nsomething old\nlittle something\nend of file";
    editor->setText($txt);
    (my $exp = $txt) =~ s/something old/something new/;
    $exp =~ s/little something/BIG\r\nSOMETHING/;
    $exp =~ s/rubbish\n//;

    sub testContents {
        my ($contents, $lineNumber, $totalLines) = @_;
        chomp($contents);
        #printf STDERR "testContents('%s')\n", dumper $contents;
        if($contents eq 'rubbish') {
            #printf STDERR "\tdelete the rubbish\n";
            eval { editor->deleteLine($lineNumber); 1; } and
            return 0; # stay on same line, because it's deleted
            #printf STDERR "\terr = '$@'\n";
        } elsif($contents eq 'something old') {
            #printf STDERR "\tchange the old\n";
            eval{ editor->replaceLine($lineNumber, "something new"); 1; };
            #printf STDERR "\terr = '$@'\n" if $@;
        } elsif($contents eq 'little something') {
            #printf STDERR "\tembiggen\n";
            eval{ editor->replaceLine($lineNumber, "BIG\r\nSOMETHING"); 1; };
            #printf STDERR "\terr = '$@'\n" if $@;
            return 2;   # replaced single with two lines, so need to go the extra line
        }
        #printf STDERR "\tcontinue\n";
        # could return 1 here, but undef works as well;
        #   note in perl, you _could_ just exit without returning, as in the PythonScript example,
        #   but in perl, that would return the last statement value, which isn't what you want
        return;
    }

    editor->forEachLine(\&testContents);

    my $got = editor->getText();
    is $got, $exp, 'editor->forEachLine example code came out right'
        or diag sprintf "actual: '%s'\n", dumper $got;

    # cleanup
    editor->setText("");
    notepad->closeAll();
}

# HELPER ALIASES:
#   HELPER: editor->write() as alias for editor->addText()
#   HELPER: editor->setTarget() as alias for editor->setTargetRange()
{
    # alias write for addText
    editor->write("Hello World");
    is editor->getText(), "Hello World", "editor->write works as alias for addText";

    # alias setTarget for setTargetRange
    editor->setTarget(6,11);
    editor->replaceTarget("Cosmos");
    is editor->getText(), "Hello Cosmos", "editor->setTarget works as alias for setTargetRange";

    # cleanup
    editor->setText("");
    notepad->closeAll();
}

# HELPER: editor->getWord
# HELPER: editor->getCurrentWord
{
    editor->setText("Hello World .:WEIRD-WORD:.");
    editor->gotoPos(3);     # inside "Hello"

    # current word (and defaults to getWord)
    my $got = editor->getCurrentWord();
    is $got, 'Hello', 'editor->getCurrentWord()';
        #note sprintf "\tresult = '%s'\n", dumper($got);

    # different position
    $got = editor->getWord(8);
    is $got, 'World', 'editor->getWord(8)';
        #note sprintf "\tresult = '%s'\n", dumper($got);

    # non-word?
    #       here's how it works in PythonScript:
    #       >>> editor.setText(".:WEIRD-WORD:.");
    #       >>> editor.setWordChars(""); editor.getWord(5,False)
    #       '.:WEIRD-WORD:.'
    #       >>> editor.setWordChars("-"); editor.getWord(5,False)
    #       '.:WEIRD'
    #       >>> editor.setCharsDefault(); editor.getWord(5,False)
    #       'WEIRD'
    editor->setWordChars("");
    $got = editor->getWord(15,0);
    is $got, '.:WEIRD-WORD:.', 'editor->getWord(15,0) with WordChars=""';
        #note sprintf "\tresult = '%s'\n", dumper($got);

    editor->setWordChars("-");
    $got = editor->getWord(15,0);
    is $got, '.:WEIRD', 'editor->getWord(15,0) with WordChars="-"';
        #note sprintf "\tresult = '%s'\n", dumper($got);

    editor->setCharsDefault();
    $got = editor->getWord(15,0);
    is $got, 'WEIRD', 'editor->getWord(15,0) with setCharsDefault';
        #note sprintf "\tresult = '%s'\n", dumper($got);

    # cleanup
    editor->setText("");
    notepad->closeAll();
}

# HELPER: editor.getUserLineSelection() -> [startLine, endLine]
# HELPER: editor.getUserCharSelection() -> [startByte, endByte]
{
    editor->setText("Hello World\r\nMiddle\r\nFarewell to thee");

    # no selection made, so beginning and end of file
    # default lines
    my $got = editor->getUserLineSelection();
    is_deeply $got, [0,2], 'editor->getUserLineSelection() with no selection';
        #note sprintf "\tresult = [%s]\n", join ',', map {$_//'<undef>'} @$got;

    # default bytes
    $got = editor->getUserCharSelection();
    is_deeply $got, [0,37], 'editor->getUserLineSelection() with no selection';
        #note sprintf "\tresult = [%s]\n", join ',', map {$_//'<undef>'} @$got;

    # make a selection
    editor->setSel(13, 29);

    # selected lines
    $got = editor->getUserLineSelection();
    is_deeply $got, [1,2], 'editor->getUserLineSelection() with active selection';
        #note sprintf "\tresult = [%s]\n", join ',', map {$_//'<undef>'} @$got;

    # selected bytes
    $got = editor->getUserCharSelection();
    is_deeply $got, [13,29], 'editor->getUserLineSelection() with active selection';
        #note sprintf "\tresult = [%s]\n", join ',', map {$_//'<undef>'} @$got;

    # cleanup
    editor->setText("");
    notepad->closeAll();
}

notepad->closeAll();

done_testing;

__END__
sub Win32::Mechanize::NotepadPlusPlus::Editor::forEachLine {
    my $self = shift;
    my $fn = shift;
    my $delta = 1;

    for(my $l=0; $l<$self->getLineCount(); $l += $delta ) {
        my $ret = $fn->( $self->getLine($l), $l, $self->getLineCount() );
        $delta = $ret//1;
    }
}
