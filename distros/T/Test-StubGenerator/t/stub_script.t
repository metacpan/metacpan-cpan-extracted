#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 4;

use File::Find;
use File::Spec;

BEGIN { use_ok( 'Test::StubGenerator' ); }

ok( my $stub = Test::StubGenerator->new( { file  => 't/inc/myscript.pl', tidy => 0 } ),
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

BEGIN { require_ok( 't/inc/myscript.pl' ); }

my $num = '';
my $add = '';

# And now to test the methods/subroutines.
ok( addnum( $num, $add ), 'can call addnum()' );
ok( addnum(), 'can call addnum() without params' );


END_EXPECTED
}
