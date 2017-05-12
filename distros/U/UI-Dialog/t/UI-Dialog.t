# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

#use Test::More ( skip_all => "Skipped until better tests are written." );

use Test::More;
BEGIN { use_ok( 'UI::Dialog' ); }
require_ok( 'UI::Dialog' );

# #########################

# # Insert your test code below, the Test::More module is use()ed here so read
# # its man page ( perldoc Test::More ) for help writing this test script.

my $obj = UI::Dialog->new();
isa_ok( $obj, 'UI::Dialog' );

my @methods = qw( new state ra rs rv nautilus xosd beep clear
                  yesno msgbox inputbox password textbox menu
                  checklist radiolist fselect dselect );
can_ok( 'UI::Dialog', @methods );

done_testing();
