########################################################################
# Verifies Notepad object messages / methods work
#   subgroup: meta-information methods
########################################################################
use 5.010;
use strict;
use warnings;
use Test::More;
use Win32;

use FindBin;
use lib $FindBin::Bin;
use myTestHelpers qw/runCodeAndClickPopup :userSession/;

use Path::Tiny 0.018 qw/path tempfile/;

use Win32::Mechanize::NotepadPlusPlus qw/:main :vars/;

my $EmergencySessionHash;
BEGIN { $EmergencySessionHash = saveUserSession(); }
END { restoreUserSession( $EmergencySessionHash ); }


# need a safe dummy file with known values (for the getNppVar tests)
our $fnew1 = tempfile( TEMPLATE => 'nppNewFile_XXXXXXXX', SUFFIX => '.txt'); note $fnew1->canonpath();
notepad->closeAll(); # don't want to affect existing files
editor->addText("MetaFile\n");
editor->addText( $fnew1->absolute->canonpath() );
notepad->saveAs( $fnew1->absolute->canonpath() );
editor->gotoPos( editor->getFileEndPosition() );

my $ret;
$ret = notepad()->getNppVersion;
like $ret, qr/^v\d+[\.\d]*$/, 'getNppVersion';
    note sprintf "\t=> \"%s\"", defined $ret ? explain $ret : '<undef>';

$ret = notepad()->getPluginVersion;
like $ret, qr/v\d+\.[\._\d]+/, 'getPluginVersion';
    note sprintf "\t=> \"%s\"", defined $ret ? explain $ret : '<undef>';

$ret = notepad()->getPerlVersion;
ok $ret, 'getPerlVersion';
    note sprintf "\t=> \"%s\"", defined $ret ? explain $ret : '<undef>';
$ret = notepad()->getPerlBits;
ok $ret, 'getPerlBits';
    note sprintf "\t=> \"%s\"", defined $ret ? explain $ret : '<undef>';

TODO: {
    local $TODO = 'unimplemented';
    $ret = notepad()->getCommandLine;
    is $ret, '', 'getCommandLine';
    note sprintf "\t=> \"%s\"", defined $ret ? explain $ret : '<undef>';
}

$ret = notepad()->getNppDir;
ok $ret, 'getNppDir';
    note sprintf "\t=> \"%s\"", defined $ret ? explain $ret : '<undef>';

$ret = notepad()->getPluginConfigDir;
ok $ret, 'getPluginConfigDir';
    note sprintf "\t=> \"%s\"", defined $ret ? explain $ret : '<undef>';

# 2020-Mar-17: add getNppVar()
$ret = notepad()->getNppVar( $INTERNALVAR{CURRENT_LINE} );
ok $ret, 'getNppVar(CURRENT_LINE)';
    note sprintf "\t=> \"%s\"", defined $ret ? explain $ret : '<undef>';

$ret = notepad()->getNppVar( $INTERNALVAR{CURRENT_COLUMN} );
ok $ret, 'getNppVar(CURRENT_COLUMN)';
    note sprintf "\t=> \"%s\"", defined $ret ? explain $ret : '<undef>';

$ret = notepad()->getNppVar( $INTERNALVAR{FULL_CURRENT_PATH} );
ok $ret, 'getNppVar(FULL_CURRENT_PATH)';
    note sprintf "\t=> \"%s\"", defined $ret ? explain $ret : '<undef>';

$ret = notepad()->getNppVar( $INTERNALVAR{CURRENT_DIRECTORY} );
ok $ret, 'getNppVar(CURRENT_DIRECTORY)';
    note sprintf "\t=> \"%s\"", defined $ret ? explain $ret : '<undef>';

$ret = notepad()->getNppVar( $INTERNALVAR{FILE_NAME} );
ok $ret, 'getNppVar(FILE_NAME)';
    note sprintf "\t=> \"%s\"", defined $ret ? explain $ret : '<undef>';

$ret = notepad()->getNppVar( $INTERNALVAR{NAME_PART} );
ok $ret, 'getNppVar(NAME_PART)';
    note sprintf "\t=> \"%s\"", defined $ret ? explain $ret : '<undef>';

$ret = notepad()->getNppVar( $INTERNALVAR{EXT_PART} );
ok $ret, 'getNppVar(EXT_PART)';
    note sprintf "\t=> \"%s\"", defined $ret ? explain $ret : '<undef>';

$ret = notepad()->getNppVar( $INTERNALVAR{CURRENT_WORD} );
ok $ret, 'getNppVar(CURRENT_WORD)';
    note sprintf "\t=> \"%s\"", defined $ret ? explain $ret : '<undef>';

$ret = notepad()->getNppVar( $INTERNALVAR{NPP_DIRECTORY} );
ok $ret, 'getNppVar(NPP_DIRECTORY)';
    note sprintf "\t=> \"%s\"", defined $ret ? explain $ret : '<undef>';

$ret = notepad()->getNppVar( $INTERNALVAR{NPP_FULL_FILE_PATH} );
ok $ret, 'getNppVar(NPP_FULL_FILE_PATH)';
    note sprintf "\t=> \"%s\"", defined $ret ? explain $ret : '<undef>';

done_testing;