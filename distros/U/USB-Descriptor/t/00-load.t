#!perl -T

use Test::More tests => 11;

BEGIN {
    use_ok( 'USB::Descriptor' ) || print "Bail out!\n";
    use_ok( 'USB::Descriptor::Device' ) || print "Bail out!\n";
    use_ok( 'USB::Descriptor::Interface' ) || print "Bail out!\n";
    use_ok( 'USB::Descriptor::Configuration' ) || print "Bail out!\n";
    use_ok( 'USB::Descriptor::Endpoint' ) || print "Bail out!\n";
    use_ok( 'USB::HID' ) || print "Bail out!\n";
    use_ok( 'USB::HID::Descriptor::Class' ) || print "Bail out!\n";
    use_ok( 'USB::HID::Descriptor::Interface' ) || print "Bail out!\n";
    use_ok( 'USB::HID::Descriptor::Report' ) || print "Bail out!\n";
    use_ok( 'USB::HID::Report' ) || print "Bail out!\n";
    use_ok( 'USB::HID::Report::Field' ) || print "Bail out!\n";
}

diag( "Testing USB::Descriptor $USB::Descriptor::VERSION, Perl $], $^X" );
