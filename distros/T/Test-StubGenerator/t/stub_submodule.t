#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 4;

use File::Find;
use File::Spec;

BEGIN { use_ok( 'Test::StubGenerator' ); }

ok( my $stub = Test::StubGenerator->new( { file  => 't/inc/MyObj/Sub.pm', tidy => 0 } ),
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

use lib '..';

BEGIN { use_ok( 'MyObj::Sub' ); }

ok( my $obj = MyObj::Sub->new(), 'can create object MyObj::Sub' );
isa_ok( $obj, 'MyObj::Sub', 'object $obj' );
can_ok( $obj, 'do_it' );

# Create some variables with which to test the MyObj::Sub objects' methods
# Note: give these some reasonable values.  Then try unreasonable values :)

# And now to test the methods/subroutines.
ok( $obj->do_it(), 'can call $obj->do_it() without params' );


END_EXPECTED
}
