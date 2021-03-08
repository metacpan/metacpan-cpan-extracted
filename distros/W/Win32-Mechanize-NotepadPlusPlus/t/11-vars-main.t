########################################################################
# Verifies the global message variables when loaded from parent module
########################################################################
use 5.010;
use strict;
use warnings;
sub nNotepad() { 14 };
sub nScintilla() { 63 };
use Test::More tests => nNotepad+nScintilla+2;

use FindBin;
BEGIN { my $f = $FindBin::Bin . '/nppPath.inc'; require $f if -f $f; }

use Win32::Mechanize::NotepadPlusPlus ':vars';

my %hashes = (
    # notepad hashes
    '%NPPMSG' => \%NPPMSG,
    '%VIEW' => \%VIEW,
    '%MODELESS' => \%MODELESS,
    '%STATUSBAR' => \%STATUSBAR,
    '%MENUHANDLE' => \%MENUHANDLE,
    '%INTERNALVAR' => \%INTERNALVAR,
    '%LANGTYPE' => \%LANGTYPE,
    '%WINVER' => \%WINVER,
    '%WINPLATFORM' => \%WINPLATFORM,
    '%NOTIFICATION' => \%NOTIFICATION,
    '%DOCSTATUS' => \%DOCSTATUS,
    '%NPPIDM' => \%NPPIDM,
    '%BUFFERENCODING' => \%BUFFERENCODING,
    '%LINENUMWIDTH' => \%LINENUMWIDTH,

    # editor hashes
    '%SCIMSG' => \%SCIMSG ,
    '%SCINTILLANOTIFICATION' => \%SCINTILLANOTIFICATION ,
    '%SCN_ARGS' => \%SCN_ARGS,
    '%SC_ACCESSIBILITY' => \%SC_ACCESSIBILITY,
    '%SC_ALPHA' => \%SC_ALPHA,
    '%SC_ANNOTATION' => \%SC_ANNOTATION,
    '%SC_AUTOC_ORDER' => \%SC_AUTOC_ORDER,
    '%SC_AUTOMATICFOLD' => \%SC_AUTOMATICFOLD,
    '%SC_BIDIRECTIONAL' => \%SC_BIDIRECTIONAL,
    '%SC_CACHE' => \%SC_CACHE,
    '%SC_CARETPOLICY' => \%SC_CARETPOLICY,
    '%SC_CARETSTICKY' => \%SC_CARETSTICKY,
    '%SC_CARETSTYLE' => \%SC_CARETSTYLE,
    '%SC_CASE' => \%SC_CASE,
    '%SC_CASEINSENSITIVE' => \%SC_CASEINSENSITIVE,
    '%SC_CHARSET' => \%SC_CHARSET,
    '%SC_CODEPAGE' => \%SC_CODEPAGE,
    '%SC_CURSOR' => \%SC_CURSOR,
    '%SC_DOCUMENTOPTION' => \%SC_DOCUMENTOPTION,
    '%SC_EDGEMODE' => \%SC_EDGEMODE,
    '%SC_EOL' => \%SC_EOL,
    '%SC_EOLSUPPORT' => \%SC_EOLSUPPORT,
    '%SC_FIND' => \%SC_FIND,
    '%SC_FOLDACTION' => \%SC_FOLDACTION,
    '%SC_FOLDDISPLAYTEXT' => \%SC_FOLDDISPLAYTEXT,
    '%SC_FOLDFLAG' => \%SC_FOLDFLAG,
    '%SC_FOLDLEVEL' => \%SC_FOLDLEVEL,
    '%SC_FONTQUAL' => \%SC_FONTQUAL,
    '%SC_FONTSIZE' => \%SC_FONTSIZE,
    '%SC_IDLESTYLING' => \%SC_IDLESTYLING,
    '%SC_IME' => \%SC_IME,
    '%SC_INDENTGUIDE' => \%SC_INDENTGUIDE,
    '%SC_INDIC' => \%SC_INDIC,
    '%SC_INDICSTYLE' => \%SC_INDICSTYLE,
    '%SC_KEY' => \%SC_KEY,
    '%SC_KEYWORDSET' => \%SC_KEYWORDSET,
    '%SC_LINECHARACTERINDEX' => \%SC_LINECHARACTERINDEX,
    '%SC_MARGIN' => \%SC_MARGIN,
    '%SC_MARK' => \%SC_MARK,
    '%SC_MARKNUM' => \%SC_MARKNUM,
    '%SC_MOD' => \%SC_MOD,
    '%SC_MULTIAUTOC' => \%SC_MULTIAUTOC,
    '%SC_MULTIPASTE' => \%SC_MULTIPASTE,
    '%SC_PHASES' => \%SC_PHASES,
    '%SC_POPUP' => \%SC_POPUP,
    '%SC_PRINTCOLOURMODE' => \%SC_PRINTCOLOURMODE,
    '%SC_SEL' => \%SC_SEL,
    '%SC_STATUS' => \%SC_STATUS,
    '%SC_STYLE' => \%SC_STYLE,
    '%SC_TABDRAW' => \%SC_TABDRAW,
    '%SC_TECHNOLOGY' => \%SC_TECHNOLOGY,
    '%SC_TEXTRETRIEVAL' => \%SC_TEXTRETRIEVAL,
    '%SC_TIMEOUT' => \%SC_TIMEOUT,
    '%SC_TYPE' => \%SC_TYPE,
    '%SC_UNDO' => \%SC_UNDO,
    '%SC_VIRTUALSPACE' => \%SC_VIRTUALSPACE,
    '%SC_VISIBLE' => \%SC_VISIBLE,
    '%SC_WEIGHT' => \%SC_WEIGHT,
    '%SC_WHITESPACE' => \%SC_WHITESPACE,
    '%SC_WRAPINDENT' => \%SC_WRAPINDENT,
    '%SC_WRAPMODE' => \%SC_WRAPMODE,
    '%SC_WRAPVISUALFLAG' => \%SC_WRAPVISUALFLAG,
    '%SC_WRAPVISUALFLAGLOC' => \%SC_WRAPVISUALFLAGLOC,
);

for my $name ( sort keys %hashes ) {
    #diag explain $href;
    ok scalar keys %{ $hashes{$name} }, "checking $name"
        or diag "$name = ", explain $hashes{$name};
}

is scalar @Win32::Mechanize::NotepadPlusPlus::EXPORT_VARS, nNotepad+nScintilla, 'number of exportable variables'
    or diag explain \@Win32::Mechanize::NotepadPlusPlus::EXPORT_VARS;

is_deeply [sort @Win32::Mechanize::NotepadPlusPlus::EXPORT_VARS], [sort keys %hashes], 'list of exportable variables';

done_testing;
