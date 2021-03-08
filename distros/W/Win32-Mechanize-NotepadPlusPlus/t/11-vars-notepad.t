########################################################################
# Verifies the message variables when loaded from parent module
#   %NPPMSG
#   %NPPIDM
#   %SCIMSG
########################################################################
use 5.010;
use strict;
use warnings;
sub nNotepad() { 14 };
use Test::More tests => nNotepad+2;

use FindBin;
BEGIN { my $f = $FindBin::Bin . '/nppPath.inc'; require $f if -f $f; }

use Win32::Mechanize::NotepadPlusPlus::Notepad ':vars';

my %hashes = (
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
);

for my $name ( sort keys %hashes ) {
    #diag explain $href;
    ok scalar keys %{ $hashes{$name} }, "checking $name"
        or diag "$name = ", explain $hashes{$name};
}

is scalar @Win32::Mechanize::NotepadPlusPlus::Notepad::EXPORT_VARS, nNotepad, 'number of exportable variables'
    or diag explain \@Win32::Mechanize::NotepadPlusPlus::Notepad::EXPORT_VARS;

is_deeply [sort @Win32::Mechanize::NotepadPlusPlus::Notepad::EXPORT_VARS], [sort keys %hashes], 'list of exportable variables';

done_testing;
