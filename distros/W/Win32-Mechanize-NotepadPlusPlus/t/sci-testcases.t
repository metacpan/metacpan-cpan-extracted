########################################################################
# the following were added to test for specific bugs or issues found after
#   release, for things
########################################################################
use 5.010;
use strict;
use warnings;
use Test::More;
use Win32;

use FindBin;
BEGIN { my $f = $FindBin::Bin . '/nppPath.inc'; require $f if -f $f; }

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
    notepad()->open( path($0)->absolute->canonpath() );
}

# https://github.com/pryrt/Win32-Mechanize-NotepadPlusPlus/issues/14
{
    # prep
    notepad->newFile();

    # original #14: getLine(1) for empty line should NOT return \0
    my $txt = editor->getLine(1);
    isnt $txt, "\0", 'ISSUE 14: getLine() for empty line should NOT return \0'
        or diag sprintf "\t!!!!! getLine = \"%s\" !!!!!\n", dumper($txt);
    is $txt, "", 'ISSUE 14: getLine() for empty line SHOULD return empty string';

    # reopen #14: ditto for getSelText()
    $txt = editor->getSelText();
    isnt $txt, "\0", 'ISSUE 14: getSelText() for empty selection should NOT return \0'
        or diag sprintf "\t!!!!! getLine = \"%s\" !!!!!\n", dumper($txt);
    is $txt, "", 'ISSUE 14: getSelText() for empty selection SHOULD return empty string';

    TODO: {
        # debug: can I tell the difference between the empty string of getSelText and actually finding a NUL character in the selection?
        local $TODO = "NUL to SPACE probably caused by Scintilla";
        editor->addText("\0");
        editor->selectAll();
        $txt = editor->getSelText();
        is $txt, "\0", 'ISSUE 14: getSelText() for actual NUL \\0 SHOULD return \\0 string' or
            diag sprintf "\t!!!!! getLine = \"%s\" intentional \\0 !!!!!\n", dumper($txt);
        editor->undo();
    }

    # cleanup
    notepad->close();
}

# setText("")
#   empty string would cause "WriteProcessMemory failed with error 87: the parameter is incorrect"
#       during appveyor tests, though not on my local machine
#   no separate bug report filed, though it was discovered during https://github.com/pryrt/Win32-Mechanize-NotepadPlusPlus/issues/15
{
    # prep
    notepad->newFile();

    editor->beginUndoAction();

    # add data
    editor->setText("Hello World");
    my $got = editor->getText();
    is $got, "Hello World", 'ISSUE 15: setText("Hello World") should set text';

    # set blank
    $got = undef;
    eval { editor->setText(""); 1; } or do { $got = "<crash: $@>"; };
    $got //= editor->getText();
    is $got, "", 'ISSUE 15: setText("") should clear text';

    # cleanup
    editor->endUndoAction();
    editor->undo();
    notepad->close();
}

# The POD documentation lists a regex-based replaceTargetRE; that algorithm needs to be verified here
#   replaceTargetRE is also covered in sci-auto.t, as the example of method(arg)->msg(length,const char *)
#   see also https://github.com/pryrt/Win32-Mechanize-NotepadPlusPlus/issues/41
#   see also https://github.com/pryrt/Win32-Mechanize-NotepadPlusPlus/issues/42
{
    # prep
    notepad->newFile();

    # simple text
    editor->setText("Hello World");
    myTestHelpers::_mysleep_ms(50);

    # just look in "Hello"
    editor->setTargetRange(0,5);

    # do the search first
    editor->setSearchFlags($SC_FIND{SCFIND_REGEXP});
    my $find = editor->searchInTarget('([aeiou])');
        #diag sprintf "searchInTarget('([aeiou])')=%s\n", $searchret//'<undef>';
    is $find, 1, "ISSUE 41-42: searchInTarget('([aeiou])') found the correct first position";

    # do the replacement
    editor->replaceTargetRE('_\\1_');
    #my $got = editor->getTargetText(); # "H_e_llo World" ; starting in v7.9.1, the selection/target after a replace changed, ...
    my $got = editor->getText();        # ... so just check the whole text instead
        #diag sprintf "getTargetText() after replaceTargetRE = '%s'\n", dumper($got//'<undef>');
        #diag sprintf "getText() after replaceTargetRE = '%s'\n", dumper(editor->getText()//'<undef>');
    is $got, 'H_e_llo World', "ISSUE 41-42: replaceTargetRE(): use an actual regular expression";

    # cleanup
    editor->setSavePoint();
    notepad->closeAll();
}

# propertyNames(): should _not_ have final character chomped
#   https://github.com/pryrt/Win32-Mechanize-NotepadPlusPlus/issues/45
#   results of experimenting: as far as I can tell (searching API description for NUL),
#       propertyNames was the last remaining scintilla message that uses retval but doesn't include NUL in that length
{
    # prep
    notepad->newFile();
    notepad->setLangType($LANGTYPE{L_PERL});
    my $t = notepad->getLangType();

    # verify correct language
    is $t, $LANGTYPE{L_PERL}, 'setLangType(L_PERL) worked';

    # this is a dangerous test, because the lexer might change in the future
#editor->__trace_autogen();
#editor->{_hwobj}->__trace_raw_string();
    my $exp = "fold\nfold.comment\nfold.compact\nfold.perl.pod\nfold.perl.package\nfold.perl.comment.explicit\nfold.perl.at.else";
    my $got = editor->propertyNames();
    is $got, $exp, 'ISSUE 45: editor->propertyNames() needs to not chomp the last character';
#editor->{_hwobj}->__untrace_raw_string();
#editor->__untrace_autogen();

    # cleanup
    editor->setSavePoint();
    notepad->closeAll();
}

done_testing;
