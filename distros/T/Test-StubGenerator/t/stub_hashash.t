#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

BEGIN {
  eval "use Test::Exception";
  plan skip_all => 'Test::Exception required for tests' if $@;
}

plan tests => 4;

use_ok( 'Test::StubGenerator' );

my $source =<<'EOS';
package test;
sub new {
  my( $class, %args ) = @_;
  return bless {}, $class;
}
sub name {
  my $self = shift;
  return $self->{ name };
}
sub args {
  my $self = shift;
  my %arg_hash = @_;
  return 1;
}
EOS
ok ( my $stub = Test::StubGenerator->new( { source => \$source, tidy => 0 } ),
    'calling new given valid looking source' );
ok( my $tests = $stub->gen_testfile, 'produced tests' );
my $expected = return_expected();
is( $tests, $expected, 'got back what we expected' );

sub return_expected {
  return<<'EOE';
#!/usr/bin/perl

use strict;
use warnings;

use Test::More qw/no_plan/;

BEGIN { use_ok( 'test' ); }

ok( my $obj = test->new(), 'can create object test' );
isa_ok( $obj, 'test', 'object $obj' );
can_ok( $obj, 'args', 'name' );

# Create some variables with which to test the test objects' methods
# Note: give these some reasonable values.  Then try unreasonable values :)
my %arg_hash = ( '' => '', );

# And now to test the methods/subroutines.
ok( $obj->args( %arg_hash ), 'can call $obj->args()' );
ok( $obj->args(), 'can call $obj->args() without params' );

ok( $obj->name(), 'can call $obj->name() without params' );


EOE
}
