########################################################################
# Verifies messaging
#   notepad()
#   editor1()
#   editor2()
########################################################################
use 5.010;
use strict;
use warnings;
use Test::More;

use Win32::Mechanize::NotepadPlusPlus::Notepad ':vars';
use Win32::Mechanize::NotepadPlusPlus::Editor ':vars';
BEGIN {
    my $MUT = 'Win32::Mechanize::NotepadPlusPlus::__hwnd';      # module under test
    use_ok( $MUT ) or diag "Couldn't even load $MUT";
}

##### HWND CREATION
my $npp = Win32::Mechanize::NotepadPlusPlus::Notepad->_new();
isa_ok $npp, 'Win32::Mechanize::NotepadPlusPlus::Notepad', 'NPP object created';
ok $npp->hwnd(), 'NPP object has non-zero hwnd' or diag explain $npp;

my $w = Win32::Mechanize::NotepadPlusPlus::__hwnd->new($npp->hwnd());
isa_ok $w, 'Win32::Mechanize::NotepadPlusPlus::__hwnd', 'new __hwnd object created with same hwnd value as NPP main object';
note explain $w;
ok $w->hwnd(), 'NPP object has non-zero hwnd' or diag explain $w;
is $w->hwnd(), $npp->hwnd(), 'NPP object and dummy HWND object use same HWND value' or diag explain $w;

##### NOTEPAD++ MESSAGES
# also covers HWND SendMessage_* variants
my $view = $w->SendMessage($NPPMSG{NPPM_GETCURRENTVIEW}, 0, 0);
like $view, qr/^[01]$/, 'GetCurrentView (should be 0 or 1): '. ($view//'<undef>');

my $ival = $w->SendMessage_get32u($NPPMSG{NPPM_GETCURRENTLANGTYPE}, 0);
note sprintf "langtype ival = '%s'\n", $ival // '<undef>';
ok defined $ival, 'SendMessage_get32u: ' . ($ival//'<undef>');

my $sval = $w->SendMessage_getUcs2le($NPPMSG{NPPM_GETLANGUAGEDESC}, $ival, { trim => 'retval'} );
note sprintf "langdesc sval = '%s'\n", $sval // '<undef>';
ok defined $sval, 'GetLanguageDesc('.($ival//'<undef>').'): "' . ($sval//'<undef>') . '"';

##### SCINTILLA MESSAGES

# first, get the scintilla object
my $edwin = $npp->editor()->{_hwobj};
isa_ok $edwin, 'Win32::Mechanize::NotepadPlusPlus::__hwnd', 'main editor';

# second, send the message
my $eolmode = $edwin->SendMessage( $SCIMSG{SCI_GETEOLMODE}, 0 , 0);
like $eolmode, qr/^[012]$/, 'SCI_GETEOLMODE (should be 0,1, or 2): '. ($eolmode//'<undef>');

done_testing();
