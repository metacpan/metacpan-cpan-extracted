########################################################################
# Verifies Notepad Sessions work.
#   This is necessary for the functioning of other test files,
########################################################################
use 5.010;
use strict;
use warnings;
use Test::More;

use FindBin;
BEGIN { my $f = $FindBin::Bin . '/nppPath.inc'; require $f if -f $f; }

use lib $FindBin::Bin;
use myTestHelpers qw/:userSession/;

use Path::Tiny 0.018 qw/path tempfile/;

use Win32::Mechanize::NotepadPlusPlus ':main';

my $EmergencySessionHash;
BEGIN { $EmergencySessionHash = saveUserSession(); }
END { restoreUserSession( $EmergencySessionHash ); }

my $size = $EmergencySessionHash->{session}->is_file ? $EmergencySessionHash->{session}->stat()->size : 0;
ok $size, sprintf 'saveCurrentSession(): size(file) = %d', $size;

done_testing;
