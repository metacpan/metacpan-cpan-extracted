# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 04_control.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 2;
BEGIN { use_ok('XML::XForms::Generator') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

my $model = xforms_model( { id => 'test' } );

ok( $model->toString() eq qq|<xforms:model xmlns:xforms="http://www.w3.org/2002/xforms/cr" id="test"/>|, "String" );
