########################################################################
# Verifies the default objects exist
#   notepad()
#   editor1()
#   editor2()
########################################################################
use 5.010;
use strict;
use warnings;
use Test::More tests => 5;

use FindBin;
BEGIN { my $f = $FindBin::Bin . '/nppPath.inc'; require $f if -f $f; }

use Win32::Mechanize::NotepadPlusPlus ':main';

my $npp = notepad();
isa_ok $npp, 'Win32::Mechanize::NotepadPlusPlus::Notepad', 'default NPP object';
ok editor(),  'default editor()  object';
ok editor1(), 'default editor1() object';
ok editor2(), 'default editor2() object';

ok $npp->{_exe}, sprintf 'default NPP object found executable at "%s"', $npp->{_exe}//'<undef>'
    or BAIL_OUT("OS unsupported without valid Notepad++ executable found");
