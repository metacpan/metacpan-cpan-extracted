#!/usr/bin/perl

# Load testing for prefork.pm

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}
use Test::More tests => 18;

# Try to prefork-load a module
use prefork;
is( prefork::prefork('File::Spec::Functions'), 1, 'prefork returns true' );
is( $prefork::MODULES{'File::Spec::Functions'}, 'File/Spec/Functions.pm', 'Module is added to queue' );
ok( ! $INC{'File/Spec/Functions.pm'}, 'Module is not loaded' );

# Load outstanding modules
is( $prefork::FORKING, '', 'The $FORKING variable is false' );
is( prefork::enable(), 1, 'prefork::enable returns true' );
is( scalar(keys %prefork::MODULES), 0, 'All modules are loaded by enable' );
is( $prefork::FORKING, 1, 'The $FORKING variable is set' );
ok( $INC{'File/Spec/Functions.pm'}, 'Module is now loaded' );

# use in pragma form after enabling, using stringification
my $Foo = Foo->new;
isa_ok( $Foo, 'Foo' );
ok( ! $INC{'Test/Simple.pm'}, 'Test::Simple is not loaded' );
is( prefork::prefork($Foo), 1, 'prefork(Object) returns true' );
is( scalar(keys %prefork::MODULES), 0, 'The %MODULES hash is still empty' );
ok( $INC{'Test/Simple.pm'}, 'Test::Simple is loaded' );





#####################################################################
# Additional error-detection tests

eval { prefork::prefork(undef); };
ok( $@ =~ /You did not pass a module name to prefork/, 'bad prefork returns correct error' );
ok( $@ =~ /02_main/, 'bad prefork error returns from correct module' );
eval { prefork::prefork(''); };
ok( $@ =~ /You did not pass a module name to prefork/, 'bad prefork returns correct error' );
eval { prefork::prefork('Foo Bar') };
ok( $@ =~ /is not a module name/, 'bad prefork returns correct error' );
ok( $@ =~ /02_main/, 'bad prefork error returns from correct module' );

exit(0);



# Test class

package Foo;

use overload '""', 'string';

sub new { bless {}, 'Foo' };
sub string { 'Test::Simple' };

1;
