########################################################################
# Verifies the module loads are okay
########################################################################
use 5.010;
use strict;
use warnings;
use Test::More tests => 6;

BEGIN {
    eval "
        use Win32::Mechanize::NotepadPlusPlus;
        1;
    " or do {
        note qq|use Win32::Mechanize::NotepadPlusPlus gave error message:\n\t$@\n|;
        BAIL_OUT "OS unsupported because it $@" if $@ =~ /^could not find an instance of \QNotepad++\E/i;
    };

    foreach my $ModUnderTest (
        'Win32::Mechanize::NotepadPlusPlus',
        'Win32::Mechanize::NotepadPlusPlus::Notepad',
        'Win32::Mechanize::NotepadPlusPlus::Editor',
        'Win32::Mechanize::NotepadPlusPlus::__hwnd',
        'Win32::Mechanize::NotepadPlusPlus::Notepad::Messages',
        'Win32::Mechanize::NotepadPlusPlus::Editor::Messages',
    ) {
        my $r = use_ok( $ModUnderTest ) or diag "Couldn't even load $ModUnderTest";
    }
}
