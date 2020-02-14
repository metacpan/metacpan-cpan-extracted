########################################################################
# Verifies the default objects exist
#   notepad()
#   editor1()
#   editor2()
########################################################################
use 5.010;
use strict;
use warnings;
use Test::More tests => 4;

use Win32::Mechanize::NotepadPlusPlus ':main';

my $npp = notepad();
isa_ok $npp, 'Win32::Mechanize::NotepadPlusPlus::Notepad', 'default NPP object';
ok editor(),  'default editor()  object';
ok editor1(), 'default editor1() object';
ok editor2(), 'default editor2() object';
