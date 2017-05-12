#!/usr/bin/perl

use strict;
use warnings;

use Test::More qw/no_plan/;

use File::Find;
use File::Spec;

BEGIN { use_ok( 'Test::StubGenerator' ); }


ok( my $stub = Test::StubGenerator->new( { file  => 't/inc/Instance.pm', tidy => 0 } ),
    'can call new' );

ok( my $output = $stub->gen_testfile, 'got output' );

my $expected = return_mod_expected();

is( $output, $expected, 'got back what we were expecting' );

sub return_mod_expected {
  return <<'END_EXPECTED';
#!/usr/bin/perl

use strict;
use warnings;

use Test::More qw/no_plan/;

BEGIN { use_ok( 'Instance' ); }

ok( my $obj = Instance->instance(), 'can create object Instance' );
isa_ok( $obj, 'Instance', 'object $obj' );
can_ok( $obj, 'get_name', 'set_name', 'set_names' );

# Create some variables with which to test the Instance objects' methods
# Note: give these some reasonable values.  Then try unreasonable values :)
my @names = ( '', );

# And now to test the methods/subroutines.
ok( $obj->get_name(), 'can call $obj->get_name() without params' );

ok( $obj->set_name(), 'can call $obj->set_name() without params' );

ok( $obj->set_names( @names ), 'can call $obj->set_names()' );
ok( $obj->set_names(), 'can call $obj->set_names() without params' );


END_EXPECTED
}
