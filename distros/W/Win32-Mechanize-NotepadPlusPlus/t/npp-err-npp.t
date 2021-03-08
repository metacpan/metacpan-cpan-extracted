########################################################################
# Coverage tests for Notepad.pm application error conditions
########################################################################
use 5.010;
use strict;
use warnings;
use Test::More ;#tests => 4;
use Test::Exception;

use FindBin;
BEGIN { my $f = $FindBin::Bin . '/nppPath.inc'; require $f if -f $f; }

use lib $FindBin::Bin;
use myTestHelpers qw/:all/;
myTestHelpers::setChildEndDelay(2);

use Win32::Mechanize::NotepadPlusPlus qw/:main :vars/;

# ->editor() errors
{
    throws_ok {
        no warnings qw/redefine/;
        local *Win32::Mechanize::NotepadPlusPlus::Notepad::getCurrentView = sub { -1 };
        Win32::Mechanize::NotepadPlusPlus::editor();
    } qr/^\QNotepad->editor(): unknown GETCURRENTSCIINTILLA=\E/, '->editor() unknown view';
}
# ->open() errors
{
    throws_ok {
        notepad->open();
    } qr/^\Q->open() method requires \E\$\QfileName argument\E/, '->open() without filename';

    throws_ok {
        no warnings qw/redefine/;
        local *Win32::Mechanize::NotepadPlusPlus::__hwnd::SendMessage_sendStrAsUcs2le = sub { die "test coverage\n" };
        notepad->open('testcoverage.txt');
    } qr/^->open\(.*?\) died with msg:/, '->open() eval failed';
}

# ->createScintilla() errors
{
    my $keep_hwnd = notepad()->{_hwnd};
    throws_ok { # also covers ||= conditions 0,0
        notepad()->{_hwnd} = undef;
        notepad()->createScintilla(undef);
    } qr/\Qrequires HWND to use as the parent, not undef or an object\E/, '->createScintilla(undef) invalid parent with false _hwnd';

    throws_ok { # also covers ||= conditions 0,1
        notepad()->{_hwnd} = [];
        notepad()->createScintilla(undef);
    } qr/\Qrequires HWND to use as the parent, not undef or an object\E/, '->createScintilla(undef) invalid parent with true _hwnd';

    throws_ok { # also covers ||= conditions 1,x
        notepad()->createScintilla([]);
    } qr/\Qrequires HWND to use as the parent, not undef or an object\E/, '->createScintilla([]) invalid parent with true argument';

    notepad->{_hwnd} = $keep_hwnd;
}

# ->runMenuCommand() ->_findActionInMenu() uncovered case
{
    # force the "else return undef" condition
    #   I don't think there's any real way to get to that block inside _findActionInMenu, but
    #   I want to defensively program against something going wrong I don't understand.
    #   I can mock it by changing GetMenuItemID and GetSubMenu, so I'll cover that "error" condition.
    {
        no warnings qw/redefine/;
        local *Win32::Mechanize::NotepadPlusPlus::Notepad::GetSubMenu = sub { 0 };
        local *Win32::Mechanize::NotepadPlusPlus::Notepad::GetMenuItemID = sub { 0 };
        my $retval = notepad()->runMenuCommand('?|About Notepad++');
        is $retval, undef, '->runMenuCommand() unexpected condition: getMenuCommandID returning undef';
    }
    
    # {%opts} error checking: the "error" condition is a reference that is not a hash
    {
        my $retval = notepad()->runMenuCommand('File|New', []);
        ok $retval, '->runMenuCommand("File|New", []) with invalid options argument'
            or diag "\tretval = ", $retval // '<undef>';
        sleep 1, notepad->close() if $retval; # if the call ran, there is an empty tab which needs closing
    }
}

done_testing;
