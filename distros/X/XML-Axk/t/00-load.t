#!perl -T
use 5.020;
use strict;
use warnings;
use Test::More tests => 6;
use Module::Loaded;

BEGIN {
    use_ok( 'XML::Axk' ) || print "Could not load XML::Axk\n";
    use_ok( 'XML::Axk::App' ) || print "Could not load XML::Axk::App\n";
    use_ok( 'XML::Axk::Core' ) || print "Could not load XML::Axk::Core\n";
}

diag( "Testing XML::Axk $XML::Axk::App::VERSION, Perl $], $^X" );
ok(is_loaded("XML::Axk"), "XML::Axk is loaded");
ok(is_loaded("XML::Axk::App"), "XML::Axk::App is loaded");
ok(is_loaded("XML::Axk::Core"), "XML::Axk::Core is loaded");

# vi: set ts=4 sts=4 sw=4 et ai: #
