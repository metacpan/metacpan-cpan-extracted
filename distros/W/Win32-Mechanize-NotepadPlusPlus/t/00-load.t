########################################################################
# Verifies the module loads are okay
########################################################################
use 5.010;
use strict;
use warnings;
use Test::More tests => 7;

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
        'Win32::Mechanize::NotepadPlusPlus::__npp_msgs',
        'Win32::Mechanize::NotepadPlusPlus::__npp_idm',
        'Win32::Mechanize::NotepadPlusPlus::__sci_msgs',
    ) {
        my $r = use_ok( $ModUnderTest ) or diag "Couldn't even load $ModUnderTest";
    }
}
