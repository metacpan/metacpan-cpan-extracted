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

use Win32::Mechanize::NotepadPlusPlus::Editor ':vars';

my $count;

eval '$count = scalar keys %nppm; 1' or do { $count = undef; };
ok !defined($count), '%nppm undefined'; note sprintf 'keys %%nppm => %s', defined($count) ? $count : '<undef>';

eval '$count = scalar keys %nppidm; 1' or do { $count = undef; };
ok !defined($count), '%nppidm undefined'; note sprintf 'keys %%nppidm => %s', defined($count) ? $count : '<undef>';

eval '$count = scalar keys %scimsg; 1' or do { $count = undef; };
ok defined($count), '%scimsg'; note sprintf 'keys %%scimsg => %s', defined($count) ? $count : '<undef>';

done_testing;