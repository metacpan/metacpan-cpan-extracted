# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 02_inheritance.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 3;
BEGIN { use_ok('XML::XForms::Generator') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

my $model = xforms_model( { id => 'test' } );

isa_ok( $model, "XML::LibXML::Node" );

my $control = xforms_input( {},
							[ "label", {}, "Label" ] );

ok( $control->toString() eq qq|<xforms:input xmlns:xforms="http://www.w3.org/2002/xforms/cr"><xforms:label>Label</xforms:label></xforms:input>|, "String" );
