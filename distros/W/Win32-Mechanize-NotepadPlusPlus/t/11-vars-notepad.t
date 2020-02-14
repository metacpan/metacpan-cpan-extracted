########################################################################
# Verifies the message variables when loaded from parent module
#   %nppm
#   %nppidm
#   %scimsg
########################################################################
use 5.010;
use strict;
use warnings;
use Test::More tests => 3;

use Win32::Mechanize::NotepadPlusPlus::Notepad ':vars';

my $count;

eval '$count = scalar keys %nppm; 1' or do { $count = undef; };
ok defined($count), '%nppm'; note sprintf 'keys %%nppm => %s', defined($count) ? $count : '<undef>';

eval '$count = scalar keys %nppidm; 1' or do { $count = undef; };
ok defined($count), '%nppidm'; note sprintf 'keys %%nppidm => %s', defined($count) ? $count : '<undef>';

eval '$count = scalar keys %scimsg; 1' or do { $count = undef; };
ok !defined($count), '%scimsg undefined'; note sprintf 'keys %%scimsg => %s', defined($count) ? $count : '<undef>';

done_testing;